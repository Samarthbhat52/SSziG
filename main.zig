const std = @import("std");
const lexer = @import("src/lexer.zig");
const parser = @import("src/parser.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const input = "## Heading main";
    var lex = lexer.Lexer.init(input);
    var p = try parser.Parser.init(allocator, &lex);

    var document = try p.parse();
    defer document.deinit();

    for (document.children.items) |val| {
        std.log.info("val: {s}", .{@tagName(val.type)});
        for (val.children.items) |r| {
            std.log.info("val: {s}, content: {?s}", .{ @tagName(r.type), r.content });
        }
    }
}
