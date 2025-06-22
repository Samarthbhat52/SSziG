const parser = @import("./parser.zig");
const ast = @import("./ast.zig");
const token = @import("../lexer/token.zig");

const Parser = parser.Parser;
const ParseError = ast.ParseError;
const ASTNode = ast.ASTNode;
const NodeType = ast.NodeType;
const TokenType = token.TokenType;

pub fn parseHeader(self: *Parser, level: u8) ParseError!ASTNode {
    var header_node = ASTNode.init(self.allocator, NodeType.header);
    header_node.header_level = level;

    try self.nextToken();

    while (self.current_token.type != TokenType.newLine and self.current_token.type != TokenType.EOF) {
        const inline_node = try self.parseInline();
        try header_node.children.append(inline_node);
    }

    return header_node;
}
