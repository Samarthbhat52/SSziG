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
    row: usize,
    col: usize,
    input: []const u8,

    pub fn init(input: []const u8) Lexer {
        return .{ .ch = input[0], .position = 0, .row = 0, .col = 0, .readPosition = 1, .input = input };
    }

    // Consumes a character
    fn readChar(l: *Lexer) void {
        if (l.ch == 0 and l.position >= l.input.len) { // Check position to be sure it's actual EOF state
            return;
        }

        // Basically CRLF
        if (l.ch == '\n') {
            l.row += 1;
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
                // Not first character, not header
                if (l.col != 0) {
                    const content = l.getContent();
                    tok = token.newToken(tokenType.text, content);
                } else {
                    // Now this is possibly a header.
                    const header_literal = getHeaderDelimiter(l);

                    // If there is no space, then it is just a text node
                    // If too make '#', then too it is a text node
                    if (header_literal.len > 6 or l.peekAhead() != ' ') {
                        tok = token.newToken(tokenType.text, header_literal);
                    } else {
                        // Finally we have header. Skip the blank line

                        l.readChar();
                        tok = token.newToken(tokenType.heading, header_literal);
                    }
                }
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
                const content = l.getContent();

                tok = token.newToken(tokenType.text, content);
                return tok;
            },
        }

        l.readChar();
        return tok;
    }
};
