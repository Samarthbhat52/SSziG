const std = @import("std");
const Token = @import("./token.zig").Token;
const TokenType = @import("./token.zig").TokenType;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const util = @import("../utils/delim_rules.zig");
const handler = @import("./handler.zig");

pub fn eatWhiteSpaces(l: *Lexer) void {
    while (l.peekAhead() == ' ') {
        l.readChar();
    }
}

pub fn getDelimiterRun(l: *Lexer, delim: u8) []const u8 {
    const position = l.position;

    while (l.peekAhead() == delim) {
        l.readChar();
    }

    return l.input[position..l.readPosition];
}

pub const Lexer = struct {
    ch: u8,
    position: usize,
    readPosition: usize,
    col: usize,
    input: []const u8,

    pub fn init(input: []const u8) Lexer {
        return .{
            .ch = input[0],
            .position = 0,
            .col = 0,
            .readPosition = 1,
            .input = input,
        };
    }

    // Consumes a character
    pub fn readChar(l: *Lexer) void {
        if (l.ch == 0 and l.position >= l.input.len) { // Check position to be sure it's actual EOF state
            return;
        }

        // Basically CRLF
        if (l.ch == '\n') {
            l.col = 0;
        } else if (l.ch != 0) {
            l.col += 1;
        }

        if (l.readPosition >= l.input.len) { // If the character we are about to "read" is beyond the input
            l.ch = 0; // Set current character to EOF
            l.position = l.readPosition; // Position now reflects EOF (e.g., input.len)
            // l.readPosition is not advanced further
        } else {
            l.ch = l.input[l.readPosition];
            l.position = l.readPosition;
            l.readPosition += 1;
        }
    }

    // looks ahead without consuming a character
    pub fn peekAhead(l: *Lexer) u8 {
        if (l.position == l.input.len - 1) {
            return 0;
        }

        return l.input[l.readPosition];
    }

    // all the characters till a non-valid character is found
    pub fn getValidContent(l: *Lexer) []const u8 {
        const start_position = l.position;
        while (util.isValidChar(l.ch)) {
            l.readChar();
        }

        return l.input[start_position..l.position];
    }

    pub fn getContentTill(l: *Lexer, delim: u8) []const u8 {
        const start_position = l.position;
        while (l.ch != delim) {
            l.readChar();
        }

        return l.input[start_position..l.position];
    }

    pub fn nextToken(l: *Lexer) !Token {
        var tok: Token = undefined;

        switch (l.ch) {
            '\n' => {
                tok = Token.newToken(.newLine, "\n");
            },
            '#' => {
                tok = handler.handleHeader(l);
            },
            '*' => {
                const delim = getDelimiterRun(l, l.ch);
                tok = Token.newToken(.asterisk, delim);
            },
            '_' => {
                const delim = getDelimiterRun(l, l.ch);
                tok = Token.newToken(.underscore, delim);
            },
            '~' => {
                const delim = getDelimiterRun(l, l.ch);
                tok = Token.newToken(.tilde, delim);
            },
            '^' => {
                const delim = getDelimiterRun(l, l.ch);
                const token_type = if (delim.len == 1) TokenType.caret else TokenType.text;

                tok = Token.newToken(token_type, delim);
            },
            '`' => {
                const delim = getDelimiterRun(l, l.ch);

                tok = if (delim.len == 1) handler.handleInlineBacktick(l, "`") else Token.newToken(.codeblock, delim);
            },
            0 => tok = Token.newToken(.EOF, "EOF"),
            else => {
                const content = l.getValidContent();

                tok = Token.newToken(.text, content);
                return tok;
            },
        }

        l.readChar();
        return tok;
    }
};
