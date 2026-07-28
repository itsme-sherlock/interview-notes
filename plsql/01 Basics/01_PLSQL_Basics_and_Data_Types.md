# PL/SQL Basics and Data Types

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **PL/SQL** = SQL + procedural programming (variables, loops, if-else, error handling).
- **Block structure** = DECLARE (optional) → BEGIN (required) → EXCEPTION (optional) → END.
- **SQL problem:** Can't store values, no loops, no if-else—just runs one command.
- **PL/SQL solution:** Store data in variables, loop, branch, handle errors.
- **Scalar types:** NUMBER, VARCHAR2, CHAR, DATE, BOOLEAN.
- **Composite types:** RECORD, collections (nested table, varray, associative array).
- **Anchoring:** Use `%TYPE` and `%ROWTYPE` to link declarations to table schema—auto-updates if table changes.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need PL/SQL?](#1-why-do-we-need-plsql)
2. [What is PL/SQL?](#2-what-is-plsql)
3. [PL/SQL Block Structure](#3-plsql-block-structure)
4. [How a Block Executes](#4-how-a-block-executes)
5. [Variables and Scope](#5-variables-and-scope)
6. [Data Types: Scalar](#6-data-types-scalar)
7. [Data Types: Composite](#7-data-types-composite)
8. [Anchored Declarations](#8-anchored-declarations)
9. [Best Practices](#9-best-practices)
10. [Common Mistakes](#10-common-mistakes)
11. [Interview Q&A](#11-interview-qa)
12. [Revision Summary](#12-revision-summary)
13. [Related Notes](#13-related-notes)

---

## 1. Why Do We Need PL/SQL?

### The SQL Problem

SQL is great for retrieving and modifying data, but it has limits:

```sql
-- What we CAN do with SQL:
SELECT first_name FROM employees WHERE employee_id = 100;  ✅ Get data

-- What we CANNOT do with SQL:
-- Store the result in a variable         ❌
-- Check if a condition is true           ❌
-- Loop through multiple rows             ❌
-- Retry if something fails               ❌
```

SQL does **one thing**: fetch or modify data. That's it. No memory, no logic, no error recovery.

### The Real-World Problem

Imagine you need to:
1. Get an employee's current salary
2. Calculate a 10% increase
3. Check if new salary exceeds company max
4. If not, update the salary
5. If yes, log an error and stop

**With SQL alone:** You can't do this. You'd need a separate program to orchestrate these steps.

### The PL/SQL Solution

PL/SQL lets you:
- **Store data** in variables
- **Make decisions** with IF/ELSE
- **Repeat actions** with loops
- **Handle errors** gracefully

**In one program block**.

---

**➡ Transition:** Now that we know why PL/SQL exists, the next question is: **What exactly is a PL/SQL block and how does Oracle execute it?**

---

## 2. What is PL/SQL?

### Simple Definition

**PL/SQL** = **Procedural Language for SQL**. It's Oracle's programming language that combines SQL with procedural logic (variables, loops, conditions, error handling).

### Key Concept: Different from SQL

| Aspect | SQL | PL/SQL |
| --- | --- | --- |
| **Purpose** | Retrieve or modify data | Orchestrate, control, automate |
| **Execution** | One statement at a time | Block of statements (atomic unit) |
| **Variables** | No native support | Full support |
| **Control flow** | WHERE clauses only | IF, CASE, LOOP, WHILE, FOR |
| **Error handling** | Limited (constraints) | EXCEPTION block (full control) |
| **Use case** | Ad-hoc queries | Stored procedures, triggers, packages |

### Real-World Analogy

- **SQL** = Individual actions (go to store, buy milk, pay cashier)
- **PL/SQL** = A script for the whole process (check if store is open → go → buy → pay → verify receipt → go home)

---

**➡ Transition:** PL/SQL adds procedural power to SQL. But how does Oracle actually **structure** a PL/SQL program? That's the block concept.

---

## 3. PL/SQL Block Structure

A PL/SQL block is the **basic unit** of PL/SQL code. It has three sections:

### Section 1: DECLARE (Optional)

Declare variables, cursors, types—anything you'll use in the block.

```sql
DECLARE
  v_name VARCHAR2(50);
  v_salary NUMBER;
  c_emp CURSOR IS SELECT * FROM employees;
```

**Why optional:** If you don't need variables, skip it.

### Section 2: BEGIN (Required)

Your **executable code** goes here. At least `BEGIN` and `END` must exist.

```sql
BEGIN
  SELECT first_name INTO v_name FROM employees WHERE employee_id = 100;
  DBMS_OUTPUT.PUT_LINE('Name: ' || v_name);
END;
```

**Why required:** Oracle must know where the logic starts.

### Section 3: EXCEPTION (Optional)

Define **error handlers**. If something goes wrong, code here catches and handles it.

```sql
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Employee not found');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Unexpected error');
END;
```

**Why optional:** If you don't expect errors, skip it (though not recommended).

### Complete Structure

```sql
DECLARE
  -- Variables and declarations
  v_name VARCHAR2(50);
  v_salary NUMBER;
BEGIN
  -- Executable code
  SELECT first_name, salary
  INTO v_name, v_salary
  FROM employees
  WHERE employee_id = 100;
  
  DBMS_OUTPUT.PUT_LINE('Employee: ' || v_name || ', Salary: ' || v_salary);
EXCEPTION
  -- Error handlers
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Employee not found');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/
```

### Minimal Block

Don't need variables? Just write:

```sql
BEGIN
  DBMS_OUTPUT.PUT_LINE('Hello, PL/SQL');
END;
/
```

---

**➡ Transition:** We now know the structure. But what exactly happens when Oracle **executes** this block? Let's trace through it.

---

## 4. How a Block Executes

When you submit a PL/SQL block to Oracle, it goes through stages:

### Stage 1: DECLARE Phase (Initialization)

Oracle **allocates memory** for all variables declared.

```sql
DECLARE
  v_name VARCHAR2(50);    -- Memory allocated for string (50 chars max)
  v_salary NUMBER;        -- Memory allocated for number
BEGIN
```

**At this point:** Variables exist but have no values (they're `NULL`).

### Stage 2: BEGIN Phase (Execution)

Oracle **executes statements in order**, top to bottom.

```sql
BEGIN
  SELECT first_name INTO v_name FROM employees WHERE employee_id = 100;  -- Step 1
  DBMS_OUTPUT.PUT_LINE(v_name);                                           -- Step 2
```

**After Step 1:** v_name holds "John"  
**After Step 2:** "John" is printed

### Stage 3: EXCEPTION Phase (Error Handling, if needed)

If any statement in BEGIN raises an error:

```sql
BEGIN
  SELECT salary INTO v_salary FROM employees WHERE employee_id = 999;  -- Error: NO_DATA_FOUND
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_salary := 0;  -- Handle the error, continue
END;
```

**If error:** Jump to matching exception handler  
**If no handler:** Entire block fails

### Stage 4: END Phase (Cleanup)

Block ends. Memory is freed.

### Execution Diagram

```
DECLARE
  ↓ Allocate memory for v_name, v_salary
  ↓
BEGIN
  ↓ Step 1: SELECT first_name INTO v_name
  ↓ v_name = "John" now
  ↓ Step 2: DBMS_OUTPUT.PUT_LINE(v_name)
  ↓ Output: "John"
  ↓
EXCEPTION
  ↓ (No error occurred, skip this)
  ↓
END;
  ↓ Memory freed, block complete
```

---

**➡ Transition:** We now know how blocks execute. But how do we **actually use** variables in practice?

---

## 5. Variables and Scope

### What is a Variable?

A **variable** is a **named container** that holds a value. You declare it in DECLARE, use it in BEGIN.

```sql
DECLARE
  v_name VARCHAR2(50);     -- Declare variable
BEGIN
  v_name := 'John';        -- Assign value (using :=, not =)
  DBMS_OUTPUT.PUT_LINE(v_name);  -- Use it
END;
```

### Scope: Where Variables Live

**Scope** = where a variable is visible and usable.

#### Local Scope (Within Block)

```sql
DECLARE
  v_name VARCHAR2(50);  -- Local to this block only
BEGIN
  v_name := 'John';
  DBMS_OUTPUT.PUT_LINE(v_name);
END;
/

-- After block ends, v_name NO LONGER EXISTS
```

#### Global Scope (Packages)

```sql
CREATE OR REPLACE PACKAGE pkg_globals AS
  g_company_name VARCHAR2(50) := 'ACME Corp';  -- Global, visible everywhere
END pkg_globals;
/

-- Anywhere else in the database:
DECLARE
  v_local VARCHAR2(50) := pkg_globals.g_company_name;  -- Access global
BEGIN
  DBMS_OUTPUT.PUT_LINE(v_local);
END;
```

### Assignment Operator

Use `:=` to assign values (not `=`):

```sql
v_salary := 50000;        -- ✅ Correct
v_salary = 50000;         -- ❌ Wrong (= is comparison in SQL)
```

### NULL Values

Variables start as `NULL`:

```sql
DECLARE
  v_name VARCHAR2(50);  -- v_name is NULL
BEGIN
  IF v_name IS NULL THEN
    DBMS_OUTPUT.PUT_LINE('No value yet');
  END IF;
END;
```

---

**➡ Transition:** We can store values in variables. But what **types** of values? Oracle has many data types. Let's look at the simplest ones first.

---

## 6. Data Types: Scalar

**Scalar types** = single values (one number, one string, one date).

### NUMBER

Stores numeric values (integers or decimals).

```sql
DECLARE
  v_salary NUMBER;           -- Any number
  v_count NUMBER(5);         -- Max 5 digits
  v_percent NUMBER(5,2);     -- Max 5 digits, 2 after decimal
BEGIN
  v_salary := 50000;
  v_percent := 15.75;
END;
```

### VARCHAR2

Stores text (variable-length strings).

```sql
DECLARE
  v_name VARCHAR2(50);       -- Max 50 characters
  v_comment VARCHAR2(1000);  -- Max 1000 characters
BEGIN
  v_name := 'John Smith';
  v_comment := 'Top performer in Q1';
END;
```

### CHAR

Stores fixed-length text (rarely used in modern PL/SQL).

```sql
DECLARE
  v_grade CHAR(1);  -- Always 1 character
BEGIN
  v_grade := 'A';
END;
```

### DATE

Stores date and time values.

```sql
DECLARE
  v_hire_date DATE;
  v_today DATE;
BEGIN
  v_hire_date := '15-JAN-2020';
  v_today := SYSDATE;  -- Current date/time
END;
```

### BOOLEAN

Stores TRUE or FALSE (only in PL/SQL, not SQL).

```sql
DECLARE
  v_is_active BOOLEAN;
  v_is_retired BOOLEAN;
BEGIN
  v_is_active := TRUE;
  v_is_retired := FALSE;
  
  IF v_is_active THEN
    DBMS_OUTPUT.PUT_LINE('Employee is active');
  END IF;
END;
```

### Scalar Types at a Glance

| Type | Example | Use Case |
| --- | --- | --- |
| NUMBER | 50000, 15.75 | Salaries, counts, calculations |
| VARCHAR2 | 'John Smith' | Names, emails, descriptions |
| CHAR | 'A' | Grades, status codes (fixed length) |
| DATE | SYSDATE | Hire dates, timestamps |
| BOOLEAN | TRUE, FALSE | Flags, conditions |

---

**➡ Transition:** Scalar types store single values. But what if you need to store **multiple related values** together? That's where composite types come in.

---

## 7. Data Types: Composite

**Composite types** = multiple values grouped together.

### RECORD Type

A **RECORD** groups columns from a table (or custom columns) together.

```sql
DECLARE
  v_emp hr.employees%ROWTYPE;  -- Record with all columns from employees table
BEGIN
  SELECT * INTO v_emp FROM employees WHERE employee_id = 100;
  
  DBMS_OUTPUT.PUT_LINE(v_emp.employee_id);  -- Access individual columns
  DBMS_OUTPUT.PUT_LINE(v_emp.first_name);
  DBMS_OUTPUT.PUT_LINE(v_emp.salary);
END;
```

### Collection Types

Collections store **multiple rows** like an array.

#### Nested Table (Most Common)

```sql
DECLARE
  TYPE emp_table_type IS TABLE OF hr.employees%ROWTYPE;
  v_emps emp_table_type;
BEGIN
  -- Later, populate v_emps with multiple rows
  DBMS_OUTPUT.PUT_LINE('Employee count: ' || v_emps.COUNT);
END;
```

#### Varray (Fixed-Size Array)

```sql
DECLARE
  TYPE skills_varray IS VARRAY(5) OF VARCHAR2(50);
  v_skills skills_varray := skills_varray('SQL', 'PL/SQL', 'Java');
BEGIN
  DBMS_OUTPUT.PUT_LINE(v_skills(1));  -- 'SQL'
END;
```

#### Associative Array (Key-Value Map)

```sql
DECLARE
  TYPE salary_map IS TABLE OF NUMBER INDEX BY VARCHAR2(50);
  v_salaries salary_map;
BEGIN
  v_salaries('John') := 50000;
  v_salaries('Jane') := 60000;
  DBMS_OUTPUT.PUT_LINE(v_salaries('John'));  -- 50000
END;
```

### When to Use Composite Types

- **RECORD:** When you fetch one complete row from a table
- **Nested Table:** When you fetch multiple rows and need to loop through them
- **Varray:** When you need a fixed-size array (rare)
- **Associative Array:** When you need a key-value lookup (like a dictionary)

---

**➡ Transition:** Now we know scalar and composite types. But hardcoding types (like `VARCHAR2(50)`) is risky. What if the table schema changes? That's where **anchoring** saves us.

---

## 8. Anchored Declarations

### The Problem: Brittle Code

Hardcoding types creates maintenance risk:

```sql
DECLARE
  v_name VARCHAR2(50);    -- If table changes to VARCHAR2(100), this breaks
  v_salary NUMBER(10,2);  -- If table changes precision, this breaks
BEGIN
  SELECT first_name, salary INTO v_name, v_salary FROM employees WHERE employee_id = 100;
END;
```

If someone expands the `first_name` column to 100 characters, your code might lose data.

### The Solution: Anchor to Table Schema

Use `%TYPE` and `%ROWTYPE` to **link your declaration directly to the table**:

#### %TYPE: Anchor Single Column

```sql
DECLARE
  v_name employees.first_name%TYPE;      -- Automatically VARCHAR2(50)
  v_salary employees.salary%TYPE;         -- Automatically NUMBER
BEGIN
  SELECT first_name, salary INTO v_name, v_salary 
  FROM employees 
  WHERE employee_id = 100;
END;
```

**Benefit:** If the table schema changes, your declaration automatically updates.

#### %ROWTYPE: Anchor Entire Row

```sql
DECLARE
  v_emp employees%ROWTYPE;  -- Record with all columns from employees
BEGIN
  SELECT * INTO v_emp FROM employees WHERE employee_id = 100;
  
  DBMS_OUTPUT.PUT_LINE(v_emp.employee_id);
  DBMS_OUTPUT.PUT_LINE(v_emp.first_name);
  DBMS_OUTPUT.PUT_LINE(v_emp.salary);
END;
```

**Benefit:** No need to list columns manually. Auto-includes all columns.

### Why This Matters for Interviews

Anchored declarations show you understand:
- **Schema awareness:** Don't hardcode when you can reference the schema
- **Maintainability:** Let Oracle handle type changes
- **Best practice:** This is what professionals do in production

### Examples: %TYPE vs %ROWTYPE

```sql
DECLARE
  -- Using %TYPE (single columns)
  v_first_name employees.first_name%TYPE;
  v_last_name employees.last_name%TYPE;
  v_salary employees.salary%TYPE;
  
  -- Using %ROWTYPE (entire row)
  v_emp employees%ROWTYPE;
  
BEGIN
  -- Option 1: Fetch into multiple %TYPE variables
  SELECT first_name, last_name, salary 
  INTO v_first_name, v_last_name, v_salary
  FROM employees WHERE employee_id = 100;
  
  -- Option 2: Fetch entire row into %ROWTYPE
  SELECT * INTO v_emp FROM employees WHERE employee_id = 100;
  
  -- Access data
  DBMS_OUTPUT.PUT_LINE(v_first_name);  -- Option 1
  DBMS_OUTPUT.PUT_LINE(v_emp.first_name);  -- Option 2
END;
```

---

**➡ Transition:** We now know how to declare variables safely using anchoring. Let's look at the practices that separate junior from senior PL/SQL developers.

---

## 9. Best Practices

### 1. Always Use %TYPE and %ROWTYPE

**Avoid:**
```sql
DECLARE
  v_name VARCHAR2(50);
  v_salary NUMBER(10,2);
```

**Prefer:**
```sql
DECLARE
  v_name employees.first_name%TYPE;
  v_salary employees.salary%TYPE;
```

**Why:** Auto-updates if table schema changes.

---

### 2. Always Validate SELECT INTO

`SELECT INTO` can fail in two ways:

```sql
BEGIN
  SELECT salary INTO v_salary FROM employees WHERE employee_id = 999;
  -- If employee doesn't exist: NO_DATA_FOUND
  -- If multiple employees match: TOO_MANY_ROWS
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_salary := 0;
  WHEN TOO_MANY_ROWS THEN
    DBMS_OUTPUT.PUT_LINE('Multiple matches found');
END;
```

---

### 3. Use %ROWTYPE for Full Row Fetches

**Avoid:**
```sql
DECLARE
  v_id NUMBER;
  v_name VARCHAR2(50);
  v_salary NUMBER;
  v_email VARCHAR2(100);
  -- ... many more columns
BEGIN
  SELECT employee_id, first_name, salary, email, ... 
  INTO v_id, v_name, v_salary, v_email, ...
  FROM employees WHERE employee_id = 100;
END;
```

**Prefer:**
```sql
DECLARE
  v_emp employees%ROWTYPE;
BEGIN
  SELECT * INTO v_emp FROM employees WHERE employee_id = 100;
  DBMS_OUTPUT.PUT_LINE(v_emp.first_name);
END;
```

**Why:** Simpler, maintains readability.

---

### 4. Initialize Variables Carefully

```sql
DECLARE
  v_counter NUMBER := 0;      -- Initialized to 0
  v_name VARCHAR2(50) := NULL; -- Explicitly NULL
  v_is_active BOOLEAN := FALSE; -- Initialized to FALSE
BEGIN
  -- Use initialized values
END;
```

---

### 5. Use Meaningful Variable Names

**Avoid:**
```sql
DECLARE
  a VARCHAR2(50);
  b NUMBER;
  c DATE;
```

**Prefer:**
```sql
DECLARE
  v_employee_name VARCHAR2(50);
  v_department_id NUMBER;
  v_hire_date DATE;
```

**Convention:** `v_` prefix for variables, `c_` for cursors, `g_` for globals.

---

## 10. Common Mistakes

### Mistake 1: Using = Instead of :=

```sql
-- ❌ WRONG
v_salary = 50000;

-- ✅ CORRECT
v_salary := 50000;
```

---

### Mistake 2: Forgetting EXCEPTION Handler

```sql
-- ❌ RISKY
BEGIN
  SELECT salary INTO v_salary FROM employees WHERE employee_id = 999;
  -- If employee not found, block fails
END;

-- ✅ SAFE
BEGIN
  SELECT salary INTO v_salary FROM employees WHERE employee_id = 999;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_salary := 0;
END;
```

---

### Mistake 3: Hardcoding Types

```sql
-- ❌ BRITTLE
DECLARE
  v_name VARCHAR2(50);

-- ✅ MAINTAINABLE
DECLARE
  v_name employees.first_name%TYPE;
```

---

### Mistake 4: Not Initializing Variables

```sql
-- ❌ RISKY
DECLARE
  v_counter NUMBER;
BEGIN
  v_counter := v_counter + 1;  -- v_counter is NULL, result is NULL
END;

-- ✅ SAFE
DECLARE
  v_counter NUMBER := 0;
BEGIN
  v_counter := v_counter + 1;  -- v_counter is 1
END;
```

---

### Mistake 5: Mixing SQL and PL/SQL Logic

```sql
-- ❌ USE SQL WHEN POSSIBLE
DECLARE
  v_total NUMBER := 0;
BEGIN
  FOR rec IN (SELECT salary FROM employees WHERE department_id = 10) LOOP
    v_total := v_total + rec.salary;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE(v_total);
END;

-- ✅ USE SET-BASED SQL
SELECT SUM(salary) FROM employees WHERE department_id = 10;
```

---

## 11. Interview Q&A

### Conceptual

**Q: What's the difference between SQL and PL/SQL?**

A: SQL is declarative—you say "what data you want". PL/SQL is procedural—you control "how to process it" with variables, loops, and conditions.

---

**Q: Why does PL/SQL need a DECLARE section?**

A: DECLARE allocates memory for variables before they're used in BEGIN.

---

**Q: What happens if SELECT INTO finds no rows?**

A: The `NO_DATA_FOUND` exception is raised. If not handled, the block fails.

---

**Q: What's the difference between %TYPE and %ROWTYPE?**

A: `%TYPE` anchors to a single column. `%ROWTYPE` anchors to all columns in a table/cursor.

---

### Comparison

**Q: RECORD vs Collections?**

A:
- **RECORD:** Single row with named columns. Use for fetching one row.
- **Collection:** Multiple rows. Use for looping through many rows (nested table, varray, associative array).

---

**Q: When should you use anchored declarations?**

A: Always. Never hardcode types like `VARCHAR2(50)`. Let the table schema drive your variable declarations.

---

### Scenario

**Q: You fetch 1000 employees and calculate total salary using a PL/SQL loop. The query times out. Why?**

A: Row-by-row processing in loops is slow. Use set-based SQL: `SELECT SUM(salary) FROM employees`.

---

**Q: Your procedure crashes with "TOO_MANY_ROWS". What went wrong?**

A: `SELECT INTO` found multiple rows. Either filter with WHERE or use a cursor to handle multiple rows.

---

## 12. Revision Summary

### 1-Minute Revision

**PL/SQL = SQL + Logic**

1. **Why:** SQL can't store values or loop. PL/SQL adds variables, conditionals, loops, error handling.
2. **What:** Block structure: DECLARE → BEGIN → EXCEPTION → END.
3. **Execution:** Allocate memory (DECLARE) → run statements (BEGIN) → handle errors (EXCEPTION) → cleanup (END).
4. **Variables:** Named containers for values. Local (inside block) or global (packages).
5. **Scalar types:** NUMBER, VARCHAR2, CHAR, DATE, BOOLEAN (single values).
6. **Composite types:** RECORD (one row), collections (multiple rows).
7. **Best practice:** Use `%TYPE` and `%ROWTYPE` to anchor to table schema.
8. **Common trap:** SELECT INTO can fail with NO_DATA_FOUND or TOO_MANY_ROWS → always handle.

### Interview Keywords

- PL/SQL block (atomic unit of code)
- DECLARE, BEGIN, EXCEPTION, END (sections)
- Variable scope (local, global)
- Anchored declarations (%TYPE, %ROWTYPE)
- SELECT INTO (risks and exceptions)
- Scalar vs composite types
- NO_DATA_FOUND, TOO_MANY_ROWS (exceptions)

### Important Syntax

```sql
-- Basic block with variables
DECLARE
  v_name employees.first_name%TYPE;
  v_salary employees.salary%TYPE;
BEGIN
  SELECT first_name, salary
  INTO v_name, v_salary
  FROM employees
  WHERE employee_id = 100;
  
  DBMS_OUTPUT.PUT_LINE(v_name || ': ' || v_salary);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Employee not found');
END;
/

-- Using %ROWTYPE
DECLARE
  v_emp employees%ROWTYPE;
BEGIN
  SELECT * INTO v_emp FROM employees WHERE employee_id = 100;
  DBMS_OUTPUT.PUT_LINE(v_emp.first_name || ': ' || v_emp.salary);
END;
/
```

---

## 13. Related Notes

- Cursor processing: [Cursors](../06%20Cursors/01_Cursors.md)
- Control flow and loops: [Operators, Control Statements and Loops](../04%20Control%20Statements/01_Operators_Control_Statements_and_Loops.md)
