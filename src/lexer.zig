const std = @import("std");
const token = @import("token.zig").Token;
const tokenType = @import("token.zig").TokenType;

fn getHeaderDelimiter(l: *Lexer) []const u8 {
    const position = l.position;

    while (l.peekAhead() == '#') {
        l.readChar();
    }

    return l.input[position..l.readPosition];
}

fn isValidChar(ch: u8) bool {
    const stop_chars = [_]u8{ '*', '`', '#', '[', ']', ')', '\n', 0 };
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
    input: []const u8,

    pub fn init(input: []const u8) Lexer {
        return .{ .ch = input[0], .position = 0, .readPosition = 1, .input = input };
    }

    // Consumes a character
    fn readChar(l: *Lexer) void {
        if (l.readPosition >= l.input.len) {
            l.ch = 0;
        } else {
            l.ch = l.input[l.readPosition];
        }

        l.position = l.readPosition;
        l.readPosition += 1;
    }

    // looks ahead without consuming a character
    fn peekAhead(l: *Lexer) u8 {
        if (l.position == l.input.len - 1) {
            return 0;
        }

        return l.input[l.readPosition];
    }

    // all the characters till a non-valid character is found
    fn getContentEndPos(l: *Lexer) usize {
        while (isValidChar(l.ch)) {
            l.readChar();
        }

        return l.position;
    }

    pub fn nextToken(l: *Lexer) !token {
        var tok: token = undefined;

        switch (l.ch) {
            '\n' => {
                tok = token.newToken(tokenType.newLine, "newline");
            },
            '#' => {
                const headerDelimiter = getHeaderDelimiter(l);
                tok = token.newToken(tokenType.heading, headerDelimiter);
            },
            '*' => {
                const next_char = l.peekAhead();

                if (next_char != '*') {
                    tok = token.newToken(tokenType.italic, "*");
                } else {
                    l.readChar();
                    tok = token.newToken(tokenType.bold, "**");
                }
            },
            0 => tok = token.newToken(tokenType.EOF, "EOF"),
            else => {
                const start_pos = l.position;
                const content = l.getContentEndPos();

                tok = token.newToken(tokenType.text, l.input[start_pos..content]);
                return tok;
            },
        }

        l.readChar();
        return tok;
    }
};
