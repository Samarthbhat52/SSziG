const parser = @import("./parser.zig");
const ast = @import("./ast.zig");
const token = @import("../lexer/token.zig");

const Parser = parser.Parser;
const ParseError = ast.ParseError;
const ASTNode = ast.ASTNode;
const NodeType = ast.NodeType;

pub fn parseLinks(self: *Parser) ParseError!ASTNode {
    var node = ASTNode.init(self.allocator, .link);
    node.url = self.current_token.url;

    try self.nextToken();

    // Get alt node
    while (self.current_token.type != .alt_end) {
        const inline_node = try self.parseInline();
        try node.children.append(inline_node);
    }

    // Discard link beacuse it is already stored.
    while (self.current_token.type != .link_end) {
        try self.nextToken();
    }

    return node;
}
