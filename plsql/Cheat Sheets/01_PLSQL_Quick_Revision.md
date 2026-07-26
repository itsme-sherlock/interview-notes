# PL/SQL Quick Revision

<!-- QUICK_SHEET_START -->

## Quick Sheet
- Block sections: DECLARE (optional), BEGIN-END (mandatory), EXCEPTION (optional).
- Anchoring: `%TYPE` for column type, `%ROWTYPE` for full row structure.
- Control flow: IF/ELSIF/CASE and LOOP/WHILE/FOR.
- Cursors: implicit for simple SQL, explicit for multi-row control.
- Interview rule: use SQL first; PL/SQL for procedural orchestration.

<!-- QUICK_SHEET_END -->

## Table of Contents
- [Core Syntax](#core-syntax)
- [High-Frequency Interview Questions](#high-frequency-interview-questions)
- [Common Pitfalls](#common-pitfalls)
- [Memory Cues](#memory-cues)

## Core Syntax
```sql
DECLARE
  v_salary employees.salary%TYPE;
BEGIN
  SELECT salary INTO v_salary
  FROM employees
  WHERE employee_id = 100;

  DBMS_OUTPUT.PUT_LINE(v_salary);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('No employee found');
END;
```

## High-Frequency Interview Questions
- Difference between SQL and PL/SQL execution model.
- `%TYPE` vs `%ROWTYPE`.
- When to choose cursor FOR loop vs manual OPEN/FETCH/CLOSE.
- Why `NO_DATA_FOUND` and `TOO_MANY_ROWS` occur in `SELECT INTO`.

## Common Pitfalls
- Declaring mismatched datatypes instead of anchored types.
- Using row-by-row logic where set-based SQL is enough.
- Missing exception handling for fragile assumptions.

## Memory Cues
- "DECLARE if needed, BEGIN always, EXCEPTION when risky."
- "Anchor types to schema to reduce breakage."
