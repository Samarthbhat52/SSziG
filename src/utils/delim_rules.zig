const std = @import("std");

fn isAlphaNumOrPunct(char: u8) bool {
    return std.ascii.isAlphanumeric(char) or isAsciiPunctuation(char);
}

fn isAsciiPunctuation(c: u8) bool {
    return switch (c) {
        '!', '"', '#', '$', '%', '&', '\'', '(', ')', '*', '+', ',', '-', '.', '/', ':', ';', '<', '=', '>', '?', '@', '[', '\\', ']', '^', '_', '`', '{', '|', '}', '~' => true,
        else => false,
    };
}

pub fn can_open(behind_token: anytype, ahead_token: anytype) bool {
    const behind_char = if (behind_token.literal.len > 0) behind_token.literal[behind_token.literal.len - 1] else 0;
    const ahead_char = if (ahead_token.literal.len > 0) ahead_token.literal[0] else 0;

    const preceededbyWhiteSpaceOrPunct = behind_token.type == .EOF or std.ascii.isWhitespace(behind_char) or isAsciiPunctuation(behind_char);
    const followedByWhitespace = ahead_token.type == .EOF or std.ascii.isWhitespace(ahead_char);
    const followedByPunct = isAlphaNumOrPunct(ahead_char);

    return !followedByWhitespace and !(followedByPunct and !preceededbyWhiteSpaceOrPunct);
}

pub fn can_close(behind_token: anytype, ahead_token: anytype) bool {
    const behind_char = if (behind_token.literal.len > 0) behind_token.literal[behind_token.literal.len - 1] else 0;
    const ahead_char = if (ahead_token.literal.len > 0) ahead_token.literal[0] else 0;

    const precededByWhitespace = behind_token.type == .EOF or std.ascii.isWhitespace(behind_char);
    const followedByWhitespaceOrPunctuation = ahead_token.type == .EOF or std.ascii.isWhitespace(ahead_char) or isAsciiPunctuation(ahead_char);
    const precededByPunct = isAlphaNumOrPunct(behind_char);

    return !precededByWhitespace and !(precededByPunct and !followedByWhitespaceOrPunctuation);
}

pub fn isValidChar(ch: u8) bool {
    const stop_chars = [_]u8{ '_', '~', '^', '*', '`', '!', '[', ']', '(', ')', '\n', 0 };
    for (stop_chars) |c| {
        if (ch == c) {
            return false;
        }
    }

    return true;
}

pub fn isNumeric(ch: u8) bool {
    return ch >= '0' and ch <= '9';
}
