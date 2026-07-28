# PL/SQL Cursors

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Cursor** = A handle to fetch multiple rows one at a time.
- **Implicit cursor** = Oracle creates it automatically for single-row queries.
- **Explicit cursor** = You declare and control it manually for multi-row processing.
- **Lifecycle** = DECLARE → OPEN → FETCH → CLOSE.
- **Attributes** = `%FOUND`, `%NOTFOUND`, `%ROWCOUNT`, `%ISOPEN` tell you cursor status.
- **Cursor FOR Loop** = Simplest way—Oracle opens, fetches, closes automatically.
- **FOR UPDATE** = Locks rows so only your cursor can modify them.
- **WHERE CURRENT OF** = Updates only the row your cursor is currently pointing to.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Cursors?](#1-why-do-we-need-cursors)
2. [What is a Cursor?](#2-what-is-a-cursor)
3. [Cursor Lifecycle](#3-cursor-lifecycle)
4. [Cursor Attributes](#4-cursor-attributes)
5. [Explicit Cursor with Manual Control](#5-explicit-cursor-with-manual-control)
6. [Cursor FOR Loop (The Easy Way)](#6-cursor-for-loop-the-easy-way)
7. [Parameterized Cursor](#7-parameterized-cursor)
8. [FOR UPDATE (Locking Rows)](#8-for-update-locking-rows)
9. [WHERE CURRENT OF (Update Current Row)](#9-where-current-of-update-current-row)
10. [REF CURSOR (Dynamic Cursors)](#10-ref-cursor-dynamic-cursors)
11. [Best Practices](#11-best-practices)
12. [Common Mistakes](#12-common-mistakes)
13. [Interview Q&A](#13-interview-qa)
14. [Revision Summary](#14-revision-summary)

---

## 1. Why Do We Need Cursors?

### The Problem

Imagine you need to fetch **10 employees** from a table. You can't use `SELECT INTO` because:

```sql
SELECT employee_id, salary
INTO v_emp_id, v_salary
FROM employees;
-- ❌ ERROR: TOO_MANY_ROWS
-- Oracle doesn't know which ONE row you want if there are many rows.
```

`SELECT INTO` works only when you know there's **exactly one row**.

### The Solution: Cursor

A **cursor** is like a **pointer** or **handle** to a result set. It lets you:
- Get **multiple rows** from a query
- Process **one row at a time** in a loop
- Know **when you've reached the end**

**Real-world analogy:** A cursor is like a bookmark in a book. You open the book (cursor), read page by page (fetch), and when you reach the end, you close it.

---

**➡ Transition:** Now that we know why cursors exist, the next question is: **What exactly happens when Oracle creates a cursor?**

---

## 2. What is a Cursor?

### Simple Definition

A **cursor** is a **temporary work area** in Oracle's memory that holds query results and a **pointer** to the current row.

Think of it like this:
- Query runs → Oracle stores results in memory
- Cursor is positioned **BEFORE the first row** (not at it)
- First FETCH moves cursor to row 1, second FETCH to row 2, etc.
- When no more rows, cursor **points beyond the last row** and `%NOTFOUND` becomes TRUE

### More Technical: What's Inside?

A cursor internally contains:

| Component | What It Does |
| --- | --- |
| **Result Set** | All rows returned by your query |
| **Cursor Pointer** | Points to the current row |
| **Status Attributes** | `%FOUND`, `%NOTFOUND`, etc. |
| **Context Area** | Memory where Oracle processes the query |

### Key Concept: Cursor vs Result Set

- **Result Set** = All the data your query returned (static)
- **Cursor** = The pointer + the mechanism to read that data one row at a time (dynamic)

Example:
```
Query returns 100 employees.
Result Set = All 100 employees stored in memory.
Cursor = A pointer currently pointing at Employee #5.
```

### Implicit vs Explicit Cursor

| Type | Oracle Creates? | You Control? | When Used? |
| --- | --- | --- | --- |
| **Implicit** | Yes, automatically | No | Single-row queries, DML |
| **Explicit** | No, you must declare | Yes, manually | Multi-row queries |

---

**➡ Transition:** If a cursor is a pointer that Oracle maintains, the next question is: **What exactly does Oracle do when you OPEN, FETCH, and CLOSE a cursor?**

---

## 3. Cursor Lifecycle

A cursor goes through **four stages**:

### Stage 1: DECLARE
You describe what query the cursor will run.
```sql
DECLARE
  CURSOR c_emp IS
    SELECT employee_id, first_name, salary
    FROM employees;
```
**At this point:** Query is NOT run yet. Just stored as a plan.

### Stage 2: OPEN
Oracle **executes the query** and populates the result set.
```sql
OPEN c_emp;
```
**What happens:**
- Oracle runs `SELECT employee_id, first_name, salary FROM employees`
- All rows are fetched and stored in memory
- Cursor pointer is positioned **BEFORE the first row**
- Cursor status `%ISOPEN` becomes `TRUE`

### Stage 3: FETCH
You pull **one row at a time** and advance cursor to next position.
```sql
FETCH c_emp INTO v_id, v_name, v_salary;
```
**What happens:**
- Current row's data is copied into `v_id, v_name, v_salary`
- Cursor moves to **next row** (or past the last row if no more data)
- `%ROWCOUNT` increments by 1
- `%FOUND` becomes `TRUE` if row was found, `FALSE` if no more rows

### Stage 4: CLOSE
You release memory and close the cursor.
```sql
CLOSE c_emp;
```
**What happens:**
- Result set is freed from memory
- Cursor pointer is reset
- `%ISOPEN` becomes `FALSE`

### Complete Lifecycle Example

```sql
DECLARE
  CURSOR c_emp IS
    SELECT employee_id, first_name, salary
    FROM employees;

  v_id     employees.employee_id%TYPE;
  v_name   employees.first_name%TYPE;
  v_salary employees.salary%TYPE;
BEGIN
  OPEN c_emp;           -- Stage 1: Execute query, cursor BEFORE Row 1
  
  LOOP
    FETCH c_emp INTO v_id, v_name, v_salary;  -- Stage 2: Get Row 1, move cursor to Row 2
    EXIT WHEN c_emp%NOTFOUND;  -- If no more rows, exit
    
    DBMS_OUTPUT.PUT_LINE(v_id || ' - ' || v_name || ' - ' || v_salary);
  END LOOP;
  
  CLOSE c_emp;          -- Stage 3: Free memory
END;
```

**Memory Diagram (Simplified):**
```
DECLARE:
  c_emp = [Query stored, not executed]

OPEN:
  Result Set = [Row1, Row2, Row3, Row4, ...]
  Cursor → BEFORE Row1 (no data yet)

FETCH 1:
  Gets Row1 data, Cursor → Row1

FETCH 2:
  Gets Row2 data, Cursor → Row2

FETCH 3:
  Gets Row3 data, Cursor → Row3

FETCH 4:
  Gets Row4 data, Cursor → Row4

FETCH 5:
  No data available, Cursor → PAST last row (%NOTFOUND = TRUE)

CLOSE:
  Cursor freed, memory released
```

---

**➡ Transition:** Now we know Oracle manages the cursor position automatically. But how does **your code** know whether more rows exist? That's where **cursor attributes** come in.

---

## 4. Cursor Attributes

Cursor attributes are **built-in variables** that tell you the **status** of the cursor.

### %NOTFOUND
Returns `TRUE` if the **last FETCH found no rows**.

```sql
FETCH c_emp INTO v_id, v_name;
IF c_emp%NOTFOUND THEN
  DBMS_OUTPUT.PUT_LINE('No more rows');
END IF;
```

**When to use:** Exit a loop when no more rows.

### %FOUND
Returns `TRUE` if the **last FETCH found a row**.

```sql
FETCH c_emp INTO v_id, v_name;
IF c_emp%FOUND THEN
  DBMS_OUTPUT.PUT_LINE('Got a row: ' || v_id);
END IF;
```

**When to use:** Opposite of `%NOTFOUND`, less common in practice.

### %ROWCOUNT
Returns the **number of rows fetched so far**.

```sql
FETCH c_emp INTO v_id, v_name;
DBMS_OUTPUT.PUT_LINE('Fetched ' || c_emp%ROWCOUNT || ' rows so far');
```

**When to use:** Track how many rows you've processed.

### %ISOPEN
Returns `TRUE` if the cursor is **currently open**.

```sql
IF c_emp%ISOPEN THEN
  CLOSE c_emp;
END IF;
```

**When to use:** Prevent errors from opening a cursor twice.

### For Implicit Cursors (DML)

When you do `INSERT`, `UPDATE`, `DELETE`, Oracle creates an **implicit cursor** automatically. Use `SQL%...` (not `cursor_name%...`):

```sql
UPDATE employees SET salary = 50000 WHERE department_id = 10;

IF SQL%ROWCOUNT > 0 THEN
  DBMS_OUTPUT.PUT_LINE('Updated ' || SQL%ROWCOUNT || ' rows');
END IF;
```

---

**➡ Transition:** We now know how to track cursor status. But how do we **actually write a complete cursor program** that processes all rows? That's what **explicit cursors** are for.

---

## 5. Explicit Cursor with Manual Control

Here's how to **manually control** every step of the cursor.

### Basic Pattern

```sql
DECLARE
  -- Step 1: Declare cursor
  CURSOR c_emp IS
    SELECT employee_id, first_name, salary
    FROM employees
    WHERE department_id = 10;
  
  -- Step 2: Declare variables to hold each row
  v_id     employees.employee_id%TYPE;
  v_name   employees.first_name%TYPE;
  v_salary employees.salary%TYPE;

BEGIN
  -- Step 3: Open cursor (execute query)
  OPEN c_emp;
  
  -- Step 4: Loop and fetch rows one by one
  LOOP
    FETCH c_emp INTO v_id, v_name, v_salary;
    EXIT WHEN c_emp%NOTFOUND;  -- Exit when no more rows
    
    -- Process each row
    DBMS_OUTPUT.PUT_LINE(v_id || ' - ' || v_name || ' - ' || v_salary);
  END LOOP;
  
  -- Step 5: Close cursor (free memory)
  CLOSE c_emp;
END;
/
```

### What This Code Does

1. **Declare** the cursor (query blueprint)
2. **Open** the cursor (Oracle runs the query)
3. **Loop** through results
   - **Fetch** one row at a time
   - **Check** if more rows exist using `%NOTFOUND`
   - **Process** the row
4. **Close** the cursor (free memory)

### Dry Run Example

```
Database: employees table has 3 employees in dept 10
  ID=1, Name=John, Salary=5000
  ID=2, Name=Jane, Salary=6000
  ID=3, Name=Bob, Salary=5500

OPEN c_emp;
  Result set fetched. Cursor positioned BEFORE Row 1.

Iteration 1:
  FETCH → Cursor moves to Row 1, copy data to v_id, v_name, v_salary
  %NOTFOUND = FALSE, continue
  PRINT: 1 - John - 5000

Iteration 2:
  FETCH → Cursor moves to Row 2, copy data
  %NOTFOUND = FALSE, continue
  PRINT: 2 - Jane - 6000

Iteration 3:
  FETCH → Cursor moves to Row 3, copy data
  %NOTFOUND = FALSE, continue
  PRINT: 3 - Bob - 5500

Iteration 4:
  FETCH → Cursor tries to move past Row 3, no data available
  %NOTFOUND = TRUE, EXIT loop

CLOSE c_emp;
  Memory freed.
```

---

**➡ Transition:** Manual cursor control works, but writing OPEN, FETCH, EXIT, and CLOSE every time is repetitive. Oracle has a **simpler way**: the cursor FOR loop that does this automatically.

---

## 6. Cursor FOR Loop (The Easy Way)

The **Cursor FOR Loop** is the **preferred way** to process cursors. Oracle automatically:
- Opens the cursor
- Fetches each row
- Closes the cursor

### Syntax

```sql
DECLARE
  CURSOR c_emp IS
    SELECT employee_id, first_name, salary
    FROM employees
    WHERE department_id = 10;
BEGIN
  FOR rec IN c_emp LOOP
    DBMS_OUTPUT.PUT_LINE(rec.employee_id || ' - ' || rec.first_name || ' - ' || rec.salary);
  END LOOP;
END;
/
```

### How It Works

- `rec` is a **record variable** that automatically holds one row
- Each iteration:
  - Oracle fetches the next row
  - Copies data into `rec`
  - When no more rows, loop exits automatically
- Cursor closes automatically at end of loop

### Compare: Manual vs FOR Loop

**Manual (verbose):**
```sql
OPEN c_emp;
LOOP
  FETCH c_emp INTO v_id, v_name, v_salary;
  EXIT WHEN c_emp%NOTFOUND;
  DBMS_OUTPUT.PUT_LINE(...);
END LOOP;
CLOSE c_emp;
```

**FOR Loop (clean):**
```sql
FOR rec IN c_emp LOOP
  DBMS_OUTPUT.PUT_LINE(...);
END LOOP;
```

### Inline Cursor FOR Loop

You don't even need to declare a cursor separately:

```sql
BEGIN
  FOR rec IN (SELECT employee_id, first_name, salary FROM employees WHERE department_id = 10)
  LOOP
    DBMS_OUTPUT.PUT_LINE(rec.employee_id || ' - ' || rec.first_name);
  END LOOP;
END;
/
```

This is the **most common pattern** you'll see in production code.

---

**➡ Transition:** Cursor FOR loops handle multiple rows easily. But what if you need **the same cursor to work with different values**? That's where **parameterized cursors** come in.

---

## 7. Parameterized Cursor

A **parameterized cursor** accepts **inputs** so the same cursor can work with different values.

### Why Needed

Without parameters, you must declare a new cursor for each department:
```sql
-- Bad: Repetitive
CURSOR c_emp_dept10 IS SELECT ... WHERE department_id = 10;
CURSOR c_emp_dept20 IS SELECT ... WHERE department_id = 20;
CURSOR c_emp_dept30 IS SELECT ... WHERE department_id = 30;
```

With parameters, one cursor works for all:
```sql
-- Good: Reusable
CURSOR c_emp(p_dept_id NUMBER) IS
  SELECT ... WHERE department_id = p_dept_id;
```

### Syntax

```sql
DECLARE
  -- Cursor accepts parameter
  CURSOR c_emp(p_dept_id NUMBER) IS
    SELECT employee_id, first_name, salary
    FROM employees
    WHERE department_id = p_dept_id;
BEGIN
  -- Pass value when opening
  FOR rec IN c_emp(10) LOOP
    DBMS_OUTPUT.PUT_LINE(rec.first_name || ': ' || rec.salary);
  END LOOP;
  
  -- Same cursor, different value
  FOR rec IN c_emp(20) LOOP
    DBMS_OUTPUT.PUT_LINE(rec.first_name || ': ' || rec.salary);
  END LOOP;
END;
/
```

### Multiple Parameters

```sql
DECLARE
  CURSOR c_emp(p_dept_id NUMBER, p_min_salary NUMBER) IS
    SELECT employee_id, first_name, salary
    FROM employees
    WHERE department_id = p_dept_id AND salary > p_min_salary;
BEGIN
  FOR rec IN c_emp(10, 50000) LOOP
    DBMS_OUTPUT.PUT_LINE(rec.first_name || ': ' || rec.salary);
  END LOOP;
END;
/
```

---

**➡ Transition:** Now we can fetch different rows dynamically. But what if we also want to **update those rows** safely? That's where **FOR UPDATE** comes in to lock rows.

---

## 8. FOR UPDATE (Locking Rows)

### The Problem: Lost Update

In a **multi-user environment**, this can go wrong:

```
Time 1: User A fetches Employee salary = 5000
Time 2: User B fetches Employee salary = 5000
Time 3: User A updates salary to 5500
Time 4: User B updates salary to 6000
Result: User A's update is overwritten. Lost update!
```

### The Solution: Lock the Rows

Add `FOR UPDATE` to the cursor to **lock** rows while you're processing them:

```sql
DECLARE
  CURSOR c_emp IS
    SELECT employee_id, salary
    FROM employees
    WHERE department_id = 10
    FOR UPDATE;  -- ← Lock the rows
BEGIN
  FOR rec IN c_emp LOOP
    UPDATE employees
    SET salary = rec.salary * 1.10
    WHERE CURRENT OF c_emp;  -- Update current row
  END LOOP;
  COMMIT;
END;
/
```

### What `FOR UPDATE` Does

- When you **OPEN** the cursor, Oracle **locks** all rows in the result set
- Other users can **read** the rows but **cannot update** them
- When you **CLOSE** or **COMMIT**, locks are released

### FOR UPDATE Options

| Option | Effect |
| --- | --- |
| `FOR UPDATE` | Lock rows. If locked by another user, wait indefinitely. |
| `FOR UPDATE NOWAIT` | Lock rows. If locked by another user, raise error immediately. |
| `FOR UPDATE WAIT 5` | Lock rows. If locked, wait up to 5 seconds, then error. |
| `FOR UPDATE SKIP LOCKED` | Lock rows. Skip rows already locked by other users. |

### Example with NOWAIT

```sql
BEGIN
  FOR rec IN (
    SELECT employee_id, salary
    FROM employees
    WHERE department_id = 10
    FOR UPDATE NOWAIT  -- Fail immediately if rows locked
  ) LOOP
    UPDATE employees SET salary = rec.salary * 1.10
    WHERE CURRENT OF c_emp;
  END LOOP;
  COMMIT;
EXCEPTION
  WHEN resource_busy THEN
    DBMS_OUTPUT.PUT_LINE('Rows are locked by another user');
END;
/
```

---

**➡ Transition:** The rows are now locked safely. But how do we **update exactly the row the cursor is pointing to**? That's what `WHERE CURRENT OF` does.

---

## 9. WHERE CURRENT OF (Update Current Row)

### The Problem Without WHERE CURRENT OF

```sql
FETCH c_emp INTO rec;
UPDATE employees SET salary = rec.salary * 1.10
WHERE employee_id = rec.employee_id;  -- Wrong if employee moved!
```

If data changes between FETCH and UPDATE, you might update the wrong row.

### The Solution: WHERE CURRENT OF

`WHERE CURRENT OF` updates **only the row the cursor is currently pointing to**:

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
    WHERE CURRENT OF c_emp;  -- ← Updates CURRENT row only
  END LOOP;
  COMMIT;
END;
/
```

### Why It's Better

- **Safer:** Updates exactly the row cursor points to
- **Faster:** No need to match on WHERE clause again
- **Atomic:** Cursor position is guaranteed

### Complete Example: Salary Increase

```sql
DECLARE
  CURSOR c_emp IS
    SELECT employee_id, first_name, salary
    FROM employees
    WHERE department_id = 10
    FOR UPDATE;
BEGIN
  FOR rec IN c_emp LOOP
    UPDATE employees
    SET salary = rec.salary * 1.10
    WHERE CURRENT OF c_emp;
    
    DBMS_OUTPUT.PUT_LINE('Updated ' || rec.first_name || ' to ' || (rec.salary * 1.10));
  END LOOP;
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Salary increases committed');
END;
/
```

---

**➡ Transition:** So far, every cursor has been **permanently attached** to one SQL statement defined at compile time. But what if you need the **SQL itself to change at runtime**? That's where **REF CURSOR** comes in.

---

## 10. REF CURSOR (Dynamic Cursors)

### The Problem: Cursors Are Static

With regular cursors, the SQL is **hardcoded**:

```sql
DECLARE
  CURSOR c_emp IS
    SELECT ... FROM employees WHERE department_id = 10;
BEGIN
  -- SQL is fixed. Always queries department_id = 10.
END;
```

### The Solution: REF CURSOR

A **REF CURSOR** is a **cursor variable** that can **point to different queries**:

```sql
DECLARE
  v_cursor SYS_REFCURSOR;  -- Cursor variable (not a cursor)
BEGIN
  -- First query
  OPEN v_cursor FOR
    SELECT * FROM employees WHERE department_id = 10;
  
  -- Can close and reuse for different query
  CLOSE v_cursor;
  
  -- Second query
  OPEN v_cursor FOR
    SELECT * FROM departments WHERE location_id = 5;
END;
/
```

### Real Use Case: Returning Results from Procedure

**Procedure:**
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
  -- Caller receives the open cursor
END;
/
```

**Caller (in another program):**
```sql
DECLARE
  v_result SYS_REFCURSOR;
  v_id     employees.employee_id%TYPE;
  v_name   employees.first_name%TYPE;
  v_sal    employees.salary%TYPE;
BEGIN
  -- Call procedure, get cursor
  get_emp_by_dept(10, v_result);
  
  -- Fetch from the returned cursor
  LOOP
    FETCH v_result INTO v_id, v_name, v_sal;
    EXIT WHEN v_result%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(v_id || ' - ' || v_name);
  END LOOP;
  
  CLOSE v_result;
END;
/
```

### SYS_REFCURSOR vs Custom Type

- **`SYS_REFCURSOR`** = Built-in, weakly typed (accepts any query)
- **Custom `REF CURSOR TYPE`** = Strongly typed (must match specific columns)

```sql
-- Custom REF CURSOR type (Strongly typed)
TYPE emp_cursor_type IS REF CURSOR RETURN employees%ROWTYPE;

DECLARE
  v_cursor emp_cursor_type;
BEGIN
  OPEN v_cursor FOR
    SELECT * FROM employees WHERE department_id = 10;
  -- Only queries returning employees rows are allowed
END;
/
```

**Interview Tip:** Know that `SYS_REFCURSOR` is simpler but less type-safe. Custom REF CURSOR types catch errors earlier.

---

**➡ Transition:** You now know every major cursor technique. Before finishing, let's look at the practices that make code production-ready.

---

## 11. Best Practices

### 1. Prefer Cursor FOR Loop Over Manual Control

**Avoid:**
```sql
OPEN c_emp;
LOOP
  FETCH c_emp INTO v_id, v_name;
  EXIT WHEN c_emp%NOTFOUND;
  -- process
END LOOP;
CLOSE c_emp;
```

**Prefer:**
```sql
FOR rec IN c_emp LOOP
  -- process
END LOOP;
```

**Why:** Simpler, fewer errors (automatic open/close).

### 2. Prefer Inline Cursors for Simple Queries

**Avoid:**
```sql
DECLARE
  CURSOR c_emp IS SELECT ... WHERE ...;
BEGIN
  FOR rec IN c_emp LOOP ...
```

**Prefer:**
```sql
BEGIN
  FOR rec IN (SELECT ... WHERE ...) LOOP ...
```

**Why:** Less code, clearer intent.

### 3. Use Parameterized Cursors for Reusability

**Avoid:**
```sql
CURSOR c_emp_10 IS SELECT ... WHERE dept = 10;
CURSOR c_emp_20 IS SELECT ... WHERE dept = 20;
```

**Prefer:**
```sql
CURSOR c_emp(p_dept_id NUMBER) IS
  SELECT ... WHERE dept = p_dept_id;
```

### 4. Always Use FOR UPDATE + WHERE CURRENT OF for Updates

**Avoid:**
```sql
FETCH c_emp INTO rec;
UPDATE employees SET salary = 100 WHERE employee_id = rec.id;
```

**Prefer:**
```sql
FOR rec IN (SELECT ... FOR UPDATE) LOOP
  UPDATE employees SET salary = 100 WHERE CURRENT OF c_emp;
END LOOP;
```

### 5. Prefer Set-Based SQL Over Cursors

**Avoid (row-by-row):**
```sql
FOR rec IN (SELECT * FROM employees WHERE dept = 10) LOOP
  UPDATE employees SET salary = salary * 1.10 WHERE employee_id = rec.id;
END LOOP;
```

**Prefer (set-based):**
```sql
UPDATE employees SET salary = salary * 1.10 WHERE department_id = 10;
```

**Why:** Faster (fewer context switches), simpler.

### 6. Handle Exceptions in Cursor Loops

```sql
BEGIN
  FOR rec IN c_emp LOOP
    BEGIN
      -- Risky operation
      UPDATE employees SET salary = rec.salary * 1.10
      WHERE CURRENT OF c_emp;
    EXCEPTION
      WHEN others THEN
        DBMS_OUTPUT.PUT_LINE('Error processing ' || rec.id);
    END;
  END LOOP;
  COMMIT;
EXCEPTION
  WHEN others THEN
    ROLLBACK;
END;
/
```

### 7. Close Cursors Explicitly in Error Cases

```sql
BEGIN
  OPEN c_emp;
  LOOP
    FETCH c_emp INTO rec;
    EXIT WHEN c_emp%NOTFOUND;
    -- Some code that might error
  END LOOP;
  CLOSE c_emp;
EXCEPTION
  WHEN others THEN
    IF c_emp%ISOPEN THEN
      CLOSE c_emp;
    END IF;
    RAISE;
END;
/
```

---

## 12. Common Mistakes

### Mistake 1: Using SELECT INTO for Multiple Rows

```sql
-- ❌ WRONG
SELECT employee_id, salary
INTO v_id, v_salary
FROM employees
WHERE department_id = 10;
-- TOO_MANY_ROWS error if 10 is not exactly 1 row
```

**Fix:** Use a cursor.

### Mistake 2: Forgetting to Close Cursor

```sql
-- ❌ WRONG
BEGIN
  FOR rec IN (SELECT * FROM employees) LOOP
    -- Never explicitly closes
  END LOOP;
END;
```

**Fix:** FOR loop closes automatically. Manual loops: always close.

### Mistake 3: Fetching Before OPEN

```sql
-- ❌ WRONG
DECLARE
  CURSOR c_emp IS SELECT * FROM employees;
BEGIN
  FETCH c_emp INTO rec;  -- NOT OPEN YET!
  OPEN c_emp;
END;
```

**Fix:** Always OPEN before FETCH.

### Mistake 4: Opening Cursor Twice

```sql
-- ❌ WRONG
OPEN c_emp;
OPEN c_emp;  -- Cursor already open!
```

**Fix:** Check with `%ISOPEN` or close first.

### Mistake 5: Using Row-by-Row When Set-Based Works

```sql
-- ❌ SLOW
FOR rec IN (SELECT * FROM employees WHERE dept = 10) LOOP
  DELETE FROM employee_audit WHERE emp_id = rec.id;
END LOOP;

-- ✅ FAST
DELETE FROM employee_audit WHERE emp_id IN (
  SELECT employee_id FROM employees WHERE dept = 10
);
```

### Mistake 6: Not Handling FOR UPDATE Locks

```sql
-- ❌ WRONG - Locks forever
DECLARE
  CURSOR c_emp IS SELECT * FROM employees FOR UPDATE;
BEGIN
  FOR rec IN c_emp LOOP
    -- If error here, locks stay until session closes
  END LOOP;
END;
```

**Fix:** Add exception handling and always COMMIT/ROLLBACK.

---

## 13. Interview Q&A

### Conceptual

**Q: What's the difference between a cursor and a result set?**

A: 
- **Result set** = All the data returned by your query (static, in memory)
- **Cursor** = A pointer + mechanism to read one row at a time (dynamic)

---

**Q: Why use a cursor instead of SELECT INTO?**

A: `SELECT INTO` requires exactly one row. If you need to process multiple rows, use a cursor.

---

**Q: What happens when you OPEN a cursor?**

A: Oracle executes the query, fetches all rows into memory, and positions the cursor at the first row.

---

**Q: What's the difference between %FOUND and %NOTFOUND?**

A: `%FOUND` = last FETCH got a row. `%NOTFOUND` = last FETCH got no rows.

---

**Q: Why use FOR UPDATE?**

A: To lock rows so other users can't modify them while you're processing.

---

**Q: What's WHERE CURRENT OF?**

A: It updates/deletes exactly the row your cursor is currently pointing to.

---

### Comparison

**Q: Explicit cursor vs Cursor FOR loop?**

A:
- **Explicit (manual):** You control OPEN, FETCH, CLOSE. More code, more control.
- **FOR Loop:** Oracle handles open/fetch/close automatically. Less code, preferred.

---

**Q: Regular cursor vs REF CURSOR?**

A:
- **Regular cursor:** SQL is hardcoded at compile time.
- **REF CURSOR:** SQL can change at runtime. Used to return cursors from procedures.

---

**Q: FOR UPDATE NOWAIT vs FOR UPDATE WAIT?**

A:
- **NOWAIT:** Fail immediately if rows locked.
- **WAIT N:** Wait N seconds, then fail if still locked.
- **SKIP LOCKED:** Process unlocked rows, skip locked ones.

---

### Scenario

**Q: You need to update 10,000 employees. Cursor or direct UPDATE?**

A: Direct `UPDATE employees SET ...` is better. Cursors process row-by-row (slow for bulk operations).

---

**Q: You need to call a procedure from Java and get results. What's the best approach?**

A: Use REF CURSOR. Procedure returns an open cursor, Java reads from it.

---

**Q: Multiple concurrent users are updating the same table. How do you prevent lost updates?**

A: Use `FOR UPDATE` in the cursor to lock rows during processing.

---

### Best Practices

**Q: Should you always use FOR UPDATE?**

A: Only if you're **modifying** the rows. If just reading, FOR UPDATE wastes resources locking unnecessarily.

---

**Q: Can a cursor parameter be a table name or column name?**

A: No. Cursor parameters accept **values only** (numbers, strings, etc.), not identifiers.

---

---

## 14. Revision Summary

### 1-Minute Revision

**Cursor = A pointer to query results. Process rows one-by-one.**

1. **Why:** `SELECT INTO` works only for single rows. Use cursor for multiple rows.
2. **What:** Pointer to result set, tracks current row position.
3. **Lifecycle:** DECLARE → OPEN → FETCH loop → CLOSE
4. **Attributes:** `%FOUND`, `%NOTFOUND`, `%ROWCOUNT`, `%ISOPEN`
5. **Best way:** Cursor FOR loop (automatic open/fetch/close)
6. **Parameters:** Make cursor reusable with `CURSOR c(param) IS ...`
7. **Updates:** Use `FOR UPDATE` to lock rows, `WHERE CURRENT OF` to update current row.
8. **Dynamic:** REF CURSOR for SQL that changes at runtime.

### Interview Keywords

- Implicit cursor (automatic, DML only)
- Explicit cursor (declare, open, fetch, close)
- Cursor FOR loop (simplest method)
- Cursor attributes (tracking status)
- FOR UPDATE (row locking)
- WHERE CURRENT OF (update current row)
- REF CURSOR (dynamic queries)
- SYS_REFCURSOR (built-in, weakly typed)

### Important Syntax

```sql
-- Declare and use explicit cursor
DECLARE
  CURSOR c_emp(p_dept NUMBER) IS
    SELECT employee_id, salary FROM employees WHERE department_id = p_dept;
BEGIN
  FOR rec IN c_emp(10) LOOP
    DBMS_OUTPUT.PUT_LINE(rec.employee_id);
  END LOOP;
END;
/

-- With updates and locks
DECLARE
  CURSOR c_emp IS
    SELECT employee_id, salary FROM employees WHERE department_id = 10
    FOR UPDATE;
BEGIN
  FOR rec IN c_emp LOOP
    UPDATE employees SET salary = salary * 1.10
    WHERE CURRENT OF c_emp;
  END LOOP;
  COMMIT;
END;
/

-- REF CURSOR from procedure
CREATE OR REPLACE PROCEDURE get_emps(p_dept IN NUMBER, p_result OUT SYS_REFCURSOR) AS
BEGIN
  OPEN p_result FOR
    SELECT employee_id, salary FROM employees WHERE department_id = p_dept;
END;
/
```

---

## Related Notes

- Control flow foundation: [Operators, Control Statements and Loops](../04%20Control%20Statements/01_Operators_Control_Statements_and_Loops.md)
- PL/SQL basics: [PL/SQL Basics and Data Types](../01%20Basics/01_PLSQL_Basics_and_Data_Types.md)
- SQL performance context: [Indexes and Execution Plans](../../sql/08%20Indexes/01_Indexes_and_Execution_Plans.md)
