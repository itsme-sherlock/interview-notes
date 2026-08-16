# SQL MERGE and Upsert Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **MERGE** = Conditional INSERT/UPDATE/DELETE based on whether rows match a join condition; all-in-one DML operation.
- **Upsert** = "Update or Insert" logic; if row exists, update; if not, insert (MERGE does this perfectly).
- **Syntax:** MERGE INTO target USING source ON join_condition WHEN MATCHED THEN ... WHEN NOT MATCHED THEN ...
- **MATCHED clause** = Executes when join condition is TRUE (row exists); can UPDATE or DELETE.
- **NOT MATCHED clause** = Executes when join condition is FALSE (row doesn't exist); can INSERT.
- **Performance** = Single pass through data (vs separate INSERT + UPDATE); atomic operation (all-or-nothing).
- **Use cases** = Data loads/ETL, reconciliation, bulk updates with conditional logic, dimension table management.
- **Atomicity** = All inserts/updates/deletes in one transaction; if error, entire MERGE rolls back.
- **Interview keywords** = Upsert, conditional DML, ETL, merge join, WHEN MATCHED vs NOT MATCHED, performance vs separate DML.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need MERGE?](#1-why-do-we-need-merge)
2. [What Is MERGE?](#2-what-is-merge)
3. [MERGE Syntax and Structure](#3-merge-syntax-and-structure)
4. [WHEN MATCHED: Updating Existing Rows](#4-when-matched-updating-existing-rows)
5. [WHEN NOT MATCHED: Inserting New Rows](#5-when-not-matched-inserting-new-rows)
6. [Complete MERGE: Insert + Update](#6-complete-merge-insert--update)
7. [MERGE with DELETE (Matched Only)](#7-merge-with-delete-matched-only)
8. [Conditional Execution (Additional WHERE)](#8-conditional-execution-additional-where)
9. [MERGE Performance and Optimization](#9-merge-performance-and-optimization)
10. [MERGE vs Separate INSERT/UPDATE](#10-merge-vs-separate-insertupdate)
11. [Common Mistakes](#11-common-mistakes)
12. [Interview Q&A](#12-interview-qa)
13. [Revision Summary](#13-revision-summary)

---

## 1. Why Do We Need MERGE?

### The Problem: Load/Update Logic Requires Multiple Statements

**Scenario:** You're loading customer data from a staging table into production.

**Requirements:**
- If customer exists (by ID), update their name and email
- If customer doesn't exist, insert new record
- If customer exists but is inactive, delete them

```sql
-- WITHOUT MERGE (pseudo-code - multiple steps)
-- Step 1: Insert new customers
INSERT INTO customers (customer_id, name, email)
SELECT customer_id, name, email FROM staging_customers
WHERE customer_id NOT IN (SELECT customer_id FROM customers);

-- Step 2: Update existing customers
UPDATE customers c
SET name = (SELECT name FROM staging_customers s WHERE s.customer_id = c.customer_id)
WHERE customer_id IN (SELECT customer_id FROM staging_customers);

-- Step 3: Delete inactive
DELETE FROM customers
WHERE customer_id IN (SELECT customer_id FROM staging_customers WHERE status = 'inactive');

-- Step 4: Commit (if all succeed)
COMMIT;
```

**Problems:**
- Multiple separate DML statements (error in step 2 leaves step 1 changes)
- Hard to debug (which step failed?)
- Performance overhead (multiple table scans)
- Inconsistent state if one step fails (no atomicity)

### The Solution: MERGE Does It All Atomically

```sql
-- WITH MERGE (one atomic operation)
MERGE INTO customers c
USING staging_customers s
  ON (c.customer_id = s.customer_id)
WHEN MATCHED AND s.status = 'inactive' THEN
  DELETE
WHEN MATCHED THEN
  UPDATE SET c.name = s.name, c.email = s.email
WHEN NOT MATCHED THEN
  INSERT (customer_id, name, email) VALUES (s.customer_id, s.name, s.email);

COMMIT;
```

**Benefits:**
- One operation (atomic: all-or-nothing)
- Clearer intent
- Better performance (one scan)
- Easier to debug

### Real-World Scenarios

- **ETL Pipelines:** Dimension table loads (slowly changing dimensions)
- **Data Sync:** Replicate data from staging to production
- **Reconciliation:** Match two tables; insert missing, update mismatches
- **Bulk Operations:** Upsert millions of rows efficiently

---

**➡ Transition:** Let's understand MERGE structure.

---

## 2. What Is MERGE?

### Simple Definition

**MERGE** is a SQL statement that combines INSERT, UPDATE, and DELETE based on a join condition. It's the most efficient way to conditionally modify data.

### Key Concept: Join-Based Logic

```
MERGE INTO target_table
USING source_table
  ON join_condition
WHEN MATCHED THEN    -- If join condition is TRUE
  UPDATE or DELETE
WHEN NOT MATCHED THEN -- If join condition is FALSE
  INSERT
```

**Think of it as:** 
- Find matches based on join condition
- For matches: UPDATE or DELETE
- For non-matches: INSERT

---

**➡ Transition:** Let's learn the syntax.

---

## 3. MERGE Syntax and Structure

### Complete Syntax

```sql
MERGE INTO target_table [t_alias]
USING source_table [s_alias]
  ON (join_condition)
WHEN MATCHED [AND additional_condition] THEN
  UPDATE SET column1 = value1, column2 = value2
  DELETE
WHEN NOT MATCHED [AND additional_condition] THEN
  INSERT (column_list) VALUES (value_list);
```

### Required Components

1. **MERGE INTO:** Target table (where changes go)
2. **USING:** Source table (where data comes from)
3. **ON:** Join condition (how to match rows)
4. **WHEN clause:** What action to take

### Example: Basic Structure

```sql
-- Example
MERGE INTO customers c
USING new_customers n
  ON (c.customer_id = n.customer_id)  -- Join condition
WHEN MATCHED THEN
  UPDATE SET c.name = n.name
WHEN NOT MATCHED THEN
  INSERT (customer_id, name) VALUES (n.customer_id, n.name);
```

---

**➡ Transition:** WHEN MATCHED is for existing rows.

---

## 4. WHEN MATCHED: Updating Existing Rows

### Simple UPDATE

```sql
MERGE INTO employees e
USING updated_employees u
  ON (e.employee_id = u.employee_id)
WHEN MATCHED THEN
  UPDATE SET 
    e.name = u.name,
    e.salary = u.salary,
    e.department_id = u.department_id;
```

**Execution:**
- For each row in updated_employees
- If matching employee_id exists in employees
- Execute UPDATE statement

### Conditional UPDATE (WHEN MATCHED AND ...)

```sql
MERGE INTO employees e
USING payroll_updates p
  ON (e.employee_id = p.employee_id)
WHEN MATCHED AND p.raise_type = 'MERIT' THEN
  UPDATE SET e.salary = e.salary * 1.10  -- 10% raise
WHEN MATCHED AND p.raise_type = 'COL' THEN
  UPDATE SET e.salary = e.salary * 1.05  -- 5% raise
WHEN MATCHED THEN
  -- Default: no action
  UPDATE SET e.last_updated = SYSDATE;
```

**Key Insight:** Multiple WHEN MATCHED clauses; each can have its own condition.

### Example: Update Only Changed Rows

```sql
MERGE INTO products p
USING product_updates u
  ON (p.product_id = u.product_id)
WHEN MATCHED AND p.price <> u.new_price THEN
  UPDATE SET 
    p.price = u.new_price,
    p.updated_date = SYSDATE;
```

---

**➡ Transition:** NOT MATCHED handles new rows.

---

## 5. WHEN NOT MATCHED: Inserting New Rows

### Simple INSERT

```sql
MERGE INTO customers c
USING new_customers n
  ON (c.customer_id = n.customer_id)
WHEN NOT MATCHED THEN
  INSERT (customer_id, name, email, created_date)
  VALUES (n.customer_id, n.name, n.email, SYSDATE);
```

**Execution:**
- For each row in new_customers
- If customer_id does NOT exist in customers
- Execute INSERT statement

### Conditional INSERT

```sql
MERGE INTO customers c
USING new_customers n
  ON (c.customer_id = n.customer_id)
WHEN NOT MATCHED AND n.customer_type = 'VIP' THEN
  INSERT (customer_id, name, category) 
  VALUES (n.customer_id, n.name, 'VIP')
WHEN NOT MATCHED THEN
  INSERT (customer_id, name, category) 
  VALUES (n.customer_id, n.name, 'STANDARD');
```

### Multiple NOT MATCHED Clauses

```sql
MERGE INTO employees e
USING candidates c
  ON (e.employee_id = c.candidate_id)
WHEN NOT MATCHED AND c.experience >= 5 THEN
  INSERT (employee_id, name, level) VALUES (c.candidate_id, c.name, 'SENIOR')
WHEN NOT MATCHED AND c.experience >= 2 THEN
  INSERT (employee_id, name, level) VALUES (c.candidate_id, c.name, 'MID')
WHEN NOT MATCHED THEN
  INSERT (employee_id, name, level) VALUES (c.candidate_id, c.name, 'JUNIOR');
```

---

**➡ Transition:** Complete MERGE combines INSERT and UPDATE.

---

## 6. Complete MERGE: Insert + Update

### Upsert Pattern (Most Common)

```sql
-- Q: Load/sync customer data (insert new, update existing)
MERGE INTO customers c
USING new_customer_data n
  ON (c.customer_id = n.customer_id)
WHEN MATCHED THEN
  UPDATE SET 
    c.name = n.name,
    c.email = n.email,
    c.phone = n.phone,
    c.updated_date = SYSDATE
WHEN NOT MATCHED THEN
  INSERT (customer_id, name, email, phone, created_date)
  VALUES (n.customer_id, n.name, n.email, n.phone, SYSDATE);
```

**Result:**
- Existing customers: Updated with new data
- New customers: Inserted into table

### Example: Customer Master Load

```sql
MERGE INTO customer_master cm
USING staging_customers sc
  ON (cm.customer_id = sc.customer_id)
WHEN MATCHED AND cm.last_updated < sc.updated_date THEN
  UPDATE SET 
    cm.name = sc.name,
    cm.email = sc.email,
    cm.address = sc.address,
    cm.last_updated = SYSDATE
WHEN NOT MATCHED THEN
  INSERT (customer_id, name, email, address, created_date, status)
  VALUES (sc.customer_id, sc.name, sc.email, sc.address, SYSDATE, 'ACTIVE');
```

---

**➡ Transition:** MERGE can also delete rows.

---

## 7. MERGE with DELETE (Matched Only)

### DELETE Clause (Only in WHEN MATCHED)

```sql
-- Note: DELETE only works in WHEN MATCHED; requires actual match
MERGE INTO employees e
USING inactive_list i
  ON (e.employee_id = i.employee_id)
WHEN MATCHED THEN
  DELETE
WHEN NOT MATCHED THEN
  -- Can't do anything here (rows don't exist)
  -- This clause is ignored if DELETE is in MATCHED
```

### Full ETL with INSERT, UPDATE, DELETE

```sql
MERGE INTO customer_dim cd
USING customer_staging cs
  ON (cd.customer_id = cs.customer_id)
WHEN MATCHED AND cs.status = 'ACTIVE' THEN
  UPDATE SET 
    cd.name = cs.name,
    cd.city = cs.city,
    cd.updated_date = SYSDATE
WHEN MATCHED AND cs.status = 'INACTIVE' THEN
  DELETE  -- Remove inactive customers
WHEN NOT MATCHED AND cs.status = 'ACTIVE' THEN
  INSERT (customer_id, name, city, created_date, status)
  VALUES (cs.customer_id, cs.name, cs.city, SYSDATE, 'ACTIVE');
```

**Flow:**
- Active + exists: UPDATE
- Inactive + exists: DELETE
- Active + doesn't exist: INSERT
- Inactive + doesn't exist: (no action)

---

## 8. Conditional Execution (Additional WHERE)

### WHEN AND Conditions

```sql
-- Update only if salary changed significantly (> 5%)
MERGE INTO employees e
USING new_salaries ns
  ON (e.employee_id = ns.employee_id)
WHEN MATCHED AND ABS((ns.salary - e.salary) / e.salary) > 0.05 THEN
  UPDATE SET e.salary = ns.salary, e.updated_date = SYSDATE
WHEN NOT MATCHED THEN
  INSERT (employee_id, salary) VALUES (ns.employee_id, ns.salary);
```

### Multiple Conditions

```sql
MERGE INTO products p
USING price_updates pu
  ON (p.product_id = pu.product_id)
WHEN MATCHED AND pu.price > p.cost AND p.status = 'ACTIVE' THEN
  UPDATE SET p.price = pu.price, p.updated_date = SYSDATE
WHEN NOT MATCHED AND pu.quantity_available > 0 THEN
  INSERT (product_id, name, price) 
  VALUES (pu.product_id, pu.name, pu.price);
```

---

## 9. MERGE Performance and Optimization

### One Pass Through Data

**MERGE advantage:** Scans target once; checks join condition for each source row.

```sql
-- FAST: One scan of both tables
MERGE INTO target t
USING source s ON t.id = s.id
WHEN MATCHED THEN UPDATE SET ...
WHEN NOT MATCHED THEN INSERT ...;

-- Equivalent separate statements (slower: 3+ scans)
INSERT INTO target SELECT * FROM source WHERE id NOT IN (SELECT id FROM target);
UPDATE target SET ... WHERE id IN (SELECT id FROM source);
DELETE FROM target WHERE id IN (SELECT id FROM source WHERE status = 'DELETE');
```

### Index Optimization

```sql
-- Ensure join columns are indexed for fast matching
CREATE INDEX idx_target_id ON target(id);
CREATE INDEX idx_source_id ON source(id);
```

---

## 10. MERGE vs Separate INSERT/UPDATE

### Performance Comparison

| Aspect | MERGE | Separate DML |
| --- | --- | --- |
| **Passes** | 1 pass | 2+ passes |
| **Atomicity** | Atomic (all-or-nothing) | Per statement (risk of inconsistency) |
| **Overhead** | Single parse/execute | Multiple parse/execute |
| **Readability** | Clear intent | Logic scattered |
| **Rollback** | Entire MERGE rolls back | Rollback each statement separately |

### Example Comparison

```sql
-- MERGE (preferred)
MERGE INTO customers c USING new_customers n
  ON (c.id = n.id)
WHEN MATCHED THEN UPDATE SET c.name = n.name
WHEN NOT MATCHED THEN INSERT (id, name) VALUES (n.id, n.name);

-- Separate (old approach)
INSERT INTO customers (id, name)
SELECT id, name FROM new_customers WHERE id NOT IN (SELECT id FROM customers);

UPDATE customers c SET name = (SELECT name FROM new_customers WHERE id = c.id)
WHERE id IN (SELECT id FROM new_customers);

-- Issues with separate approach:
-- 1. INSERT runs first; if fails, UPDATE never runs
-- 2. Multiple scans of tables
-- 3. If UPDATE fails, INSERT already committed (inconsistency)
```

---

## 11. Common Mistakes

### Mistake 1: Using = in ON Clause (Not LIKE or Range)

```sql
-- ❌ WRONG (LIKE doesn't work in ON)
MERGE INTO customers c
USING new_customers n
  ON (c.name LIKE n.name)  -- Can't use pattern matching in join

-- ✅ CORRECT (use =, <, >, BETWEEN, etc.)
MERGE INTO customers c
USING new_customers n
  ON (c.customer_id = n.customer_id)
```

---

### Mistake 2: Multiple Matched Without AND Conditions

```sql
-- ❌ WRONG (ambiguous; which WHEN MATCHED executes?)
MERGE INTO employees e
USING updates u ON e.id = u.id
WHEN MATCHED THEN UPDATE SET e.name = u.name
WHEN MATCHED THEN UPDATE SET e.salary = u.salary;  -- Duplicate; error

-- ✅ CORRECT (use AND to differentiate)
MERGE INTO employees e
USING updates u ON e.id = u.id
WHEN MATCHED AND u.type = 'NAME' THEN UPDATE SET e.name = u.name
WHEN MATCHED AND u.type = 'SALARY' THEN UPDATE SET e.salary = u.salary;
```

---

### Mistake 3: DELETE in NOT MATCHED (Doesn't Make Sense)

```sql
-- ❌ WRONG (can't delete rows that don't exist)
MERGE INTO target t
USING source s ON t.id = s.id
WHEN NOT MATCHED THEN
  DELETE;  -- Error: no rows to delete

-- ✅ CORRECT (DELETE only in WHEN MATCHED)
MERGE INTO target t
USING source s ON t.id = s.id
WHEN MATCHED THEN
  DELETE;
```

---

### Mistake 4: Referencing Target Table in WHEN NOT MATCHED

```sql
-- ❌ WRONG (target row doesn't exist; can't reference)
MERGE INTO target t
USING source s ON t.id = s.id
WHEN NOT MATCHED THEN
  INSERT (id, value) VALUES (s.id, t.old_value);  -- t.old_value doesn't exist!

-- ✅ CORRECT (reference source only)
MERGE INTO target t
USING source s ON t.id = s.id
WHEN NOT MATCHED THEN
  INSERT (id, value) VALUES (s.id, s.value);
```

---

### Mistake 5: Not Handling Duplicates in Source

```sql
-- ❌ PROBLEM (if source has 2 rows with same ID, which one wins?)
MERGE INTO customers c
USING staging_customers s ON c.customer_id = s.customer_id
WHEN MATCHED THEN UPDATE SET c.name = s.name;
-- If staging has ID 1 twice, behavior is unpredictable

-- ✅ SOLUTION (ensure source is unique)
MERGE INTO customers c
USING (SELECT DISTINCT customer_id, name FROM staging_customers) s 
  ON c.customer_id = s.customer_id
WHEN MATCHED THEN UPDATE SET c.name = s.name;
```

---

## 12. Interview Q&A

### Q1: What does MERGE do and why is it better than separate INSERT/UPDATE?

**A:** MERGE combines INSERT, UPDATE, and DELETE in one atomic operation. It's better because:
1. **One pass:** Only scans table once (vs 2+ for separate statements)
2. **Atomic:** All-or-nothing (if error, entire MERGE rolls back)
3. **Clearer:** Intent is obvious (upsert logic is explicit)

**Example:**
```sql
-- MERGE (good)
MERGE INTO t USING s ON t.id = s.id
WHEN MATCHED THEN UPDATE SET ...
WHEN NOT MATCHED THEN INSERT ...;

-- Separate (risky)
INSERT INTO t SELECT * FROM s WHERE id NOT IN (SELECT id FROM t);
UPDATE t SET ... WHERE id IN (SELECT id FROM s);
-- If INSERT succeeds but UPDATE fails, inconsistency
```

---

### Q2: What's the difference between WHEN MATCHED and WHEN NOT MATCHED?

**A:**
- **WHEN MATCHED:** Row exists (join condition TRUE); can UPDATE or DELETE
- **WHEN NOT MATCHED:** Row doesn't exist (join condition FALSE); can INSERT

---

### Q3: Can you use DELETE in WHEN NOT MATCHED?

**A:** No. DELETE only makes sense in WHEN MATCHED (when rows exist). You can't delete rows that don't exist.

---

### Q4: How do you handle conditional logic in MERGE?

**A:** Use AND conditions:

```sql
WHEN MATCHED AND condition THEN ...
WHEN NOT MATCHED AND condition THEN ...
```

Multiple clauses are evaluated top-to-bottom; first match is used.

---

### Q5: What happens if the source has duplicate keys?

**A:** Behavior is unpredictable (depends on order). Use DISTINCT or aggregate in source:

```sql
MERGE INTO t USING (SELECT DISTINCT id, name FROM source) s ...
```

---

### Q6: Is MERGE better than separate INSERT/UPDATE for performance?

**A:** Usually yes (one pass), but test both. MERGE may not always be faster than optimized separate statements in specific scenarios.

For ETL and bulk operations, MERGE is preferred.

---

### Q7: Can MERGE source be a JOIN of multiple tables?

**A:** Yes:

```sql
MERGE INTO customers c
USING (
    SELECT s.customer_id, s.name, p.country
    FROM staging_customers s
    JOIN postal_codes p ON s.postal_code = p.postal_code
) src
ON c.customer_id = src.customer_id
WHEN MATCHED THEN UPDATE SET ...
WHEN NOT MATCHED THEN INSERT ...;
```

---

### Q8: How do you rollback a MERGE if something goes wrong?

**A:** Entire MERGE is atomic. If error occurs, entire operation rolls back:

```sql
BEGIN
    MERGE INTO customers c
    USING new_customers n ON c.id = n.id
    WHEN MATCHED THEN UPDATE ...
    WHEN NOT MATCHED THEN INSERT ...;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
```

---

### Q9: What's the output of a MERGE statement?

**A:** MERGE returns the number of rows affected (inserted + updated + deleted), but you can use RETURNING clause:

```sql
MERGE INTO customers c
USING new_customers n ON c.customer_id = n.customer_id
WHEN MATCHED THEN UPDATE SET c.name = n.name
WHEN NOT MATCHED THEN INSERT (customer_id, name) VALUES (n.customer_id, n.name)
RETURNING c.customer_id, 'INSERT' AS action INTO merged_customers;
-- Captures which rows were inserted/updated
```

---

### Q10: How would you handle a slowly changing dimension (Type 2) with MERGE?

**A:**

```sql
MERGE INTO customer_dim cd
USING new_customers nc ON cd.customer_id = nc.customer_id 
  AND cd.end_date IS NULL  -- Current row
WHEN MATCHED AND cd.name <> nc.name THEN
  UPDATE SET cd.end_date = SYSDATE - 1  -- Close old version
WHEN NOT MATCHED THEN
  INSERT (customer_id, name, start_date, end_date) 
  VALUES (nc.customer_id, nc.name, SYSDATE, NULL);  -- New row
```

---

## 13. Revision Summary

### Key Takeaways

1. **MERGE** = Conditional INSERT/UPDATE/DELETE based on join condition
2. **Upsert** = Insert if new, update if exists (MERGE does this perfectly)
3. **WHEN MATCHED** = Row exists; can UPDATE or DELETE
4. **WHEN NOT MATCHED** = Row doesn't exist; can INSERT
5. **Atomic** = All-or-nothing; if error, entire MERGE rolls back
6. **Performance** = One pass through table (better than separate DML)
7. **Multiple conditions** = Use AND to differentiate WHEN clauses
8. **Source uniqueness** = Ensure no duplicate keys in source
9. **Use cases** = ETL, data loads, dimension table management, reconciliation
10. **vs INSERT/UPDATE/DELETE** = Faster, clearer, atomic vs scattered logic

### MERGE Pattern Template

```sql
MERGE INTO target_table t
USING source_table s
  ON (t.id = s.id)
WHEN MATCHED AND condition THEN
  UPDATE SET column1 = s.column1
WHEN MATCHED THEN
  DELETE  -- Optional
WHEN NOT MATCHED AND condition THEN
  INSERT (columns) VALUES (s.columns)
WHEN NOT MATCHED THEN
  INSERT (columns) VALUES (s.columns);
```
