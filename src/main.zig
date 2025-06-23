//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

const std = @import("std");
const Lexer = @import("./lexer/lexer.zig").Lexer;
const Parser = @import("./parser/parser.zig").Parser;
const Html = @import("./nodeToHtml.zig").Html;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const input = "    # main header";
    std.log.debug("some text: '{s}'", .{input});
    var lex = Lexer.init(input);

    var p = try Parser.init(allocator, &lex);

    var document = try p.parse();
    defer document.deinit();

    var generator = Html.init(allocator);
    const html = try generator.generateHtml(document);

    defer allocator.free(html);

    std.log.debug("'{s}'", .{html});
}
