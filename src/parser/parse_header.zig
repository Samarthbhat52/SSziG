const Parser = @import("./parser.zig").Parser;
const ParseError = @import("./ast.zig").ParseError;
const ASTNode = @import("./ast.zig").ASTNode;
const NodeType = @import("./ast.zig").NodeType;
const TokenType = @import("../token.zig").TokenType;

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
