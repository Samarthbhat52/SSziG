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

        while (l.peekAhead(1) == delim) {
            l.advance();
        }

        return l.input[position..l.readPosition];
    }

    // looks ahead without consuming a character
    pub fn peekAhead(l: *Lexer, pos: u8) u8 {
        if (l.position == l.input.len - pos) {
            return 0;
        }

        return l.input[l.position + pos];
    }

    // all the characters till a non-valid character is found
    pub fn getValidContent(l: *Lexer) []const u8 {
        const start_position = l.position;
        while (util.isValidChar(l.ch)) {
            l.advance();
        }

        return l.input[start_position..l.position];
    }

    pub fn collectLink(l: *Lexer, image: bool) Token {
        const delim = if (image) "![" else "[";
        const fallback_token = if (image) Token.newToken(.text, "![") else Token.newToken(.text, "[");

        const token_type: TokenType = if (image) .image else .link;
        var tok = Token.newToken(token_type, delim);

        l.advance(); // consume the opening alt bracket

        // Collect alt text if it has any.
        var alt_idx = l.position; // position of first letter or alt text
        while (alt_idx < l.input.len - 1 and l.input[alt_idx] != ']') {
            alt_idx += 1;
        }

        // No close delim found, just send the text as is as is.
        if (l.input[alt_idx] != ']') {
            return fallback_token;
        }

        const alt_text = l.input[l.position..alt_idx];

        if (alt_idx + 1 < l.input.len and l.input[alt_idx + 1] != '(') {
            return fallback_token;
        }

        // Collect link if it has any
        const link_idx_start = alt_idx + 2;
        var link_idx_end = alt_idx + 2; // position of first letter of link

        if (link_idx_start > l.input.len - 1) {
            return fallback_token;
        }

        while (link_idx_end < l.input.len - 1 and l.input[link_idx_end] != ')') {
            link_idx_end += 1;
        }

        // No close link delim found
        if (l.input[link_idx_end] != ')') {
            return fallback_token;
        }

        const url = l.input[link_idx_start..link_idx_end];
        tok.url = url;

        if (image) {
            tok.literal = alt_text;
        }

        return tok;
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

                if (col == 0 and delim.len <= 6 and l.peekAhead(1) == ' ') {
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
            '-' => {
                if (l.col == 0 and l.peekAhead(1) == ' ') {
                    l.advance();
                    tok = Token.newToken(.ul, "-");
                } else {
                    tok = Token.newToken(.text, "-");
                }
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
                if (l.col == 0 and l.peekAhead(1) == ' ') {
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
            '!' => {
                if (l.peekAhead(1) == '[') {
                    l.advance();
                    return l.collectLink(true);
                }
                tok = Token.newToken(.text, "!");
            },
            '[' => {
                return l.collectLink(false);
            },
            ']' => {
                tok = Token.newToken(.alt_end, "]");
            },
            '(' => {
                tok = Token.newToken(.link_start, "(");
            },
            ')' => {
                tok = Token.newToken(.link_end, ")");
            },
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
