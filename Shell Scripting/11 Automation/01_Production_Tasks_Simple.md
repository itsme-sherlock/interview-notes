# Production Shell Tasks (Real-World Database Automation)

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Typical automation flow:** Validate inputs → Execute → Check status → Log → Report
- **Core pattern:** Check exit code (`$?`), fail on error, log everything
- **Shell orchestrates:** File operations, SQL execution, error handling
- **SQL handles:** Business logic, data transformations (shell just runs it)
- **Practical tasks:** Export to CSV, run SQL scripts, validate files, backup data
- **Always:** Validate files exist/readable before using, capture stderr to logs
- **Safe for cron:** Use absolute paths, redirect all output, return meaningful exit codes

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Automate with Shell?](#1-why-automate-with-shell)
2. [Task Anatomy: The Golden Pattern](#2-task-anatomy-the-golden-pattern)
3. [Task 1: Export Query to CSV](#3-task-1-export-query-to-csv)
4. [Task 2: Run SQL Script with Logging](#4-task-2-run-sql-script-with-logging)
5. [Task 3: Validate Input File Before Load](#5-task-3-validate-input-file-before-load)
6. [Task 4: Backup Table to File](#6-task-4-backup-table-to-file)
7. [Task 5: Conditional Logic Based on Query Result](#7-task-5-conditional-logic-based-on-query-result)
8. [Building a Complete ETL](#8-building-a-complete-etl)
9. [Best Practices](#9-best-practices)
10. [Common Mistakes](#10-common-mistakes)
11. [Interview Q&A](#11-interview-qa)
12. [Revision Summary](#12-revision-summary)

---

## 1. Why Automate with Shell?

### The Problem: Manual Database Tasks

**Scenario:** Every morning, you need to:
```
1. Export yesterday's orders
2. Validate the export (no NULL dates)
3. Load into staging table
4. Run validation queries
5. Email results
6. Archive backups
```

**Manual approach (30 minutes):**
```bash
# 8:00 - Manually run export
sqlplus scott/password @export.sql > export.txt
# Wait... check output...

# 8:10 - Run validation
sqlplus scott/password @validate.sql
# Check results...

# 8:20 - Load data
sqlldr scott/password control=load.ctl
# Check if succeeded...

# 8:45 - Send email (if you remember)
```

**Automated approach (3 seconds):**
```bash
./daily_etl.sh  # Runs completely, sends email when done
```

### Real-World Benefits

- **Scheduled:** Runs automatically at 8am (no manual work)
- **Reliable:** Exact same steps every time
- **Observable:** Logs capture everything that happened
- **Scalable:** Same script handles 100 records or 1 million
- **Responsive:** Sends notifications if failures occur
- **Auditable:** For compliance, shows exactly what ran when

---

**➡ Transition:** Successful automation follows a repeating pattern. Let's understand the structure.

---

## 2. Task Anatomy: The Golden Pattern

### Universal Production Pattern

**Every production task follows this flow:**

```
┌─────────────────┐
│  SETUP          │ - Initialize, create directories
├─────────────────┤
│  VALIDATE INPUT │ - Check prerequisites exist
├─────────────────┤
│  EXECUTE        │ - Run actual command
├─────────────────┤
│  CHECK STATUS   │ - Did it succeed? ($? -eq 0)
├─────────────────┤
│  LOG RESULT     │ - Capture what happened
├─────────────────┤
│  REPORT         │ - Send notifications if needed
└─────────────────┘
```

### Pattern Pseudocode

```bash
#!/bin/bash

# SETUP
LOG_FILE="./logs/task_$(date +%Y%m%d_%H%M%S).log"
mkdir -p ./logs

# VALIDATE
[ -f "$input_file" ] || { echo "File not found"; exit 1; }

# EXECUTE
command "$input_file" > "$output_file" 2>&1
status=$?

# CHECK
if [ $status -ne 0 ]; then
  # REPORT
  echo "Task failed with status $status" | mail -s "Alert" admin@company.com
  exit 1
fi

# LOG SUCCESS
echo "Task completed successfully" >> "$LOG_FILE"
exit 0
```

### Critical Mindset

Production automation focuses on:
- ✅ **Failing fast** (detect problems early)
- ✅ **Failing loudly** (notify when problems occur)
- ✅ **Failing safely** (don't corrupt data)

---

**➡ Transition:** Now let's explore specific production tasks, starting with CSV export.

---

## 3. Task 1: Export Query to CSV

### The Challenge

Export employee data daily to CSV for reporting.

**Requirements:**
- Run every morning at 6am
- Save with timestamped filename
- Validate export succeeded (non-empty file)
- Log the operation
- Return error if export fails

### Script: Export Query to CSV

```bash
#!/bin/bash
# Task: Export query results to CSV
# Runs: daily via cron
# Author: your_name

# ===== SETUP =====
OUTPUT_DIR="./exports"
LOG_FILE="./logs/export_$(date +%Y%m%d).log"
mkdir -p "$OUTPUT_DIR" "./logs"

timestamp=$(date +%Y%m%d_%H%M%S)
outfile="$OUTPUT_DIR/employees_$timestamp.csv"

# ===== VALIDATE =====
# (No validation needed for this export - database handles it)

# ===== EXECUTE =====
echo "[$(date)] Starting export to $outfile" >> "$LOG_FILE"

sqlplus -S scott/password@orcl <<'EOF' > "$outfile"
SET HEADING OFF
SET FEEDBACK OFF
SET PAGESIZE 0
SET COLSEP ','
SET TRIMSPOOL ON
SELECT employee_id, first_name, last_name, salary 
FROM employees 
WHERE hire_date >= TRUNC(SYSDATE) - 1;
EXIT;
EOF

status=$?

# ===== CHECK =====
if [ $status -ne 0 ]; then
  echo "[$(date)] Export FAILED with status $status" >> "$LOG_FILE"
  exit 1
fi

# Verify file non-empty
if [ ! -s "$outfile" ]; then
  echo "[$(date)] Export file empty!" >> "$LOG_FILE"
  rm "$outfile"
  exit 1
fi

# ===== LOG & REPORT =====
line_count=$(wc -l < "$outfile")
echo "[$(date)] Export SUCCESS: $line_count rows in $outfile" >> "$LOG_FILE"
echo "Export to $outfile complete ($line_count rows)"

exit 0
```

### Breakdown

**sqlplus options:**
- `-S` = Silent mode (no headers/footers)
- `SET HEADING OFF` = No column names
- `SET PAGESIZE 0` = No page breaks
- `SET COLSEP ','` = Comma-separated columns
- `SET TRIMSPOOL ON` = Remove trailing spaces

**File validation:**
- `[ $status -ne 0 ]` = Check sqlplus exit code
- `[ ! -s "$outfile" ]` = File exists and non-empty

### Cron Integration

```bash
# crontab -e

# Daily export at 6:00 AM
0 6 * * * /home/oracle/scripts/export.sh >> /home/oracle/logs/cron.log 2>&1
```

---

**➡ Transition:** Export alone isn't useful; it's one step in larger workflows. Let's execute SQL scripts within automation.

---

## 4. Task 2: Run SQL Script with Logging

### The Challenge

Execute SQL validation scripts, capture output, report failures.

**Requirements:**
- Accept SQL filename as argument
- Capture both stdout and stderr
- Log complete output for debugging
- Return clear success/failure status
- Identify which SQL statement failed (if any)

### Script: Run SQL Script with Logging

```bash
#!/bin/bash
# Task: Execute SQL script and log results
# Usage: run_sql.sh <sql_file>
# Author: your_name

# ===== SETUP =====
LOG_DIR="./logs"
mkdir -p "$LOG_DIR"

timestamp=$(date +%Y%m%d_%H%M%S)
log_file="$LOG_DIR/sql_run_$timestamp.log"

# ===== VALIDATE INPUT =====
if [ -z "$1" ]; then
  echo "Usage: $0 <sql_file>"
  exit 1
fi

sql_file="$1"

# Check SQL file exists
if [ ! -f "$sql_file" ]; then
  echo "SQL file not found: $sql_file" | tee "$log_file"
  exit 2
fi

# Check SQL file readable
if [ ! -r "$sql_file" ]; then
  echo "SQL file not readable: $sql_file" | tee "$log_file"
  exit 3
fi

# ===== EXECUTE =====
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Executing: $sql_file" >> "$log_file"
echo "========================" >> "$log_file"

# Run SQL and capture all output
sqlplus -S scott/password@orcl @"$sql_file" >> "$log_file" 2>&1
status=$?

echo "========================" >> "$log_file"

# ===== CHECK =====
if [ $status -ne 0 ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] SQL FAILED with status $status" >> "$log_file"
  echo "ERROR: SQL execution failed. See $log_file for details"
  
  # Alert DBA
  tail -n 20 "$log_file" | mail -s "SQL Error: $sql_file" dba@company.com
  
  exit $status  # Return original status
fi

# ===== LOG SUCCESS =====
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SQL SUCCEEDED" >> "$log_file"
echo "SQL execution successful. Log: $log_file"

exit 0
```

### Key Features

**Logging:**
- Redirect both stdout and stderr: `>> "$log_file" 2>&1`
- Timestamp each action: `$(date '+%Y-%m-%d %H:%M:%S')`
- Preserve complete output for debugging

**Error handling:**
- Check argument provided
- Check file exists and readable
- Capture and report failures
- Send email alert on error

---

**➡ Transition:** Execution requires setup, validation ensures data integrity. Let's focus on validation.

---

## 5. Task 3: Validate Input File Before Load

### The Challenge

Before loading CSV into database, validate data quality to prevent corrupt inserts.

**Requirements:**
- File must exist
- File must be readable
- File must not be empty
- File format must match expectations
- Return clear status for each failure

### Script: Validate CSV Before Loading

```bash
#!/bin/bash
# Task: Validate CSV file before SQL*Loader load
# Usage: validate_csv.sh <csv_file>
# Author: your_name

# ===== SETUP =====
LOG_FILE="./logs/validate_$(date +%Y%m%d).log"
mkdir -p ./logs

# ===== VALIDATE ARGUMENTS =====
if [ -z "$1" ]; then
  echo "Usage: $0 <csv_file>" | tee -a "$LOG_FILE"
  exit 1
fi

csv_file="$1"

# ===== VALIDATION CHECKS (Fail Fast) =====

# Check 1: File exists
if [ ! -f "$csv_file" ]; then
  echo "[$(date)] ERROR: File not found: $csv_file" | tee -a "$LOG_FILE"
  exit 2
fi

# Check 2: File readable
if [ ! -r "$csv_file" ]; then
  echo "[$(date)] ERROR: File not readable: $csv_file" | tee -a "$LOG_FILE"
  exit 3
fi

# Check 3: File not empty
if [ ! -s "$csv_file" ]; then
  echo "[$(date)] ERROR: File is empty: $csv_file" | tee -a "$LOG_FILE"
  exit 4
fi

# Check 4: File size reasonable (not too large)
size_bytes=$(wc -c < "$csv_file")
max_bytes=$((500 * 1024 * 1024))  # 500 MB limit
if [ "$size_bytes" -gt "$max_bytes" ]; then
  echo "[$(date)] ERROR: File too large ($size_bytes bytes): $csv_file" | tee -a "$LOG_FILE"
  exit 5
fi

# Check 5: Expected columns (sample check)
first_line=$(head -1 "$csv_file")
if ! echo "$first_line" | grep -q "^[0-9].*,.*,.*,.*$"; then
  echo "[$(date)] ERROR: Invalid format (expected 4+ comma-separated fields)" | tee -a "$LOG_FILE"
  exit 6
fi

# ===== ALL CHECKS PASSED =====
line_count=$(wc -l < "$csv_file")
echo "[$(date)] VALIDATION PASSED: $csv_file ($line_count lines, $size_bytes bytes)" | tee -a "$LOG_FILE"

exit 0
```

### Validation Pattern

```bash
# IMPORTANT: Each check validates ONE thing and exits with unique code
[ condition ] || { echo "Error message"; exit N; }
```

**Example validation chain:**

```bash
[ -f "$file" ] || { echo "File not found"; exit 1; }
[ -r "$file" ] || { echo "Not readable"; exit 2; }
[ -s "$file" ] || { echo "File empty"; exit 3; }
# More checks...

# If we get here, all checks passed
echo "All validations passed"
```

### Exit Code Convention

| Exit Code | Meaning |
| --- | --- |
| 0 | Success |
| 1 | Missing argument |
| 2 | File not found |
| 3 | File not readable |
| 4 | File empty |
| 5 | File too large |
| 6 | Invalid format |

This lets calling scripts know exactly what failed.

---

**➡ Transition:** After executing tasks, we often need to save state - backups of table data before modifications.

---

## 6. Task 4: Backup Table to File

### The Challenge

Before modifying data, create backup snapshot for recovery.

**Requirements:**
- Export table to file with timestamp
- Store in backups directory
- Verify backup succeeded (non-empty file)
- Clean old backups (keep only recent)
- Log the operation

### Script: Backup Table

```bash
#!/bin/bash
# Task: Create timestamped backup of table
# Usage: backup_table.sh <table_name> [days_to_keep]
# Author: your_name

# ===== SETUP =====
BACKUP_DIR="./backups"
LOG_FILE="./logs/backup_$(date +%Y%m%d).log"
mkdir -p "$BACKUP_DIR" "./logs"

DAYS_TO_KEEP=${2:-30}  # Default: keep 30 days

# ===== VALIDATE INPUT =====
if [ -z "$1" ]; then
  echo "Usage: $0 <table_name> [days_to_keep]" | tee -a "$LOG_FILE"
  exit 1
fi

table_name="$1"
timestamp=$(date +%Y%m%d_%H%M%S)
backup_file="$BACKUP_DIR/${table_name}_$timestamp.sql"

# ===== EXECUTE BACKUP =====
echo "[$(date)] Starting backup of table: $table_name" >> "$LOG_FILE"

sqlplus -S scott/password@orcl <<EOF > "$backup_file" 2>&1
SET LONG 20000
SET PAGESIZE 0
SET LINESIZE 1000
SET FEEDBACK OFF
SET VERIFY OFF
SET TRIMSPOOL ON

SELECT 'INSERT INTO $table_name VALUES(' || 
       LISTAGG(CASE WHEN data_type IN ('VARCHAR2', 'CHAR', 'DATE') 
                    THEN '''' || value || ''''
                    ELSE value
               END, ', ') WITHIN GROUP (ORDER BY column_id) || ');'
FROM (
  SELECT column_id, column_name, data_type, data_value as value
  FROM $table_name
);

EXIT;
EOF

status=$?

# ===== CHECK BACKUP =====
if [ $status -ne 0 ] || [ ! -s "$backup_file" ]; then
  echo "[$(date)] Backup FAILED for table: $table_name" | tee -a "$LOG_FILE"
  rm -f "$backup_file"
  exit 1
fi

# ===== CLEANUP OLD BACKUPS =====
echo "[$(date)] Cleaning backups older than $DAYS_TO_KEEP days" >> "$LOG_FILE"
find "$BACKUP_DIR" -name "${table_name}_*.sql" -mtime +$DAYS_TO_KEEP -delete

# ===== LOG SUCCESS =====
backup_size=$(wc -c < "$backup_file")
echo "[$(date)] Backup SUCCESS: $backup_file ($backup_size bytes)" >> "$LOG_FILE"

exit 0
```

### Key Concepts

**Backup strategy:**
- Separate backup per day (timestamped filename)
- Automatic cleanup (keep only 30 days)
- Verify backup non-empty before keeping

**Restore from backup:**
```bash
sqlplus scott/password@orcl @./backups/employees_20260728_120000.sql
```

---

**➡ Transition:** Sometimes you need to branch logic based on query results. This requires capturing output and parsing.

---

## 7. Task 5: Conditional Logic Based on Query Result

### The Challenge

Make automation decisions based on database query results.

**Example:** 
```
IF order_count > 100
  THEN run full processing
  ELSE send warning to DBA
```

### Script: Conditional on Query Result

```bash
#!/bin/bash
# Task: Check data condition and branch logic
# Author: your_name

# ===== SETUP =====
LOG_FILE="./logs/conditional_$(date +%Y%m%d).log"
mkdir -p ./logs

# ===== QUERY DATABASE FOR VALUE =====
echo "[$(date)] Checking order count..." >> "$LOG_FILE"

count=$(sqlplus -S scott/password@orcl <<EOF
SET HEADING OFF
SET FEEDBACK OFF
SET PAGESIZE 0
SELECT COUNT(*) FROM orders WHERE created_date >= TRUNC(SYSDATE);
EXIT;
EOF
)

echo "[$(date)] Order count result: $count" >> "$LOG_FILE"

# ===== CONDITIONAL LOGIC =====
if [ "$count" -eq 0 ]; then
  echo "[$(date)] No orders found - skipping processing" >> "$LOG_FILE"
  echo "No new orders for today"
  exit 0
fi

if [ "$count" -lt 100 ]; then
  echo "[$(date)] Low order count ($count) - alert DBA" >> "$LOG_FILE"
  echo "Warning: Only $count orders today (expected > 100)" | \
    mail -s "Low Order Count Alert" dba@company.com
  exit 1
fi

# ===== NORMAL PROCESSING =====
echo "[$(date)] Order count OK ($count) - proceeding with full processing" >> "$LOG_FILE"

# ... full ETL logic here ...

exit 0
```

### Output Parsing Pattern

```bash
# Query returns single value
value=$(sqlplus -S user/password <<EOF
SET HEADING OFF FEEDBACK OFF PAGESIZE 0
SELECT COUNT(*) FROM table WHERE condition;
EXIT;
EOF
)

# Trim whitespace (sqlplus adds spaces)
value=$(echo "$value" | tr -d ' ')

# Use in conditional
if [ "$value" -gt 100 ]; then
  echo "High volume: $value"
fi
```

---

**➡ Transition:** Individual tasks are useful, but production requires orchestrating multiple tasks into complete workflows.

---

## 8. Building a Complete ETL

### Real-World Example: Daily Order Processing

```bash
#!/bin/bash
# Daily ETL: Orders from staging to production
# Runs: 7am daily via cron
# Author: your_name

set -e  # Exit on any error
set -u  # Exit on undefined variable

# ===== SETUP =====
WORK_DIR="/home/oracle/etl/orders"
LOG_DIR="$WORK_DIR/logs"
BACKUP_DIR="$WORK_DIR/backups"
STAGE_DB="scott"
PROD_DB="prod"

LOG_FILE="$LOG_DIR/etl_$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$LOG_DIR" "$BACKUP_DIR"

log_msg() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# ===== TASK 1: VALIDATE STAGE DATA =====
log_msg "TASK 1: Validating staged data..."
validation_file="$WORK_DIR/orders_stage_$(date +%Y%m%d).csv"

if [ ! -f "$validation_file" ] || [ ! -s "$validation_file" ]; then
  log_msg "ERROR: Validation file missing or empty"
  exit 1
fi

log_msg "✓ Stage data valid"

# ===== TASK 2: BACKUP PRODUCTION ORDERS =====
log_msg "TASK 2: Backing up production table..."
sqlplus -S "$PROD_DB" <<EOF >> "$LOG_FILE" 2>&1
CREATE TABLE orders_backup_$(date +%Y%m%d) AS SELECT * FROM orders;
EOF
log_msg "✓ Backup created"

# ===== TASK 3: LOAD TO PRODUCTION =====
log_msg "TASK 3: Loading staged data..."
sqlplus -S "$PROD_DB" <<EOF >> "$LOG_FILE" 2>&1
INSERT INTO orders SELECT * FROM orders_stage;
COMMIT;
EOF
log_msg "✓ Data loaded"

# ===== TASK 4: VALIDATE LOAD =====
log_msg "TASK 4: Validating loaded data..."
error_count=$(sqlplus -S "$PROD_DB" <<EOF
SET HEADING OFF FEEDBACK OFF PAGESIZE 0
SELECT COUNT(*) FROM orders WHERE amount IS NULL;
EXIT;
EOF
)

error_count=$(echo "$error_count" | tr -d ' ')

if [ "$error_count" -gt 0 ]; then
  log_msg "ERROR: Found $error_count NULL amounts"
  exit 1
fi

log_msg "✓ Data validation passed"

# ===== TASK 5: GENERATE REPORT =====
log_msg "TASK 5: Generating daily report..."
sqlplus -S "$PROD_DB" <<EOF > "$WORK_DIR/daily_report_$(date +%Y%m%d).txt"
COLUMN order_id FORMAT 999999
COLUMN amount FORMAT 99999.99
SELECT order_id, customer_id, amount FROM orders 
WHERE created_date >= TRUNC(SYSDATE)
ORDER BY order_id;
EOF
log_msg "✓ Report generated"

# ===== SUCCESS =====
log_msg "ETL COMPLETE - All tasks succeeded"
echo "Daily ETL completed successfully" | \
  mail -s "ETL Status: Success" dba@company.com

exit 0
```

---

## 9. Best Practices

### 1. Always Use Absolute Paths

```bash
# ❌ WRONG: Relative path fails if cron runs from different directory
cd ./work && sqlplus ... @script.sql

# ✅ CORRECT: Absolute path always works
sqlplus ... @/home/oracle/scripts/script.sql
```

---

### 2. Capture Complete Output

```bash
# ❌ WRONG: stderr lost
sqlplus scott/password @script.sql > output.log

# ✅ CORRECT: Both stdout and stderr saved
sqlplus scott/password @script.sql > output.log 2>&1
```

---

### 3. Fail on First Error

```bash
# ✅ GOOD: Stop immediately on any error
set -e

sqlplus scott/password @step1.sql  # If fails, script stops
sqlplus scott/password @step2.sql  # Only runs if step1 succeeds
```

---

## 10. Common Mistakes

### Mistake 1: No Exit Code Checking

```bash
# ❌ WRONG: Proceeds even if SQL fails
sqlplus scott/password @bad_script.sql
echo "Completed"  # Prints even if SQL had errors!

# ✅ CORRECT: Check exit code
sqlplus scott/password @bad_script.sql || { echo "Failed"; exit 1; }
echo "Completed"  # Only prints if SQL succeeded
```

---

### Mistake 2: Unquoted File Paths

```bash
# ❌ WRONG: Fails with spaces in path
file=/tmp/my export.csv
sqlplus ... @$file

# ✅ CORRECT: Always quote
file="/tmp/my export.csv"
sqlplus ... @"$file"
```

---

### Mistake 3: No Logging

```bash
# ❌ WRONG: Output goes to screen, nothing saved
sqlplus scott/password @script.sql

# ✅ CORRECT: Save output for debugging
sqlplus scott/password @script.sql >> "$log_file" 2>&1
```

---

## 11. Interview Q&A

### Scenario

**Q: Write a script that exports data, validates it, and loads it. Handle failures gracefully.**

A: 
```bash
#!/bin/bash
set -e  # Fail on error

# Export
echo "Exporting..."
sqlplus scott/password @export.sql > export.csv 2>&1

# Validate
if [ ! -s export.csv ]; then
  echo "Export failed"
  exit 1
fi

# Load
echo "Loading..."
sqlplus scott/password @load.sql export.csv >> load.log 2>&1

echo "Success"
exit 0
```

---

**Q: How to make script safe for cron?**

A: Use absolute paths, redirect all output to log, check exit codes, use `set -e` to fail fast.

---

## 12. Revision Summary

### Production Automation Pattern

```
Validate Input → Execute → Check Status → Log Result → Report
```

### Key Commands

- **Export:** `sqlplus -S ... SET ... SELECT ...`
- **Load:** `sqlldr user/password control=file.ctl`
- **Check status:** `[ $? -ne 0 ]` or `set -e`
- **Log:** `>> logfile 2>&1` (both stdout and stderr)
- **Notify:** `mail`, `echo ... | mail`

### Best Practices Checklist

✅ Validate inputs early (fail fast)
✅ Use absolute file paths
✅ Redirect all output to logs
✅ Check exit codes of commands
✅ Return meaningful exit codes
✅ Log timestamps and status
✅ Send alerts on failures
✅ Test script manually before scheduling
✅ Include script version/author in comments
✅ Clean up old backups automatically

## Task 1 Export Query to CSV

```sh
#!/bin/bash
outfile="employees_$(date +%Y%m%d).csv"

sqlplus -S scott/password@orcl <<EOF > "$outfile"
SET HEADING OFF
SET FEEDBACK OFF
SET PAGESIZE 0
SET COLSEP ','
SELECT employee_id, first_name, salary FROM employees;
EXIT;
EOF

[ -s "$outfile" ] && echo "Exported: $outfile" || { echo "Export failed"; exit 1; }
```

## Task 2 Run SQL Script with Logging

```sh
#!/bin/bash
sql_file="$1"
log_file="run_$(date +%Y%m%d_%H%M%S).log"

sqlplus -S scott/password@orcl @"$sql_file" > "$log_file" 2>&1
status=$?

if [ $status -ne 0 ]; then
  echo "SQL execution failed. See $log_file"
  exit $status
fi

echo "SQL execution successful. Log: $log_file"
```

## Task 3 Validate Input File Before Load

```sh
#!/bin/bash
file="$1"

[ -z "$file" ] && { echo "Usage: $0 <csv-file>"; exit 1; }
[ ! -f "$file" ] && { echo "File not found"; exit 2; }
[ ! -r "$file" ] && { echo "File not readable"; exit 3; }
[ ! -s "$file" ] && { echo "File is empty"; exit 4; }

echo "Validation passed for $file"
```

## Task 4 Backup Table Output

```sh
#!/bin/bash
table="$1"
outdir="./backups"
mkdir -p "$outdir"
outfile="$outdir/${table}_$(date +%Y%m%d_%H%M%S).txt"

sqlplus -S scott/password@orcl <<EOF > "$outfile"
SET PAGESIZE 1000
SELECT * FROM $table;
EXIT;
EOF

[ -s "$outfile" ] && echo "Backup created: $outfile" || { echo "Backup failed"; exit 1; }
```

## Interview Insights

- Explain how each script protects against bad input and silent failure.
- Mention logging and exit codes as core production requirements.
- Show that SQLPlus integration is orchestration, not business logic replacement.

## Related Notes

- Foundations: [Shell Scripting Basics](../02%20Shell%20Basics/01_Shell_Scripting_Basics.md)
- Interview prep: [Shell Scripting Checklist](../12%20Interview/01_Shell_Scripting_Checklist.md)
