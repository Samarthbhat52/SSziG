const std = @import("std");
const lexer = @import("src/lexer.zig");

pub fn main() !void {
    const input = "## Heading main\nsome sentence with **bold and *italic* in it.**";
    const tokens = try lexer.lex(input);

    for (tokens) |val| {
        std.log.debug("token: {s}, value: {s}", .{ @tagName(val.type), val.literal });
    }
}
