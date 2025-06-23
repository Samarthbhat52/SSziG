//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

const std = @import("std");
const Lexer = @import("./lexer/lexer.zig").Lexer;
const Parser = @import("./parser/parser.zig").Parser;
const Html = @import("./nodeToHtml.zig").Html;
const TokenType = @import("./lexer/token.zig").TokenType;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const input = "something *__bold__ and italic_";
    std.log.debug("some text: '{s}'", .{input});
    var lex = Lexer.init(input);

    // var tok = try lex.nextToken();
    //
    // while (tok.type != TokenType.EOF) {
    //     std.log.info("type: {s}, token: '{s}'", .{ @tagName(tok.type), tok.literal });
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
