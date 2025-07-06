const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const clap = @import("clap");
const config = @import("config");

const Lexer = @import("./lexer/lexer.zig").Lexer;
const TokenType = @import("./lexer/token.zig").TokenType;
const Html = @import("./nodeToHtml.zig").Html;
const Parser = @import("./parser/parser.zig").Parser;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const params = comptime clap.parseParamsComptime(
        \\-h, --help             Display this help and exit.
        \\-v, --version          Display version and exit.
        \\-f, --file             Markdown file path.
        \\-d, --dir              Directory of markdown files (can be nested).
        \\<str>
        \\
    );

    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag,
        .allocator = gpa.allocator(),
    }) catch |err| {
        diag.report(std.io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0) {
        return clap.help(std.io.getStdErr().writer(), clap.Help, &params, .{});
    }

    if (res.args.version != 0) {
        print("SSziG v{s}\n", .{config.version});
        return;
    }

    try replFunction(allocator);
}

fn replFunction(alloc: Allocator) !void {
    const stdin = std.io.getStdIn().reader();

    print("\nSSziG v{s}\n", .{config.version});
    print("write in a markdown line and see the parsed output\n\n", .{});
    print("Type 'quit' or 'exit' to stop\n", .{});
    print("----------------------------------------\n", .{});

    while (true) {
        print("> ", .{});

        // read from stdin
        if (try stdin.readUntilDelimiterOrEofAlloc(alloc, '\n', 1024)) |input| {
            defer alloc.free(input);

            // check for exit command.
            if (std.mem.eql(u8, input, "quit") or std.mem.eql(u8, input, "exit")) {
                print("closing\n", .{});
                break;
            }

            var lex = Lexer.init(input);
            var p = try Parser.init(alloc, &lex);
            var document = try p.parse();

            var generator = Html.init(alloc);
            const html = try generator.generateHtml(document);

            print("SSzig: '{s}'\n", .{html});

            document.deinit();
            alloc.free(html);
            continue;
        } else {
            print("\nclosing\n", .{});
            break;
        }
    }
}
