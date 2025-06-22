const std = @import("std");
const token = @import("./token.zig").Token;
const tokenType = @import("./token.zig").TokenType;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

fn isValidHeader(header_literal: []const u8, l: *Lexer) bool {
    // Too many '#' characters (max 6 for h1-h6)
    if (header_literal.len > 6) return false;

    // Must be followed by a space
    if (l.peekAhead() != ' ') return false;

    // If there is (are) space(s) after, consume it, We don't need it
    eatWhiteSpaces(l);

    // Check if there's actually content after the space
    // (this seems to be what the original double-space check was doing)
    const next_pos = l.position + 1;
    if (next_pos < l.input.len and l.input[next_pos] == ' ') return false;

    return true;
}

fn eatWhiteSpaces(l: *Lexer) void {
    while (l.peekAhead() == ' ') {
        l.readChar();
    }
}

fn getDelimiterRun(l: *Lexer, delim: u8) []const u8 {
    const position = l.position;

    while (l.peekAhead() == delim) {
        l.readChar();
    }

    return l.input[position..l.readPosition];
}

fn isValidChar(ch: u8) bool {
    const stop_chars = [_]u8{ '*', '`', '[', ']', ')', '\n', 0 };
    for (stop_chars) |c| {
        if (ch == c) {
            return false;
        }
    }

    return true;
}

pub const Lexer = struct {
    ch: u8,
    position: usize,
    readPosition: usize,
    col: usize,
    input: []const u8,
    delim_stack: ArrayList(tokenType),

    pub fn init(input: []const u8, allocator: Allocator) Lexer {
        var delim_stack = ArrayList(tokenType).init(allocator);
        errdefer delim_stack.deinit();

        return .{
            .ch = input[0],
            .position = 0,
            .col = 0,
            .readPosition = 1,
            .input = input,
            .delim_stack = delim_stack,
        };
    }

    pub fn deinit(l: *Lexer) void {
        l.delim_stack.deinit();
    }

    // Consumes a character
    fn readChar(l: *Lexer) void {
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
    fn peekAhead(l: *Lexer) u8 {
        if (l.position == l.input.len - 1) {
            return 0;
        }

        return l.input[l.readPosition];
    }

    // all the characters till a non-valid character is found
    fn getContent(l: *Lexer) []const u8 {
        const start_position = l.position;
        while (isValidChar(l.ch)) {
            l.readChar();
        }

        return l.input[start_position..l.position];
    }

    pub fn nextToken(l: *Lexer) !token {
        var tok: token = undefined;

        switch (l.ch) {
            '\n' => {
                tok = token.newToken(tokenType.newLine, "newline");
            },
            '#' => {
                tok = handleHeader(l);
            },
            '*' => {
                const asterisk = getDelimiterRun(l, '*');
                tok = token.newToken(tokenType.asterisk, asterisk);
            },
            0 => tok = token.newToken(tokenType.EOF, "EOF"),
            else => {
                const content = l.getContent();

                tok = token.newToken(tokenType.text, content);
                return tok;
            },
        }

        l.readChar();
        return tok;
    }
};

pub fn handleHeader(l: *Lexer) token {
    // Headers must start at the beginning of a line
    if (l.col != 0) {
        const content = l.getContent();
        return token.newToken(tokenType.text, content);
    }

    const header_literal = getDelimiterRun(l, '#');

    // Check if this is a valid header format
    if (!isValidHeader(header_literal, l)) {
        return token.newToken(tokenType.text, header_literal);
    }

    // Consume the space after the header delimiter
    return token.newToken(tokenType.heading, header_literal);
}
