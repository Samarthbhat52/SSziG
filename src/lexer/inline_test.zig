const std = @import("std");
const Lexer = @import("./lexer.zig").Lexer;
const Token = @import("./token.zig").Token;
const TokenType = @import("./token.zig").TokenType;

test "inline bold and italic" {
    const input = "sentence with **bold** and *italic*";

    var l = Lexer.init(input);

    const expected = [_]Token{
        Token{ .type = TokenType.text, .literal = "sentence with " },
        Token{ .type = TokenType.asterisk, .literal = "**" },
        Token{ .type = TokenType.text, .literal = "bold" },
        Token{ .type = TokenType.asterisk, .literal = "**" },
        Token{ .type = TokenType.text, .literal = " and " },
        Token{ .type = TokenType.asterisk, .literal = "*" },
        Token{ .type = TokenType.text, .literal = "italic" },
        Token{ .type = TokenType.asterisk, .literal = "*" },
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
        Token{ .type = TokenType.text, .literal = "sentence with " },
        Token{ .type = TokenType.underscore, .literal = "__" },
        Token{ .type = TokenType.text, .literal = "bold" },
        Token{ .type = TokenType.underscore, .literal = "__" },
        Token{ .type = TokenType.text, .literal = " and " },
        Token{ .type = TokenType.underscore, .literal = "_" },
        Token{ .type = TokenType.text, .literal = "italic" },
        Token{ .type = TokenType.underscore, .literal = "_" },
    };

    for (expected) |exp| {
        const tok = try l.nextToken();
        try std.testing.expectEqual(exp.type, tok.type);
        try std.testing.expectEqualStrings(exp.literal, tok.literal);
    }
}
