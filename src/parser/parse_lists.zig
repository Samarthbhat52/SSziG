const std = @import("std");
const parser = @import("./parser.zig");
const ast = @import("./ast.zig");
const token = @import("../lexer/token.zig");

const Parser = parser.Parser;
const ParseError = ast.ParseError;
const ASTNode = ast.ASTNode;

const TokenType = token.TokenType;
const NodeType = ast.NodeType;

pub fn parseList(self: *Parser, tok_type: TokenType) ParseError!ASTNode {
    const node_type = if (tok_type == .ul) NodeType.ul else NodeType.ol;
    var list_node = ASTNode.init(self.allocator, node_type);

    // consume the '-' token
    try self.nextToken();

    var container_node: ?ASTNode = null;

    while (self.current_token.type != .EOF) {
        if (self.current_token.type == .newLine and container_node != null) {
            try list_node.children.append(container_node.?);
            container_node = null;

            if (self.peek_token.type != tok_type) {
                break;
            }

            try self.nextToken();
            try self.nextToken();
            continue;
        }

        if (container_node == null) {
            container_node = ASTNode.init(self.allocator, .container);
        }
        const inline_node = try self.parseInline();
        try container_node.?.children.append(inline_node);
    }

    if (container_node != null) {
        try list_node.children.append(container_node.?);
    }
    return list_node;
}
