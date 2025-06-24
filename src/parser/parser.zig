const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const ast = @import("./ast.zig");
const token = @import("../lexer/token.zig");
const lex = @import("../lexer/lexer.zig");

const Lexer = lex.Lexer;
const NodeType = ast.NodeType;
const ASTNode = ast.ASTNode;
const ParseError = ast.ParseError;
const TokenType = token.TokenType;
const Token = token.Token;
const parseHeader = @import("./parse_header.zig").parseHeader;
const parseDelim = @import("./parse_delimiter.zig").parseDelimiter;

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
            .prev_token = Token.newToken(TokenType.EOF, "EOF"),
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

    pub fn parse(self: *Parser) !ASTNode {
        // Prep the main node.
        var document = ASTNode.init(self.allocator, NodeType.document);
        errdefer document.deinit();

        var paragraph_node: ?ASTNode = null;
        errdefer {
            if (paragraph_node) |*para| {
                para.deinit();
            }
        }

        while (self.current_token.type != TokenType.EOF) {
            switch (self.current_token.type) {
                TokenType.heading => {
                    // Check if there is a praragraph already and finalise it.
                    if (paragraph_node != null) {
                        try document.children.append(paragraph_node.?);
                        // Reset paragraph node
                        paragraph_node = null;
                    }

                    const header_level: u8 = @intCast(self.current_token.literal.len);

                    const header_node = try parseHeader(self, header_level);
                    try document.children.append(header_node);
                },
                TokenType.newLine => {
                    // If next token is also new line, finalise the current paragraph node
                    if (self.peek_token.type == TokenType.newLine and paragraph_node != null) {
                        try document.children.append(paragraph_node.?);
                        paragraph_node = null;
                    }

                    try self.nextToken();
                },
                else => {
                    // A plain text node
                    // Create a new paragraph if null, add to the current one if not

                    if (paragraph_node == null) {
                        paragraph_node = ASTNode.init(self.allocator, NodeType.paragraph);
                    }

                    const inline_node = try self.parseInline();
                    try paragraph_node.?.children.append(inline_node);
                },
            }
        }

        if (paragraph_node != null) {
            try document.children.append(paragraph_node.?);
            paragraph_node = null;
        }

        return document;
    }

    pub fn parseInline(self: *Parser) ParseError!ASTNode {
        const delim = self.current_token.type;

        switch (delim) {
            TokenType.text => {
                var text_node = ASTNode.init(self.allocator, NodeType.text);
                text_node.content = self.current_token.literal;

                try self.nextToken();
                return text_node;
            },
            TokenType.asterisk,
            TokenType.underscore,
            TokenType.tilde,
            TokenType.caret,
            => {
                const ast_node = try parseDelim(self, delim);

                return ast_node;
            },
            // Redundant currently, will fix later.
            else => {
                var text_node = ASTNode.init(self.allocator, NodeType.text);
                text_node.content = self.current_token.literal;

                try self.nextToken();
                return text_node;
            },
        }
    }
};
