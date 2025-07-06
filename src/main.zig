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

    if (res.args.dir) |dirname| {
        var cwd = std.fs.cwd();

        try generatePageRecursive(allocator, &cwd, dirname, "page");
        // try parseFile(filename);
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

// TODO: CHANGE THE PATH JOINING TO USE `std.fs.path` library.

fn generatePageRecursive(
    allocator: Allocator,
    cwd: *std.fs.Dir,
    content_dir: []const u8,
    dest_dir: []const u8,
) !void {
    // Create the dest_dir
    try cwd.*.makeDir(dest_dir);

    // open the content directory
    const dir = try cwd.*.openDir(content_dir, .{ .iterate = true });
    var it = dir.iterate();
    while (try it.next()) |entry| switch (entry.kind) {
        .directory => {
            const new_content_dir = try std.mem.concat(allocator, u8, &.{
                content_dir,
                entry.name,
            });
            defer allocator.free(new_content_dir);

            const new_dest_dir = try std.mem.concat(allocator, u8, &.{
                dest_dir,
                entry.name,
            });
            defer allocator.free(new_dest_dir);

            try generatePageRecursive(allocator, cwd, new_content_dir, new_dest_dir);
        },
        .file => {
            // Create a new file, parse content, and add the parsed content to the new file.
            const content_file_path = try std.mem.concat(allocator, u8, &.{ content_dir, entry.name });
            defer allocator.free(content_file_path);

            try parseFile(content_file_path, dest_dir, cwd);
        },
        else => return error.InvalidFormatError,
    };
}

fn parseFile(
    content_file_path: []const u8,
    dest_dir: []const u8,
    cwd: *std.fs.Dir,
) !void {
    const allocator = std.heap.page_allocator;

    // Do nothing if the file is not markdown
    sanitizeFilepath(content_file_path) catch return;
    const filename = path.basename(content_file_path);

    // Read from file.
    const max_bytes = std.math.maxInt(usize);
    const input = cwd.*.readFileAlloc(allocator, content_file_path, max_bytes) catch |err| {
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
    const html_content = try generator.generateHtml(document);
    defer allocator.free(html_content);

    try createHtmlFile(allocator, dest_dir, filename, html_content);
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
    dest_dir: []const u8,
    filename: []const u8,
    content: []const u8,
) !void {
    const ext = ".md";
    // Remove the 'md' extension.
    const basename_no_ext = filename[0 .. filename.len - ext.len];

    const html_filename = try std.mem.concat(allocator, u8, &.{ basename_no_ext, ".html" });
    defer allocator.free(html_filename);

    const html_path = try std.fs.path.join(allocator, &.{ dest_dir, html_filename });
    defer allocator.free(html_path);

    // Write to the destination file.
    var file = try std.fs.cwd().createFile(html_path, .{});
    defer file.close();
    var buffered = std.io.bufferedWriter(file.writer());
    var bufwriter = buffered.writer();

    try bufwriter.writeAll(content);
}
