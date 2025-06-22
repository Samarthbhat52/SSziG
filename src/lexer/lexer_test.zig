const std = @import("std");
const Lexer = @import("./lexer.zig").Lexer;
const Token = @import("./token.zig").Token;
const TokenType = @import("./token.zig").TokenType;

test "proper headings" {
    const input =
        \\# Heading
        \\## Heading two
        \\### Heading three
        \\#### Heading four
        \\##### Heading five
        \\###### Heading six
    ;
    const allocator = std.testing.allocator;
    var l = Lexer.init(input, allocator);
    defer l.deinit();

    const expected = [_]Token{
        Token{ .type = TokenType.heading, .literal = "#" },
        Token{ .type = TokenType.text, .literal = "Heading" },
        Token{ .type = TokenType.newLine, .literal = "newline" },
        Token{ .type = TokenType.heading, .literal = "##" },
        Token{ .type = TokenType.text, .literal = "Heading two" },
        Token{ .type = TokenType.newLine, .literal = "newline" },
        Token{ .type = TokenType.heading, .literal = "###" },
        Token{ .type = TokenType.text, .literal = "Heading three" },
        Token{ .type = TokenType.newLine, .literal = "newline" },
        Token{ .type = TokenType.heading, .literal = "####" },
        Token{ .type = TokenType.text, .literal = "Heading four" },
        Token{ .type = TokenType.newLine, .literal = "newline" },
        Token{ .type = TokenType.heading, .literal = "#####" },
        Token{ .type = TokenType.text, .literal = "Heading five" },
        Token{ .type = TokenType.newLine, .literal = "newline" },
        Token{ .type = TokenType.heading, .literal = "######" },
        Token{ .type = TokenType.text, .literal = "Heading six" },
        Token{ .type = TokenType.EOF, .literal = "EOF" },
    };

    for (expected) |exp| {
        const tok = try l.nextToken();

        try std.testing.expectEqual(exp.type, tok.type);
        try std.testing.expectEqualStrings(exp.literal, tok.literal);
    }
}
