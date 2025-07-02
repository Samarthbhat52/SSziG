const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

pub const NodeType = enum {
    container,
    document,
    paragraph,
    text,
    bold,
    italic,
    header,
    quote,
    strikethrough,
    sub,
    sup,
    code,
    codeblock,
};

pub const ASTNode = struct {
    allocator: Allocator,
    type: NodeType,
    content: ?[]const u8 = null,
    children: ArrayList(ASTNode),
    header_level: ?u8 = null,
    class: ?[]const u8 = null,

    pub fn init(allocator: Allocator, node_type: NodeType) ASTNode {
        return ASTNode{
            .allocator = allocator,
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

pub const ParseError = error{
    OutOfMemory,
    // Add other potential errors from your lexer here
};
