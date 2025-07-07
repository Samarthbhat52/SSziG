const parser = @import("./parser.zig");
const ast = @import("./ast.zig");
const token = @import("../lexer/token.zig");

const Parser = parser.Parser;
const ParseError = ast.ParseError;
const ASTNode = ast.ASTNode;

pub fn parseQuote(self: *Parser) ParseError!ASTNode {
    var quote_node = ASTNode.init(self.allocator, .quote);
    var paragraph_node = ASTNode.init(self.allocator, .paragraph);

    try self.nextToken();

    while (self.current_token.type != .EOF) {
        if (self.current_token.type == .newLine) {
            if (self.peek_token.type != .quote) {
                break;
            }

            var new_line_node = ASTNode.init(self.allocator, .text);
            new_line_node.content = self.current_token.literal;

            try paragraph_node.children.append(new_line_node);

            try self.nextToken();
            try self.nextToken();

            continue;
        }

        const inline_node = try self.parseInline();
        try paragraph_node.children.append(inline_node);
    }

    try quote_node.children.append(paragraph_node);
    return quote_node;
}
