# SSziG

A fast and lightweight markdown to HTML parser written in Zig.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
  - [Interactive Mode (REPL)](#interactive-mode-repl)
  - [Command Line Interface](#command-line-interface)
- [Architecture](#architecture)
- [Building from Source](#building-from-source)
- [Contributing](#contributing)
- [License](#license)
- [Roadmap](#roadmap)

## Overview

SSziG is a markdown to HTML parser built with performance and simplicity in mind. Written in Zig, it provides a clean interface for converting markdown text to HTML output through both an interactive REPL mode and command-line interface.

The parser follows a traditional lexer-parser architecture, tokenizing markdown input and building an abstract syntax tree before generating the final HTML output.

## Features

- **Interactive REPL Mode**: Test markdown parsing in real-time with immediate feedback
- **Command Line Interface**: Process markdown through standard command-line arguments
- **Memory Safe**: Built with Zig's memory safety guarantees
- **Lightweight**: Minimal dependencies and fast execution
- **Modular Architecture**: Clean separation between lexing, parsing, and HTML generation

### Planned Features

- **File Processing**: Parse entire markdown files
- **Directory Processing**: Batch process multiple markdown files in a directory
- **Extended Markdown Support**: Additional markdown syntax elements
- **Output Customization**: Configurable HTML output options

## Installation

### Prerequisites

- Zig compiler (version 0.11.0 or later recommended)

### From Source

```bash
git clone https://github.com/yourusername/sszig.git
cd sszig
zig build
```

The compiled binary will be available in the `zig-out/bin/` directory.

## Usage

### Interactive Mode (REPL)

Launch SSziG without any arguments to enter interactive mode:

```bash
./sszig
```

This will start the REPL interface where you can:

- Enter markdown text line by line
- See immediate HTML conversion results
- Type `quit` or `exit` to stop the session
- Use Ctrl+D (Unix) or Ctrl+Z (Windows) to exit

#### Example REPL Session

```
SSziG v0.1.0
write in a markdown line and see the parsed output

Type 'quit' or 'exit' to stop
----------------------------------------
> # Hello World
SSzig: '<h1>Hello World</h1>'
> **Bold text**
SSzig: '<strong>Bold text</strong>'
> quit
closing
```

### Command Line Interface

#### Help Command

Display usage information:

```bash
./sszig help
# or
./sszig --help
# or
./sszig -h
```

#### Current Commands

- `help`, `--help`, `-h`: Display help information and usage instructions

### Input Limitations

- REPL mode currently supports single-line input up to 1024 characters
- Complex multi-line markdown structures should be processed line by line in the current version

## Architecture

SSziG follows a clean three-stage parsing architecture:

### 1. Lexical Analysis (`lexer/lexer.zig`)
- Tokenizes raw markdown input into meaningful tokens
- Handles different markdown syntax elements
- Provides token stream for the parser

### 2. Parsing (`parser/parser.zig`)
- Consumes token stream from the lexer
- Builds an abstract syntax tree (AST) representation
- Handles markdown grammar and structure validation

### 3. HTML Generation (`nodeToHtml.zig`)
- Traverses the parsed AST
- Generates clean HTML output
- Handles proper HTML escaping and formatting

### Token Types (`lexer/token.zig`)
- Defines all supported markdown token types
- Provides token classification and metadata

## Building from Source

### Development Build

```bash
zig build
```

### Release Build

```bash
zig build -Doptimize=ReleaseFast
```

### Running Tests

```bash
zig build test
```

### Debug Build

```bash
zig build -Doptimize=Debug
```

## Project Structure

```
sszig/
├── src/
│   ├── main.zig              # Main entry point and CLI handling
│   ├── lexer/
│   │   ├── lexer.zig         # Lexical analyzer
│   │   └── token.zig         # Token definitions
│   ├── parser/
│   │   └── parser.zig        # Parser implementation
│   └── nodeToHtml.zig        # HTML generation
├── build.zig                 # Build configuration
└── README.md                 # This file
```

## Contributing

Contributions are welcome! Please follow these guidelines:

1. **Code Style**: Follow Zig's standard formatting conventions
2. **Testing**: Add tests for new features and bug fixes
3. **Documentation**: Update documentation for any API changes
4. **Memory Safety**: Ensure proper memory management in all contributions

### Development Setup

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `zig build test`
5. Submit a pull request

### Reporting Issues

When reporting issues, please include:

- Zig version
- Operating system
- Input markdown that caused the issue
- Expected vs actual output
- Full error messages or stack traces

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Roadmap

### Version 0.2.0
- File input support
- Basic file output options
- Enhanced error handling and reporting

### Version 0.3.0
- Directory processing capabilities
- Batch conversion features
- Configuration file support

### Version 1.0.0
- Complete CommonMark compliance
- Performance optimizations
- Comprehensive test suite
- Stable API

### Future Enhancements
- Plugin system for custom renderers
- Advanced markdown extensions
- Integration with popular static site generators
- WebAssembly target support

## Performance

SSziG is designed for speed and efficiency:

- **Memory Management**: Uses Zig's allocator system for predictable memory usage
- **Zero-Copy Parsing**: Minimizes string copying during tokenization
- **Streaming Processing**: Handles large inputs without loading everything into memory
- **Compiled Performance**: Native code generation through Zig compiler

## Compatibility

- **Markdown Standards**: Currently supports basic markdown syntax
- **Output Format**: Generates standard HTML5-compatible output
- **Platform Support**: Cross-platform compatibility through Zig
- **Zig Versions**: Compatible with Zig 0.11.0 and later

---

For more information, visit the [project repository](https://github.com/yourusername/sszig) or open an issue for support.
