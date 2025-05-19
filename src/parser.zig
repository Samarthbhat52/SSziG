const std = @import("std");
const tokenType = @import("token.zig").TokenType;

const NodeType = union(tokenType) {
    heading: struct { level: u8, text: []const u8 },
};

const ASTNode = struct {
    type: NodeType,
    children: std.ArrayList(?*ASTNode),
    value: []const u8,
};

// pub fn parse()
