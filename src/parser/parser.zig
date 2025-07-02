const std = @import("std");
const ast = @import("./ast.zig");
const token = @import("../lexer/token.zig");
const lex = @import("../lexer/lexer.zig");

const Allocator = std.mem.Allocator;
const Lexer = lex.Lexer;
const ASTNode = ast.ASTNode;
const ParseError = ast.ParseError;
const Token = token.Token;

// Parsers
const parseHeader = @import("./parse_header.zig").parseHeader;
const parseDelim = @import("./parse_delimiter.zig").parseDelimiter;
const parseQuote = @import("./parse_blockquote.zig").parseQuote;
const parseLink = @import("./parse_links.zig").parseLinks;

pub const Parser = struct {
    lexer: *Lexer,
    current_token: Token,
    peek_token: Token,
    prev_token: Token,
    allocator: Allocator,

    pub fn init(allocator: Allocator, lexer: *Lexer) !Parser {
        var parser = Parser{
            .lexer = lexer,
            .current_token = undefined,
            .peek_token = undefined,
            .prev_token = Token.newToken(.EOF, "EOF"),
            .allocator = allocator,
        };

        // init both current and peak tokens
        try parser.nextToken();
        try parser.nextToken();

        return parser;
    }

    pub fn nextToken(self: *Parser) !void {
        self.prev_token = self.current_token;
        self.current_token = self.peek_token;
        self.peek_token = try self.lexer.nextToken();
    }

    pub fn finalizeParagraph(_: *Parser, document: *ASTNode, paragraph_node: *?ASTNode) !void {
        if (paragraph_node.*) |*para| {
            try document.children.append(para.*);
            paragraph_node.* = null;
        }
    }

    pub fn parse(self: *Parser) !ASTNode {
        // Prep the main node.
        var document = ASTNode.init(self.allocator, .document);
        errdefer document.deinit();

        var paragraph_node: ?ASTNode = null;
        errdefer {
            if (paragraph_node) |*para| {
                para.deinit();
            }
        }

        while (self.current_token.type != .EOF) {
            switch (self.current_token.type) {
                .heading => {
                    try self.finalizeParagraph(&document, &paragraph_node);

                    const header_level: u8 = @intCast(self.current_token.literal.len);

                    const header_node = try parseHeader(self, header_level);
                    try document.children.append(header_node);
                },
                .quote => {
                    try self.finalizeParagraph(&document, &paragraph_node);

                    const quote_node = try parseQuote(self);
                    try document.children.append(quote_node);
                },
                .newLine => {
                    // If next token is also new line, finalise the current paragraph node
                    if (self.peek_token.type == .newLine) {
                        try self.finalizeParagraph(&document, &paragraph_node);
                    }

                    try self.nextToken();
                },
                .codeblock => {
                    try self.finalizeParagraph(&document, &paragraph_node);

                    var code_block_node = ASTNode.init(self.allocator, .codeblock);
                    code_block_node.content = self.current_token.literal;

                    if (self.current_token.class) |class| {
                        code_block_node.class = class;
                    }

                    try self.nextToken();
                    try document.children.append(code_block_node);
                },
                else => {
                    // A plain text node
                    // Create a new paragraph if null, add to the current one if not

                    if (paragraph_node == null) {
                        paragraph_node = ASTNode.init(self.allocator, .paragraph);
                    }

                    const inline_node = try self.parseInline();
                    try paragraph_node.?.children.append(inline_node);
                },
            }
        }

        try self.finalizeParagraph(&document, &paragraph_node);

        return document;
    }

    pub fn parseInline(self: *Parser) ParseError!ASTNode {
        const delim = self.current_token.type;

        switch (delim) {
            .text => {
                var text_node = ASTNode.init(self.allocator, .text);
                text_node.content = self.current_token.literal;

                try self.nextToken();
                return text_node;
            },
            .asterisk,
            .underscore,
            .tilde,
            .caret,
            => {
                const ast_node = try parseDelim(self, delim);

                return ast_node;
            },
            .code => {
                var code_node = ASTNode.init(self.allocator, .code);
                code_node.content = self.current_token.literal;

                try self.nextToken();
                return code_node;
            },
            .link => {
                const link_node = try parseLink(self);

                try self.nextToken();
                return link_node;
            },
            else => {
                var text_node = ASTNode.init(self.allocator, .text);
                text_node.content = self.current_token.literal;

                try self.nextToken();
                return text_node;
            },
        }
    }
};
