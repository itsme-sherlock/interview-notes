# Shell Scripting Quick Revision

<!-- QUICK_SHEET_START -->

## Quick Sheet
- Script header: `#!/bin/bash`.
- Validate args and fail fast with non-zero exit code.
- Use `if`, `case`, loops, and file-test operators (`-f`, `-r`, `-w`, `-x`, `-s`).
- Redirect logs using `>`, `>>`, and `2>&1`.
- For DB automation: run SQLPlus, capture status, log outcome.

<!-- QUICK_SHEET_END -->

## Table of Contents
- [Core Syntax](#core-syntax)
- [High-Frequency Interview Questions](#high-frequency-interview-questions)
- [Common Pitfalls](#common-pitfalls)
- [Memory Cues](#memory-cues)

## Core Syntax
```sh
#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <file>"
  exit 1
fi

if [ ! -f "$1" ]; then
  echo "File not found"
  exit 2
fi

echo "Processing $1" >> job.log 2>&1
```

## High-Frequency Interview Questions
- Difference between `$@` and `$*`.
- Why check `$?` or enable strict mode.
- How to run SQL scripts from shell and capture failures.

## Common Pitfalls
- Not quoting variables.
- Ignoring command exit status.
- Writing scripts without logs.

## Memory Cues
- "Validate, execute, verify, log."
- "Quote variables unless intentional splitting is needed."
