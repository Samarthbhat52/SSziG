const std = @import("std");
const Lexer = @import("src/lexer.zig").Lexer;
const Token = @import("src/token.zig").Token;
const TokenType = @import("src/token.zig").TokenType;

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

test "malformed headings" {
    const input =
        \\#HeadingWithoutSpace
        \\##  
        \\####### Too many hashes
        \\#    Extra space before text
        \\##Heading#In#Middle
        \\##
        \\#
    ;
    const allocator = std.testing.allocator;
    var l = Lexer.init(input, allocator);
    defer l.deinit();

    const expected = [_]Token{
        Token{ .type = TokenType.text, .literal = "#" },
        Token{ .type = TokenType.text, .literal = "HeadingWithoutSpace" },
        Token{ .type = TokenType.newLine, .literal = "newline" },

        // "##   " → valid heading with no text
        Token{ .type = TokenType.heading, .literal = "##" },
        Token{ .type = TokenType.newLine, .literal = "newline" },

        // "####### Too many hashes" → invalid (markdown only allows up to 6)
        Token{ .type = TokenType.text, .literal = "#######" },
        Token{ .type = TokenType.text, .literal = " Too many hashes" },
        Token{ .type = TokenType.newLine, .literal = "newline" },

        // "#    Extra space before text" → valid heading
        Token{ .type = TokenType.heading, .literal = "#" },
        Token{ .type = TokenType.text, .literal = "Extra space before text" },
        Token{ .type = TokenType.newLine, .literal = "newline" },

        // "##Heading#In#Middle" → not valid heading (no space after ##)
        Token{ .type = TokenType.text, .literal = "##" },
        Token{ .type = TokenType.text, .literal = "Heading#In#Middle" },
        Token{ .type = TokenType.newLine, .literal = "newline" },

        // "##\n" → valid heading, no text
        Token{ .type = TokenType.text, .literal = "##" },
        Token{ .type = TokenType.newLine, .literal = "newline" },

        // Just "#" → valid heading, but no text
        Token{ .type = TokenType.text, .literal = "#" },
        Token{ .type = TokenType.EOF, .literal = "EOF" },
    };

    for (expected) |exp| {
        const tok = try l.nextToken();
        try std.testing.expectEqual(exp.type, tok.type);
        try std.testing.expectEqualStrings(exp.literal, tok.literal);
    }
}
