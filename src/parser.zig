const std = @import("std");
const Token = @import("token.zig").Token;
const TokenType = @import("token.zig").TokenType;
const Lexer = @import("lexer.zig").Lexer;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

pub const NodeType = enum {
    document,
    paragraph,
    text,
    bold,
    italic,
    header,
};

pub const ASTNode = struct {
    type: NodeType,
    content: ?[]const u8 = null,
    children: ArrayList(ASTNode),
    url: ?[]const u8 = null,
    header_level: ?u8 = null,

    fn init(allocator: Allocator, node_type: NodeType) ASTNode {
        var array_node = ArrayList(ASTNode).init(allocator);
        errdefer array_node.deinit();

        return ASTNode{
            .type = node_type,
            .children = array_node,
        };
    }

    pub fn deinit(self: *ASTNode) void {
        for (self.children.items) |*child| {
            child.deinit();
        }

        self.children.deinit();
    }
};

pub const Parser = struct {
    lexer: *Lexer,
    current_token: Token,
    peek_token: Token,
    allocator: Allocator,

    pub fn init(allocator: Allocator, lexer: *Lexer) !Parser {
        var parser = Parser{
            .lexer = lexer,
            .current_token = undefined,
            .peek_token = undefined,
            .allocator = allocator,
        };

        // init both current and peak tokens
        try parser.nextToken();
        try parser.nextToken();

        return parser;
    }

    pub fn nextToken(self: *Parser) !void {
        self.current_token = self.peek_token;
        self.peek_token = try self.lexer.nextToken();
    }

    pub fn parse(self: *Parser) !ASTNode {
        // Prep the main node.
        var document = ASTNode.init(self.allocator, NodeType.document);
        errdefer document.deinit();

        var paragraph_node: ?ASTNode = null;

        while (self.current_token.type != TokenType.EOF) {
            switch (self.current_token.type) {
                TokenType.heading => {
                    // Check if there is a praragraph already and finalise it.
                    if (paragraph_node != null) {
                        try document.children.append(paragraph_node.?);
                        // Reset paragraph node
                        paragraph_node = null;
                    }

                    const header_node = try self.pareseHeader();
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

        return document;
    }

    fn pareseHeader(self: *Parser) !ASTNode {
        const header_level: u8 = @intCast(self.current_token.literal.len);

        var header_node = ASTNode.init(self.allocator, NodeType.header);
        header_node.header_level = header_level;

        try self.nextToken();

        while (self.current_token.type != TokenType.newLine and self.current_token.type != TokenType.EOF) {
            const inline_node = try self.parseInline();
            try header_node.children.append(inline_node);
        }

        return header_node;
    }

    pub fn parseInline(self: *Parser) !ASTNode {
        switch (self.current_token.type) {
            TokenType.text => {
                var text_node = ASTNode.init(self.allocator, NodeType.text);
                text_node.content = self.current_token.literal;

                try self.nextToken();
                return text_node;
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
