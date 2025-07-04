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
    try testInput("_italic **bold and italic_ still bold**", "<div><p><em>italic **bold and italic</em> still bold**</p></div>");
}

test "consecutive formatting markers" {
    try testInput("**bold****more bold** and __underline____more underline__", "<div><p><strong>bold****more bold</strong> and <strong>underline____more underline</strong></p></div>");
}

test "bold formatting" {
    try testInput("This is **bold** text.", "<div><p>This is <strong>bold</strong> text.</p></div>");
}

test "italic formatting" {
    try testInput("This is *italic* text.", "<div><p>This is <em>italic</em> text.</p></div>");
}

test "strikethrough formatting" {
    try testInput("This is ~~struck through~~ text.", "<div><p>This is <del>struck through</del> text.</p></div>");
}

test "superscript and subscript" {
    try testInput("H^2^O and H ~2~ O", "<div><p>H<sup>2</sup>O and H <sub>2</sub> O</p></div>");
}

test "unordered list" {
    try testInput("- Item one\n- Item two\n- Item three", "<div><ul><li>Item one</li><li>Item two</li><li>Item three</li></ul></div>");
}

test "anchor link" {
    try testInput("[OpenAI](https://openai.com)", "<div><p><a href=\"https://openai.com\">OpenAI</a></p></div>");
}

test "inline code" {
    try testInput("This is `inline code` in a sentence.", "<div><p>This is <code>inline code</code> in a sentence.</p></div>");
}

test "code block" {
    try testInput("```\nfn main() {\n    // code\n}\n```", "<div><pre><code>fn main() {\n    // code\n}\n</code></pre></div>");
}

test "blockquote" {
    try testInput("> This is a blockquote.", "<div><blockquote><p>This is a blockquote.</p></blockquote></div>");
}

test "combined formatting" {
    try testInput("**Bold**, *Italic*, and ~~Strikethrough~~ together.", "<div><p><strong>Bold</strong>, <em>Italic</em>, and <del>Strikethrough</del> together.</p></div>");
}

test "nested formatting" {
    try testInput("**This is *nested* bold**", "<div><p><strong>This is <em>nested</em> bold</strong></p></div>");
}

test "complex mixed content" {
    try testInput("- List item with [link](https://example.com), `code`, and **bold** text.", "<div><ul><li>List item with <a href=\"https://example.com\">link</a>, <code>code</code>, and <strong>bold</strong> text.</li></ul></div>");
}

// Malformed input

test "multiple malformed markers" {
    try testInput("Mix of ~~strikethrough __underline **bold*", "<div><p>Mix of ~~strikethrough __underline *<em>bold</em></p></div>");
}

test "random lone formatting symbols" {
    try testInput("Symbols like *, _, ~, and ` in text.", "<div><p>Symbols like *, _, ~, and ` in text.</p></div>");
}

test "empty strikethrough markers" {
    try testInput("This has ~~ ~~ empty strikethrough.", "<div><p>This has ~~ ~~ empty strikethrough.</p></div>");
}

test "incomplete strikethrough in bold" {
    try testInput("markdown with **bold but ~~incomplete strikethrough**", "<div><p>markdown with <strong>bold but ~~incomplete strikethrough</strong></p></div>");
}

test "unclosed bold" {
    try testInput("This is **bold text", "<div><p>This is **bold text</p></div>");
}

test "unclosed italic" {
    try testInput("This is *italic text", "<div><p>This is *italic text</p></div>");
}

test "unclosed strikethrough" {
    try testInput("This is ~~strike", "<div><p>This is ~~strike</p></div>");
}

test "unclosed superscript" {
    try testInput("E = mc^2", "<div><p>E = mc^2</p></div>");
}

test "unclosed subscript" {
    try testInput("H~2O", "<div><p>H~2O</p></div>");
}

test "unclosed link" {
    try testInput("[Link text](https://example.com", "<div><p>[Link text](https://example.com</p></div>");
}

test "unclosed inline code" {
    try testInput("This is `code", "<div><p>This is `code</p></div>");
}

test "unclosed code block" {
    try testInput("```\nfn broken() {}", "<div><pre><code>fn broken() {}</code></pre></div>");
}

test "unordered list without leading space" {
    try testInput("-Item without space", "<div><p>-Item without space</p></div>");
}

test "list followed by paragraph without separation" {
    try testInput("- List item\nSecond paragraph", "<div><ul><li>List item</li></ul><p>Second paragraph</p></div>");
}

test "unclosed nested formatting" {
    try testInput("**Bold *Italic** Still bold*", "<div><p><em><em>Bold <em>Italic</em></em> Still bold</em></p></div>");
}

test "empty link" {
    try testInput("[](https://example.com)", "<div><p><a href=\"https://example.com\"></a></p></div>");
}

test "link with missing URL" {
    try testInput("[Example]() text", "<div><p><a href=\"\">Example</a> text</p></div>");
}

test "basic image" {
    try testInput("![Alt text](https://example.com/image.png)", "<div><p><img src=\"https://example.com/image.png\" alt=\"Alt text\" /></p></div>");
}

test "image surrounded by text" {
    try testInput("Here is an image: ![Logo](https://example.com/logo.svg) in the middle.", "<div><p>Here is an image: <img src=\"https://example.com/logo.svg\" alt=\"Logo\" /> in the middle.</p></div>");
}

test "image inside list item" {
    try testInput("- Item with ![icon](icon.png)", "<div><ul><li>Item with <img src=\"icon.png\" alt=\"icon\" /></li></ul></div>");
}

test "missing parentheses in image" {
    try testInput("![alt text]image.png", "<div><p>![alt text]image.png</p></div>");
}

test "missing alt text" {
    try testInput("![](image.png)", "<div><p><img src=\"image.png\" alt=\"\" /></p></div>");
}

test "missing src in image" {
    try testInput("![Alt]()", "<div><p><img src=\"\" alt=\"Alt\" /></p></div>");
}

test "image without closing bracket" {
    try testInput("![Broken image(image.png)", "<div><p>![Broken image(image.png)</p></div>");
}

test "image with only alt text" {
    try testInput("![Only alt text]", "<div><p>![Only alt text]</p></div>");
}

test "image with malformed URL" {
    try testInput("![Alt](ht!tp://bad[.url)", "<div><p><img src=\"ht!tp://bad[.url\" alt=\"Alt\" /></p></div>");
}
