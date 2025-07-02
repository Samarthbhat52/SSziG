const std = @import("std");
const print = std.debug.print;

const Allocator = std.mem.Allocator;
const Lexer = @import("./lexer/lexer.zig").Lexer;
const Parser = @import("./parser/parser.zig").Parser;
const Html = @import("./nodeToHtml.zig").Html;
const TokenType = @import("./lexer/token.zig").TokenType;

const CliError = error{
    InvalidCommand,
    MissingArgument,
};

const Command = enum {
    help,
    unknown,
};

fn parseCommand(arg: []const u8) Command {
    if (std.mem.eql(u8, arg, "help")) {
        return .help;
    }
    return .unknown;
}

fn printHelp() void {
    print("\nSSziG v0.1.0\n\n", .{});
    print("USAGE:\n", .{});
    print("    sszig [COMMAND]\n\n", .{});
    print("COMMANDS:\n", .{});
    print("    help, --help, -h    Show this help message\n\n", .{});
}

fn replFunction(alloc: Allocator) !void {
    const stdin = std.io.getStdIn().reader();

    print("\nSSziG v0.1.0\n", .{});
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
            defer document.deinit();

            var generator = Html.init(alloc);
            const html = try generator.generateHtml(document);

            defer alloc.free(html);

            print("SSzig: '{s}'\n", .{html});
            continue;
        } else {
            // EOF reached (Ctrl+D on Unix, Ctrl+Z on Windows)
            print("\nclosing\n", .{});
            break;
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        try replFunction(allocator);
        return;
    }

    const command = parseCommand(args[1]);

    switch (command) {
        .help => printHelp(),
        .unknown => {
            print("\nError: Unknown command '{s}'\n", .{args[1]});
            print("Run 'sszig help' for usage information.\n", .{});
            return;
        },
    }
}
