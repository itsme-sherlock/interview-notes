# Operators, Control Statements and Loops

<!-- QUICK_SHEET_START -->

## Quick Sheet
- Arithmetic: `+`, `-`, `*`, `/`.
- Comparison: `=`, `!=`, `>`, `<`, `>=`, `<=`.
- Logical: `AND`, `OR`, `NOT`.
- Branching: `IF`, `ELSIF`, `CASE`.
- Loops: `LOOP`, `WHILE`, `FOR`, `REVERSE`.

<!-- QUICK_SHEET_END -->

## Table of Contents
- [Arithmetic Operators](#arithmetic-operators)
- [Comparison Operators](#comparison-operators)
- [Logical Operators](#logical-operators)
- [assignment Operators](#assignment-operators)
- [Conditional Statements](#conditional-statements)
- [Loops](#loops)

# module 4 Operators
# Operators, Control Statements and Loops

<!-- QUICK_SHEET_START -->

## Quick Sheet
- Arithmetic in PL/SQL: `+`, `-`, `*`, `/`.
- Comparison: `=`, `!=`, `>`, `<`, `>=`, `<=`.
- Logical: `AND`, `OR`, `NOT`.
- Branching: `IF`, `ELSIF`, `CASE`.
- Loops: `LOOP ... EXIT WHEN`, `WHILE`, `FOR`, `FOR ... REVERSE`.

<!-- QUICK_SHEET_END -->

## Table of Contents
- [Main Content](#main-content)
- [Operators](#operators)
- [Conditional Statements](#conditional-statements)
- [Loops](#loops)
- [Best Practices](#best-practices)
- [Interview Insights](#interview-insights)
- [Related Notes](#related-notes)

## Main Content

## Operators
### Arithmetic Operators
| Operator | Meaning | Example |
|---|---|---|
| `+` | Addition | `v_total := v_a + v_b;` |
| `-` | Subtraction | `v_diff := v_a - v_b;` |
| `*` | Multiplication | `v_mul := v_a * v_b;` |
| `/` | Division | `v_ratio := v_a / v_b;` |

### Comparison Operators
| Operator | Meaning |
|---|---|
| `=` | Equal |
| `!=` or `<>` | Not equal |
| `>` | Greater than |
| `<` | Less than |
| `>=` | Greater than or equal |
| `<=` | Less than or equal |

### Logical Operators
- `AND`: both conditions must be true.
- `OR`: at least one condition must be true.
- `NOT`: reverses boolean result.

## Conditional Statements
### IF
```sql
IF v_salary > 10000 THEN
  DBMS_OUTPUT.PUT_LINE('High salary');
END IF;
```

### IF / ELSIF / ELSE
```sql
IF v_score >= 90 THEN
  v_grade := 'A';
ELSIF v_score >= 75 THEN
  v_grade := 'B';
ELSE
  v_grade := 'C';
END IF;
```

### CASE
```sql
CASE v_grade
  WHEN 'A' THEN DBMS_OUTPUT.PUT_LINE('Excellent');
  WHEN 'B' THEN DBMS_OUTPUT.PUT_LINE('Good');
  ELSE DBMS_OUTPUT.PUT_LINE('Needs improvement');
END CASE;
```

## Loops
### Basic LOOP
```sql
DECLARE
  v_counter NUMBER := 1;
BEGIN
  LOOP
    DBMS_OUTPUT.PUT_LINE(v_counter);
    v_counter := v_counter + 1;
    EXIT WHEN v_counter > 5;
  END LOOP;
END;
```

### WHILE LOOP
```sql
DECLARE
  v_counter NUMBER := 1;
BEGIN
  WHILE v_counter <= 5 LOOP
    DBMS_OUTPUT.PUT_LINE(v_counter);
    v_counter := v_counter + 1;
  END LOOP;
END;
```

### FOR LOOP and REVERSE
```sql
BEGIN
  FOR i IN 1..3 LOOP
    DBMS_OUTPUT.PUT_LINE('Forward: ' || i);
  END LOOP;

  FOR i IN REVERSE 1..3 LOOP
    DBMS_OUTPUT.PUT_LINE('Reverse: ' || i);
  END LOOP;
END;
```

## Best Practices
- Prefer `CASE` when there are many equality branches.
- Keep loop bodies small and readable.
- Avoid infinite loops unless deliberately controlled.
- Validate divisor before division to avoid runtime errors.

## Interview Insights
- `EXIT WHEN` is a common and clean loop termination pattern.
- `CASE` can improve readability over deeply nested `IF` blocks.
- In SQL, `%` is not the modulus operator in Oracle SQL syntax; use `MOD(a, b)`.

## Related Notes
- Cursor loops and row processing: [Cursors](../06%20Cursors/01_Cursors.md)
- Foundations and datatypes: [PL/SQL Basics and Data Types](../01%20Basics/01_PLSQL_Basics_and_Data_Types.md)
