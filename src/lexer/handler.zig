const std = @import("std");
const lexer = @import("./lexer.zig");
const token = @import("./token.zig");
const tokenType = @import("./token.zig");

const Lexer = lexer.Lexer;
const Token = token.Token;
const TokenType = token.TokenType;

fn isValidHeader(header_literal: []const u8, l: *Lexer) bool {
    // Too many '#' characters (max 6 for h1-h6)
    if (header_literal.len > 6) return false;

    // Must be followed by a space
    if (l.peekAhead() != ' ') return false;

    // If there is (are) space(s) after, consume it, We don't need it
    lexer.eatWhiteSpaces(l);

    // Check if there's actually content after the space
    // (this seems to be what the original double-space check was doing)
    const next_pos = l.position + 1;
    if (next_pos < l.input.len and l.input[next_pos] == ' ') return false;

    return true;
}

pub fn handleHeader(l: *Lexer) Token {
    // Headers must start at the beginning of a line
    if (l.col != 0) {
        const content = l.getValidContent();
        return Token.newToken(TokenType.text, content);
    }

    const header_literal = lexer.getDelimiterRun(l, '#');

    // Check if this is a valid header format
    if (!isValidHeader(header_literal, l)) {
        return Token.newToken(TokenType.text, header_literal);
    }

    // Consume the space after the header delimiter
    return Token.newToken(TokenType.heading, header_literal);
}

pub fn handleInlineBacktick(l: *Lexer, delim: []const u8) Token {
    // Search for closing delim.
    var i = l.position + 1;
    var found = false;

    while (i < l.input.len and l.input[i] != '\n') {
        if (l.input[i] == '`') {
            var k: usize = i;
            var len: usize = 0;

            while (k < l.input.len and l.input[k] == '`') : (k += 1) {
                len += 1;
            }

            if (len == delim.len) {
                found = true;
                break;
            }

            i += len;
            continue;
        }

        i += 1;
    }

    if (!found) {
        return Token.newToken(.text, delim);
    }

    const content = l.input[l.position + 1 .. i];

    // consume all the characters between start and closing block
    while (l.position < i + delim.len) {
        l.readChar();
    }

    return Token.newToken(.code, content);
}
