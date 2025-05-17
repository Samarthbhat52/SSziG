// I'll just start with adding support for plain paragraphs, heading and blockquotes

pub const TokenType = enum {
    EOF,
    text,
    heading,
    quote,
    bold,
    italic,
};

pub const Token = struct {
    type: TokenType,
    literal: []const u8,

    pub fn newToken(tok: TokenType, lit: []const u8) Token {
        return .{ .type = tok, .literal = lit };
    }
};
