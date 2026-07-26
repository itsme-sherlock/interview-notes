# Production Shell Tasks (Simple and Interview-Ready)

<!-- QUICK_SHEET_START -->

## Quick Sheet
- Common DB automation tasks: export data, run SQL, validate files, backup outputs.
- Essential flow: validate -> execute -> verify -> log.
- Always capture exit status and write timestamped logs.
- Use shell for orchestration, SQL/PLSQL for database logic.

<!-- QUICK_SHEET_END -->

## Table of Contents
- [Main Content](#main-content)
- [Task 1 Export Query to CSV](#task-1-export-query-to-csv)
- [Task 2 Run SQL Script with Logging](#task-2-run-sql-script-with-logging)
- [Task 3 Validate Input File Before Load](#task-3-validate-input-file-before-load)
- [Task 4 Backup Table Output](#task-4-backup-table-output)
- [Interview Insights](#interview-insights)
- [Related Notes](#related-notes)

## Main Content

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
