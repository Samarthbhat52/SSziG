const lexer = @import("./lexer.zig");
const token = @import("./token.zig");

const Lexer = lexer.Lexer;
const Token = token.Token;

pub fn handleInlineBacktick(l: *Lexer, delim: []const u8) Token {
    // consume the last opening delim
    l.advance();

    // Search for closing delim.
    var i = l.position;
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

    const content = l.input[l.position..i];

    // consume all the characters between start and closing block
    while (l.position < i + delim.len) {
        l.advance();
    }

    return Token.newToken(.code, content);
}

pub fn handleBlockBacktick(l: *Lexer, delim: u8) Token {
    // consume the last backtick in the run
    l.advance();

    // Collect the class name
    l.eatWhiteSpaces(); // discard whitespace before class name
    const class_start = l.position;
    while (l.ch != '\n' and l.ch != 0) {
        l.advance();
    }
    const class_name = l.input[class_start..l.position];

    // consume the newline character
    l.advance();

    const code_content_start = l.position;
    var closing_found = false;
    while (l.ch != 0) {
        if (l.col == 0 and l.ch == delim and l.peekAhead() == delim and l.peekAheadTwo() == delim) {
            closing_found = true;
            break;
        }

        l.advance();
    }

    const content = l.input[code_content_start..l.position];

    if (closing_found) {
        // consume both closing delim
        for (0..3) |_| {
            l.advance();
        }
    }

    var code_block_node = Token.newToken(.codeblock, content);
    if (class_name.len > 0) {
        code_block_node.class = class_name;
    }

    return code_block_node;
}
