const std = @import("std");
const Token = @import("token.zig").Token;
const TokenType = @import("token.zig").TokenType;
const Lexer = @import("lexer.zig").Lexer;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const NodeType = enum {
    document,
    paragraph,
    text,
    bold,
    italic,
    header,
};

const ASTNode = struct {
    type: NodeType,
    content: ?[]const u8 = null,
    children: ArrayList(ASTNode),
    url: ?[]const u8 = null,
    header_level: ?u8 = null,

    fn init(allocator: Allocator, node_type: NodeType) ASTNode {
        return ASTNode{
            .type = node_type,
            .children = ArrayList(ASTNode).init(allocator),
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

        while (self.current_token.type != TokenType.EOF) {
            const header_node = try self.pareseHeader();
            try document.children.append(header_node);
        }

        return document;
    }

    fn pareseHeader(self: *Parser) !ASTNode {
        var header_node = ASTNode.init(self.allocator, NodeType.header);
        const header_level: u8 = @intCast(self.current_token.literal.len);

        header_node.header_level = header_level;

        try self.nextToken();

        // TODO: Add parse inline later.
        while (self.current_token.type != TokenType.newLine and self.current_token.type != TokenType.EOF) {
            const inline_node = try self.parseInline();
            try header_node.children.append(inline_node);
        }

        return header_node;
    }

    pub fn parseInline(self: *Parser) !ASTNode {
        var text_node = ASTNode.init(self.allocator, NodeType.text);
        text_node.content = self.current_token.literal;

        try self.nextToken();

        return text_node;
    }
};
