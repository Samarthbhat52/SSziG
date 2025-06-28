const std = @import("std");
const parser = @import("./parser.zig");
const ast = @import("./ast.zig");
const token = @import("../lexer/token.zig");

const Parser = parser.Parser;
const ParseError = ast.ParseError;
const ASTNode = ast.ASTNode;
const ArrayList = std.ArrayList;

pub fn parseCodeBlock(self: *Parser) ParseError!ASTNode {
    var code_block_node = ASTNode.init(self.allocator, .codeblock);

    try self.nextToken(); // Start collecting the language specicifier

    // collect the language tag.
    var output = ArrayList(u8).init(self.allocator);

    while (self.current_token.type != .newLine and self.peek_token.type != .EOF) : (try self.nextToken()) {
        try output.appendSlice(self.current_token.literal);
    }

    if (output.items.len != 0) {
        code_block_node.class = try output.toOwnedSlice();
    } else {
        output.deinit();
    }

    if (self.current_token.type == .newLine) {
        try self.nextToken();
    }

    while (self.current_token.type != .EOF and self.current_token.type != .codeblock) : (try self.nextToken()) {
        var child_node = ASTNode.init(self.allocator, .text);
        child_node.content = self.current_token.literal;

        try code_block_node.children.append(child_node);
    }

    return code_block_node;
}
