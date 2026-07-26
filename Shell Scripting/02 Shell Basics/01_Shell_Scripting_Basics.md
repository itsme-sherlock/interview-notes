# Shell Scripting Basics for Database Work

<!-- QUICK_SHEET_START -->

## Quick Sheet
- Start scripts with `#!/bin/bash`.
- Validate inputs early and return non-zero on failures.
- Quote variables: `"$var"`.
- Core control flow: `if`, `case`, `for`, `while`, `until`.
- File checks: `-f`, `-d`, `-r`, `-w`, `-x`, `-s`.

<!-- QUICK_SHEET_END -->

## Table of Contents
- [Main Content](#main-content)
- [Script Structure](#script-structure)
- [Arguments and Exit Codes](#arguments-and-exit-codes)
- [Conditionals and Loops](#conditionals-and-loops)
- [File Tests](#file-tests)
- [Best Practices](#best-practices)
- [Interview Insights](#interview-insights)
- [Related Notes](#related-notes)

## Main Content

## Script Structure
```sh
#!/bin/bash
# Example

echo "Hello from shell"
```

## Arguments and Exit Codes
- `$0`: script name
- `$1`, `$2`: positional arguments
- `$#`: argument count
- `$@`: all arguments
- `$?`: status of previous command

```sh
#!/bin/bash
if [ -z "$1" ]; then
  echo "Usage: $0 <name>"
  exit 1
fi

echo "Hello, $1"
exit 0
```

## Conditionals and Loops
```sh
if [ "$1" = "start" ]; then
  echo "Starting"
elif [ "$1" = "stop" ]; then
  echo "Stopping"
else
  echo "Unknown command"
fi

for i in 1 2 3; do
  echo "Run $i"
done
```

## File Tests
```sh
file="$1"
if [ -f "$file" ] && [ -r "$file" ]; then
  echo "Readable file"
else
  echo "Invalid file"
fi
```

## Best Practices
- Always quote variables unless intentional splitting is required.
- Log both output and errors for scheduled jobs.
- Prefer small reusable functions in larger scripts.
- Fail fast when required resources are missing.

## Interview Insights
- Explain how exit codes drive automation reliability.
- Show how you validate file state before SQL*Loader or SQLPlus calls.
- Mention idempotent scripts for repeatable operations.

## Related Notes
- Operational templates: [Production Tasks Simple](../11%20Automation/01_Production_Tasks_Simple.md)
- Interview checklist: [Shell Scripting Checklist](../12%20Interview/01_Shell_Scripting_Checklist.md)
- PL/SQL integration context: [PL/SQL README](../../plsql/README.md)
