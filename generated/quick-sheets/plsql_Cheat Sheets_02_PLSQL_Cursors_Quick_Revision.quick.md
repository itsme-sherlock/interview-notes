# Quick Sheet: plsql\Cheat Sheets\02_PLSQL_Cursors_Quick_Revision.md

<!-- QUICK_SHEET_START -->

## Quick Sheet
- Source: plsql\Cheat Sheets\02_PLSQL_Cursors_Quick_Revision.md
- Blocks captured: 1


## Quick Sheet
- Cursor: pointer to query result rows.
- Lifecycle: OPEN -> FETCH -> EXIT WHEN %NOTFOUND -> CLOSE.
- Cursor FOR loop auto-manages lifecycle.
- Locking: `FOR UPDATE` + `WHERE CURRENT OF` for safe row updates.
- REF CURSOR: dynamic query result handoff, often with `SYS_REFCURSOR`.


<!-- QUICK_SHEET_END -->

## Table of Contents
- [Main Content](#main-content)

## Main Content

