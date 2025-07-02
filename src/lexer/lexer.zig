const std = @import("std");
const token = @import("./token.zig");
const util = @import("../utils/delim_rules.zig");
const handler = @import("./handle_backtick.zig");

const handleInlineBacktick = handler.handleInlineBacktick;
const handleBlockBacktick = handler.handleBlockBacktick;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Token = token.Token;
const TokenType = token.TokenType;

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
    pub fn advance(l: *Lexer) void {
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

    pub fn eatWhiteSpaces(l: *Lexer) void {
        while (l.ch == ' ') {
            l.advance();
        }
    }

    pub fn getDelimiterRun(l: *Lexer, delim: u8) []const u8 {
        const position = l.position;

        while (l.peekAhead() == delim) {
            l.advance();
        }

        return l.input[position..l.readPosition];
    }

    // looks ahead without consuming a character
    pub fn peekAhead(l: *Lexer) u8 {
        if (l.position == l.input.len - 1) {
            return 0;
        }

        return l.input[l.readPosition];
    }

    pub fn peekAheadTwo(l: *Lexer) u8 {
        if (l.position == l.input.len - 2) {
            return 0;
        }

        return l.input[l.position + 2];
    }

    // all the characters till a non-valid character is found
    pub fn getValidContent(l: *Lexer) []const u8 {
        const start_position = l.position;
        while (util.isValidChar(l.ch)) {
            l.advance();
        }

        return l.input[start_position..l.position];
    }

    pub fn collectAltText(l: *Lexer, image: bool) Token {
        l.advance(); // consume the opening alt bracket

        // Collect alt text if it has any.
        var alt_idx = l.position; // position of first letter or alt text
        while (alt_idx < l.input.len - 1 and l.input[alt_idx] != '[') {
            alt_idx += 1;
        }

        // No close delim found, just send the text as is as is.
        if (l.input[alt_idx] != ']') {
            if (image) {
                return Token.newToken(.text, "![");
            }
            return Token.newToken(.text, "[");
        }

        const delim = if (image) "![" else "[";
        const token_type: TokenType = if (image) .img_alt else .link_alt;

        return Token.newToken(token_type, delim);
    }

    pub fn nextToken(l: *Lexer) !Token {
        var tok: Token = undefined;

        switch (l.ch) {
            '\n' => {
                tok = Token.newToken(.newLine, "\n");
            },
            '#' => {
                const col = l.col;
                const delim = l.getDelimiterRun(l.ch);

                if (col == 0 and delim.len <= 6 and l.peekAhead() == ' ') {
                    l.advance();
                    l.eatWhiteSpaces();

                    return Token.newToken(.heading, delim);
                }

                tok = Token.newToken(.text, delim);
            },
            '*' => {
                const delim = l.getDelimiterRun(l.ch);
                tok = Token.newToken(.asterisk, delim);
            },
            '_' => {
                const delim = l.getDelimiterRun(l.ch);
                tok = Token.newToken(.underscore, delim);
            },
            '~' => {
                const col = l.col;
                const delim = l.getDelimiterRun(l.ch);

                if (delim.len == 3 and col == 0) {
                    return handleBlockBacktick(l, l.ch);
                }

                tok = Token.newToken(.tilde, delim);
            },
            '>' => {
                if (l.col == 0 and l.peekAhead() == ' ') {
                    l.advance();
                    l.eatWhiteSpaces();
                    return Token.newToken(.quote, ">");
                }

                tok = Token.newToken(.text, ">");
            },
            '^' => {
                const delim = l.getDelimiterRun(l.ch);
                const token_type = if (delim.len == 1) TokenType.caret else TokenType.text;

                tok = Token.newToken(token_type, delim);
            },
            '`' => {
                const col = l.col;
                const delim = l.getDelimiterRun(l.ch);
                const delim_len = delim.len;

                if (delim_len > 3) {
                    return Token.newToken(.text, delim);
                }

                if (delim_len == 3 and col == 0) {
                    return handleBlockBacktick(l, l.ch);
                }

                return handleInlineBacktick(l, delim);
            },
            // '!' => {
            //     if (l.peekAhead() == '[') {
            //         l.advance();
            //         return l.collectAltText(true);
            //     }
            //
            //     tok = Token.newToken(.text, "!");
            // },
            // '[' => {
            //     return l.collectAltText(false);
            // },
            0 => tok = Token.newToken(.EOF, "EOF"),
            else => {
                const content = l.getValidContent();

                tok = Token.newToken(.text, content);
                return tok;
            },
        }

        l.advance();
        return tok;
    }
};
