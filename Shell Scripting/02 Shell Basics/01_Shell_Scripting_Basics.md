# Shell Scripting Basics for Database Work

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Shebang** = `#!/bin/bash` (tells OS to use bash interpreter)
- **Always quote variables:** `"$var"` (prevents word splitting and glob expansion)
- **Exit codes:** 0 (success), non-zero (failure). Check with `$?`
- **Arguments:** `$0` (script name), `$1`, `$2`... (positional args), `$#` (count), `$@` (all args)
- **Control flow:** `if/elif/else`, `case`, `for`, `while`, `until`
- **File tests:** `-f` (regular file), `-d` (directory), `-r` (readable), `-w` (writable), `-x` (executable), `-s` (not empty)
- **Always validate inputs early** and return non-zero exit code on failure
- **Log everything:** Redirect output to files with `>`, `>>`, `2>&1` (stderr too)
- **Fail fast:** Check critical resources before proceeding with main logic

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Shell Scripting for Database Work?](#1-why-shell-scripting-for-database-work)
2. [What is a Shell Script?](#2-what-is-a-shell-script)
3. [Script Structure and Shebang](#3-script-structure-and-shebang)
4. [Making Scripts Executable](#4-making-scripts-executable)
5. [Variables and Arguments](#5-variables-and-arguments)
6. [Quoting: Single vs Double Quotes](#6-quoting-single-vs-double-quotes)
7. [Exit Codes](#7-exit-codes)
8. [Conditionals: if/elif/else](#8-conditionals-ifelif-else)
9. [Case Statements](#9-case-statements)
10. [Loops: for, while, until](#10-loops-for-while-until)
11. [File Testing](#11-file-testing)
12. [Input Validation](#12-input-validation)
13. [Logging and Redirection](#13-logging-and-redirection)
14. [Best Practices](#14-best-practices)
15. [Common Mistakes](#15-common-mistakes)
16. [Interview Q&A](#16-interview-qa)
17. [Revision Summary](#17-revision-summary)

---

## 1. Why Shell Scripting for Database Work?

### The Problem: Repetitive Manual Tasks

**Scenario:** Every morning, you need to:
1. Export employee data to CSV
2. Run a SQL validation script
3. Load CSV data into staging table
4. Send email if errors found
5. Archive old backup files

**Manual approach:**
```bash
sqlplus scott/password @export.sql  # Wait
# ... check output manually
SQL*Loader ... # Wait
# ... check if succeeded
# ... manually delete old files
# ... send email (if you remember)
```

Takes 30 minutes, error-prone.

### The Solution: Automated Shell Scripts

**Automated approach:**
```bash
./daily_etl.sh  # Run once
# ... all tasks execute automatically
# ... logs capture everything
# ... notifications sent on failure
```

Takes 3 seconds, repeatable, reliable.

### Real-World Benefits

- **Scheduled automation:** cron runs scripts daily/hourly (no manual work)
- **Error handling:** Detect failures immediately, stop before making things worse
- **Audit trail:** Logs show exactly what ran and when
- **Orchestration:** Shell coordinates SQL, file operations, email notifications
- **Production reliability:** Same script runs identically every time

---

**➡ Transition:** Shell is an automation language. Let's understand the basics: script structure, variables, control flow.

---

## 2. What is a Shell Script?

### Simple Definition

A **shell script** is a file containing shell commands executed in sequence. It automates tasks by combining:
- Shell commands (mkdir, cp, grep)
- Control flow (if, loops)
- SQL/database commands (sqlplus, oracle utilities)
- Variables and conditionals

### Analogy: Recipe Card

A shell script is like a recipe:
```
Recipe:
1. Preheat oven (setup)
2. Mix ingredients (variables)
3. Pour into pan (main logic)
4. IF temp > 350 THEN bake 30 min (conditionals)
5. WHILE not done, check every 5 min (loops)
6. Serve (output)
```

### Key Characteristics

- **Text-based:** Simple to write, version-control friendly
- **Interpreted:** No compilation needed
- **Sequential:** Commands execute in order
- **Flexible:** Mix shell commands with SQL, programming constructs
- **Portable:** Works on Linux, Unix, macOS (bash is standard)

---

**➡ Transition:** Scripts need a special first line to tell OS which interpreter to use.

---

## 3. Script Structure and Shebang

### The Shebang Line

**Shebang** = First line starting with `#!` tells OS which interpreter to use.

```bash
#!/bin/bash
```

**Reads as:** "Execute this file using /bin/bash"

### Complete Script Structure

```bash
#!/bin/bash
# Script: daily_export.sh
# Purpose: Export employee data daily
# Author: Your Name
# Date: 2026-07-28

# ===== FUNCTIONS =====
log_message() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# ===== MAIN LOGIC =====
log_message "Starting export..."

# ... script logic here ...

log_message "Export complete."
exit 0
```

### Comments

```bash
#!/bin/bash

# Single-line comment
echo "Hello"  # Inline comment

: <<'EOF'
Multi-line comment
Useful for documenting complex logic
EOF
```

---

**➡ Transition:** Once written, scripts need permission to execute.

---

## 4. Making Scripts Executable

### Permission Basics

```bash
# View permissions
ls -l daily_export.sh
# Result: -rw-r--r-- (not executable)

# Make executable (for owner)
chmod +x daily_export.sh
# Result: -rwxr-xr-x (executable now)

# Verify
ls -l daily_export.sh
```

### Running Scripts

```bash
# Method 1: Direct execution (requires execute permission)
./daily_export.sh

# Method 2: Explicit bash interpreter (no execute permission needed)
bash daily_export.sh

# Method 3: Using full path
/home/user/daily_export.sh
```

---

**➡ Transition:** Scripts need to receive input (arguments) and communicate success/failure (exit codes).

---

## 5. Variables and Arguments

### Variable Basics

```bash
#!/bin/bash

# Assign variable
name="John"
age=30
echo "Hello $name, age $age"

# Variable from command
today=$(date +%Y-%m-%d)
echo "Today is $today"
```

### Script Arguments

**$0, $1, $2...** = Positional arguments

```bash
#!/bin/bash

echo "Script name: $0"
echo "First arg: $1"
echo "Second arg: $2"
echo "All args: $@"
echo "Arg count: $#"
```

**Usage:**
```bash
./script.sh arg1 arg2 arg3
# Output:
# Script name: ./script.sh
# First arg: arg1
# Second arg: arg2
# All args: arg1 arg2 arg3
# Arg count: 3
```

### Special Variables

| Variable | Meaning |
| --- | --- |
| `$0` | Script name |
| `$1, $2, ...` | Arguments 1, 2, ... |
| `$#` | Number of arguments |
| `$@` | All arguments (preserves spacing) |
| `$*` | All arguments (concatenated) |
| `$?` | Exit status of last command |
| `$$` | Process ID of script |
| `$!` | Process ID of last background job |

---

**➡ Transition:** Variables need protection. Quoting is critical for reliability.

---

## 6. Quoting: Single vs Double Quotes

### Single Quotes: Literal

```bash
var="world"

echo 'Hello $var'      # Hello $var (literal)
echo 'Don'"'"'t'       # Don't (escaping required)
```

**Use single quotes when:** You want literal text, no variable expansion

### Double Quotes: Expand Variables

```bash
var="world"

echo "Hello $var"      # Hello world (var expanded)
echo "Cost: \$5"       # Cost: $5 (escape $ if needed)
```

**Use double quotes when:** You need variable expansion

### The Critical Quoting Rule

**ALWAYS quote variables unless you intentionally want word splitting:**

```bash
file="/path/to/my file.txt"

# ❌ WRONG: No quotes
rm $file  # Removes /path/to/my AND file.txt (2 files!)

# ✅ CORRECT: Quoted
rm "$file"  # Removes /path/to/my file.txt (1 file)
```

### Special Quoting Case: "$@"

```bash
# Pass all arguments preserving spacing
function process_args() {
  for arg in "$@"; do  # Quotes preserve individual args
    echo "Arg: $arg"
  done
}

process_args "hello world" "foo bar"
# Output: Arg: hello world | Arg: foo bar
```

---

**➡ Transition:** Scripts communicate success/failure through exit codes, not console output.

---

## 7. Exit Codes

### What are Exit Codes?

Exit code = Numeric status returned by command:
- **0** = Success
- **Non-zero** = Failure

```bash
#!/bin/bash

ls /tmp         # Succeeds
echo $?         # 0 (success)

ls /nonexistent # Fails
echo $?         # 2 (failure)
```

### Checking Exit Codes

```bash
#!/bin/bash

sqlplus scott/password @script.sql
status=$?

if [ $status -ne 0 ]; then
  echo "SQL failed with status $status"
  exit 1
fi

echo "SQL succeeded"
exit 0
```

### Returning Exit Codes from Scripts

```bash
#!/bin/bash

if [ -z "$1" ]; then
  echo "ERROR: Missing argument"
  exit 1  # Return failure
fi

echo "Processing $1..."
exit 0    # Return success
```

### Production Pattern: Always Check Status

```bash
#!/bin/bash
set -e  # Exit immediately on any error (safer)

sqlplus scott/password @script.sql  # If fails, script stops
backup_file
send_email  # Only runs if backup succeeded
```

---

**➡ Transition:** Exit codes flow into conditionals (if/elif/else) which drive decision logic.

---

## 8. Conditionals: if/elif/else

### Basic if/then/else

```bash
#!/bin/bash

if [ -f "/tmp/datafile.txt" ]; then
  echo "File exists"
else
  echo "File not found"
fi
```

### if/elif/else Chain

```bash
#!/bin/bash
status=$1

if [ "$status" = "start" ]; then
  echo "Starting service..."
elif [ "$status" = "stop" ]; then
  echo "Stopping service..."
elif [ "$status" = "restart" ]; then
  echo "Restarting service..."
else
  echo "Unknown status: $status"
fi
```

### Test Operators

| Operator | Meaning | Example |
| --- | --- | --- |
| `=` | String equal | `[ "$name" = "john" ]` |
| `!=` | String not equal | `[ "$name" != "john" ]` |
| `-eq` | Numeric equal | `[ $count -eq 5 ]` |
| `-ne` | Numeric not equal | `[ $count -ne 0 ]` |
| `-lt` | Numeric less than | `[ $count -lt 10 ]` |
| `-gt` | Numeric greater than | `[ $count -gt 0 ]` |
| `-z` | String empty | `[ -z "$var" ]` |
| `-n` | String not empty | `[ -n "$var" ]` |

### Combining Conditions

```bash
#!/bin/bash

if [ -f "$file" ] && [ -r "$file" ]; then
  echo "File exists and readable"
fi

if [ "$user" = "admin" ] || [ "$user" = "root" ]; then
  echo "Privileged user"
fi

if ! [ -d "$dir" ]; then
  echo "Directory not found"
fi
```

---

**➡ Transition:** Complex conditionals can be cleaner with case statements.

---

## 9. Case Statements

### Basic Case

```bash
#!/bin/bash
command=$1

case "$command" in
  start)
    echo "Starting service..."
    ;;
  stop)
    echo "Stopping service..."
    ;;
  restart)
    echo "Restarting service..."
    ;;
  *)
    echo "Unknown command: $command"
    exit 1
    ;;
esac
```

**Read as:** "Match $command against patterns until found, then execute code."

### Pattern Matching

```bash
#!/bin/bash
file=$1

case "$file" in
  *.sql)
    echo "SQL file"
    ;;
  *.sh)
    echo "Shell script"
    ;;
  *.txt|*.log)
    echo "Text or log file"
    ;;
  *)
    echo "Unknown file type"
    ;;
esac
```

### Case vs if/elif

- **Case:** Multiple exact matches (cleaner syntax)
- **if/elif:** Complex conditions, ranges

---

**➡ Transition:** Looping is critical for batch processing - repeating operations on multiple items.

---

## 10. Loops: for, while, until

### for Loop: Iterate Over List

```bash
#!/bin/bash

for name in John Alice Bob; do
  echo "Hello $name"
done

# Output:
# Hello John
# Hello Alice
# Hello Bob
```

### for Loop: Iterate Over Range

```bash
#!/bin/bash

for ((i=1; i<=5; i++)); do
  echo "Run $i"
done

# Output: Run 1, Run 2, Run 3, Run 4, Run 5
```

### while Loop: Repeat While Condition True

```bash
#!/bin/bash

count=1
while [ $count -le 5 ]; do
  echo "Count: $count"
  ((count++))
done
```

### until Loop: Repeat Until Condition True

```bash
#!/bin/bash

count=1
until [ $count -gt 5 ]; do
  echo "Count: $count"
  ((count++))
done
```

### Real-World: Loop Over Files

```bash
#!/bin/bash

for file in *.csv; do
  echo "Processing $file..."
  # validate_csv "$file"
  # load_into_db "$file"
done
```

---

**➡ Transition:** Before processing files, validate they exist and are readable.

---

## 11. File Testing

### File Test Operators

| Operator | Meaning |
| --- | --- |
| `-f` | Regular file exists |
| `-d` | Directory exists |
| `-e` | File/directory exists (any type) |
| `-r` | Readable |
| `-w` | Writable |
| `-x` | Executable |
| `-s` | Non-empty (has size > 0) |
| `-L` | Symbolic link |

### Examples

```bash
#!/bin/bash

file="$1"

# Check if regular file
if [ -f "$file" ]; then
  echo "File exists"
fi

# Check if directory
if [ -d "$file" ]; then
  echo "Directory exists"
fi

# Check if readable
if [ -r "$file" ]; then
  echo "File is readable"
fi

# Check if empty
if [ -s "$file" ]; then
  echo "File is not empty"
else
  echo "File is empty or doesn't exist"
fi
```

### Combined Test: Production Pattern

```bash
#!/bin/bash
file="$1"

# All conditions must pass
if [ -f "$file" ] && [ -r "$file" ] && [ -s "$file" ]; then
  echo "File valid, processing..."
else
  echo "File missing, unreadable, or empty"
  exit 1
fi
```

---

**➡ Transition:** File testing is part of broader input validation strategy.

---

## 12. Input Validation

### Fail Fast Pattern

```bash
#!/bin/bash

# Check script has argument
if [ -z "$1" ]; then
  echo "Usage: $0 <filename>"
  exit 1
fi

file="$1"

# Check file exists
if [ ! -f "$file" ]; then
  echo "ERROR: File not found: $file"
  exit 2
fi

# Check file readable
if [ ! -r "$file" ]; then
  echo "ERROR: File not readable: $file"
  exit 3
fi

# Check file not empty
if [ ! -s "$file" ]; then
  echo "ERROR: File is empty: $file"
  exit 4
fi

# All checks passed, proceed with main logic
echo "Validation passed, processing $file..."
```

### Production Checklist

✅ Argument count check: `[ -z "$1" ]`
✅ File existence: `[ -f "$file" ]`
✅ File readable: `[ -r "$file" ]`
✅ File not empty: `[ -s "$file" ]`
✅ Database connectivity: Test sqlplus before main logic
✅ Directory writable: `[ -w "$dir" ]` before writing

---

**➡ Transition:** Validation prevents failures, logging captures what happened when failures occur.

---

## 13. Logging and Redirection

### Standard Output and Error

```bash
echo "Message"              # Goes to stdout
echo "Error" >&2            # Goes to stderr

command > output.txt        # Redirect stdout to file
command 2> error.txt        # Redirect stderr to file
command > output.txt 2>&1   # Redirect both to file
command 2>&1 | tee log.txt  # Show AND save to file
```

### Logging Pattern

```bash
#!/bin/bash

LOG_FILE="./logs/script_$(date +%Y%m%d).log"
mkdir -p ./logs

exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo "[$(date)] Script started"
# ... script logic ...
echo "[$(date)] Script completed"
```

### Better Logging Function

```bash
#!/bin/bash

log_message() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_message "Export starting..."
# ... do work ...
log_message "Export completed with status $?"
```

---

## 14. Best Practices

### 1. Always Quote Variables

```bash
# ❌ WRONG
rm $file

# ✅ CORRECT
rm "$file"
```

---

### 2. Validate Before Using

```bash
# ❌ WRONG: Assume file exists
rm "$file"

# ✅ CORRECT: Check first
if [ -f "$file" ]; then
  rm "$file"
fi
```

---

### 3. Check Exit Status

```bash
# ❌ WRONG: Ignore failure
sqlplus scott/password @script.sql
echo "Done"

# ✅ CORRECT: Check status
sqlplus scott/password @script.sql
if [ $? -ne 0 ]; then
  echo "SQL failed"
  exit 1
fi
```

---

### 4. Use Meaningful Exit Codes

```bash
# ✅ GOOD: Different codes for different failures
if [ ! -f "$file" ]; then
  exit 1  # Missing file
fi

if [ ! -r "$file" ]; then
  exit 2  # Permission denied
fi

if [ ! -s "$file" ]; then
  exit 3  # Empty file
fi
```

---

### 5. Log Everything for Cron

```bash
#!/bin/bash

# For cron execution, redirect all output
exec > "./logs/cron_$(date +%Y%m%d_%H%M%S).log" 2>&1

log_message() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log_message "Cron job started"
# ... work ...
log_message "Cron job completed"
```

---

## 15. Common Mistakes

### Mistake 1: Unquoted Variables

```bash
# ❌ WRONG
file=/tmp/my file.txt
echo $file  # Prints: /tmp/my file.txt (but wrong interpretation)

# ✅ CORRECT
file="/tmp/my file.txt"
echo "$file"
```

---

### Mistake 2: Not Checking Exit Codes

```bash
# ❌ WRONG
sqlplus scott/password @bad_script.sql
echo "Done"  # Prints even if SQL failed!

# ✅ CORRECT
sqlplus scott/password @bad_script.sql
[ $? -eq 0 ] || { echo "SQL failed"; exit 1; }
```

---

### Mistake 3: $@ vs $*

```bash
# ❌ WRONG: Loses argument boundaries
for arg in $@; do
  # "hello world" becomes 2 arguments

# ✅ CORRECT: Preserves argument boundaries
for arg in "$@"; do
  # "hello world" stays 1 argument
```

---

## 16. Interview Q&A

### Conceptual

**Q: What is a shebang and why do we need it?**

A: Shebang (`#!/bin/bash`) tells OS which interpreter to use. Without it, OS doesn't know if file is bash, python, perl, etc.

---

**Q: Why always quote variables?**

A: Unquoted variables can split on whitespace or glob-expand, causing unexpected behavior. Quote to keep literal value intact: `"$var"`

---

### Scenario

**Q: Script should fail if input file missing or unreadable. Show validation.**

A: Check conditions early and exit non-zero:
```bash
[ -f "$file" ] || { echo "File not found"; exit 1; }
[ -r "$file" ] || { echo "Not readable"; exit 2; }
```

---

**Q: How to make script safe for cron execution?**

A: Redirect all output to log file, use absolute paths, check exit codes, avoid interactive commands.

---

## 17. Revision Summary

### 1-Minute Revision

**Shell script = Automated task executor combining commands, variables, conditionals, loops.**

1. **Shebang:** `#!/bin/bash` (first line)
2. **Variables:** `$var`, `$1`, `$#`, `$?` (special)
3. **Quoting:** Always quote: `"$var"` (preserves value)
4. **Exit codes:** 0=success, non-zero=failure, check with `$?`
5. **Conditionals:** `if/elif/else` (complex), `case` (exact matches)
6. **Loops:** `for` (list), `while` (condition), `until` (negative)
7. **File tests:** `-f` (file), `-d` (dir), `-r` (read), `-w` (write), `-s` (not empty)
8. **Validation:** Check args, files, permissions BEFORE main logic
9. **Logging:** Redirect to file with `>` (overwrite), `>>` (append), `2>&1` (stderr)
10. **Production:** Fail fast, log everything, return meaningful exit codes

### Interview Keywords

- Shebang (`#!/bin/bash`)
- Variables and arguments (`$0`, `$1`, `$@`, `$#`, `$?`)
- Quoting rules (single vs double, importance)
- Exit codes (0=success, check with `$?`)
- Control flow (`if/elif/else`, `case`, `for`, `while`, `until`)
- File tests (`-f`, `-d`, `-r`, `-w`, `-x`, `-s`)
- Input validation (fail fast pattern)
- Logging and redirection (`>`, `>>`, `2>&1`)
- Idempotent scripts (same result running multiple times)
- cron-safe practices (absolute paths, logging, exit codes)

### Critical Syntax

```bash
#!/bin/bash
# Validate input
[ -z "$1" ] && { echo "Usage: $0 <arg>"; exit 1; }

# Check file
[ -f "$file" ] && [ -r "$file" ] || { echo "Invalid file"; exit 1; }

# Control flow
if [ condition ]; then
  action1
elif [ condition ]; then
  action2
else
  action3
fi

# Loop
for item in list; do
  echo "Processing $item"
done

# Exit with status
[ $status -eq 0 ] && exit 0 || exit 1
```

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
