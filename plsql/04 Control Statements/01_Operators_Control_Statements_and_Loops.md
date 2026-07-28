# Operators, Control Statements and Loops

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Operators** = Tools to compare, calculate, and combine conditions.
- **Arithmetic:** `+`, `-`, `*`, `/` (calculate values).
- **Comparison:** `=`, `!=`, `>`, `<`, `>=`, `<=` (compare values).
- **Logical:** `AND`, `OR`, `NOT` (combine conditions).
- **Conditionals:** `IF-ELSIF-ELSE` (one path), `CASE` (many paths).
- **Loops:** `LOOP...EXIT WHEN` (manual), `WHILE` (condition-based), `FOR` (count-based).
- **Interview tip:** Prefer `CASE` for multiple conditions, `EXIT WHEN` for clean loop exit.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Control Flow?](#1-why-do-we-need-control-flow)
2. [What Are Operators?](#2-what-are-operators)
3. [Arithmetic Operators](#3-arithmetic-operators)
4. [Comparison Operators](#4-comparison-operators)
5. [Logical Operators](#5-logical-operators)
6. [Conditional Statements (IF/ELSIF/ELSE)](#6-conditional-statements-ifelsifelse)
7. [CASE Statement](#7-case-statement)
8. [Basic LOOP](#8-basic-loop)
9. [WHILE LOOP](#9-while-loop)
10. [FOR LOOP](#10-for-loop)
11. [Choosing the Right Loop](#11-choosing-the-right-loop)
12. [Best Practices](#12-best-practices)
13. [Common Mistakes](#13-common-mistakes)
14. [Interview Q&A](#14-interview-qa)
15. [Revision Summary](#15-revision-summary)
16. [Related Notes](#16-related-notes)

---

## 1. Why Do We Need Control Flow?

### The Problem: Static Variables

Without control flow, PL/SQL can only do simple tasks:

```sql
DECLARE
  v_age NUMBER := 25;
  v_name VARCHAR2(50) := 'John';
BEGIN
  DBMS_OUTPUT.PUT_LINE(v_name || ' is ' || v_age);
  -- That's it. Can't make decisions or repeat.
END;
```

Real programs need to:
- **Make decisions:** "If age > 18, allow; otherwise, deny"
- **Do calculations:** "Multiply salary by 1.10"
- **Repeat actions:** "Process 1000 employees one by one"

Without control flow, you're stuck with static statements.

### The Solution: Operators + Control Structures

- **Operators** let you compare and calculate
- **IF/CASE** let you make decisions
- **LOOPS** let you repeat actions

---

**➡ Transition:** Now let's look at the tools—operators—that help us build these control structures.

---

## 2. What Are Operators?

**Operators** are symbols that perform operations on values.

They fall into three categories:
1. **Arithmetic** - Calculate new values
2. **Comparison** - Compare values and get TRUE/FALSE
3. **Logical** - Combine TRUE/FALSE values

Example of flow:
```
Salary := 50000

Arithmetic:        Salary * 1.10 = 55000

Comparison:        If 55000 > 60000? FALSE

Logical:           Is senior AND salary high? FALSE AND FALSE = FALSE

Decision:          Don't give raise
```

---

## 3. Arithmetic Operators

Arithmetic operators **calculate new values**.

| Operator | Meaning | Example | Result |
| --- | --- | --- | --- |
| `+` | Addition | `10 + 5` | 15 |
| `-` | Subtraction | `10 - 5` | 5 |
| `*` | Multiplication | `10 * 5` | 50 |
| `/` | Division | `10 / 5` | 2 |

### Using Arithmetic Operators

```sql
DECLARE
  v_salary NUMBER := 50000;
  v_raise NUMBER;
  v_new_salary NUMBER;
BEGIN
  v_raise := v_salary * 0.10;           -- Calculate 10% raise = 5000
  v_new_salary := v_salary + v_raise;   -- Add raise to salary = 55000
  
  DBMS_OUTPUT.PUT_LINE('New Salary: ' || v_new_salary);
END;
```

### Key Point: No Modulus Operator in Assignment

In SQL, `%` is not modulus. Use `MOD()` function instead:

```sql
BEGIN
  -- ❌ WRONG
  v_remainder := 10 % 3;
  
  -- ✅ CORRECT
  v_remainder := MOD(10, 3);  -- Result: 1
END;
```

---

**➡ Transition:** Arithmetic operators calculate values. But to make decisions, we need to **compare** values and get TRUE or FALSE answers.

---

## 4. Comparison Operators

Comparison operators **compare two values** and return TRUE or FALSE.

| Operator | Meaning | Example | Result |
| --- | --- | --- | --- |
| `=` | Equal | `10 = 10` | TRUE |
| `!=` or `<>` | Not equal | `10 != 5` | TRUE |
| `>` | Greater than | `10 > 5` | TRUE |
| `<` | Less than | `10 < 5` | FALSE |
| `>=` | Greater than or equal | `10 >= 10` | TRUE |
| `<=` | Less than or equal | `10 <= 10` | TRUE |

### Using Comparison Operators

```sql
DECLARE
  v_salary NUMBER := 50000;
  v_is_high_salary BOOLEAN;
BEGIN
  v_is_high_salary := (v_salary > 60000);  -- FALSE
  
  IF v_salary >= 50000 THEN
    DBMS_OUTPUT.PUT_LINE('Above minimum');
  END IF;
END;
```

### Common Comparisons

```sql
DECLARE
  v_age NUMBER := 25;
  v_name VARCHAR2(50) := 'John';
BEGIN
  -- Numeric comparison
  IF v_age >= 18 THEN
    DBMS_OUTPUT.PUT_LINE('Adult');
  END IF;
  
  -- String comparison
  IF v_name = 'John' THEN
    DBMS_OUTPUT.PUT_LINE('Name matches');
  END IF;
  
  -- NULL check (special)
  IF v_name IS NULL THEN
    DBMS_OUTPUT.PUT_LINE('No name provided');
  END IF;
END;
```

---

**➡ Transition:** Comparison operators give us TRUE/FALSE. But what if we need to check **multiple conditions** at the same time? That's where logical operators come in.

---

## 5. Logical Operators

Logical operators **combine multiple conditions** into one TRUE/FALSE result.

### AND Operator

Returns TRUE only if **both conditions are TRUE**.

| Condition 1 | Condition 2 | AND Result |
| --- | --- | --- |
| TRUE | TRUE | **TRUE** |
| TRUE | FALSE | FALSE |
| FALSE | TRUE | FALSE |
| FALSE | FALSE | FALSE |

**Example:**
```sql
DECLARE
  v_age NUMBER := 25;
  v_salary NUMBER := 50000;
BEGIN
  IF v_age >= 18 AND v_salary >= 40000 THEN
    DBMS_OUTPUT.PUT_LINE('Eligible for loan');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Not eligible');
  END IF;
END;
```

---

### OR Operator

Returns TRUE if **at least one condition is TRUE**.

| Condition 1 | Condition 2 | OR Result |
| --- | --- | --- |
| TRUE | TRUE | **TRUE** |
| TRUE | FALSE | **TRUE** |
| FALSE | TRUE | **TRUE** |
| FALSE | FALSE | FALSE |

**Example:**
```sql
BEGIN
  IF v_status = 'ACTIVE' OR v_status = 'PENDING' THEN
    DBMS_OUTPUT.PUT_LINE('Process employee');
  END IF;
END;
```

---

### NOT Operator

Reverses the result. TRUE becomes FALSE, FALSE becomes TRUE.

| Condition | NOT Result |
| --- | --- |
| TRUE | **FALSE** |
| FALSE | **TRUE** |

**Example:**
```sql
BEGIN
  IF NOT v_is_deleted THEN
    DBMS_OUTPUT.PUT_LINE('Show employee');
  END IF;
  
  -- Equivalent to:
  IF v_is_deleted = FALSE THEN
    DBMS_OUTPUT.PUT_LINE('Show employee');
  END IF;
END;
```

---

### Combining Operators

You can combine multiple conditions:

```sql
DECLARE
  v_age NUMBER := 25;
  v_salary NUMBER := 50000;
  v_years_employed NUMBER := 3;
BEGIN
  IF (v_age >= 18 AND v_salary >= 40000) OR v_years_employed >= 5 THEN
    DBMS_OUTPUT.PUT_LINE('Eligible for promotion');
  END IF;
END;
```

**Logic:** Promote if (adult AND good salary) OR (long tenure)

---

**➡ Transition:** Now we can compare and combine conditions. Let's use these to **make decisions**—using IF statements.

---

## 6. Conditional Statements (IF/ELSIF/ELSE)

### Simple IF

Executes a block if a condition is TRUE.

```sql
DECLARE
  v_salary NUMBER := 50000;
BEGIN
  IF v_salary > 60000 THEN
    DBMS_OUTPUT.PUT_LINE('High salary');
  END IF;
  
  DBMS_OUTPUT.PUT_LINE('Check complete');
END;
```

**Flow:**
```
Is salary > 60000?
  YES → Print "High salary"
  NO → Skip this block
Print "Check complete"
```

---

### IF / ELSE

Execute one block if TRUE, another if FALSE.

```sql
BEGIN
  IF v_salary > 60000 THEN
    DBMS_OUTPUT.PUT_LINE('High salary');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Standard salary');
  END IF;
END;
```

**Flow:**
```
Is salary > 60000?
  YES → Print "High salary"
  NO → Print "Standard salary"
```

---

### IF / ELSIF / ELSE

Check multiple conditions, execute first TRUE block.

```sql
DECLARE
  v_score NUMBER := 85;
  v_grade VARCHAR2(1);
BEGIN
  IF v_score >= 90 THEN
    v_grade := 'A';
  ELSIF v_score >= 80 THEN
    v_grade := 'B';
  ELSIF v_score >= 70 THEN
    v_grade := 'C';
  ELSE
    v_grade := 'F';
  END IF;
  
  DBMS_OUTPUT.PUT_LINE('Grade: ' || v_grade);  -- Output: B
END;
```

**Flow:**
```
Is score >= 90?
  YES → Grade = 'A', skip rest
  NO → Check: Is score >= 80?
    YES → Grade = 'B', skip rest
    NO → Check: Is score >= 70?
      YES → Grade = 'C', skip rest
      NO → Grade = 'F'
```

**Important:** Only the first TRUE block executes. Rest are skipped.

### Nested IF

You can nest IF statements inside each other:

```sql
BEGIN
  IF v_age >= 18 THEN
    DBMS_OUTPUT.PUT_LINE('Adult');
    IF v_salary > 50000 THEN
      DBMS_OUTPUT.PUT_LINE('High earner');
    END IF;
  ELSE
    DBMS_OUTPUT.PUT_LINE('Minor');
  END IF;
END;
```

---

**➡ Transition:** IF/ELSIF works for checking conditions step-by-step. But when you have **many branches** (like grades or status codes), CASE is cleaner and faster.

---

## 7. CASE Statement

CASE is cleaner than multiple ELSIF blocks when comparing one value against many options.

### CASE Simple (Most Common)

Compare one value against multiple options.

```sql
DECLARE
  v_grade VARCHAR2(1) := 'B';
BEGIN
  CASE v_grade
    WHEN 'A' THEN DBMS_OUTPUT.PUT_LINE('Excellent');
    WHEN 'B' THEN DBMS_OUTPUT.PUT_LINE('Good');
    WHEN 'C' THEN DBMS_OUTPUT.PUT_LINE('Average');
    WHEN 'D' THEN DBMS_OUTPUT.PUT_LINE('Below Average');
    ELSE DBMS_OUTPUT.PUT_LINE('Fail');
  END CASE;
END;
/
```

**Output:** Good

**Flow:**
```
Check v_grade:
  'A'? No
  'B'? YES → Print "Good", exit CASE
  (rest skipped)
```

### CASE Searched (For Complex Conditions)

When each branch has a different condition (not just equality):

```sql
DECLARE
  v_salary NUMBER := 55000;
BEGIN
  CASE
    WHEN v_salary >= 100000 THEN
      DBMS_OUTPUT.PUT_LINE('Executive');
    WHEN v_salary >= 60000 THEN
      DBMS_OUTPUT.PUT_LINE('Senior Staff');
    WHEN v_salary >= 40000 THEN
      DBMS_OUTPUT.PUT_LINE('Staff');
    ELSE
      DBMS_OUTPUT.PUT_LINE('Entry Level');
  END CASE;
END;
/
```

**Output:** Senior Staff

### IF vs CASE: When to Use Which

**Use IF/ELSIF when:**
- Conditions are complex (multiple variables, ranges)
- Not just comparing one value

**Use CASE when:**
- Comparing one variable against many fixed values (statuses, codes)
- Multiple branches based on equality

```sql
-- Use CASE
CASE v_status
  WHEN 'ACTIVE' THEN ...
  WHEN 'INACTIVE' THEN ...
  WHEN 'DELETED' THEN ...
END CASE;

-- Use IF/ELSIF
IF v_age >= 18 AND v_salary > 50000 THEN ...
ELSIF v_years_employed >= 5 THEN ...
END IF;
```

---

**➡ Transition:** Conditionals let us make one-time decisions. But what if we need to **repeat the same action** many times (like processing 1000 employees)? That's where loops come in.

---

## 8. Basic LOOP

A **LOOP** repeats a block of code until you tell it to stop with `EXIT`.

### Simple LOOP with EXIT WHEN

```sql
DECLARE
  v_counter NUMBER := 1;
BEGIN
  LOOP
    DBMS_OUTPUT.PUT_LINE(v_counter);
    v_counter := v_counter + 1;
    EXIT WHEN v_counter > 5;  -- Exit when counter exceeds 5
  END LOOP;
  
  DBMS_OUTPUT.PUT_LINE('Loop complete');
END;
```

**Output:**
```
1
2
3
4
5
Loop complete
```

**Flow:**
```
Iteration 1: counter=1, print 1, increment to 2, check EXIT (2 > 5? NO)
Iteration 2: counter=2, print 2, increment to 3, check EXIT (3 > 5? NO)
Iteration 3: counter=3, print 3, increment to 4, check EXIT (4 > 5? NO)
Iteration 4: counter=4, print 4, increment to 5, check EXIT (5 > 5? NO)
Iteration 5: counter=5, print 5, increment to 6, check EXIT (6 > 5? YES) → EXIT
Print "Loop complete"
```

### Key Point: EXIT WHEN vs EXIT

```sql
-- Recommended: Clear condition
LOOP
  ...
  EXIT WHEN v_counter > 5;
END LOOP;

-- Also valid: unconditional exit (use sparingly)
LOOP
  IF v_counter > 5 THEN
    EXIT;
  END IF;
  ...
END LOOP;
```

### Infinite Loop Prevention

Always have an EXIT condition:

```sql
-- ❌ RISKY: Might loop forever
LOOP
  DBMS_OUTPUT.PUT_LINE(v_counter);
  -- Forgot v_counter := v_counter + 1;
  EXIT WHEN v_counter > 5;
END LOOP;

-- ✅ SAFE: Clear exit condition
LOOP
  DBMS_OUTPUT.PUT_LINE(v_counter);
  v_counter := v_counter + 1;
  EXIT WHEN v_counter > 5;
END LOOP;
```

---

## 9. WHILE LOOP

A **WHILE LOOP** checks the condition before each iteration. Loop runs only if condition is TRUE.

```sql
DECLARE
  v_counter NUMBER := 1;
BEGIN
  WHILE v_counter <= 5 LOOP
    DBMS_OUTPUT.PUT_LINE(v_counter);
    v_counter := v_counter + 1;
  END LOOP;
  
  DBMS_OUTPUT.PUT_LINE('Loop complete');
END;
```

**Output:**
```
1
2
3
4
5
Loop complete
```

**Flow:**
```
Check: 1 <= 5? YES → Execute body
Check: 2 <= 5? YES → Execute body
Check: 3 <= 5? YES → Execute body
Check: 4 <= 5? YES → Execute body
Check: 5 <= 5? YES → Execute body
Check: 6 <= 5? NO → Exit loop
```

### WHILE Loop Advantage

Condition is checked **before** loop body runs. If condition is false from start, loop never executes:

```sql
DECLARE
  v_counter NUMBER := 10;
BEGIN
  WHILE v_counter <= 5 LOOP
    DBMS_OUTPUT.PUT_LINE(v_counter);  -- Never executes
    v_counter := v_counter + 1;
  END LOOP;
  
  DBMS_OUTPUT.PUT_LINE('Done');  -- Prints immediately
END;
```

---

## 10. FOR LOOP

A **FOR LOOP** automatically counts from one number to another. Best for **known number of iterations**.

### FOR Loop (Forward)

```sql
BEGIN
  FOR i IN 1..5 LOOP
    DBMS_OUTPUT.PUT_LINE(i);
  END LOOP;
END;
```

**Output:**
```
1
2
3
4
5
```

**Syntax:** `FOR i IN start..end LOOP`
- `i` = loop variable (automatically increments)
- `1..5` = range from 1 to 5 (inclusive)

### FOR REVERSE

Count backward:

```sql
BEGIN
  FOR i IN REVERSE 1..5 LOOP
    DBMS_OUTPUT.PUT_LINE(i);
  END LOOP;
END;
```

**Output:**
```
5
4
3
2
1
```

### FOR Loop Over Cursor

Fetch multiple rows and loop:

```sql
DECLARE
  CURSOR c_emp IS SELECT employee_id, first_name FROM employees WHERE department_id = 10;
BEGIN
  FOR rec IN c_emp LOOP
    DBMS_OUTPUT.PUT_LINE(rec.employee_id || ': ' || rec.first_name);
  END LOOP;
END;
```

---

## 11. Choosing the Right Loop

### Use LOOP ... EXIT WHEN When

- You need manual control over exit condition
- Exit condition is complex

```sql
LOOP
  FETCH c_emp INTO rec;
  EXIT WHEN c_emp%NOTFOUND;
  -- Process rec
END LOOP;
```

---

### Use WHILE When

- Condition is checked **before** each iteration
- Loop might not run at all
- Condition is simple

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

---

### Use FOR When

- You know the exact **start and end** of range
- Simple counting loop
- Processing cursor results

```sql
BEGIN
  FOR i IN 1..100 LOOP
    DBMS_OUTPUT.PUT_LINE(i);
  END LOOP;
END;
```

---

### Quick Comparison Table

| Loop Type | When to Use | Exit Condition |
| --- | --- | --- |
| **LOOP...EXIT** | Manual control, complex exit | Explicit EXIT WHEN |
| **WHILE** | Simple condition, pre-checked | Checked before iteration |
| **FOR** | Count from X to Y, cursors | Automatic when range ends |

---

## 12. Best Practices

### 1. Prefer CASE Over Many ELSIF Blocks

**Avoid:**
```sql
IF v_status = 'A' THEN ...
ELSIF v_status = 'B' THEN ...
ELSIF v_status = 'C' THEN ...
ELSIF v_status = 'D' THEN ...
END IF;
```

**Prefer:**
```sql
CASE v_status
  WHEN 'A' THEN ...
  WHEN 'B' THEN ...
  WHEN 'C' THEN ...
  WHEN 'D' THEN ...
END CASE;
```

**Why:** CASE is cleaner and performs better.

---

### 2. Always Initialize Loop Counter

```sql
-- ✅ CORRECT
DECLARE
  v_counter NUMBER := 1;
BEGIN
  LOOP
    ...
    v_counter := v_counter + 1;
  END LOOP;
END;

-- ❌ WRONG (counter starts as NULL)
DECLARE
  v_counter NUMBER;
BEGIN
  LOOP
    v_counter := v_counter + 1;  -- NULL + 1 = NULL
  END LOOP;
END;
```

---

### 3. Avoid Infinite Loops

Always ensure your exit condition **will** be met:

```sql
-- ❌ RISKY
LOOP
  DBMS_OUTPUT.PUT_LINE('Test');
  -- No exit! Infinite loop.
END LOOP;

-- ✅ SAFE
LOOP
  DBMS_OUTPUT.PUT_LINE('Test');
  v_counter := v_counter + 1;
  EXIT WHEN v_counter > 5;
END LOOP;
```

---

### 4. Keep Loop Body Small

```sql
-- ✅ GOOD
FOR rec IN c_emp LOOP
  process_employee(rec.employee_id);  -- Call procedure
END LOOP;

-- ❌ COMPLEX (hard to read)
FOR rec IN c_emp LOOP
  SELECT * INTO v_emp_details FROM employees WHERE ...;
  FOR rec2 IN (SELECT * FROM salary_history WHERE ...) LOOP
    ...
  END LOOP;
END LOOP;
```

---

### 5. Validate Before Division

```sql
-- ❌ RISKY (dividing by zero)
v_percentage := (v_count / v_total) * 100;

-- ✅ SAFE
IF v_total > 0 THEN
  v_percentage := (v_count / v_total) * 100;
ELSE
  v_percentage := 0;
END IF;
```

---

### 6. Use FOR Loop for Cursor Processing

**Prefer:**
```sql
FOR rec IN c_emp LOOP
  DBMS_OUTPUT.PUT_LINE(rec.first_name);
END LOOP;
```

**Over:**
```sql
OPEN c_emp;
LOOP
  FETCH c_emp INTO rec;
  EXIT WHEN c_emp%NOTFOUND;
  DBMS_OUTPUT.PUT_LINE(rec.first_name);
END LOOP;
CLOSE c_emp;
```

---

## 13. Common Mistakes

### Mistake 1: Forgetting to Increment Loop Counter

```sql
-- ❌ INFINITE LOOP
LOOP
  DBMS_OUTPUT.PUT_LINE(v_counter);
  -- Forgot v_counter := v_counter + 1;
  EXIT WHEN v_counter > 5;
END LOOP;

-- ✅ CORRECT
LOOP
  DBMS_OUTPUT.PUT_LINE(v_counter);
  v_counter := v_counter + 1;
  EXIT WHEN v_counter > 5;
END LOOP;
```

---

### Mistake 2: Using = Instead of := for Assignment

```sql
-- ❌ WRONG (= is comparison)
v_counter = v_counter + 1;

-- ✅ CORRECT
v_counter := v_counter + 1;
```

---

### Mistake 3: EXIT Not Reached

```sql
-- ❌ WRONG (EXIT never reached because of earlier LOOP exit)
LOOP
  v_counter := v_counter + 1;
  IF v_counter = 3 THEN
    LOOP
      -- Inner loop with no exit condition
      ...
    END LOOP;
  END IF;
  EXIT WHEN v_counter > 5;
END LOOP;
```

---

### Mistake 4: Comparing NULL Values

```sql
-- ❌ WRONG
IF v_name = NULL THEN ...  -- Always FALSE (NULL is unknown)

-- ✅ CORRECT
IF v_name IS NULL THEN ...
```

---

### Mistake 5: Complex Nested Conditionals

```sql
-- ❌ HARD TO READ
IF v_age >= 18 THEN
  IF v_salary >= 50000 THEN
    IF v_years_employed >= 3 THEN
      DBMS_OUTPUT.PUT_LINE('Eligible');
    END IF;
  END IF;
END IF;

-- ✅ CLEANER
IF v_age >= 18 AND v_salary >= 50000 AND v_years_employed >= 3 THEN
  DBMS_OUTPUT.PUT_LINE('Eligible');
END IF;
```

---

## 14. Interview Q&A

### Conceptual

**Q: What's the difference between LOOP and WHILE loop?**

A: 
- **LOOP:** Runs body first, checks EXIT condition after.
- **WHILE:** Checks condition before running body. May not run at all.

---

**Q: When should you use FOR loop over WHILE?**

A: FOR loop when you know the exact start and end points. WHILE when the end depends on a condition.

---

**Q: What does EXIT WHEN do?**

A: Immediately exits the innermost loop when the condition is TRUE.

---

### Comparison

**Q: IF/ELSIF vs CASE?**

A:
- **IF/ELSIF:** For complex conditions or ranges (age >= 18 AND salary > 50000).
- **CASE:** For one variable against many fixed values (status = 'A', 'B', 'C').

---

**Q: AND vs OR?**

A:
- **AND:** Both conditions must be TRUE.
- **OR:** At least one condition must be TRUE.

---

### Scenario

**Q: Your loop processes 1000 employees but times out. Why?**

A: Row-by-row processing in loops is slow. Use set-based SQL: `UPDATE employees SET...` instead of looping.

---

**Q: Your CASE statement doesn't work for decimal values. Why?**

A: CASE checks equality. For ranges (salary > 50000), use IF/ELSIF instead.

---

## 15. Revision Summary

### 1-Minute Revision

**Control Flow = Making Decisions + Repeating Actions**

1. **Operators:** Arithmetic (`+`, `-`, `*`, `/`), Comparison (`=`, `>`, `<`), Logical (`AND`, `OR`, `NOT`).
2. **Conditionals:** IF/ELSIF for complex checks, CASE for one value vs many options.
3. **Loops:** LOOP (manual control), WHILE (condition-based), FOR (count-based).
4. **EXIT WHEN:** Clean way to exit any loop.
5. **Best practice:** Prefer CASE over deeply nested IF, prefer FOR for cursor processing.
6. **Trap:** NULL comparisons need IS NULL, not = NULL.

### Interview Keywords

- Arithmetic, comparison, logical operators
- IF/ELSIF/ELSE (branching)
- CASE vs IF (readability)
- LOOP, WHILE, FOR (different use cases)
- EXIT WHEN (loop control)
- Nested conditionals
- Loop counter initialization

### Important Syntax

```sql
-- IF/ELSIF/ELSE
IF v_score >= 90 THEN v_grade := 'A';
ELSIF v_score >= 80 THEN v_grade := 'B';
ELSE v_grade := 'C';
END IF;

-- CASE
CASE v_status
  WHEN 'A' THEN DBMS_OUTPUT.PUT_LINE('Active');
  WHEN 'I' THEN DBMS_OUTPUT.PUT_LINE('Inactive');
  ELSE DBMS_OUTPUT.PUT_LINE('Unknown');
END CASE;

-- LOOP with EXIT
LOOP
  DBMS_OUTPUT.PUT_LINE(v_counter);
  v_counter := v_counter + 1;
  EXIT WHEN v_counter > 5;
END LOOP;

-- WHILE LOOP
WHILE v_counter <= 5 LOOP
  DBMS_OUTPUT.PUT_LINE(v_counter);
  v_counter := v_counter + 1;
END LOOP;

-- FOR LOOP
FOR i IN 1..5 LOOP
  DBMS_OUTPUT.PUT_LINE(i);
END LOOP;

-- FOR REVERSE
FOR i IN REVERSE 1..5 LOOP
  DBMS_OUTPUT.PUT_LINE(i);
END LOOP;
```

---

## 16. Related Notes

- Cursor loops and row processing: [Cursors](../06%20Cursors/01_Cursors.md)
- Foundations and datatypes: [PL/SQL Basics and Data Types](../01%20Basics/01_PLSQL_Basics_and_Data_Types.md)
