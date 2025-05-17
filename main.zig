const std = @import("std");
const lexer = @import("src/lexer.zig");

pub fn main() !void {
    const input = "## Heading main\n> Blockquote";

    var lex = lexer.Lexer.init(input);

    for (0..4) |_| {
        const tok = try lex.nextToken();
        std.debug.print("type: {s}, content: {s}\n", .{ @tagName(tok.type), tok.literal });
    }
}
