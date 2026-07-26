# Master Quick Sheet - Interview Revision

<!-- QUICK_SHEET_START -->

## Quick Sheet
- Generated from all source markdown quick sheets.
- Use this file for fast full-repo revision.
- Generated at: 2026-07-26 21:11:43

<!-- QUICK_SHEET_END -->

## Table of Contents
- [Main Content](#main-content)

## Main Content

---

## REPO_AUDIT_REPORT.md


## Quick Sheet
- Scope audited: all original SQL, PL/SQL, shell scripting, generated quick-sheet, and script files.
- Main issues found: duplication in PL/SQL notes, corrupted partitioning file, inconsistent naming/foldering.
- Main actions: merged duplicates, normalized structure, standardized markdown format, regenerated quick sheets.
- Status: repository now organized for SQL, PL/SQL, and Shell Scripting only.


---

## plsql\README.md


## Quick Sheet
- Focus: PL/SQL blocks, control flow, cursors, and interview-ready coding patterns.
- Study order: Basics -> Control Statements -> Cursors -> Practice Scripts -> Cheat Sheets.
- High-yield interview topics: %TYPE/%ROWTYPE, exception handling, cursor for loop, FOR UPDATE.
- Practice rule: prefer set-based SQL first, then PL/SQL only when row-wise logic is required.


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
- Lifecycle: `OPEN -> FETCH -> EXIT WHEN %NOTFOUND -> CLOSE`.
- Prefer cursor FOR loop unless low-level control is required.
- Use `FOR UPDATE` + `WHERE CURRENT OF` for safe row-level updates.


---

## plsql\Cheat Sheets\01_PLSQL_Quick_Revision.md


## Quick Sheet
- Block sections: DECLARE (optional), BEGIN-END (mandatory), EXCEPTION (optional).
- Anchoring: `%TYPE` for column type, `%ROWTYPE` for full row structure.
- Control flow: IF/ELSIF/CASE and LOOP/WHILE/FOR.
- Cursors: implicit for simple SQL, explicit for multi-row control.
- Interview rule: use SQL first; PL/SQL for procedural orchestration.


---

## plsql\Cheat Sheets\02_PLSQL_Cursors_Quick_Revision.md


## Quick Sheet
- Cursor: pointer to query result rows.
- Lifecycle: OPEN -> FETCH -> EXIT WHEN %NOTFOUND -> CLOSE.
- Cursor FOR loop auto-manages lifecycle.
- Locking: `FOR UPDATE` + `WHERE CURRENT OF` for safe row updates.
- REF CURSOR: dynamic query result handoff, often with `SYS_REFCURSOR`.


---

## Shell Scripting\README.md


## Quick Sheet
- Focus: shell scripting for database workflows (SQL/PLSQL automation).
- Study order: Shell basics -> automation tasks -> interview checklist.
- High-yield interview topics: input validation, exit codes, logging, idempotent scripts.
- Production rule: validate first, log everything, fail fast on errors.


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

## Shell Scripting\Cheat Sheets\01_Shell_Scripting_Quick_Revision.md


## Quick Sheet
- Script header: `#!/bin/bash`.
- Validate args and fail fast with non-zero exit code.
- Use `if`, `case`, loops, and file-test operators (`-f`, `-r`, `-w`, `-x`, `-s`).
- Redirect logs using `>`, `>>`, and `2>&1`.
- For DB automation: run SQLPlus, capture status, log outcome.


---

## sql\README.md


## Quick Sheet
- Focus: Oracle SQL for interviews and practical database work.
- Study order: Fundamentals -> Functions -> Views -> Indexes -> Performance -> Interview revision.
- High-yield interview topics: indexing strategy, view updatability, window functions, partition pruning.
- Daily revision: one topic note + one cheat sheet + two query drills.


---

## sql\04 Functions\01_Single_Row_Functions.md


## Quick Sheet
- Character: `UPPER`, `LOWER`, `INITCAP`, `SUBSTR`, `INSTR`, `REPLACE`, `TRIM`.
- Numeric: `ROUND`, `TRUNC`, `MOD`, `CEIL`, `FLOOR`, `ABS`, `POWER`.
- Date: `SYSDATE`, `CURRENT_DATE`, `ADD_MONTHS`, `MONTHS_BETWEEN`, `LAST_DAY`.
- Null handling: `NVL`, `NVL2`, `COALESCE`, `NULLIF`.
- Conversion: `TO_CHAR`, `TO_DATE`, `TO_NUMBER`, `CAST`.


---

## sql\07 Views\01_Views_and_Materialized_Views.md


## Quick Sheet
- View: virtual table storing query text.
- Materialized view: physical data snapshot with refresh strategy.
- Simple view is usually updatable; complex view often needs `INSTEAD OF` trigger.
- `WITH CHECK OPTION`: enforce view filter for DML through the view.
- `WITH READ ONLY`: block DML through the view.


---

## sql\08 Indexes\01_Indexes_and_Execution_Plans.md


## Quick Sheet
- Index stores key values with ROWID references.
- B-tree: default, best for high-cardinality columns.
- Bitmap: best for low-cardinality analytic workloads.
- Composite index depends on leading-column usage.
- Optimizer may still choose full table scan based on cost.


---

## sql\09 Performance\01_Window_Functions_and_Analytics.md


## Quick Sheet
- Window function computes across related rows while preserving row detail.
- `OVER` defines partition and ordering scope.
- Ranking: `ROW_NUMBER`, `RANK`, `DENSE_RANK`.
- Relative row access: `LAG`, `LEAD`.
- Running totals: `SUM(...) OVER (...)`.


---

## sql\09 Performance\02_Table_Partitioning.md


## Quick Sheet
- Partitioning splits one large table into smaller physical segments.
- It improves manageability and query performance via partition pruning.
- Common strategies: range, list, hash, composite.
- Good partition key choice is critical for balanced data and query targeting.
- Partitioning complements indexes; it does not replace them.


---

## sql\Cheat Sheets\01_SQL_Quick_Revision.md


## Quick Sheet
- Single-row functions: UPPER, LOWER, SUBSTR, INSTR, NVL, COALESCE, TO_CHAR, TO_DATE.
- Views: virtual, no data storage; materialized views: physical storage + refresh.
- Indexes: B-tree for high cardinality, bitmap for low cardinality analytics.
- Window functions: ROW_NUMBER, RANK, DENSE_RANK, LAG, LEAD, SUM OVER.
- Partitioning: range/list/hash/composite; partition pruning is key optimization.


