# Master Quick Sheet - Interview Revision

Generated: 2026-07-28 09:49:16

---

## plsql\01 Basics\01_PLSQL_Basics_and_Data_Types.md


## Quick Sheet

- PL/SQL block: DECLARE (optional), BEGIN-END (mandatory), EXCEPTION (optional).
- SQL is declarative; PL/SQL adds procedural logic (variables, loops, exceptions).
- Scalar types: NUMBER, VARCHAR2, DATE, BOOLEAN.
- Composite types: RECORD and collections.
- Anchoring: use `%TYPE` and `%ROWTYPE` for schema-safe declarations.


---

## plsql\04 Control Statements\01_Operators_Control_Statements_and_Loops.md


## Quick Sheet

- Arithmetic in PL/SQL: `+`, `-`, `*`, `/`.
- Comparison: `=`, `!=`, `>`, `<`, `>=`, `<=`.
- Logical: `AND`, `OR`, `NOT`.
- Branching: `IF`, `ELSIF`, `CASE`.
- Loops: `LOOP ... EXIT WHEN`, `WHILE`, `FOR`, `FOR ... REVERSE`.


---

## plsql\06 Cursors\01_Cursors.md


## Quick Sheet

- Cursor = pointer to query result rows.
- Implicit cursor: automatic for DML and single-row `SELECT INTO`.
- Explicit cursor: manual control for multi-row processing.
- Lifecycle: `OPEN -> FETCH -> EXIT WHEN cursor%NOTFOUND -> CLOSE`.
- Cursor FOR loop is the clean default for explicit cursor work.
- `FOR UPDATE` and `WHERE CURRENT OF` support safe row-level updates.


---

## Shell Scripting\02 Shell Basics\01_Shell_Scripting_Basics.md


## Quick Sheet

- Start scripts with `#!/bin/bash`.
- Validate inputs early and return non-zero on failures.
- Quote variables: `"$var"`.
- Core control flow: `if`, `case`, `for`, `while`, `until`.
- File checks: `-f`, `-d`, `-r`, `-w`, `-x`, `-s`.


---

## Shell Scripting\11 Automation\01_Production_Tasks_Simple.md


## Quick Sheet

- Common DB automation tasks: export data, run SQL, validate files, backup outputs.
- Essential flow: validate -> execute -> verify -> log.
- Always capture exit status and write timestamped logs.
- Use shell for orchestration, SQL/PLSQL for database logic.


---

## Shell Scripting\12 Interview\01_Shell_Scripting_Checklist.md


## Quick Sheet

- Know script structure, permissions, args, and exit codes.
- Be ready with file validation, logging, and SQLPlus integration patterns.
- Practice one mini automation flow end-to-end.
- Explain reliability choices: quoting, checks, non-zero exits.


---

## sql\01 Fundamentals\01_Pseudo_Columns_Guide.md


## Quick Sheet

- Pseudo columns appear like regular columns but are not stored; they provide metadata about rows or the session.
- `ROWNUM`: sequential row counter from query result (assigned before ORDER BY).
- `ROWID`: physical row identifier in the table; can change with TRUNCATE/ALTER.
- `SYSDATE` and `SYSTIMESTAMP`: current date/time; SYSTIMESTAMP includes fractional seconds and timezone.
- `USER` and `UID`: current database user name and session identifier.
- `LEVEL`: hierarchy level in CONNECT BY queries (hierarchical data).


---

## sql\04 Functions\01_Single_Row_Functions.md


## Quick Sheet

- Character functions: `UPPER`, `LOWER`, `INITCAP`, `SUBSTR`, `INSTR`, `REPLACE`, `TRANSLATE`, `TRIM`, `LPAD`, `RPAD`.
- Numeric functions: `ROUND`, `TRUNC`, `MOD`, `CEIL`, `FLOOR`, `ABS`, `SIGN`, `POWER`.
- Date functions: `SYSDATE`, `CURRENT_DATE`, `ADD_MONTHS`, `MONTHS_BETWEEN`, `NEXT_DAY`, `LAST_DAY`, `EXTRACT`.
- General functions: `GREATEST`, `LEAST`, `CONCAT`, `CASE`, `DECODE`.
- Null and conversion: `NVL`, `NVL2`, `COALESCE`, `NULLIF`, `TO_CHAR`, `TO_DATE`, `TO_NUMBER`, `CAST`.


---

## sql\07 Views\01_Views_and_Materialized_Views.md


## Quick Sheet

- View: virtual table defined by a query; no data storage of its own.
- Use views for abstraction, security, and query simplification.
- Updatable views are usually simple single-table views.
- `WITH CHECK OPTION` enforces the view predicate on DML.
- Materialized views store query results physically and need a refresh strategy.


---

## sql\08 Indexes\01_Indexes_and_Execution_Plans.md


## Quick Sheet

- Index speeds up reads by storing key value + ROWID.
- B-tree is the default and suits high-cardinality columns.
- Bitmap is better for low-cardinality analytics, not high-concurrency OLTP.
- Composite indexes depend on the leading-column rule.
- Execution plan and optimizer choice determine whether an index is used.


---

## sql\09 Performance\01_Window_Functions_and_Analytics.md


## Quick Sheet

- Window functions compute across related rows while keeping row detail.
- `OVER` defines the partition and ordering scope.
- Key ranking functions: `ROW_NUMBER`, `RANK`, `DENSE_RANK`.
- `LAG` and `LEAD` compare previous and next rows.
- Running totals are built with `SUM(...) OVER (...)`.


---

## sql\09 Performance\02_Table_Partitioning.md


## Quick Sheet

- Partitioning splits one logical table into multiple physical segments.
- Common methods: range, list, hash, composite.
- Partition pruning scans only relevant partitions when the partition key is in the predicate.
- Partitioning complements indexes; it does not replace them.
- Good partition-key choice is critical for balance and performance.


