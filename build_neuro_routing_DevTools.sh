#!/usr/bin/env bash
# Build NeuroRoute DevCLI v0.4.0 into one executable: dist/neuro
# Works with an extracted source directory, .zip archive, or .tar.gz archive.

set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_NAME=${0##*/}
SOURCE_INPUT=""
OUTPUT_DIR="$(pwd)/dist"
COMPILER="auto"
RUN_TESTS=1
KEEP_WORK=0
WORK_DIR=""

usage() {
    cat <<USAGE
Usage:
  $SCRIPT_NAME [options] [source]

Source may be:
  - the extracted neuroroute-devcli-v0.4.0 directory
  - neuroroute-devcli-v0.4.0.zip
  - neuroroute-devcli-v0.4.0.tar.gz

Options:
  --source PATH       Source directory or release archive
  --output DIR        Output directory (default: ./dist)
  --compiler NAME     auto, gcc, clang, or another C compiler command
  --skip-tests        Build without running the test suite
  --keep-work         Keep the temporary build directory
  -h, --help          Show this help

Result:
  <output-directory>/neuro

Examples:
  ./$SCRIPT_NAME neuroroute-devcli-v0.4.0.zip
  ./$SCRIPT_NAME --compiler clang --output ./release ./neuroroute-devcli-v0.4.0
USAGE
}

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

cleanup() {
    if [[ -n "$WORK_DIR" && -d "$WORK_DIR" ]]; then
        if [[ "$KEEP_WORK" -eq 1 ]]; then
            printf 'Temporary build directory kept at: %s\n' "$WORK_DIR"
        else
            rm -rf -- "$WORK_DIR"
        fi
    fi
}
trap cleanup EXIT

while [[ $# -gt 0 ]]; do
    case "$1" in
        --source)
            [[ $# -ge 2 ]] || fail "--source requires a path"
            SOURCE_INPUT=$2
            shift 2
            ;;
        --output)
            [[ $# -ge 2 ]] || fail "--output requires a directory"
            OUTPUT_DIR=$2
            shift 2
            ;;
        --compiler)
            [[ $# -ge 2 ]] || fail "--compiler requires a compiler name"
            COMPILER=$2
            shift 2
            ;;
        --skip-tests)
            RUN_TESTS=0
            shift
            ;;
        --keep-work)
            KEEP_WORK=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            [[ $# -le 1 ]] || fail "only one source path may be supplied"
            if [[ $# -eq 1 ]]; then
                SOURCE_INPUT=$1
                shift
            fi
            ;;
        -*)
            fail "unknown option: $1"
            ;;
        *)
            [[ -z "$SOURCE_INPUT" ]] || fail "only one source path may be supplied"
            SOURCE_INPUT=$1
            shift
            ;;
    esac
done

command_exists make || fail "make is required"
command_exists ar || fail "ar is required"
command_exists mktemp || fail "mktemp is required"

if [[ -z "$SOURCE_INPUT" ]]; then
    if [[ -f ./Makefile && -d ./src && -d ./include ]]; then
        SOURCE_INPUT=.
    elif [[ -f ./neuroroute-devcli-v0.4.0.zip ]]; then
        SOURCE_INPUT=./neuroroute-devcli-v0.4.0.zip
    elif [[ -f ./neuroroute-devcli-v0.4.0.tar.gz ]]; then
        SOURCE_INPUT=./neuroroute-devcli-v0.4.0.tar.gz
    else
        fail "no source supplied and no NeuroRoute source/archive found in the current directory"
    fi
fi

[[ -e "$SOURCE_INPUT" ]] || fail "source does not exist: $SOURCE_INPUT"

case "$COMPILER" in
    auto)
        if command_exists clang; then
            CC_BIN=clang
        elif command_exists gcc; then
            CC_BIN=gcc
        elif command_exists cc; then
            CC_BIN=cc
        else
            fail "no C compiler found; install clang or gcc"
        fi
        ;;
    *)
        command_exists "$COMPILER" || fail "compiler not found: $COMPILER"
        CC_BIN=$COMPILER
        ;;
esac

WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/neuroroute-devcli-build.XXXXXX")
EXTRACT_DIR="$WORK_DIR/source"
mkdir -p "$EXTRACT_DIR"

printf 'Source: %s\n' "$SOURCE_INPUT"
printf 'Compiler: %s\n' "$CC_BIN"
printf 'Workspace: %s\n' "$WORK_DIR"

if [[ -d "$SOURCE_INPUT" ]]; then
    # Copy into the isolated workspace so the original source remains untouched.
    cp -R "$SOURCE_INPUT"/. "$EXTRACT_DIR"/
elif [[ "$SOURCE_INPUT" == *.zip ]]; then
    command_exists unzip || fail "unzip is required for ZIP input"

    # Reject absolute paths and parent-directory traversal before extraction.
    while IFS= read -r entry; do
        [[ -z "$entry" ]] && continue
        case "$entry" in
            /*|../*|*/../*|*/..)
                fail "unsafe ZIP entry: $entry"
                ;;
        esac
    done < <(unzip -Z1 "$SOURCE_INPUT")

    unzip -q "$SOURCE_INPUT" -d "$EXTRACT_DIR"
elif [[ "$SOURCE_INPUT" == *.tar.gz || "$SOURCE_INPUT" == *.tgz ]]; then
    command_exists tar || fail "tar is required for tar.gz input"

    while IFS= read -r entry; do
        [[ -z "$entry" ]] && continue
        case "$entry" in
            /*|../*|*/../*|*/..)
                fail "unsafe tar entry: $entry"
                ;;
        esac
    done < <(tar -tzf "$SOURCE_INPUT")

    tar -xzf "$SOURCE_INPUT" -C "$EXTRACT_DIR"
else
    fail "unsupported source type; use a directory, .zip, .tar.gz, or .tgz"
fi

find_project_root() {
    local candidate

    if [[ -f "$EXTRACT_DIR/Makefile" && -d "$EXTRACT_DIR/src" && -d "$EXTRACT_DIR/include" ]]; then
        printf '%s\n' "$EXTRACT_DIR"
        return 0
    fi

    candidate=$(find "$EXTRACT_DIR" -mindepth 1 -maxdepth 3 -type f -name Makefile -print | head -n 1 || true)
    [[ -n "$candidate" ]] || return 1
    candidate=${candidate%/Makefile}
    [[ -d "$candidate/src" && -d "$candidate/include" ]] || return 1
    printf '%s\n' "$candidate"
}

PROJECT_ROOT=$(find_project_root) || fail "could not locate the NeuroRoute project root"

printf '\n== Clean build ==\n'
make -C "$PROJECT_ROOT" clean CC="$CC_BIN"
make -C "$PROJECT_ROOT" devcli CC="$CC_BIN"

[[ -x "$PROJECT_ROOT/bin/neuro" ]] || fail "build completed without producing bin/neuro"

if [[ "$RUN_TESTS" -eq 1 ]]; then
    printf '\n== Full test suite ==\n'
    make -C "$PROJECT_ROOT" test CC="$CC_BIN"
else
    printf '\nTests: SKIPPED by request\n'
fi

printf '\n== Binary smoke test ==\n'
"$PROJECT_ROOT/bin/neuro" help >/dev/null

mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR=$(cd "$OUTPUT_DIR" && pwd)
install -m 0755 "$PROJECT_ROOT/bin/neuro" "$OUTPUT_DIR/neuro"

printf '\nBUILD PASS\n'
printf 'Executable: %s/neuro\n' "$OUTPUT_DIR"
printf 'Run: %s/neuro help\n' "$OUTPUT_DIR"
printf 'Version information:\n'
"$CC_BIN" --version | sed -n '1p'
