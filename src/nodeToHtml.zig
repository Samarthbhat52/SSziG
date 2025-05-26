const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const ASTNode = @import("parser.zig").ASTNode;
const NodeType = @import("parser.zig").NodeType;

pub const Html = struct {
    allocator: Allocator,

    pub fn init(allocator: Allocator) Html {
        return Html{ .allocator = allocator };
    }

    pub fn generateHtml(self: *Html, node: ASTNode) ![]const u8 {
        var output = ArrayList(u8).init(self.allocator);
        errdefer output.deinit();

        try self.generateNode(&output, node);

        return output.toOwnedSlice();
    }

    fn generateNode(self: *Html, output: *ArrayList(u8), node: ASTNode) !void {
        switch (node.type) {
            NodeType.document => {
                for (node.children.items) |child| {
                    try self.generateNode(output, child);
                    try output.appendSlice("\n");
                }
            },
            NodeType.paragraph => {
                try output.appendSlice("<p>");
                for (node.children.items) |child| {
                    try self.generateNode(output, child);
                }
                try output.appendSlice("</p>");
            },
            NodeType.header => {
                const level = node.header_level orelse 1;

                try output.appendSlice("<h");
                try output.appendSlice(&[_]u8{'0' + level});
                try output.appendSlice(">");

                for (node.children.items) |child| {
                    try self.generateNode(output, child);
                }

                try output.appendSlice("</h");
                try output.appendSlice(&[_]u8{'0' + level});
                try output.appendSlice(">");
            },
            else => {
                if (node.content) |content| {
                    // Probably replace some symbols with html escapes
                    try output.appendSlice(content);
                }
            },
        }
    }
};
