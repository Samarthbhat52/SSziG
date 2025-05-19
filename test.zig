const std = @import("std");
const Lexer = @import("src/lexer.zig");
const Token = @import("src/token.zig").Token;
const TokenType = @import("src/token.zig").TokenType;

test "heading token" {
    const input =
        \\# Main
        \\## Secondary
        \\### Tertiary
    ;
    const tokens = try Lexer.lex(input);

    const expected_tokens = [_]Token{
        Token{ .type = TokenType.heading, .literal = "#" },
        Token{ .type = TokenType.text, .literal = " Main" },
        Token{ .type = TokenType.newLine, .literal = "newline" },
        Token{ .type = TokenType.heading, .literal = "##" },
        Token{ .type = TokenType.text, .literal = " Secondary" },
        Token{ .type = TokenType.newLine, .literal = "newline" },
        Token{ .type = TokenType.heading, .literal = "###" },
        Token{ .type = TokenType.text, .literal = " Tertiary" },
    };

    try std.testing.expectEqual(expected_tokens.len, tokens.len);

    for (0..expected_tokens.len) |i| {
        try std.testing.expectEqual(expected_tokens[i].type, tokens[i].type);
        try std.testing.expectEqualStrings(expected_tokens[i].literal, tokens[i].literal);
    }
}

test "heading and quote token" {
    const input =
        \\# Heading main
        \\> Blockquote
    ;
    const tokens = try Lexer.lex(input);

    const expected_tokens = [_]Token{
        Token{ .type = TokenType.heading, .literal = "#" },
        Token{ .type = TokenType.text, .literal = " Heading main" },
        Token{ .type = TokenType.newLine, .literal = "newline" },
        Token{ .type = TokenType.quote, .literal = ">" },
        Token{ .type = TokenType.text, .literal = " Blockquote" },
    };

    try std.testing.expectEqual(expected_tokens.len, tokens.len);

    for (0..expected_tokens.len) |i| {
        try std.testing.expectEqual(expected_tokens[i].type, tokens[i].type);
        try std.testing.expectEqualStrings(expected_tokens[i].literal, tokens[i].literal);
    }
}

test "heading and italic token" {
    const input =
        \\# Heading main
        \\some *italic* text
    ;
    const tokens = try Lexer.lex(input);

    const expected_tokens = [_]Token{
        Token{ .type = TokenType.heading, .literal = "#" },
        Token{ .type = TokenType.text, .literal = " Heading main" },
        Token{ .type = TokenType.newLine, .literal = "newline" },
        Token{ .type = TokenType.text, .literal = "some " },
        Token{ .type = TokenType.italic, .literal = "*" },
        Token{ .type = TokenType.text, .literal = "italic" },
        Token{ .type = TokenType.italic, .literal = "*" },
        Token{ .type = TokenType.text, .literal = " text" },
    };

    try std.testing.expectEqual(expected_tokens.len, tokens.len);

    for (0..expected_tokens.len) |i| {
        try std.testing.expectEqual(expected_tokens[i].type, tokens[i].type);
        try std.testing.expectEqualStrings(expected_tokens[i].literal, tokens[i].literal);
    }
}

test "bold text token" {
    const input = "this is **bold** text";
    const tokens = try Lexer.lex(input);

    const expected_tokens = [_]Token{
        Token{ .type = TokenType.text, .literal = "this is " },
        Token{ .type = TokenType.bold, .literal = "**" },
        Token{ .type = TokenType.text, .literal = "bold" },
        Token{ .type = TokenType.bold, .literal = "**" },
        Token{ .type = TokenType.text, .literal = " text" },
    };

    try std.testing.expectEqual(expected_tokens.len, tokens.len);

    for (0..expected_tokens.len) |i| {
        try std.testing.expectEqual(expected_tokens[i].type, tokens[i].type);
        try std.testing.expectEqualStrings(expected_tokens[i].literal, tokens[i].literal);
    }
}
