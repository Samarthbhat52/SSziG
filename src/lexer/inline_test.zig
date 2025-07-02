const std = @import("std");
const Lexer = @import("./lexer.zig").Lexer;
const Token = @import("./token.zig").Token;

test "inline bold and italic" {
    const input = "sentence with **bold** and *italic*";

    var l = Lexer.init(input);

    const expected = [_]Token{
        Token{ .type = .text, .literal = "sentence with " },
        Token{ .type = .asterisk, .literal = "**" },
        Token{ .type = .text, .literal = "bold" },
        Token{ .type = .asterisk, .literal = "**" },
        Token{ .type = .text, .literal = " and " },
        Token{ .type = .asterisk, .literal = "*" },
        Token{ .type = .text, .literal = "italic" },
        Token{ .type = .asterisk, .literal = "*" },
        Token{ .type = .EOF, .literal = "EOF" },
    };

    for (expected) |exp| {
        const tok = try l.nextToken();
        try std.testing.expectEqual(exp.type, tok.type);
        try std.testing.expectEqualStrings(exp.literal, tok.literal);
    }
}

test "inline underscore delimeter" {
    const input = "sentence with __bold__ and _italic_";

    var l = Lexer.init(input);

    const expected = [_]Token{
        Token{ .type = .text, .literal = "sentence with " },
        Token{ .type = .underscore, .literal = "__" },
        Token{ .type = .text, .literal = "bold" },
        Token{ .type = .underscore, .literal = "__" },
        Token{ .type = .text, .literal = " and " },
        Token{ .type = .underscore, .literal = "_" },
        Token{ .type = .text, .literal = "italic" },
        Token{ .type = .underscore, .literal = "_" },
        Token{ .type = .EOF, .literal = "EOF" },
    };

    for (expected) |exp| {
        const tok = try l.nextToken();
        try std.testing.expectEqual(exp.type, tok.type);
        try std.testing.expectEqualStrings(exp.literal, tok.literal);
    }
}

test "inline nested delimeter" {
    const input = "sentence with ***bold** with italic*";

    var l = Lexer.init(input);

    const expected = [_]Token{
        Token{ .type = .text, .literal = "sentence with " },
        Token{ .type = .asterisk, .literal = "***" },
        Token{ .type = .text, .literal = "bold" },
        Token{ .type = .asterisk, .literal = "**" },
        Token{ .type = .text, .literal = " with italic" },
        Token{ .type = .asterisk, .literal = "*" },
        Token{ .type = .EOF, .literal = "EOF" },
    };

    for (expected) |exp| {
        const tok = try l.nextToken();
        try std.testing.expectEqual(exp.type, tok.type);
        try std.testing.expectEqualStrings(exp.literal, tok.literal);
    }
}

test "inline nested underscore" {
    const input = "sentence with ___bold__ with italic_";

    var l = Lexer.init(input);

    const expected = [_]Token{
        Token{ .type = .text, .literal = "sentence with " },
        Token{ .type = .underscore, .literal = "___" },
        Token{ .type = .text, .literal = "bold" },
        Token{ .type = .underscore, .literal = "__" },
        Token{ .type = .text, .literal = " with italic" },
        Token{ .type = .underscore, .literal = "_" },
        Token{ .type = .EOF, .literal = "EOF" },
    };

    for (expected) |exp| {
        const tok = try l.nextToken();
        try std.testing.expectEqual(exp.type, tok.type);
        try std.testing.expectEqualStrings(exp.literal, tok.literal);
    }
}

test "test code blocks" {
    const input = "# header\n\n```\ncode block\n```";

    var l = Lexer.init(input);

    const expected = [_]Token{
        Token{ .type = .heading, .literal = "#" },
        Token{ .type = .text, .literal = "header" },
        Token{ .type = .newLine, .literal = "\n" },
        Token{ .type = .newLine, .literal = "\n" },
        Token{ .type = .codeblock, .literal = "code block\n" },
        Token{ .type = .EOF, .literal = "EOF" },
    };

    for (expected) |exp| {
        const tok = try l.nextToken();
        try std.testing.expectEqual(exp.type, tok.type);
        try std.testing.expectEqualStrings(exp.literal, tok.literal);
    }
}
