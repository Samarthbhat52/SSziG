pub const TokenType = enum {
    EOF,
    newLine,
    text,
    heading,
    quote,
    asterisk,
    underscore,
    tilde,
    caret,
    code,
    codeblock,
};

pub const Token = struct {
    type: TokenType,
    literal: []const u8,
    header_level: ?u8 = null,

    pub fn newToken(tok: TokenType, lit: []const u8) Token {
        return .{ .type = tok, .literal = lit };
    }
};
