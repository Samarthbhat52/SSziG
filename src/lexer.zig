const std = @import("std");
const token = @import("token.zig").Token;
const tokenType = @import("token.zig").TokenType;
const handler = @import("token_handler.zig");

fn isValidChar(ch: u8) bool {
    const valid = (ch >= 'a' and ch <= 'z') or
        (ch >= 'A' and ch <= 'Z') or (ch == ' ');
    return valid;
}

pub fn lex(input: []const u8) ![]token {
    // Allocate memory for token stream.
    var tokens = std.ArrayList(token).init(std.heap.page_allocator);
    defer tokens.deinit();

    var l = Lexer.init(input);
    var tok = try nextToken(&l);

    while (tok.type != tokenType.EOF) {
        try tokens.append(tok);
        tok = try nextToken(&l);
    }

    return tokens.toOwnedSlice(); // Return to caller
}

pub const Lexer = struct {
    ch: u8,
    position: usize,
    readPosition: usize,
    input: []const u8,

    pub fn init(input: []const u8) Lexer {
        return .{ .ch = input[0], .position = 0, .readPosition = 1, .input = input };
    }

    pub fn readChar(l: *Lexer) void {
        if (l.readPosition >= l.input.len) {
            l.ch = 0;
        } else {
            l.ch = l.input[l.readPosition];
        }

        l.position = l.readPosition;
        l.readPosition += 1;
    }

    fn eatNewLine(l: *Lexer) void {
        while (l.ch == '\n') {
            l.readChar();
        }
    }

    pub fn getHeaderDelimiter(l: *Lexer) []const u8 {
        const position = l.position;

        while (l.peekAhead() == '#') {
            l.readChar();
        }

        return l.input[position..l.readPosition];
    }

    pub fn peekAhead(l: *Lexer) u8 {
        return l.input[l.readPosition];
    }

    pub fn getContent(l: *Lexer) []const u8 {
        const position = l.position;

        while (isValidChar(l.ch)) {
            l.readChar();
        }

        return l.input[position..l.position];
    }
};

pub fn nextToken(l: *Lexer) !token {
    var tok: token = undefined;

    switch (l.ch) {
        '\n' => {
            tok = token.newToken(tokenType.newLine, "newline");
        },
        '#' => {
            tok = handler.handleHeader(l);
        },
        '>' => {
            tok = handler.handleQuote(l);
        },
        '*' => {
            tok = handler.handleAstersik(l);
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

// What other tokens do we need?
// # => Heading -> heading type (1..6) function -> get the heading value function.
// > => blockquote -> get the blockquote value function.
// * => italic or bold -> get italic/bold value function
// - => unordered list -> Get all the ul values -> until a new line doesn't start with -
// 1. => ordered list -> Get all ol values -> new line not strating with a number.
// `` => inline code block -> get the contents between code block.
