const std = @import("std");
const Lexer = @import("./lexer/lexer.zig").Lexer;
const Parser = @import("./parser/parser.zig").Parser;
const Html = @import("./nodeToHtml.zig").Html;
const TokenType = @import("./lexer/token.zig").TokenType;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const input = "Time to test ^superscript text^ and also test ^formatting ~~***inside the***~~ superscript^, 2^14^ karma gets you in the arcanum.";
    // const input = "*****some random** *sentence**";
    // const input = "***please** work*";
    // const input = "sentence with `code some more **text** codeblock too block`";

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
