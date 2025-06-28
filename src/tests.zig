const std = @import("std");
const Lexer = @import("./lexer/lexer.zig").Lexer;
const Parser = @import("./parser/parser.zig").Parser;
const Html = @import("./nodeToHtml.zig").Html;

fn testInput(input: []const u8, expected: []const u8) !void {
    // Use the testing allocator which automatically detects memory leaks
    const allocator = std.testing.allocator;

    var lex = Lexer.init(input);
    var parser = try Parser.init(allocator, &lex);
    var document = try parser.parse();
    defer document.deinit();

    var generator = Html.init(allocator);
    const html = try generator.generateHtml(document);
    defer allocator.free(html);

    try std.testing.expectEqualStrings(expected, html);
}

test "superscript formatting" {
    try testInput("Time to test ^superscript text^ and also test ^formatting ~~***inside the***~~ superscript^, 2^14^ karma gets you in the arcanum.", "<div><p>Time to test <sup>superscript text</sup> and also test <sup>formatting <del><strong><em>inside the</em></strong></del> superscript</sup>, 2<sup>14</sup> karma gets you in the arcanum.</p></div>");
}

test "ambiguous formatting stars" {
    try testInput("*****some random** *sentence**", "<div><p>**<em><strong>some random</strong> <em>sentence</em></em></p></div>");
}

test "unbalanced emphasis" {
    try testInput("***please** work*", "<div><p><em><strong>please</strong> work</em></p></div>");
}

test "code block and multiple formatting" {
    try testInput(
        \\a sentence with `code block` and some other **formatting** _with italic_ and ~~strikethrough~~
        \\
        \\> let's add in a quote as well
    , "<div><p>a sentence with <code>code block</code> and some other <strong>formatting</strong> <em>with italic</em> and <del>strikethrough</del></p><blockquote><p>let's add in a quote as well</p></blockquote></div>");
}

test "too many heading hashes" {
    try testInput("####### wrong heading", "<div><p>####### wrong heading</p></div>");
}

test "unfinished code block backticks" {
    try testInput(
        \\sentence with
        \\```  some lang
        \\more code babie
        \\ and some more
    , "<div><p>sentence with</p><pre><code class=\"language-some lang\">more code babie\n and some more</code></pre></div>");
}

test "unfinished code block tildes" {
    try testInput(
        \\sentence with
        \\~~~zig
        \\more code babie
    , "<div><p>sentence with</p><pre><code class=\"language-zig\">more code babie</code></pre></div>");
}

test "valid header" {
    try testInput("#### header", "<div><h4>header</h4></div>");
}

test "incomplete nested code blocks" {
    try testInput(
        \\outer text
        \\```js
        \\function test() {
        \\  console.log("nested ```backticks``` in code");
        \\}
        \\```
    , "<div><p>outer text</p><pre><code class=\"language-js\">function test() {\n  console.log(\"nested ```backticks``` in code\");\n}\n</code></pre></div>");
}

test "empty formatting markers" {
    try testInput("This has ** ** empty bold and __ __ empty underline.", "<div><p>This has ** ** empty bold and __ __ empty underline.</p></div>");
}

test "overlapping emphasis boundaries" {
    try testInput("_italic **bold and italic_ still bold**", "<div><p>_italic <strong>bold and italic_ still bold</strong></p></div>");
}

test "consecutive formatting markers" {
    try testInput("**bold****more bold** and __underline____more underline__", "<div><p><strong>bold****more bold</strong> and <strong>underline____more underline</strong></p></div>");
}

test {
    _ = @import("lexer/header_test.zig");
    _ = @import("lexer/inline_test.zig");
}
