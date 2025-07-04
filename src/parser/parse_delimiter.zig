const std = @import("std");

// Group related imports
const parser = @import("./parser.zig");
const ast = @import("./ast.zig");
const token = @import("../lexer/token.zig");
const delim_rules = @import("../utils/delim_rules.zig");

// Create local aliases for frequently used types
const Parser = parser.Parser;
const NodeType = ast.NodeType;
const ASTNode = ast.ASTNode;
const ParseError = ast.ParseError;
const TokenType = token.TokenType;
const Token = token.Token;
const ArrayList = std.ArrayList;

const DelimiterInfo = struct {
    token: Token,
    length: usize,
    can_open: bool,
    can_close: bool,
};

const ParseResult = struct {
    node: ASTNode,
    remaining_open_length: usize,
    remaining_close_length: usize,
};

fn isAnotherInlineDelim(delim: TokenType) bool {
    const inlineDelims = [_]TokenType{ .caret, .asterisk, .underscore, .tilde };

    for (inlineDelims) |d| {
        if (d == delim) {
            return true;
        }
    }

    return false;
}

fn createDelimiterInfo(self: *Parser, tok: Token) DelimiterInfo {
    return DelimiterInfo{
        .token = tok,
        .length = tok.literal.len,
        .can_open = if (tok.type == .caret) true else delim_rules.can_open(self.prev_token, self.peek_token),
        .can_close = if (tok.type == .caret) true else delim_rules.can_close(self.prev_token, self.peek_token),
    };
}

fn createNodeFromDelimiterSize(allocator: std.mem.Allocator, delim_size: usize, delim: TokenType) ASTNode {
    const node_type = switch (delim) {
        TokenType.asterisk, TokenType.underscore => if (delim_size == 2) NodeType.bold else NodeType.italic,
        TokenType.tilde => if (delim_size == 2) NodeType.strikethrough else NodeType.sub,
        TokenType.caret => if (delim_size == 2) NodeType.container else NodeType.sup,
        else => NodeType.text,
    };

    return ASTNode.init(allocator, node_type);
}

fn recursiveDelimiterParse(self: *Parser, consume_count: usize, content_buf: ArrayList(ASTNode), delim: TokenType) ParseError!ASTNode {
    const delim_size: usize = if (consume_count >= 2) 2 else 1;
    var node = createNodeFromDelimiterSize(self.allocator, delim_size, delim);

    const new_consume_count = consume_count - delim_size;

    if (new_consume_count == 0) {
        // Base case: append all content to this node
        for (content_buf.items) |item| {
            try node.children.append(item);
        }
        return node;
    }

    // Recursive case: create child node with remaining consume count
    const children_node = try recursiveDelimiterParse(self, new_consume_count, content_buf, delim);
    try node.children.append(children_node);

    return node;
}

fn handleClosingDelimiter(
    self: *Parser,
    content_buf: *ArrayList(ASTNode),
    open_delim_info: *DelimiterInfo,
    close_delim_info: DelimiterInfo,
) ParseError!struct { node: ?ASTNode, remaining_close_delim: bool } {
    const consume_count = @min(open_delim_info.length, close_delim_info.length);
    const node = try recursiveDelimiterParse(self, consume_count, content_buf.*, close_delim_info.token.type);

    open_delim_info.length -= consume_count;
    const remaining_close_length = close_delim_info.length - consume_count;

    // If we still have opening delimiters left, continue parsing
    if (open_delim_info.length > 0) {
        content_buf.clearRetainingCapacity();
        try content_buf.append(node);
        try self.nextToken();

        return .{ .node = null, .remaining_close_delim = false }; // Continue parsing
    }

    // Create remaining close delimiter info if any
    if (remaining_close_length > 0) {
        const new_literal = close_delim_info.token.literal[0..remaining_close_length];
        const tok = Token.newToken(close_delim_info.token.type, new_literal);
        self.current_token = tok;

        return .{ .node = node, .remaining_close_delim = true };
    }

    return .{ .node = node, .remaining_close_delim = false };
}

fn createFallbackTextNode(
    allocator: std.mem.Allocator,
    content_buf: ArrayList(ASTNode),
    open_delim_info: DelimiterInfo,
) ParseError!ASTNode {
    var container_node = ASTNode.init(allocator, NodeType.container);

    // Add remaining opening delimiter as text if any
    if (open_delim_info.length > 0) {
        var remaining_node = ASTNode.init(allocator, NodeType.text);
        remaining_node.content = open_delim_info.token.literal[0..open_delim_info.length];
        try container_node.children.insert(0, remaining_node);
    }

    // Add all parsed content
    for (content_buf.items) |item| {
        try container_node.children.append(item);
    }

    return container_node;
}

pub fn parseDelimiter(self: *Parser, delim: TokenType) ParseError!ASTNode {
    var content_buf = ArrayList(ASTNode).init(self.allocator);
    defer content_buf.deinit();

    var open_delim_info = createDelimiterInfo(self, self.current_token);

    if (!open_delim_info.can_open) {
        // Cannot open here, treat as regular text
        try self.nextToken();
        return createFallbackTextNode(self.allocator, content_buf, open_delim_info);
    }

    try self.nextToken();

    // Main parsing loop
    while (self.current_token.type != TokenType.EOF and
        self.current_token.type != TokenType.newLine)
    {
        const close_delim_info = createDelimiterInfo(self, self.current_token);
        if (self.current_token.type == delim) {
            if (close_delim_info.can_close) {
                const result = try handleClosingDelimiter(self, &content_buf, &open_delim_info, close_delim_info);

                if (result.node) |node| {
                    // Successfully parsed, but we might have remaining close delimiters
                    if (!result.remaining_close_delim) {
                        // if there are no remaining closing tokens after parsing,
                        // just consume the current token and continue
                        try self.nextToken();
                    }

                    return node;
                }
                // Continue parsing if we have remaining open delimiters
                continue;
            }
        }

        if (!close_delim_info.can_open and self.current_token.type != delim and isAnotherInlineDelim(self.current_token.type)) {
            return createFallbackTextNode(self.allocator, content_buf, open_delim_info);
        }

        // Parse inline content
        const inline_node = try self.parseInline();
        try content_buf.append(inline_node);
    }

    // No closing delimiter found, return as plain text
    try self.nextToken();
    return createFallbackTextNode(self.allocator, content_buf, open_delim_info);
}
