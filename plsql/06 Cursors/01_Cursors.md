# PL/SQL Cursors

<!-- QUICK_SHEET_START -->

## Quick Sheet
- Cursor = pointer to query result rows.
- Implicit cursor: automatic for DML and single-row `SELECT INTO`.
- Explicit cursor: manual control for multi-row processing.
- Lifecycle: `OPEN -> FETCH -> EXIT WHEN cursor%NOTFOUND -> CLOSE`.
- Cursor FOR loop is the clean default for explicit cursor work.
- `FOR UPDATE` and `WHERE CURRENT OF` support safe row-level updates.

<!-- QUICK_SHEET_END -->

## Table of Contents
- [Types of Cursors](#types-of-cursors)
- [Implicit Cursor Example](#implicit-cursor-example)
- [Attributes of Implicit Cursor](#attributes-of-implicit-cursor)
- [Explicit Cursor Example](#explicit-cursor-example)
- [OPEN, FETCH, CLOSE](#open-fetch-close)
- [Difference between implicit and explicit cursor](#difference-between-implicit-and-explicit-cursor)
- [Cursor For Loop](#cursor-for-loop)
- [Parameterized cursor](#parameterized-cursor)
- [Cursor FOR UPDATE](#cursor-for-update)
- [WHERE CURRENT OF](#where-current-of)
- [Errors in Cursors](#errors-in-cursors)
- [Ref Cursor](#ref-cursor)
- [Ref cursor as an output parameter](#ref-cursor-as-an-output-parameter)

# Cursor in PLSQL
# PL/SQL Cursors

<!-- QUICK_SHEET_START -->

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
- [Cursor Types](#cursor-types)
- [Implicit Cursor Attributes](#implicit-cursor-attributes)
- [Explicit Cursor Lifecycle](#explicit-cursor-lifecycle)
- [Cursor FOR Loop](#cursor-for-loop)
- [Parameterized Cursor](#parameterized-cursor)
- [FOR UPDATE and WHERE CURRENT OF](#for-update-and-where-current-of)
- [REF CURSOR](#ref-cursor)
- [Common Errors](#common-errors)
- [Interview Insights](#interview-insights)
- [Related Notes](#related-notes)

## Main Content

## Cursor Types
1. Implicit cursor: Oracle creates it automatically.
2. Explicit cursor: you declare and control it.

## Implicit Cursor Attributes
| Attribute | Meaning |
|---|---|
| `SQL%FOUND` | Last SQL affected at least one row |
| `SQL%NOTFOUND` | Last SQL affected zero rows |
| `SQL%ROWCOUNT` | Number of rows affected |
| `SQL%ISOPEN` | Always `FALSE` for implicit cursor |

## Explicit Cursor Lifecycle
```sql
DECLARE
  CURSOR c_emp IS
    SELECT employee_id, first_name, salary
    FROM employees;

  v_id     employees.employee_id%TYPE;
  v_name   employees.first_name%TYPE;
  v_salary employees.salary%TYPE;
BEGIN
  OPEN c_emp;
  LOOP
    FETCH c_emp INTO v_id, v_name, v_salary;
    EXIT WHEN c_emp%NOTFOUND;

    DBMS_OUTPUT.PUT_LINE(v_id || ' - ' || v_name || ' - ' || v_salary);
  END LOOP;
  CLOSE c_emp;
END;
```

## Cursor FOR Loop
```sql
DECLARE
  CURSOR c_emp IS
    SELECT employee_id, salary
    FROM employees;
BEGIN
  FOR rec IN c_emp LOOP
    DBMS_OUTPUT.PUT_LINE(rec.employee_id || ': ' || rec.salary);
  END LOOP;
END;
```
Oracle automatically opens, fetches, and closes the cursor.

## Parameterized Cursor
```sql
DECLARE
  CURSOR c_emp(p_dept_id NUMBER) IS
    SELECT employee_id, first_name, salary
    FROM employees
    WHERE department_id = p_dept_id;
BEGIN
  FOR rec IN c_emp(10) LOOP
    DBMS_OUTPUT.PUT_LINE(rec.first_name || ': ' || rec.salary);
  END LOOP;
END;
```

## FOR UPDATE and WHERE CURRENT OF
```sql
DECLARE
  CURSOR c_emp IS
    SELECT employee_id, salary
    FROM employees
    WHERE department_id = 10
    FOR UPDATE;
BEGIN
  FOR rec IN c_emp LOOP
    UPDATE employees
    SET salary = rec.salary * 1.10
    WHERE CURRENT OF c_emp;
  END LOOP;

  COMMIT;
END;
```

## REF CURSOR
Use `SYS_REFCURSOR` when query output must be returned dynamically from procedures.

```sql
CREATE OR REPLACE PROCEDURE get_emp_by_dept (
  p_department_id IN employees.department_id%TYPE,
  p_result        OUT SYS_REFCURSOR
) AS
BEGIN
  OPEN p_result FOR
    SELECT employee_id, first_name, salary
    FROM employees
    WHERE department_id = p_department_id;
END;
```

## Common Errors
- `NO_DATA_FOUND`: single-row `SELECT INTO` returns no row.
- `TOO_MANY_ROWS`: single-row `SELECT INTO` returns multiple rows.
- Cursor already open: opening an already-open explicit cursor.

## Interview Insights
- Prefer set-based SQL for bulk data operations.
- Cursor FOR loop is the clean default for explicit cursor scenarios.
- Use row locking only when business logic requires safe in-place updates.

## Related Notes
- Control flow foundation: [Operators, Control Statements and Loops](../04%20Control%20Statements/01_Operators_Control_Statements_and_Loops.md)
- PL/SQL basics: [PL/SQL Basics and Data Types](../01%20Basics/01_PLSQL_Basics_and_Data_Types.md)
- SQL performance context: [Indexes and Execution Plans](../../sql/08%20Indexes/01_Indexes_and_Execution_Plans.md)
