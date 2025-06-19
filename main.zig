const std = @import("std");
const lexer = @import("src/lexer.zig");
const tokenType = @import("src/token.zig").TokenType;
const parser = @import("src/parser.zig");
const htmlGenerator = @import("src/nodeToHtml.zig").Html;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    // const input = "properly formatted **bold** with *italic*";
    // const input = "## Header with *italic and **bold** text to show*";
    const input = "some **just strong** and ** other";
    var lex = lexer.Lexer.init(input, allocator);
    defer lex.deinit();

    // var tok = try lex.nextToken();
    //
    // while (tok.type != tokenType.EOF) {
    //     std.log.info("type: {s}, token: '{s}'", .{ @tagName(tok.type), tok.literal });
    //     tok = try lex.nextToken();
    // }

    var p = try parser.Parser.init(allocator, &lex);

    var document = try p.parse();
    defer document.deinit();

    var generator = htmlGenerator.init(allocator);
    const html = try generator.generateHtml(document);

    defer allocator.free(html);

    std.log.debug("some text: '{s}'", .{input});
    std.log.debug("'{s}'", .{html});
}
