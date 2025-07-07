# SSziG

A fast and lightweight markdown to HTML parser written in Zig.

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Usage](#usage)
  - [Prerequisites](#Prerequisites)
  - [From Source](#from-source)
- [Usage](#usage)
  - [Command Line Interface](#command-line-interface)
  - [Single File Processing](#single-file-processing)
  - [Directory Processing](#directory-processing)
- [Current Limitations](#current-limitations)
- [File Processing Rules](#file-processing-rules)
- [Contributing](#contributing)
- [License](#license)

## Overview

SSziG is a lightweight, fast static site generator written in Zig that converts Markdown files to HTML. SSziG can process individual files or entire directory structures, making it perfect for building static websites, documentation sites, or blogs.

## Installation

### Prerequisites

- Zig compiler (version 0.11.0 or later recommended)

### From Source

```bash
git clone https://github.com/Samarthbhat52/SSziG.git
cd SSziG
zig build
```

The compiled binary will be available in the `zig-out/bin/` directory.

## Usage

### Command Line Interface

```bash
# Display help
sszig --help
sszig -h

# Display version
sszig --version
sszig -v

# Process a single Markdown file
sszig --file input.md
sszig -f input.md

# Process an entire directory
sszig --dir content/
sszig -d content/
```


### Single File Processing

When processing a single file, SSziG creates an `output/` directory in the current working directory:

```bash
sszig -f my-document.md
```

**Input:** `my-document.md`  
**Output:** `output/my-document.html`

### Directory Processing

When processing a directory, SSziG recursively processes all `.md` files and maintains the directory structure:

```bash
sszig -d content/
```

**Example structure:**
```
content/
├── index.md
├── about.md
└── blog/
    ├── post1.md
    └── post2.md
```

**Output:**
```
public/
├── index.html
├── about.html
└── blog/
    ├── post1.html
    └── post2.html
```

## Current Limitations

The following features are **not supported**:

- Raw HTML blocks
- superscript
- Nested code blocks
- Escape sequences
- Some other delimiters that I may not have encountered yet

## File Processing Rules

- Only `.md` files are processed
- Files without extensions are skipped
- Non-markdown files are ignored with a skip message

## Contributing

At this time, I'm not accepting contributions. However, feel free to fork or clone the repository and experiment on your own!

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
