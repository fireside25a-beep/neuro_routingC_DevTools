# NeuroRoute DevCLI v0.4.0 🚀

NeuroRoute DevCLI is a portable C11 developer command-line tool built around a deterministic routing library.

The project preserves the original NeuroRoute behavior, including maximum-weight graph routing, activation thresholds, fallback handling, atomic route-use counters, and 256-bit Hamming-distance spatial matching, while extending it into a practical developer workflow for common programming languages.

The DevCLI can inspect a directory, detect the project type using deterministic priority rules, report ambiguous layouts instead of silently guessing, identify installed compilers and interpreters, create minimal starter projects, and safely execute build, run, test, clean, and edit operations.

Supported languages:

- C
- C++
- Python
- Rust
- JavaScript
- Go
- Zig
- Java

Missing toolchains are reported clearly and are never presented as successful tests.

## What NeuroRoute DevCLI is

NeuroRoute DevCLI is a focused orchestration tool for local development workflows.

It is designed to remain:

- portable;
- deterministic;
- inspectable;
- source-first;
- small enough to understand;
- explicit about failures and missing dependencies.

It is not:

- an AI model;
- an operating system;
- a compiler;
- a package manager;
- a shell;
- a terminal emulator;
- a PTY implementation.

## Original NeuroRoute behavior

The preserved NeuroRoute C library provides:

- deterministic maximum-weight graph routing;
- activation-threshold handling;
- fallback route selection;
- atomic route-use counters;
- 256-bit Hamming-distance spatial matching;
- a portable C11 static library;
- routing and spatial-pool unit tests;
- the original CLI demonstration.

Expected original test output:

```text
routing tests: PASS
spatial pool tests: PASS
```

Expected original demo output:

```text
Selected route target: 1002
Selected spatial page: 8192
```

The routing and spatial-pool algorithms remain separate from the developer CLI implementation.

## DevCLI commands ⚙️

```text
neuro help
neuro status
neuro detect [path]
neuro init <language> <directory>
neuro build [path]
neuro run [path]
neuro test [path]
neuro clean [path]
neuro edit <file>
```

Running `neuro` without arguments opens the optional interactive mode:

```text
neuro> status
neuro> detect .
neuro> build .
neuro> run .
neuro> test .
neuro> quit
```

The interactive mode is intentionally limited. It does not implement shell pipelines, redirects, job control, shell expansion, complete quoting rules, or PTY emulation.

## Supported languages and toolchains

| Language | Detection markers | Required tools | Generated entry point |
|---|---|---|---|
| C | `Makefile`, `*.c` | `clang` or `gcc` | `main.c` |
| C++ | `CMakeLists.txt`, `*.cpp`, `*.cc`, `*.cxx` | `clang++` or `g++` | `main.cpp` |
| Python | `pyproject.toml`, `requirements.txt`, `*.py` | `python3` | `main.py` |
| Rust | `Cargo.toml`, `*.rs` | `cargo` | `Cargo.toml`, `src/main.rs` |
| JavaScript | `package.json`, `*.js`, `*.mjs`, `*.cjs` | `node`, optional `npm` | `main.js` |
| Go | `go.mod`, `*.go` | `go` | `go.mod`, `main.go` |
| Zig | `build.zig`, `*.zig` | `zig` | `main.zig` |
| Java | `pom.xml`, `build.gradle`, `*.java` | `javac`, `java` | `Main.java` |

NeuroRoute DevCLI does not download or install external toolchains.

## Deterministic project detection

Project detection uses deterministic priority rules based on recognized manifests and source-file extensions.

The general priority is:

1. language-specific manifest files;
2. recognized source-file extensions;
3. a generic Makefile as weaker C evidence.

When multiple project types conflict at the same priority, NeuroRoute reports the ambiguity instead of silently selecting one.

Example:

```bash
neuro detect .
```

## Starter-project generation

Each generated starter project prints:

```text
Hello from NeuroRoute DevCLI
```

Example for C:

```bash
neuro init c /tmp/hello-c
neuro build /tmp/hello-c
neuro run /tmp/hello-c
neuro test /tmp/hello-c
```

Example for Python:

```bash
neuro init python /tmp/hello-python
neuro run /tmp/hello-python
neuro test /tmp/hello-python
```

Example for Java:

```bash
neuro init java /tmp/hello-java
neuro build /tmp/hello-java
neuro run /tmp/hello-java
neuro test /tmp/hello-java
```

Project generation is intentionally conservative.

NeuroRoute refuses to overwrite an existing non-empty directory. Generated programs print a known verification message, and every external command returns its real exit status.

## Process execution and security

External commands are launched using POSIX argument arrays through:

```text
posix_spawnp()
waitpid()
```

The project does not pass user input through:

```text
system()
popen()
sh -c
bash -c
```

This reduces command-injection risk in the process-launching layer.

Child programs inherit normal standard input, output, error streams, and environment variables.

NeuroRoute DevCLI does not sandbox compilers, interpreters, editors, scripts, project files, Makefiles, or external build systems. Only run projects and tools you trust.

The DevCLI itself performs no network calls. External development tools may access the network according to their own configuration.

## Single-file installer

The release includes a self-contained installer with the complete source archive embedded inside one Bash script.

No separate ZIP or tarball is required when using the installer.

```bash
chmod +x install-neuroroute-devcli-v0.4.0.sh
./install-neuroroute-devcli-v0.4.0.sh
```

The default installation path is:

```text
$HOME/
`-- .local/
    `-- bin/
        `-- neuro
```

Run the installed program:

```bash
$HOME/.local/bin/neuro help
$HOME/.local/bin/neuro status
```

Install to a custom prefix:

```bash
./install-neuroroute-devcli-v0.4.0.sh --prefix "$HOME/neuro"
```

Install system-wide:

```bash
sudo ./install-neuroroute-devcli-v0.4.0.sh --prefix /usr/local
```

The installer:

1. extracts its embedded source into an isolated temporary directory;
2. verifies the embedded payload;
3. builds the project;
4. runs the bundled test suite;
5. verifies the original NeuroRoute demo;
6. creates, builds, and runs a generated C starter project;
7. installs the final `neuro` executable;
8. removes temporary build files.

Installer SHA-256:

```text
63976b2d4df2d7895e4b1e123514a242cb91cce6720ba7b38e7d337970f64bdb
```

Verify on Linux:

```bash
sha256sum install-neuroroute-devcli-v0.4.0.sh
```

Verify on macOS:

```bash
shasum -a 256 install-neuroroute-devcli-v0.4.0.sh
```

## Build from source

Requirements:

- macOS or Linux;
- a C11 compiler such as GCC or Clang;
- `make`;
- `ar`;
- standard POSIX process APIs.

Build everything:

```bash
make
```

Run all tests:

```bash
make test
```

Run the original demo:

```bash
make demo
```

Build only the developer CLI:

```bash
make devcli
```

Run sanitizer checks where supported:

```bash
make sanitize
```

Clean generated files:

```bash
make clean
```

Strict compiler warnings:

```text
-std=c11 -Wall -Wextra -Wpedantic -Werror
```

The normal build produces:

```text
lib/libneuro_router.a
bin/neuro
bin/neuro_demo
bin/test_routing
bin/test_spatial_pool
bin/test_process_runner
bin/test_project_detect
bin/test_project_init
```

## One-command source builder

The source release also includes a build helper:

```bash
chmod +x build_neuroroute_devcli.sh
./build_neuroroute_devcli.sh .
```

It can build from:

```text
an extracted source directory
neuroroute-devcli-v0.4.0.zip
neuroroute-devcli-v0.4.0.tar.gz
```

The resulting executable is written to:

```text
dist/
`-- neuro
```

Example:

```bash
./build_neuroroute_devcli.sh neuroroute-devcli-v0.4.0.tar.gz
./dist/neuro help
```

## Toolchain overrides

Specific tools may be selected through environment variables:

```text
NEURO_CC
NEURO_CXX
NEURO_PYTHON
NEURO_CARGO
NEURO_NODE
NEURO_NPM
NEURO_GO
NEURO_ZIG
NEURO_JAVAC
NEURO_JAVA
```

Examples:

```bash
NEURO_CC=gcc neuro build /tmp/hello-c
NEURO_CC=clang neuro build /tmp/hello-c
NEURO_CXX=clang++ neuro build /tmp/hello-cpp
```

## Editor command

`neuro edit <file>` checks:

1. `VISUAL`;
2. `EDITOR`;
3. `vi` as the fallback.

Example:

```bash
EDITOR=nano neuro edit main.c
```

The editor setting must identify one executable name or path. Embedded shell arguments are rejected.

## Source tree 🔍

```text
neuroroute-devcli-v0.4.0/
|-- examples/
|   `-- demo.c
|-- include/
|   |-- asm/
|   |   `-- primitives.h
|   |-- mm/
|   |   `-- spatial_pool.h
|   |-- devcli.h
|   |-- fs_utils.h
|   |-- neuro.h
|   |-- process_runner.h
|   |-- project_actions.h
|   |-- project_detect.h
|   |-- project_init.h
|   `-- toolchains.h
|-- src/
|   |-- devcli.c
|   |-- fs_utils.c
|   |-- main.c
|   |-- process_runner.c
|   |-- project_actions.c
|   |-- project_detect.c
|   |-- project_init.c
|   |-- routing.c
|   |-- spatial_pool.c
|   `-- toolchains.c
|-- tests/
|   |-- test_cli.sh
|   |-- test_process_runner.c
|   |-- test_project_detect.c
|   |-- test_project_init.c
|   |-- test_routing.c
|   `-- test_spatial_pool.c
|-- build_neuroroute_devcli.sh
|-- install-neuroroute-devcli-v0.4.0.sh
|-- LICENSE
|-- Makefile
|-- PROJECT_TREE.txt
|-- VALIDATION_REPORT.txt
`-- README.md
```

## Validation

Validated environment:

```text
Debian GNU/Linux 13
x86_64
```

The release was tested with both GCC and Clang using strict C11 warning flags.

| Validation area | Result |
|---|---|
| GCC strict C11 build and tests | PASS |
| Clang strict C11 build and tests | PASS |
| Original routing test | PASS |
| Original spatial-pool test | PASS |
| Original CLI demo | PASS |
| Process-runner tests | PASS |
| Project-detection tests | PASS |
| Project-initialization tests | PASS |
| CLI smoke tests | PASS |
| GCC AddressSanitizer and UndefinedBehaviorSanitizer | PASS |
| Generated C project | PASS |
| Generated C++ project | PASS |
| Generated Python project | PASS |
| Generated JavaScript project | PASS |
| Generated Go project | PASS |
| Generated Java project | PASS |
| Generated Rust project | SKIPPED - Cargo unavailable |
| Generated Zig project | SKIPPED - Zig unavailable |

Rust and Zig were marked as skipped because those toolchains were not installed in the validation environment. They were not incorrectly reported as passed.

The installed Clang sanitizer runtime failed during process startup on the validation host, including for an independent minimal C program. That result was recorded as an environment-specific failure rather than represented as a NeuroRoute sanitizer pass.

The source is designed for macOS and Linux and includes no architecture-specific precompiled binaries or handwritten assembly.

macOS runtime validation was not performed in the Linux validation environment.

## Limitations

- Windows is not supported in v0.4.0.
- The CLI does not install missing compilers or interpreters.
- Detection is intentionally marker-based.
- Framework-specific entry points are not automatically inferred.
- CMake, Maven, and Gradle files may assist detection, but full framework orchestration is not implemented.
- The interactive mode is not a complete shell or terminal emulator.
- Arbitrary Makefile projects may build and test, but the CLI does not guess an unknown output executable.
- Source portability does not prove runtime behavior on every operating system or CPU architecture.
- External tools remain responsible for their own security, dependencies, configuration, and network behavior.

## Why this project exists

NeuroRoute DevCLI is intended for developers who want a compact and transparent tool that combines deterministic project detection with direct access to locally installed development toolchains.

The goal is to provide useful local orchestration without hidden behavior, silent assumptions, unnecessary abstraction, or false test claims.

The repository includes the portable C11 library, the developer CLI, unit tests, CLI smoke tests, starter-project generators, build rules, sanitizer targets, documentation, source-release archives, and a self-contained installer.

## License

MIT License. See `LICENSE`.
