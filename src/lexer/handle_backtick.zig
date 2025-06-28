const lexer = @import("./lexer.zig");
const token = @import("./token.zig");

const Lexer = lexer.Lexer;
const Token = token.Token;

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
        l.advance();
    }

    return Token.newToken(.code, content);
}
