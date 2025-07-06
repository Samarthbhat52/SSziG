const std = @import("std");

// TODO: Change this to stdout
const print = std.debug.print;
const path = std.fs.path;
const Allocator = std.mem.Allocator;

const clap = @import("clap");
const config = @import("config");

const Lexer = @import("./lexer/lexer.zig").Lexer;
const TokenType = @import("./lexer/token.zig").TokenType;
const Html = @import("./nodeToHtml.zig").Html;
const Parser = @import("./parser/parser.zig").Parser;

const FSError = error{
    NotMdFileError,
    MissingExtError,
    InvalidFormatError,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const params = comptime clap.parseParamsComptime(
        \\-h, --help             Display this help and exit.
        \\-v, --version          Display version and exit.
        \\-f, --file <str>       Markdown file path.
        \\-d, --dir  <str>       Directory of markdown files (can be nested).
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

    if (res.args.file) |filename| {
        try parseFile(filename);
        return;
    }

    try replFunction(allocator);
}

fn replFunction(alloc: Allocator) !void {
    const stdin_reader = std.io.getStdIn().reader();
    var stdin_buffer = std.io.bufferedReader(stdin_reader);
    const stdin = stdin_buffer.reader();

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

fn parseFile(filepath: []const u8) !void {
    const allocator = std.heap.page_allocator;

    try sanitizeFilepath(filepath);

    const dir = path.dirname(filepath) orelse ".";
    const filename = path.basename(filepath);

    // Read from file.
    const cwd = std.fs.cwd();
    const file = try cwd.openFile(filepath, .{ .mode = .read_only });
    defer file.close();

    const max_bytes = std.math.maxInt(usize);
    const input = cwd.readFileAlloc(allocator, filepath, max_bytes) catch |err| {
        // TODO: Handle this error better
        print("Failed to read file: {}\n", .{err});
        return err;
    };

    // Parse md to html.
    var lex = Lexer.init(input);
    var p = try Parser.init(allocator, &lex);
    var document = try p.parse();
    defer document.deinit();

    var generator = Html.init(allocator);
    const html = try generator.generateHtml(document);
    defer allocator.free(html);

    try createHtmlFile(allocator, dir, filename, html);
}

fn sanitizeFilepath(filepath: []const u8) FSError!void {
    const ext = path.extension(filepath);

    // check for proper markdown file.
    if (ext.len == 0) return FSError.MissingExtError;
    if (!std.mem.eql(u8, ext, ".md")) {
        print("file format: {s}", .{ext});
        return FSError.InvalidFormatError;
    }
}

fn createHtmlFile(
    allocator: Allocator,
    dir: []const u8,
    filename: []const u8,
    content: []const u8,
) !void {
    const ext = ".md";
    // Remove the 'md' extension.
    const basename_no_ext = filename[0 .. filename.len - ext.len];

    const html_filename = try std.mem.concat(allocator, u8, &.{ basename_no_ext, ".html" });
    defer allocator.free(html_filename);

    const html_path = try std.fs.path.join(allocator, &.{ dir, html_filename });
    defer allocator.free(html_path);

    // TODO: Change this to buffered writer.
    var file = try std.fs.cwd().createFile(html_path, .{ .read = true, .truncate = true });
    defer file.close();

    try file.writeAll(content);
}
