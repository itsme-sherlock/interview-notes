# PL/SQL Cursors Quick Revision

<!-- QUICK_SHEET_START -->

## Quick Sheet
- Cursor: pointer to query result rows.
- Lifecycle: OPEN -> FETCH -> EXIT WHEN %NOTFOUND -> CLOSE.
- Cursor FOR loop auto-manages lifecycle.
- Locking: `FOR UPDATE` + `WHERE CURRENT OF` for safe row updates.
- REF CURSOR: dynamic query result handoff, often with `SYS_REFCURSOR`.

<!-- QUICK_SHEET_END -->

## Table of Contents
- [Core Syntax](#core-syntax)
- [High-Frequency Interview Questions](#high-frequency-interview-questions)
- [Common Pitfalls](#common-pitfalls)
- [Memory Cues](#memory-cues)

## Core Syntax
```sql
DECLARE
  CURSOR c_emp IS
    SELECT employee_id, salary
    FROM employees
    WHERE department_id = 10
    FOR UPDATE;
BEGIN
  FOR r IN c_emp LOOP
    UPDATE employees
    SET salary = r.salary * 1.05
    WHERE CURRENT OF c_emp;
  END LOOP;
END;
```

## High-Frequency Interview Questions
- Implicit cursor vs explicit cursor.
- Why `%ROWCOUNT` and `%NOTFOUND` matter.
- When to use `FOR UPDATE`.
- REF CURSOR use cases in procedures.

## Common Pitfalls
- Forgetting to close manually managed cursors.
- Updating rows without considering concurrency.
- Overusing cursors where SQL set logic is cleaner.

## Memory Cues
- "FOR loop cursor = safest default."
- "FOR UPDATE protects current row intent."
