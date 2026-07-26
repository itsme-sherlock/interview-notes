# PL/SQL Basics and Data Types

<!-- QUICK_SHEET_START -->

## Quick Sheet
- PL/SQL block: DECLARE (optional), BEGIN-END (mandatory), EXCEPTION (optional).
- SQL is declarative; PL/SQL adds procedural logic (variables, loops, exceptions).
- Scalar types: NUMBER, VARCHAR2, DATE, BOOLEAN.
- Composite types: RECORD and collections.
- Anchoring: use `%TYPE` and `%ROWTYPE` for schema-safe declarations.

<!-- QUICK_SHEET_END -->

## Table of Contents
- [Main Content](#main-content)
- [What Is PL/SQL](#what-is-plsql)
- [SQL vs PL/SQL](#sql-vs-plsql)
- [Block Structure](#block-structure)
- [Variables and Scope](#variables-and-scope)
- [Data Types](#data-types)
- [Anchored Declarations](#anchored-declarations)
- [Interview Insights](#interview-insights)
- [Related Notes](#related-notes)

## Main Content

## What Is PL/SQL
PL/SQL is Oracle's procedural extension to SQL. SQL answers "what data", while PL/SQL adds logic to control "how to process it".

## SQL vs PL/SQL
| Aspect | SQL | PL/SQL |
|---|---|---|
| Execution | One statement at a time | Block of statements |
| Variables | Not native | Supported |
| Control flow | Limited | IF, CASE, LOOP, WHILE, FOR |
| Error handling | Limited | EXCEPTION block |

## Block Structure
```sql
DECLARE
  -- optional declarations
BEGIN
  -- mandatory executable section
EXCEPTION
  -- optional error handlers
END;
```

### Hello World
```sql
BEGIN
  DBMS_OUTPUT.PUT_LINE('Hello, PL/SQL');
END;
```

## Variables and Scope
- Local variables exist inside the current block.
- Global variables are usually exposed through packages.

```sql
DECLARE
  v_name VARCHAR2(50);
BEGIN
  SELECT first_name
  INTO v_name
  FROM hr.employees
  WHERE employee_id = 100;

  DBMS_OUTPUT.PUT_LINE(v_name);
END;
```

## Data Types
### Scalar
- NUMBER
- VARCHAR2
- CHAR
- DATE
- BOOLEAN

### Composite
- RECORD
- Collections (nested table, varray, associative array)

## Anchored Declarations
Using anchored declarations reduces maintenance risk when table definitions change.

```sql
DECLARE
  v_salary hr.employees.salary%TYPE;
  v_emp    hr.employees%ROWTYPE;
BEGIN
  SELECT salary INTO v_salary
  FROM hr.employees
  WHERE employee_id = 100;

  SELECT * INTO v_emp
  FROM hr.employees
  WHERE employee_id = 100;
END;
```

## Interview Insights
- Prefer `%TYPE` and `%ROWTYPE` over hardcoded datatypes.
- `SELECT INTO` can raise `NO_DATA_FOUND` and `TOO_MANY_ROWS`.
- Use SQL for set operations first; PL/SQL for orchestration and control.

## Related Notes
- Cursor processing: [Cursors](../06%20Cursors/01_Cursors.md)
- Control flow and loops: [Operators, Control Statements and Loops](../04%20Control%20Statements/01_Operators_Control_Statements_and_Loops.md)
- SQL fundamentals reference: [SQL README](../../sql/README.md)
