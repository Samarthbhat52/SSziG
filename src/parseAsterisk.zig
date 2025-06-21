const std = @import("std");
const Parser = @import("./parser.zig").Parser;
const ASTNode = @import("./parser.zig").ASTNode;
const NodeType = @import("./parser.zig").NodeType;
const ParseError = @import("./parser.zig").ParseError;
const TokenType = @import("token.zig").TokenType;
const Token = @import("token.zig").Token;
const ArrayList = std.ArrayList;
const isWhitespace = std.ascii.isWhitespace;

fn recureiveAsteriskParse(self: *Parser, consume_count: usize, contentBuf: ArrayList(ASTNode)) ParseError!ASTNode {
    const delim_size: usize = if (consume_count >= 2) 2 else 1;
    const node_type = if (delim_size == 2) NodeType.bold else NodeType.italic;

    var node = ASTNode.init(self.allocator, node_type);

    const new_consume_count: usize = consume_count - delim_size;

    if (new_consume_count == 0) {
        for (contentBuf.items) |item| {
            try node.children.append(item);
        }
        return node;
    }

    const children_node = try recureiveAsteriskParse(self, new_consume_count, contentBuf);
    try node.children.append(children_node);

    return node;
}

pub fn parseAsterisk(self: *Parser) ParseError!ASTNode {
    var contentBuf = ArrayList(ASTNode).init(self.allocator);
    defer contentBuf.deinit();

    // Save opening delim length
    const open_delim = self.current_token;
    var open_delim_len = self.current_token.literal.len;
    const can_open_here = can_open(self);

    if (can_open_here) {
        try self.nextToken();

        while (self.current_token.type != TokenType.EOF and self.current_token.type != TokenType.newLine) {
            if (self.current_token.type == TokenType.asterisk and can_close(self)) {
                // Found the closing delimeter. handle recursive parsing
                const close_delim = self.current_token;
                var close_delim_len = self.current_token.literal.len;
                const consume_count: usize = @min(open_delim_len, close_delim_len);

                const node = try recureiveAsteriskParse(self, consume_count, contentBuf);

                open_delim_len = open_delim_len - consume_count;
                close_delim_len = close_delim_len - consume_count;

                if (open_delim_len > 0) {
                    contentBuf.clearRetainingCapacity();
                    try contentBuf.append(node);
                    try self.nextToken();
                    continue;
                }

                if (close_delim_len > 0) {
                    const new_current_token = Token.newToken(TokenType.asterisk, close_delim.literal[0..close_delim_len]);
                    // override the satate of the current token,
                    self.current_token = new_current_token;
                }

                return node;
            }

            // If not closing delimiter, continue to parse recursively.
            const inline_node = try self.parseInline();
            try contentBuf.append(inline_node);
        }
    }
    // If it reaches here, then no closing node found.
    // Just return a plain text node.
    var text_node = ASTNode.init(self.allocator, NodeType.text);

    for (contentBuf.items) |item| {
        try text_node.children.append(item);
    }

    var remaining_node = ASTNode.init(self.allocator, NodeType.text);
    remaining_node.content = open_delim.literal[0..open_delim_len];

    try text_node.children.insert(0, remaining_node);

    try self.nextToken();
    return text_node;
}

fn isAlphaNumOrPunct(char: u8) bool {
    return std.ascii.isAlphanumeric(char) or isAsciiPunctuation(char);
}

fn isAsciiPunctuation(c: u8) bool {
    return switch (c) {
        '!', '"', '#', '$', '%', '&', '\'', '(', ')', '*', '+', ',', '-', '.', '/', ':', ';', '<', '=', '>', '?', '@', '[', '\\', ']', '^', '_', '`', '{', '|', '}', '~' => true,
        else => false,
    };
}

pub fn can_open(self: *Parser) bool {
    const behind = self.prev_token;
    const ahead = self.peek_token;

    const behind_char = if (behind.literal.len > 0) behind.literal[behind.literal.len - 1] else 0;
    const ahead_char = if (ahead.literal.len > 0) ahead.literal[0] else 0;

    const precededByWhitespace = behind.type == TokenType.EOF or isWhitespace(behind_char);
    const followedByWhitespace = ahead.type == TokenType.EOF or isWhitespace(ahead_char);

    const followedByPunct = isAsciiPunctuation(ahead_char);

    const leftFlanking = !followedByWhitespace and !(followedByPunct and !precededByWhitespace);

    return leftFlanking;
}

pub fn can_close(self: *Parser) bool {
    const behind = self.prev_token;
    const ahead = self.peek_token;

    const behind_char = if (behind.literal.len > 0) behind.literal[behind.literal.len - 1] else 0;
    const ahead_char = if (ahead.literal.len > 0) ahead.literal[0] else 0;

    const precededByWhitespace = behind.type == TokenType.EOF or isWhitespace(behind_char);
    const followedByWhitespace = ahead.type == TokenType.EOF or isWhitespace(ahead_char);

    const precededByPunct = isAsciiPunctuation(behind_char);

    const rightFlanking = !precededByWhitespace and !(precededByPunct and !followedByWhitespace);

    return rightFlanking;
}
