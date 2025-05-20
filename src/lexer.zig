const std = @import("std");
const token = @import("token.zig").Token;
const tokenType = @import("token.zig").TokenType;

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

    fn readChar(l: *Lexer) void {
        if (l.readPosition >= l.input.len) {
            l.ch = 0;
        } else {
            l.ch = l.input[l.readPosition];
        }

        l.position = l.readPosition;
        l.readPosition += 1;
    }

    fn getHeaderDelimiter(l: *Lexer) []const u8 {
        const position = l.position;

        while (l.peekAhead() == '#') {
            l.readChar();
        }

        return l.input[position..l.readPosition];
    }

    fn peekAhead(l: *Lexer) u8 {
        if (l.position == l.input.len - 1) {
            return 0;
        }

        return l.input[l.readPosition];
    }

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
                const headerDelimiter = l.getHeaderDelimiter();
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

pub fn lex(input: []const u8) ![]token {
    // Allocate memory for token stream.
    var tokens = std.ArrayList(token).init(std.heap.page_allocator);
    defer tokens.deinit();

    var l = Lexer.init(input);
    var tok = try l.nextToken();

    while (tok.type != tokenType.EOF) {
        try tokens.append(tok);

        tok = try l.nextToken();
    }

    return tokens.toOwnedSlice(); // Return to caller
}
