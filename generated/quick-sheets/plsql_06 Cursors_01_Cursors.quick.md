# Quick Sheet: plsql\06 Cursors\01_Cursors.md

<!-- QUICK_SHEET_START -->

## Quick Sheet
- Source: plsql\06 Cursors\01_Cursors.md
- Blocks captured: 1


## Quick Sheet
- Cursor = pointer to query result rows.
- Implicit cursor: automatic for DML and single-row `SELECT INTO`.
- Explicit cursor: manual control for multi-row processing.
- Lifecycle: `OPEN -> FETCH -> EXIT WHEN %NOTFOUND -> CLOSE`.
- Prefer cursor FOR loop unless low-level control is required.
- Use `FOR UPDATE` + `WHERE CURRENT OF` for safe row-level updates.


<!-- QUICK_SHEET_END -->

## Table of Contents
- [Main Content](#main-content)

## Main Content

