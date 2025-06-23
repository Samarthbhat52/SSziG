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
    var l = Lexer.init(input);

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

test "headings with spaces before hash" {
    const input = "   # Heading with leading spaces";
    var l = Lexer.init(input);

    const expected = [_]Token{
        Token{ .type = TokenType.text, .literal = "   # Heading with leading spaces" },
        Token{ .type = TokenType.EOF, .literal = "EOF" },
    };
    for (expected) |exp| {
        const tok = try l.nextToken();
        try std.testing.expectEqual(exp.type, tok.type);
        try std.testing.expectEqualStrings(exp.literal, tok.literal);
    }
}

test "headings with no space after hash" {
    const input = "#NoSpaceHeading";
    var l = Lexer.init(input);

    const expected = [_]Token{
        Token{ .type = TokenType.text, .literal = "#" },
        Token{ .type = TokenType.text, .literal = "NoSpaceHeading" },
        Token{ .type = TokenType.EOF, .literal = "EOF" },
    };
    for (expected) |exp| {
        const tok = try l.nextToken();
        try std.testing.expectEqual(exp.type, tok.type);
        try std.testing.expectEqualStrings(exp.literal, tok.literal);
    }
}

test "headings with multiple spaces after hash" {
    const input = "##    Multiple spaces after hash";
    var l = Lexer.init(input);

    const expected = [_]Token{
        Token{ .type = TokenType.heading, .literal = "##" },
        Token{ .type = TokenType.text, .literal = "Multiple spaces after hash" },
        Token{ .type = TokenType.EOF, .literal = "EOF" },
    };
    for (expected) |exp| {
        const tok = try l.nextToken();
        try std.testing.expectEqual(exp.type, tok.type);
        try std.testing.expectEqualStrings(exp.literal, tok.literal);
    }
}

test "invalid heading with too many hashes" {
    const input = "####### Seven hashes should not be a heading";
    var l = Lexer.init(input);

    const expected = [_]Token{
        Token{ .type = TokenType.text, .literal = "#######" },
        Token{ .type = TokenType.text, .literal = " Seven hashes should not be a heading" },
        Token{ .type = TokenType.EOF, .literal = "EOF" },
    };
    for (expected) |exp| {
        const tok = try l.nextToken();
        try std.testing.expectEqual(exp.type, tok.type);
        try std.testing.expectEqualStrings(exp.literal, tok.literal);
    }
}

test "heading with trailing hashes" {
    const input = "## Heading with trailing ##";
    var l = Lexer.init(input);

    const expected = [_]Token{
        Token{ .type = TokenType.heading, .literal = "##" },
        Token{ .type = TokenType.text, .literal = "Heading with trailing ##" },
        Token{ .type = TokenType.EOF, .literal = "EOF" },
    };
    for (expected) |exp| {
        const tok = try l.nextToken();
        try std.testing.expectEqual(exp.type, tok.type);
        try std.testing.expectEqualStrings(exp.literal, tok.literal);
    }
}

test "heading mid-line should not be heading" {
    const input = "This is not a # heading in the middle";
    var l = Lexer.init(input);

    const expected = [_]Token{
        Token{ .type = TokenType.text, .literal = "This is not a # heading in the middle" },
        Token{ .type = TokenType.EOF, .literal = "EOF" },
    };
    for (expected) |exp| {
        const tok = try l.nextToken();
        try std.testing.expectEqual(exp.type, tok.type);
        try std.testing.expectEqualStrings(exp.literal, tok.literal);
    }
}

test "mixed valid and invalid headings" {
    const input =
        \\# Valid heading
        \\Not a heading # in middle
        \\## Another valid
        \\####### Too many hashes
    ;
    var l = Lexer.init(input);

    const expected = [_]Token{
        Token{ .type = TokenType.heading, .literal = "#" },
        Token{ .type = TokenType.text, .literal = "Valid heading" },
        Token{ .type = TokenType.newLine, .literal = "newline" },
        Token{ .type = TokenType.text, .literal = "Not a heading # in middle" },
        Token{ .type = TokenType.newLine, .literal = "newline" },
        Token{ .type = TokenType.heading, .literal = "##" },
        Token{ .type = TokenType.text, .literal = "Another valid" },
        Token{ .type = TokenType.newLine, .literal = "newline" },
        Token{ .type = TokenType.text, .literal = "#######" },
        Token{ .type = TokenType.text, .literal = " Too many hashes" },
        Token{ .type = TokenType.EOF, .literal = "EOF" },
    };
    for (expected) |exp| {
        const tok = try l.nextToken();
        try std.testing.expectEqual(exp.type, tok.type);
        try std.testing.expectEqualStrings(exp.literal, tok.literal);
    }
}

test "empty heading" {
    const input = "###";
    var l = Lexer.init(input);

    const expected = [_]Token{
        Token{ .type = TokenType.text, .literal = "###" },
        Token{ .type = TokenType.EOF, .literal = "EOF" },
    };
    for (expected) |exp| {
        const tok = try l.nextToken();
        try std.testing.expectEqual(exp.type, tok.type);
        try std.testing.expectEqualStrings(exp.literal, tok.literal);
    }
}
