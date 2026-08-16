# PL/SQL Procedures and Functions Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Procedure** = A named PL/SQL program that performs an action.
- **Function** = A named PL/SQL program that returns one value.
- **Parameters:** `IN` receives data, `OUT` returns data, and `IN OUT` does both.
- **Local subprogram:** A procedure or function declared inside another block.
- **Overloading:** Same name with different parameter signatures.
- **Validation:** Check inputs at the boundary and raise clear application errors.
- **Design rule:** Keep transaction ownership with the caller unless the routine is a complete business transaction.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Procedures and Functions?](#1-why-do-we-need-procedures-and-functions)
2. [What Are Procedures and Functions?](#2-what-are-procedures-and-functions)
3. [Procedure Parameters](#3-procedure-parameters)
4. [Functions and Return Values](#4-functions-and-return-values)
5. [Nested Subprograms and Overloading](#5-nested-subprograms-and-overloading)
6. [Comparison Matrix](#6-comparison-matrix)
7. [Best Practices](#7-best-practices)
8. [Common Mistakes](#8-common-mistakes)
9. [Interview Q&A](#9-interview-qa)
10. [Revision Summary](#10-revision-summary)

---

## 1. Why Do We Need Procedures and Functions?

### The Problem: Repeated Business Logic

Copying the same validation and DML into several anonymous blocks causes inconsistent rules, difficult maintenance, and weak testing.

```sql
-- The same salary rule gets copied into multiple scripts.
IF p_salary < 10000 THEN
  RAISE_APPLICATION_ERROR(-20001, 'Salary is too low');
END IF;
```

**Problems with the current approach:**
- Business rules are duplicated.
- Callers cannot rely on one consistent contract.
- Changes require editing many scripts.

### The Solution: Named Program Units

Store the logic once in a procedure or function and call it from SQL clients, jobs, applications, or other PL/SQL code.

### Real-World Scenarios

- **Employee onboarding:** A procedure validates and inserts a new employee.
- **Reporting:** A function calculates a reusable business metric.
- **Batch jobs:** A local procedure isolates one processing step.

---

**Transition:** The first design choice is whether the routine performs an action or calculates a value.

---

## 2. What Are Procedures and Functions?

### Simple Definition

A **procedure** performs work; a **function** performs work and returns a value.

A procedure is like submitting a form. A function is like asking a calculator for an answer.

### Key Characteristics

- Standalone routines are stored database objects.
- A procedure can return values through `OUT` or `IN OUT` parameters.
- A function must return a value matching its declared return type.
- Both can contain SQL, control flow, cursors, and exception handling.

### Basic Syntax

```sql
CREATE OR REPLACE PROCEDURE apply_raise (
  p_employee_id IN employees.employee_id%TYPE,
  p_percent     IN NUMBER
) AS
BEGIN
  IF p_percent <= 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Percent must be positive');
  END IF;

  UPDATE employees
  SET salary = salary * (1 + p_percent / 100)
  WHERE employee_id = p_employee_id;
END apply_raise;
/

CREATE OR REPLACE FUNCTION annual_salary (
  p_monthly_salary IN NUMBER
) RETURN NUMBER AS
BEGIN
  RETURN p_monthly_salary * 12;
END annual_salary;
/
```

---

## 3. Procedure Parameters

### Parameter Modes

| Mode | Caller sends | Routine changes | Caller receives |
| --- | --- | --- | --- |
| `IN` | Yes | No | Original value |
| `OUT` | No | Yes | Returned value |
| `IN OUT` | Yes | Yes | Changed value |

```sql
CREATE OR REPLACE PROCEDURE employee_name (
  p_employee_id IN employees.employee_id%TYPE,
  p_name        OUT VARCHAR2
) AS
BEGIN
  SELECT first_name || ' ' || last_name
  INTO p_name
  FROM employees
  WHERE employee_id = p_employee_id;
END;
/
```

Use `%TYPE` for parameters tied to table columns. Validate required values before DML and use `RAISE_APPLICATION_ERROR` for caller-facing errors.

---

## 4. Functions and Return Values

A function must return on every successful execution path.

```sql
CREATE OR REPLACE FUNCTION bonus_amount (
  p_salary IN NUMBER,
  p_rate   IN NUMBER
) RETURN NUMBER AS
BEGIN
  IF p_salary IS NULL OR p_rate IS NULL THEN
    RAISE_APPLICATION_ERROR(-20002, 'Salary and rate are required');
  END IF;

  RETURN p_salary * p_rate;
END bonus_amount;
/

SELECT bonus_amount(50000, 0.10) AS bonus FROM dual;
```

Functions used from SQL should avoid unintended DML, commits, or session state changes. A function can be called from PL/SQL even when it is not suitable for SQL.

---

## 5. Nested Subprograms and Overloading

A nested routine is visible only inside its enclosing block or program unit.

```sql
DECLARE
  FUNCTION valid_salary(p_salary NUMBER) RETURN BOOLEAN IS
  BEGIN
    RETURN p_salary BETWEEN 10000 AND 500000;
  END;
BEGIN
  IF valid_salary(75000) THEN
    DBMS_OUTPUT.PUT_LINE('Accepted');
  END IF;
END;
/
```

Overloading lets one name support different parameter types or counts.

```sql
CREATE OR REPLACE PACKAGE text_tools AS
  FUNCTION label(p_value NUMBER) RETURN VARCHAR2;
  FUNCTION label(p_value DATE)   RETURN VARCHAR2;
END text_tools;
/
```

The compiler selects the matching signature. Avoid overloads that are ambiguous because of implicit conversions.

---

## 6. Comparison Matrix

| Aspect | Procedure | Function | Nested subprogram |
| --- | --- | --- | --- |
| Main purpose | Perform an action | Return a value | Support one enclosing unit |
| Required return | No | Yes | Depends on type |
| SQL usage | Not directly in a query | Often callable from SQL | Usually not visible to SQL |
| Reuse scope | Database-wide or package-wide | Database-wide or package-wide | Local |
| Best use | Commands and workflows | Calculations and lookups | Private helper logic |

---

## 7. Best Practices

### 1. Keep the public contract small

**Avoid:** Exposing internal helper parameters and implementation details.

**Prefer:** Expose only business inputs and outputs in the procedure specification.

**Why:** Smaller contracts are easier to change safely.

### 2. Use anchored parameter types

```sql
p_employee_id IN employees.employee_id%TYPE
```

This keeps the routine aligned with the table definition.

### 3. Validate at the boundary

Reject null, invalid, and out-of-range inputs before changing data.

### 4. Let callers control transactions

Do not commit inside a reusable routine unless it explicitly owns a complete transaction.

### 5. Raise useful application errors

Use a documented `-20000` to `-20999` error code and a message that identifies the failed rule.

---

## 8. Common Mistakes

### Mistake 1: Missing `RETURN`

A function path that reaches `END` without returning raises an error. Return from every successful path.

### Mistake 2: Confusing `=` and `:=`

Use `:=` for assignment and `=` for comparison or SQL predicates.

### Mistake 3: Committing inside every procedure

This prevents callers from treating several calls as one atomic unit. Keep transaction ownership explicit.

### Mistake 4: Using `OUT` when `IN OUT` is required

An `OUT` parameter should be treated as output only; use `IN OUT` when the original value matters.

### Mistake 5: Ambiguous overloads

Overloads that differ only through implicit conversion can fail at compile time or surprise callers. Prefer clearly distinct signatures.

---

## 9. Interview Q&A

**Q: What is the difference between a procedure and a function?**

A: A procedure performs an operation and may return values through parameters. A function must return one value and can often be used in SQL.

**Q: Can a procedure return a value?**

A: Yes. It can use `OUT` or `IN OUT` parameters, but it does not use a `RETURN datatype` declaration like a function.

**Q: When should a function not be called from SQL?**

A: Avoid SQL calls when the function performs transaction control, changes data unexpectedly, depends on session state, or has side effects that make query results unpredictable.

**Q: Why should reusable procedures avoid `COMMIT`?**

A: The caller may need to combine several operations into one transaction or roll them back together.

**Q: How would you design an employee-hire procedure?**

A: Validate inputs, check required parent data, insert the employee, convert expected constraint errors into clear application errors, and let the caller decide whether to commit.

---

## 10. Revision Summary

### 1-Minute Recap

Procedures perform actions; functions return values.

- `IN` → input
- `OUT` → output
- `IN OUT` → input plus output
- `%TYPE` → schema-aligned parameter type
- Nested routine → private helper
- Overloading → one name, multiple signatures

### Interview Keywords

- **Standalone subprogram** → stored procedure or function
- **Parameter mode** → `IN`, `OUT`, or `IN OUT`
- **Overloading** → compile-time signature selection
- **`RAISE_APPLICATION_ERROR`** → caller-facing business error
- **Transaction ownership** → deciding where commit and rollback belong

### Important Syntax

```sql
CREATE OR REPLACE PROCEDURE p_name(p_id IN NUMBER) AS
BEGIN
  NULL;
END;
/

CREATE OR REPLACE FUNCTION f_name(p_id IN NUMBER)
RETURN NUMBER AS
BEGIN
  RETURN p_id * 2;
END;
/
```
