# Shell Scripting Interview Checklist and Practice Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Fundamentals:** Shebang (`#!/bin/bash`), variables (`$var`, `$1`, `$?`), quoting, exit codes
- **Control flow:** if/elif/else, case, for/while/until loops
- **File operations:** File tests (`-f`, `-d`, `-r`, `-s`), validation before use
- **Database:** sqlplus integration, capturing output, checking exit codes
- **Production:** Logging (stdout + stderr), timestamps, fail-fast pattern, meaningful exit codes
- **Interview prep:** Master 3-4 real scripts end-to-end, explain reliability choices
- **Idempotency:** Same script run multiple times = same safe result

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Module Learning Checklist](#1-module-learning-checklist)
2. [Core Concepts to Master](#2-core-concepts-to-master)
3. [Hands-On Practice Scripts](#3-hands-on-practice-scripts)
4. [High-Value Interview Questions](#4-high-value-interview-questions)
5. [Interview Scenario Walkthrough](#5-interview-scenario-walkthrough)
6. [Common Mistakes to Avoid](#6-common-mistakes-to-avoid)
7. [Practice Challenge](#7-practice-challenge)
8. [Related Resources](#8-related-resources)

---

## 1. Module Learning Checklist

### Fundamentals

- [ ] Understand shebang (`#!/bin/bash`) and script execution permissions
- [ ] Master variable assignment and usage (`$var`, quoting rules)
- [ ] Know positional parameters (`$0`, `$1`, `$#`, `$@` vs `$*`)
- [ ] Understand exit codes (0=success, non-zero=failure)
- [ ] Can check previous command's exit code (`$?`)
- [ ] Understand quoting: single (literal) vs double (expansion)

### Control Flow

- [ ] Master if/elif/else with test operators (`=`, `-eq`, `-lt`, `-f`, `-d`, etc.)
- [ ] Understand case statements for pattern matching
- [ ] Know for loops (list-based and C-style range)
- [ ] Understand while and until loops
- [ ] Can combine conditions with AND (`&&`) and OR (`||`)
- [ ] Understand logical NOT (`!`) and negation in tests

### File Operations

- [ ] Know file test operators: `-f`, `-d`, `-r`, `-w`, `-x`, `-s`, `-e`
- [ ] Understand importance of validating files BEFORE using them
- [ ] Can read file line-by-line with while loop + read
- [ ] Know directory creation (`mkdir -p`) and permissions
- [ ] Understand file listing with `ls` and globbing patterns

### Database Integration

- [ ] Can execute sqlplus from shell script
- [ ] Know sqlplus command-line options (`-S` for silent, `@` for file)
- [ ] Can redirect sqlplus output to variables/files
- [ ] Know how to pass arguments to SQL via shell
- [ ] Can parse sqlplus output for values/conditions
- [ ] Understand sqlplus exit codes and error detection

### Logging and Redirection

- [ ] Can redirect stdout to file (`>`) and append (`>>`)
- [ ] Can redirect stderr to stdout (`2>&1`)
- [ ] Understand combining stdout/stderr (`>> logfile 2>&1`)
- [ ] Can use `tee` to show and save output simultaneously
- [ ] Know how to log with timestamps
- [ ] Understand log rotation and cleanup of old files

### Production Practices

- [ ] Implement fail-fast pattern (stop on first error)
- [ ] Always validate inputs before using them
- [ ] Capture both stdout and stderr in logs
- [ ] Use `set -e` to exit on error
- [ ] Use `set -u` to error on undefined variables
- [ ] Return meaningful exit codes (0=success, specific non-zero for failures)
- [ ] Make scripts idempotent (safe to run multiple times)
- [ ] Test cron safety (absolute paths, full output capture, no interactive prompts)

### Advanced (Optional)

- [ ] Understand defensive options (`set -e`, `set -u`, `set -o pipefail`)
- [ ] Function-based script organization for large scripts
- [ ] Error handling with trap commands
- [ ] Parallel execution of independent tasks

---

**➡ Transition:** Each concept builds on the previous. Let's understand the core mastery areas.

---

## 2. Core Concepts to Master

### Core 1: Script Structure and Shebang

**Minimal script:**
```bash
#!/bin/bash
echo "Hello"
exit 0
```

**Interview question:** "Why is `#!/bin/bash` on the first line?"
**Answer:** Tells OS which interpreter to use. Without it, OS can't execute script.

---

### Core 2: Variables and Arguments

**Master pattern:**
```bash
#!/bin/bash

# Check argument provided
if [ -z "$1" ]; then
  echo "Usage: $0 <name>"
  exit 1
fi

# Use argument
name="$1"
echo "Hello $name"
exit 0
```

**Interview question:** "What's the difference between `$*` and `$@`?"
**Answer:** `$*` concatenates all args into one string. `$@` preserves individual args as separate items. Use `$@` for correct behavior with args containing spaces.

---

### Core 3: Exit Codes and Failure Handling

**Master pattern:**
```bash
#!/bin/bash

# Check if command succeeded
sqlplus scott/password @script.sql
if [ $? -ne 0 ]; then
  echo "SQL failed"
  exit 1
fi

# Safer: use 'set -e' (exit immediately on any error)
set -e
sqlplus scott/password @script.sql  # If fails, script stops
echo "SQL succeeded"
exit 0
```

**Interview question:** "Why check exit codes?"
**Answer:** Exit codes tell you if command succeeded. Non-zero means failure. Ignoring them leads to silent failures (script continues as if command succeeded).

---

### Core 4: File Validation Before Use

**Master pattern:**
```bash
#!/bin/bash

# Validate file before using
file="$1"

[ -z "$file" ] && { echo "Missing file argument"; exit 1; }
[ ! -f "$file" ] && { echo "File not found: $file"; exit 2; }
[ ! -r "$file" ] && { echo "File not readable: $file"; exit 3; }
[ ! -s "$file" ] && { echo "File empty: $file"; exit 4; }

# All checks passed, proceed
echo "File OK, processing..."
```

**Interview question:** "Why validate files before using them?"
**Answer:** Prevents silent failures. If file missing/unreadable/empty, script should fail immediately with clear error message, not crash later or corrupt data.

---

### Core 5: Logging for Production

**Master pattern:**
```bash
#!/bin/bash

LOG_FILE="./logs/script_$(date +%Y%m%d_%H%M%S).log"
mkdir -p ./logs

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting..." >> "$LOG_FILE"

# Redirect all output to log
sqlplus scott/password @script.sql >> "$LOG_FILE" 2>&1
status=$?

if [ $status -ne 0 ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] FAILED with status $status" >> "$LOG_FILE"
  exit $status
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS" >> "$LOG_FILE"
exit 0
```

**Interview question:** "How to make a script safe for cron?"
**Answer:** Redirect all output to log file, use absolute paths, check exit codes, avoid interactive prompts, use timestamps for debugging.

---

## 3. Hands-On Practice Scripts

### Script 1: Simple Validator (✅ START HERE)

**Goal:** Validate CSV file and report status.

```bash
#!/bin/bash

# Check argument
if [ -z "$1" ]; then
  echo "Usage: $0 <csv_file>"
  exit 1
fi

csv_file="$1"

# Validate file exists and readable
if [ ! -f "$csv_file" ]; then
  echo "File not found: $csv_file"
  exit 2
fi

if [ ! -r "$csv_file" ]; then
  echo "File not readable: $csv_file"
  exit 3
fi

# Check not empty
if [ ! -s "$csv_file" ]; then
  echo "File is empty: $csv_file"
  exit 4
fi

# Count lines and report
line_count=$(wc -l < "$csv_file")
echo "Validation passed: $csv_file has $line_count lines"
exit 0
```

**Test it:**
```bash
chmod +x validate.sh
./validate.sh test.csv
echo $?  # Should be 0 (success)
```

---

### Script 2: SQL Executor with Logging (✅ MEDIUM)

**Goal:** Execute SQL file and capture output.

```bash
#!/bin/bash

LOG_DIR="./logs"
mkdir -p "$LOG_DIR"

if [ -z "$1" ]; then
  echo "Usage: $0 <sql_file>"
  exit 1
fi

sql_file="$1"
log_file="$LOG_DIR/run_$(date +%Y%m%d_%H%M%S).log"

# Validate SQL file
[ -f "$sql_file" ] || { echo "File not found: $sql_file"; exit 2; }
[ -r "$sql_file" ] || { echo "File not readable: $sql_file"; exit 3; }

# Execute and log
echo "[$(date)] Executing: $sql_file" > "$log_file"
sqlplus scott/password @"$sql_file" >> "$log_file" 2>&1
status=$?

if [ $status -ne 0 ]; then
  echo "[$(date)] FAILED with status $status" >> "$log_file"
  echo "SQL failed. See $log_file"
  exit $status
fi

echo "[$(date)] SUCCESS" >> "$log_file"
echo "SQL executed successfully. Log: $log_file"
exit 0
```

---

### Script 3: Complete ETL (✅ ADVANCED)

**Goal:** Export, validate, transform, load (4-step workflow).

```bash
#!/bin/bash
set -e  # Exit on any error

# Setup
WORK_DIR="./work"
mkdir -p "$WORK_DIR"
export_file="$WORK_DIR/export_$(date +%Y%m%d).csv"
log_file="$WORK_DIR/etl_$(date +%Y%m%d).log"

# Step 1: Export
echo "[$(date)] Step 1: Exporting..." | tee -a "$log_file"
sqlplus -S scott/password <<'EOF' > "$export_file"
SET HEADING OFF FEEDBACK OFF PAGESIZE 0
SELECT employee_id, first_name, salary FROM employees;
EXIT;
EOF

# Step 2: Validate export
if [ ! -s "$export_file" ]; then
  echo "Export file empty or missing" | tee -a "$log_file"
  exit 1
fi

# Step 3: Transform (example: add date column)
temp_file="$WORK_DIR/transformed_$(date +%Y%m%d).csv"
while IFS=',' read id name salary; do
  echo "$id,$name,$salary,$(date +%Y-%m-%d)" >> "$temp_file"
done < "$export_file"

# Step 4: Load to staging table
echo "[$(date)] Step 4: Loading..." | tee -a "$log_file"
sqlplus -S scott/password <<EOF >> "$log_file" 2>&1
INSERT INTO employee_staging SELECT * FROM external_table '$temp_file';
COMMIT;
EXIT;
EOF

echo "[$(date)] ETL Complete" | tee -a "$log_file"
exit 0
```

---

## 4. High-Value Interview Questions

### Q1: Basic Concepts

**Q: Explain exit codes and why they're important.**

A: Exit codes (0 for success, non-zero for failure) let scripts detect if commands succeeded. Without checking, a script continues even when critical commands fail, leading to data corruption or silent failures.

---

**Q: Why should variables be quoted?**

A: Unquoted variables can split on whitespace or expand glob patterns. For example, unquoted `$file` with value `/tmp/my file.txt` becomes two arguments. Always quote: `"$file"`.

---

### Q2: Practical Scenarios

**Q: Write a script that validates CSV before loading. Handle 3 failure cases clearly.**

A:
```bash
#!/bin/bash
file="$1"

[ -z "$file" ] && { echo "ERROR: No file provided"; exit 1; }
[ ! -f "$file" ] && { echo "ERROR: File not found"; exit 2; }
[ ! -s "$file" ] && { echo "ERROR: File empty"; exit 3; }

echo "OK: File validated"
exit 0
```

---

**Q: How to make a script safe to run from cron?**

A: Use absolute paths (cron runs from arbitrary directory), redirect all output to log file with `>> logfile 2>&1`, check exit codes of commands, use timestamps in logs for debugging, avoid interactive prompts.

---

### Q3: Advanced Concepts

**Q: Explain the difference between these two approaches:**

```bash
# Approach 1
sqlplus scott/password @script.sql

# Approach 2
set -e
sqlplus scott/password @script.sql
```

A: Approach 1 doesn't check if sqlplus failed. Approach 2 uses `set -e` to exit immediately if any command fails. Approach 2 is safer for production because if sqlplus has an error, the script stops and doesn't continue to next commands.

---

## 5. Interview Scenario Walkthrough

### Scenario: "Write a daily backup script"

**Requirements:**
- Daily backup of employees table
- Backup should include timestamp
- Log success/failure
- Clean up backups older than 30 days
- Send email alert if backup fails

**Solution:**

```bash
#!/bin/bash
set -e

# Setup
BACKUP_DIR="/home/oracle/backups"
LOG_FILE="/home/oracle/logs/backup_$(date +%Y%m%d).log"
mkdir -p "$BACKUP_DIR" "$(dirname "$LOG_FILE")"

log_msg() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"; }

# Backup
log_msg "Starting backup..."
backup_file="$BACKUP_DIR/employees_$(date +%Y%m%d_%H%M%S).dmp"

expdp scott/password@orcl TABLES=employees DUMPFILE="$backup_file" >> "$LOG_FILE" 2>&1 || {
  log_msg "BACKUP FAILED"
  mail -s "Backup Failed" dba@company.com < "$LOG_FILE"
  exit 1
}

log_msg "Backup succeeded: $backup_file"

# Cleanup old backups
log_msg "Cleaning backups older than 30 days"
find "$BACKUP_DIR" -name "employees_*.dmp" -mtime +30 -delete

log_msg "Backup complete"
exit 0
```

**Interview explanation points:**
- ✅ `set -e` makes script exit on any error
- ✅ Timestamps in log for tracking
- ✅ Email alert on failure
- ✅ Automatic cleanup of old backups
- ✅ Meaningful exit codes
- ✅ Logging with function for consistency

---

## 6. Common Mistakes to Avoid

### Mistake 1: Not Quoting Variables

❌ BAD:
```bash
file=/tmp/my file.txt
rm $file  # Tries to remove /tmp/my AND file.txt!
```

✅ GOOD:
```bash
file="/tmp/my file.txt"
rm "$file"  # Removes single file correctly
```

---

### Mistake 2: Ignoring Exit Codes

❌ BAD:
```bash
sqlplus scott/password @bad_script.sql
echo "SQL complete"  # Prints even if SQL failed!
```

✅ GOOD:
```bash
sqlplus scott/password @bad_script.sql || { echo "SQL failed"; exit 1; }
echo "SQL complete"  # Only prints if SQL succeeded
```

---

### Mistake 3: Relative Paths in Cron

❌ BAD:
```bash
#!/bin/bash
sqlplus scott/password @./scripts/load.sql  # Cron runs from random dir!
```

✅ GOOD:
```bash
#!/bin/bash
sqlplus scott/password @/home/oracle/scripts/load.sql  # Absolute path
```

---

## 7. Practice Challenge

### Challenge: Mini ETL Script

**Write a script that:**

1. Accepts a table name as argument
2. Validates the table exists (query database)
3. Exports table to CSV with timestamp
4. Validates CSV not empty
5. Logs all steps with timestamps
6. Returns exit code 0 on success, non-zero on failure

**Requirements:**
- Use absolute paths
- Validate all inputs
- Check all exit codes
- Log to file
- Include error messages
- Clean comments

**Test cases:**
```bash
./mini_etl.sh              # Error: no argument
./mini_etl.sh nonexistent  # Error: table doesn't exist
./mini_etl.sh employees    # Success: exports to CSV
```

**Hints:**
- Use sqlplus to check if table exists: `SELECT COUNT(*) FROM user_tables WHERE table_name='EMPLOYEES'`
- Use `SET HEADING OFF` to avoid header rows
- Capture exit codes with `$?`

---

## 8. Related Resources

- [Shell Scripting Basics](../02%20Shell%20Basics/01_Shell_Scripting_Basics.md) - Foundation concepts
- [Production Tasks Simple](../11%20Automation/01_Production_Tasks_Simple.md) - Real-world examples
- Quick Revision: [Shell Scripting Quick Revision](../Cheat%20Sheets/01_Shell_Scripting_Quick_Revision.md)
- SQL Integration: [PL/SQL README](../../plsql/README.md)

## Module Checklist

- [x] Shebang and execution permissions.
- [x] Variables and positional parameters.
- [x] `if`/`elif`/`else`, `case`, loops.
- [x] File test operators.
- [x] SQLPlus command execution from shell.
- [x] Logging with `>`, `>>`, and `2>&1`.
- [ ] Function-based script organization for larger scripts.
- [ ] Defensive options (`set -e`, `set -u`) with safe usage.

## Interview Practice Tasks

1. Build a script that validates a CSV and logs result.
2. Execute a SQL file and return clear success/failure status.
3. Export query output daily with timestamped filenames.
4. Compare pre and post data snapshots with row-count summary.

## High-Value Questions

- What is the difference between `$@` and `$*`?
- Why should shell scripts check `$?` or exit codes?
- How do you prevent failures from bad filenames with spaces?
- How do you make a script safe for cron execution?

## Related Notes

- Script fundamentals: [Shell Scripting Basics](../02%20Shell%20Basics/01_Shell_Scripting_Basics.md)
- Automation patterns: [Production Tasks Simple](../11%20Automation/01_Production_Tasks_Simple.md)
- Quick revision: [Shell Scripting Quick Revision](../Cheat%20Sheets/01_Shell_Scripting_Quick_Revision.md)
