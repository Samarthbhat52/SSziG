const std = @import("std");
const lexer = @import("src/lexer.zig");
// const parser = @import("src/parser.zig");
// const htmlGenerator = @import("src/nodeToHtml.zig").Html;

pub fn main() !void {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer _ = gpa.deinit();

    // const allocator = gpa.allocator();

    const input = "###### Heading main\n### Heading two";
    var lex = lexer.Lexer.init(input);

    for (0..5) |_| {
        const tok = try lex.nextToken();
        std.log.info("type: {s}, token: {s}", .{ @tagName(tok.type), tok.literal });
    }

    // var p = try parser.Parser.init(allocator, &lex);
    //
    // var document = try p.parse();
    // defer document.deinit();

    // var generator = htmlGenerator.init(allocator);
    // const html = try generator.generateHtml(document);
    //
    // defer allocator.free(html);

    // std.log.debug("{s}", .{html});
}
