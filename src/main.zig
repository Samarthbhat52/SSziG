const std = @import("std");
const Lexer = @import("./lexer/lexer.zig").Lexer;
const Parser = @import("./parser/parser.zig").Parser;
const Html = @import("./nodeToHtml.zig").Html;
const TokenType = @import("./lexer/token.zig").TokenType;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const input = "some text [a link]() some text";

    std.log.debug("some text: '{s}'", .{input});
    var lex = Lexer.init(input);

    // var tok = try lex.nextToken();
    //
    // while (tok.type != .EOF) {
    //     std.log.info("type: {s}, value: {s}", .{ @tagName(tok.type), tok.literal });
    //     tok = try lex.nextToken();
    // }

    var p = try Parser.init(allocator, &lex);

    var document = try p.parse();
    defer document.deinit();

    var generator = Html.init(allocator);
    const html = try generator.generateHtml(document);

    defer allocator.free(html);

    std.log.debug("'{s}'", .{html});
}
