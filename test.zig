const std = @import("std");
const Lexer = @import("src/lexer.zig").Lexer;
const Token = @import("src/token.zig").Token;
const TokenType = @import("src/token.zig").TokenType;

test "heading token" {
    const input =
        \\# Main
        \\## Secondary
        \\### Tertiary
    ;
    var lexer = Lexer.init(input);

    const expected_tokens = [_]Token{
        Token{ .type = TokenType.heading, .literal = "#" },
        Token{ .type = TokenType.text, .literal = " Main" },
        Token{ .type = TokenType.heading, .literal = "##" },
        Token{ .type = TokenType.text, .literal = " Secondary" },
        Token{ .type = TokenType.heading, .literal = "###" },
        Token{ .type = TokenType.text, .literal = " Tertiary" },
    };

    for (expected_tokens) |expected| {
        const tok = try lexer.nextToken();
        try std.testing.expectEqual(expected.type, tok.type);
        try std.testing.expectEqualStrings(expected.literal, tok.literal);
    }
}

test "heading and quote token" {
    const input =
        \\# Heading main
        \\> Blockquote
    ;
    var lexer = Lexer.init(input);

    const expected_tokens = [_]Token{
        Token{ .type = TokenType.heading, .literal = "#" },
        Token{ .type = TokenType.text, .literal = " Heading main" },
        Token{ .type = TokenType.quote, .literal = ">" },
        Token{ .type = TokenType.text, .literal = " Blockquote" },
    };

    for (expected_tokens) |expected| {
        const tok = try lexer.nextToken();
        try std.testing.expectEqual(expected.type, tok.type);
        try std.testing.expectEqualStrings(expected.literal, tok.literal);
    }
}

test "heading and italic token" {
    const input =
        \\# Heading main
        \\some *italic* text
    ;
    var lexer = Lexer.init(input);

    const expected_tokens = [_]Token{
        Token{ .type = TokenType.heading, .literal = "#" },
        Token{ .type = TokenType.text, .literal = " Heading main" },
        Token{ .type = TokenType.text, .literal = "some " },
        Token{ .type = TokenType.italic, .literal = "*" },
        Token{ .type = TokenType.text, .literal = "italic" },
        Token{ .type = TokenType.italic, .literal = "*" },
        Token{ .type = TokenType.text, .literal = " text" },
    };

    for (expected_tokens) |expected| {
        const tok = try lexer.nextToken();
        try std.testing.expectEqual(expected.type, tok.type);
        try std.testing.expectEqualStrings(expected.literal, tok.literal);
    }
}

test "bold text token" {
    const input = "this is **bold** text";
    var lexer = Lexer.init(input);

    const expected_tokens = [_]Token{
        Token{ .type = TokenType.text, .literal = "this is " },
        Token{ .type = TokenType.bold, .literal = "**" },
        Token{ .type = TokenType.text, .literal = "bold" },
        Token{ .type = TokenType.bold, .literal = "**" },
        Token{ .type = TokenType.text, .literal = " text" },
    };

    for (expected_tokens) |expected| {
        const tok = try lexer.nextToken();
        try std.testing.expectEqual(expected.type, tok.type);
        try std.testing.expectEqualStrings(expected.literal, tok.literal);
    }
}
