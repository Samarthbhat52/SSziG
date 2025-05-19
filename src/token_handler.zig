const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;
const Token = @import("token.zig").Token;
const TokenType = @import("token.zig").TokenType;

// Helper
fn getContentTillDelim(l: *Lexer, delim: u8, repeat: ?bool) []const u8 {
    const r = repeat orelse false;
    const position = l.position;

    while (l.peekAhead() != delim or l.peekAhead() != 0) {
        l.readChar();
    }

    return l.input[position..l.position];
}

pub fn handleHeader(l: *Lexer) Token {
    const headerDelimiter = l.getHeaderDelimiter();

    if (l.peekAhead() != ' ') {
        return Token.newToken(TokenType.text, headerDelimiter);
    }
    return Token.newToken(TokenType.heading, headerDelimiter);
}

pub fn handleQuote(l: *Lexer) Token {
    if (l.peekAhead() != ' ') {
        return Token.newToken(TokenType.text, ">");
    }

    return Token.newToken(TokenType.quote, ">");
}

pub fn handleAstersik(l: *Lexer) Token {
    switch (l.peekAhead()) {}
}
