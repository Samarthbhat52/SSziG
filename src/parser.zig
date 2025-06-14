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

const delimiter = struct {
    type: TokenType,
    len: usize,
    can_open: bool,
    can_close: bool,
};

fn peekStack(stack: *ArrayList(delimiter)) ?*delimiter {
    const stack_len = stack.items.len;
    if (stack_len > 0) {
        return stack.items[stack_len - 1];
    }

    return null;
}

pub const Parser = struct {
    lexer: *Lexer,
    current_token: Token,
    peek_token: Token,
    allocator: Allocator,
    delimiter_stack: ArrayList(delimiter),

    pub fn init(allocator: Allocator, lexer: *Lexer) !Parser {
        var delim_stack = ArrayList(delimiter).init(allocator);
        errdefer delim_stack.deinit();

        var parser = Parser{
            .lexer = lexer,
            .current_token = undefined,
            .peek_token = undefined,
            .allocator = allocator,
            .delimiter_stack = delim_stack,
        };

        // init both current and peak tokens
        try parser.nextToken();
        try parser.nextToken();

        return parser;
    }

    pub fn deinit(p: *Parser) void {
        p.delimiter_stack.deinit();
    }

    pub fn nextToken(self: *Parser) !void {
        self.current_token = self.peek_token;
        self.peek_token = try self.lexer.nextToken();
        // std.log.info("type: '{s}', token: '{s}'", .{ @tagName(self.current_token.type), self.current_token.literal });
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

                    const header_node = try pareseHeader(self, header_level);
                    try document.children.append(header_node);
                },
                TokenType.asterisk => {
                    // if (paragraph_node == null) {
                    //     paragraph_node = ASTNode.init(self.allocator, NodeType.paragraph);
                    // }
                    //
                    // const node = try parseAsterisk(self);
                    // try paragraph_node.?.children.append(node);
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

fn pareseHeader(self: *Parser, level: u8) !ASTNode {
    var header_node = ASTNode.init(self.allocator, NodeType.header);
    header_node.header_level = level;

    try self.nextToken();

    while (self.current_token.type != TokenType.newLine and self.current_token.type != TokenType.EOF) {
        const inline_node = try self.parseInline();
        try header_node.children.append(inline_node);
    }

    return header_node;
}
