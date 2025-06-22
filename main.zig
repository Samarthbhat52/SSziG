const std = @import("std");
const Lexer = @import("src/lexer.zig").Lexer;
const Parser = @import("src/parser/parser.zig").Parser;
const htmlGenerator = @import("src/nodeToHtml.zig").Html;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const input = "**italic*** and word";
    std.log.debug("some text: '{s}'", .{input});
    var lex = Lexer.init(input, allocator);
    defer lex.deinit();

    var p = try Parser.init(allocator, &lex);

    var document = try p.parse();
    defer document.deinit();

    var generator = htmlGenerator.init(allocator);
    const html = try generator.generateHtml(document);

    defer allocator.free(html);

    std.log.debug("'{s}'", .{html});
}
