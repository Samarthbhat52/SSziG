const std = @import("std");
const Parser = @import("./parser.zig").Parser;
const ASTNode = @import("./parser.zig").ASTNode;
const NodeType = @import("./parser.zig").NodeType;
const ParseError = @import("./parser.zig").ParseError;
const TokenType = @import("token.zig").TokenType;
const ArrayList = std.ArrayList;

fn batchAsterisk(self: *Parser, asterisk_run: []const u8) ![][]const u8 {
    var i: usize = 0;
    var chunk_index: usize = 0;
    const len = asterisk_run.len;

    const count: usize = (len + 1) / 2;

    const result = try self.allocator.alloc([]const u8, count);
    errdefer self.allocator.free(result);

    while (i < len) {
        const slice_len: usize = if (i + 1 < len) 2 else 1;
        result[chunk_index] = asterisk_run[i .. i + slice_len];
        i += slice_len;
        chunk_index += 1;
    }

    return result;
}

fn recureiveAsteriskParse(self: *Parser, batched_asterisk: [][]const u8) ParseError!ASTNode {
    const delim = batched_asterisk[0];
    const node_type = switch (delim.len) {
        1 => NodeType.italic,
        else => NodeType.bold,
    };

    var node = ASTNode.init(self.allocator, node_type);

    if (batched_asterisk.len == 1) {
        if (self.NodeBuffer) |n| {
            node.children = n.children;
            self.NodeBuffer = null;
        }
        return node;
    }

    const children_node = try recureiveAsteriskParse(self, batched_asterisk[1..]);
    try node.children.append(children_node);

    return node;
}

pub fn parseAsterisk(self: *Parser) ParseError!ASTNode {
    var container_node = ASTNode.init(self.allocator, NodeType.text);

    const open_token = self.current_token;
    const open_token_len = open_token.literal.len;

    const can_open_here = can_open(self);

    if (can_open_here) {
        try self.nextToken();

        while (self.current_token.type != TokenType.newLine and self.current_token.type != TokenType.EOF) {
            const can_close_here = can_close(self);
            if (self.current_token.type == TokenType.asterisk and can_close_here) {
                const close_token = self.current_token;
                const close_token_len = close_token.literal.len;

                var asterisk_run: []const u8 = undefined;
                if (open_token_len >= close_token_len) {
                    asterisk_run = open_token.literal[0..close_token_len];
                }

                if (close_token_len >= open_token_len) {
                    asterisk_run = open_token.literal[0..open_token_len];
                }

                const batched_asterisk = try batchAsterisk(self, asterisk_run);
                defer self.allocator.free(batched_asterisk);

                self.NodeBuffer = &container_node;
                const node = try recureiveAsteriskParse(self, batched_asterisk);

                try self.nextToken();
                return node;
            }

            const inline_node = try self.parseInline();
            try container_node.children.append(inline_node);
        }
    } else {
        container_node.content = self.current_token.literal;
        try self.nextToken();
    }

    return container_node;
}

fn can_open(self: *Parser) bool {
    const behind = self.prev_token;
    const ahead = self.peek_token;

    if (ahead.type == TokenType.EOF or ahead.type == TokenType.newLine) {
        return false;
    }

    const ahead_has_char = ahead.literal.len > 0;
    const behind_has_char = behind.literal.len > 0;

    if (behind.type != TokenType.EOF and behind.type != TokenType.newLine) {
        const last_behind_char = if (behind_has_char) behind.literal[behind.literal.len - 1] else 0;
        return ahead_has_char and ahead.literal[0] != ' ' and last_behind_char == ' ';
    } else {
        return ahead_has_char and ahead.literal[0] != ' ';
    }
}

fn can_close(self: *Parser) bool {
    const behind = self.prev_token;
    const ahead = self.peek_token;

    if (behind.type == TokenType.EOF or behind.type == TokenType.newLine) {
        return false;
    }

    if (ahead.type == TokenType.EOF) {
        return true;
    }

    const ahead_has_char = ahead.literal.len > 0;
    const behind_has_char = behind.literal.len > 0;

    if (ahead.type != TokenType.EOF and ahead.type != TokenType.newLine) {
        const last_behind_char = if (behind_has_char) behind.literal[behind.literal.len - 1] else 0;
        return ahead_has_char and ahead.literal[0] == ' ' and last_behind_char != ' ';
    } else {
        return ahead_has_char and ahead.literal[0] == ' ';
    }
}
