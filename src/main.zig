const std = @import("std");

const print = std.debug.print;
const path = std.fs.path;
const Allocator = std.mem.Allocator;

const clap = @import("clap");
const config = @import("config");

const Lexer = @import("./lexer/lexer.zig").Lexer;
const TokenType = @import("./lexer/token.zig").TokenType;
const Html = @import("./nodeToHtml.zig").Html;
const Parser = @import("./parser/parser.zig").Parser;

const html_template = @import("./template.zig").html_template;

const FSError = error{
    NotMdFileError,
    MissingExtError,
    InvalidFormatError,
};

fn Error(comptime fmt: []const u8, args: anytype) void {
    const stderr = std.io.getStdErr().writer();
    stderr.print("Error: " ++ fmt ++ "\n", args) catch {};
}

fn printError(filepath: []const u8, err: anyerror) void {
    switch (err) {
        error.FileNotFound => Error("Not found: '{s}'", .{filepath}),
        error.IsDir => Error("'{s}' is a directory, not a file", .{filepath}),
        error.NotDir => Error("'{s}' is not a directory", .{filepath}),
        else => Error("Failed to process file '{s}': {}", .{ filepath, err }),
    }
}

pub fn main() !u8 {
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
        return 1;
    };
    defer res.deinit();

    if (res.args.help != 0) {
        clap.help(std.io.getStdErr().writer(), clap.Help, &params, .{}) catch {};
        return 0;
    }

    if (res.args.version != 0) {
        print("SSziG v{s}\n", .{config.version});
        return 0;
    }

    if (res.args.dir) |dirname| {
        var cwd = std.fs.cwd();

        generatePageRecursive(allocator, &cwd, dirname, "public") catch |err| {
            printError(dirname, err);
            return 1;
        };
        return 0;
    }

    if (res.args.file) |filename| {
        // Create output directory if it doesn't exist
        std.fs.cwd().makeDir("output") catch |err| {
            if (err != std.posix.OpenError.PathAlreadyExists) {
                Error("error creating output directory\n", .{});
                return err;
            }
        };

        parseFile(allocator, filename, "output") catch |err| {
            printError(filename, err);
            return 1;
        };
        return 0;
    }

    return 1;
}

fn generatePageRecursive(
    allocator: Allocator,
    cwd: *std.fs.Dir,
    content_dir: []const u8,
    dest_dir: []const u8,
) !void {
    // Create the dest_dir
    cwd.*.makeDir(dest_dir) catch |err| {
        if (err != std.posix.OpenError.PathAlreadyExists) {
            print("error creating directory: {s}\n", .{dest_dir});
            return err;
        }
    };

    // open the content directory
    const dir = try cwd.*.openDir(content_dir, .{ .iterate = true });
    var it = dir.iterate();
    while (try it.next()) |entry| switch (entry.kind) {
        .directory => {
            const new_content_dir = try path.join(allocator, &.{
                content_dir,
                entry.name,
            });
            defer allocator.free(new_content_dir);

            const new_dest_dir = try path.join(allocator, &.{
                dest_dir,
                entry.name,
            });
            defer allocator.free(new_dest_dir);

            try generatePageRecursive(allocator, cwd, new_content_dir, new_dest_dir);
        },
        .file => {
            // Create a new file, parse content, and add the parsed content to the new file.
            const content_file_path = try path.join(allocator, &.{ content_dir, entry.name });
            defer allocator.free(content_file_path);

            try parseFile(allocator, content_file_path, dest_dir);
        },
        else => return error.InvalidFormatError,
    };
}

fn parseFile(
    allocator: Allocator,
    content_file_path: []const u8,
    dest_dir: []const u8,
) !void {
    // Do nothing if the file is not markdown
    sanitizeFilepath(content_file_path) catch return;
    const filename = path.basename(content_file_path);

    // Read from file.
    const max_bytes = std.math.maxInt(usize);
    const input = try std.fs.cwd().readFileAlloc(allocator, content_file_path, max_bytes);
    defer allocator.free(input);

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
        print("skipped file: {s}\n", .{ext});
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

    const html_path = try path.join(allocator, &.{ dest_dir, html_filename });
    defer allocator.free(html_path);

    // Write to the destination file.
    var file = try std.fs.cwd().createFile(html_path, .{});
    defer file.close();
    var buffered = std.io.bufferedWriter(file.writer());
    var bufwriter = buffered.writer();

    const html_temp_content = try std.fmt.allocPrint(allocator, html_template, .{content});
    defer allocator.free(html_temp_content);

    try bufwriter.writeAll(html_temp_content);
    try buffered.flush();
}
