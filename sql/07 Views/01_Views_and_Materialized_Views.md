# Oracle Views Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **View** = Virtual table (stores query, not data). Always reflects latest source data.
- **Materialized View** = Physical table (stores data). Needs refresh for latest data.
- **Why views:** Security (hide columns), simplification (complex queries), abstraction (schema changes).
- **Updatable views:** Single-table views only. No aggregates, joins, GROUP BY.
- **WITH CHECK OPTION** = Prevents INSERT/UPDATE that violate view's WHERE condition.
- **WITH READ ONLY** = Prevents all DML (no INSERT/UPDATE/DELETE).
- **Materialized view refresh methods:** Complete (full re-execute), Fast (only changes), Force (fast if possible, else complete).

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Views?](#1-why-do-we-need-views)
2. [What is a View?](#2-what-is-a-view)
3. [Creating Views](#3-creating-views)
4. [Simple Views vs Complex Views](#4-simple-views-vs-complex-views)
5. [Updatable Views](#5-updatable-views)
6. [WITH CHECK OPTION](#6-with-check-option)
7. [WITH READ ONLY](#7-with-read-only)
8. [Updating Views with Joins](#8-updating-views-with-joins)
9. [Why Materialized Views?](#9-why-materialized-views)
10. [Materialized View vs Regular View](#10-materialized-view-vs-regular-view)
11. [Creating Materialized Views](#11-creating-materialized-views)
12. [Refreshing Materialized Views](#12-refreshing-materialized-views)
13. [View Invalidation](#13-view-invalidation)
14. [Best Practices](#14-best-practices)
15. [Common Mistakes](#15-common-mistakes)
16. [Interview Q&A](#16-interview-qa)
17. [Revision Summary](#17-revision-summary)
18. [Related Notes](#18-related-notes)

---

## 1. Why Do We Need Views?

### The Problem: Raw Data Access Issues

Without views, users have direct access to base tables:

```sql
-- Direct access to employees table
SELECT * FROM employees;
-- Everyone sees all columns: ID, name, salary, SSN, home address, phone
-- Security risk!
```

Problems:
- **Security:** Users see all columns (including sensitive data like SSN)
- **Complexity:** Users must understand complex joins and business logic
- **Maintenance:** Schema changes break user queries
- **Duplication:** Users repeatedly write the same complex queries

### The Solution: Views

A **view** is a **virtual table** that sits between users and actual tables:

```
User → View (SELECT ...) → Base Tables
```

Benefits:
1. **Security:** Show only needed columns
2. **Simplification:** Encapsulate complex logic
3. **Abstraction:** Hide schema changes
4. **Reusability:** Write once, use many times

---

**➡ Transition:** Now that we know why views exist, what exactly **is** a view and how does Oracle handle it?

---

## 2. What is a View?

### Simple Definition

A **view** is a **named SQL query** stored in the database. It appears to be a table but contains no actual data—only a query definition.

When you query a view, Oracle executes the underlying query and returns results in real-time.

### Key Characteristics

- **Virtual:** No data storage (unless it's a materialized view)
- **Query-based:** Stores SELECT statement
- **Dynamic:** Always shows latest data from base tables
- **Reusable:** Multiple users can query the same view
- **Queryable:** Can SELECT, and sometimes UPDATE/INSERT/DELETE

### Real-World Analogy

- **Table** = An actual filing cabinet with papers inside
- **View** = A window into the filing cabinet showing only specific papers in a specific order

### Syntax: Create a View

```sql
CREATE OR REPLACE VIEW view_name AS
  SELECT columns FROM base_table WHERE conditions;
```

### Example

```sql
CREATE OR REPLACE VIEW emp_dept_10 AS
  SELECT employee_id, first_name, last_name, salary
  FROM employees
  WHERE department_id = 10;
```

### Using the View

```sql
SELECT * FROM emp_dept_10;
-- Oracle runs the underlying query and returns results
```

---

**➡ Transition:** Views let us SELECT from them. But **how do we create views** and what options do we have?

---

## 3. Creating Views

### Basic Syntax

```sql
CREATE OR REPLACE VIEW view_name AS
  SELECT column1, column2, ...
  FROM table_name
  WHERE conditions;
```

### CREATE vs CREATE OR REPLACE

**CREATE:**
```sql
CREATE VIEW emp_view AS
  SELECT * FROM employees WHERE department_id = 10;
-- Fails if view already exists
```

**CREATE OR REPLACE:**
```sql
CREATE OR REPLACE VIEW emp_view AS
  SELECT * FROM employees WHERE department_id = 10;
-- Creates if doesn't exist; updates if it does (if compatible)
```

**Prefer CREATE OR REPLACE** for development—fewer errors.

### Modifying a View

```sql
-- Drop and recreate
DROP VIEW emp_view;

CREATE VIEW emp_view AS
  SELECT employee_id, first_name, department_id, salary
  FROM employees
  WHERE department_id = 10;
```

### Dropping a View

```sql
DROP VIEW emp_view;
```

### Querying a View

```sql
SELECT * FROM emp_view;

SELECT * FROM emp_view WHERE salary > 50000;

SELECT COUNT(*) FROM emp_view;
```

---

**➡ Transition:** We can create views from single or multiple tables. This distinction—simple vs complex views—matters for updates.

---

## 4. Simple Views vs Complex Views

### Simple View

A **simple view** is based on **one table** with **no aggregation or joins**.

```sql
CREATE OR REPLACE VIEW emp_view_simple AS
  SELECT employee_id, first_name, salary
  FROM employees
  WHERE department_id = 10;
```

**Characteristics:**
- Single table
- No aggregate functions (SUM, COUNT, AVG, etc.)
- No joins
- No DISTINCT, GROUP BY, HAVING
- **Can be updated (INSERT, UPDATE, DELETE)**

### Complex View

A **complex view** is based on **multiple tables** or uses **aggregate functions**.

```sql
CREATE OR REPLACE VIEW emp_salary_summary AS
  SELECT d.department_id, 
         d.department_name,
         COUNT(*) AS emp_count,
         SUM(e.salary) AS total_salary,
         AVG(e.salary) AS avg_salary
  FROM departments d
  JOIN employees e ON d.department_id = e.department_id
  GROUP BY d.department_id, d.department_name;
```

**Characteristics:**
- Multiple tables (joins)
- Aggregate functions
- GROUP BY, HAVING
- DISTINCT
- **Cannot be directly updated (need INSTEAD OF triggers)**

### Comparison

| Aspect | Simple | Complex |
| --- | --- | --- |
| **Tables** | One | Multiple |
| **Aggregates** | No | Yes |
| **Updatable** | Yes (with conditions) | No (without INSTEAD OF trigger) |
| **Use case** | Security, simplification | Analytics, reporting |

---

**➡ Transition:** Simple views can be updated, but with strict conditions. Let's look at what makes a view updatable.

---

## 5. Updatable Views

### What Makes a View Updatable?

A view is updatable if and only if:
1. Based on **single table only** (no joins)
2. No **aggregate functions** (SUM, COUNT, AVG, MAX, MIN)
3. No **GROUP BY or HAVING**
4. No **DISTINCT**
5. No **set operators** (UNION, INTERSECT, EXCEPT)
6. All **non-NULL columns** of base table are included (for INSERT)

### Updatable View: Example

```sql
CREATE OR REPLACE VIEW emp_view AS
  SELECT employee_id, first_name, last_name, salary
  FROM employees
  WHERE department_id = 10;
```

**Can be updated:**
```sql
-- INSERT
INSERT INTO emp_view VALUES (999, 'John', 'Doe', 50000);
-- Note: department_id automatically set to 10 (from WHERE clause)

-- UPDATE
UPDATE emp_view SET salary = 55000 WHERE employee_id = 101;

-- DELETE
DELETE FROM emp_view WHERE employee_id = 101;
```

### Non-Updatable View: Example

```sql
CREATE OR REPLACE VIEW emp_summary AS
  SELECT department_id, COUNT(*) AS emp_count, AVG(salary) AS avg_sal
  FROM employees
  GROUP BY department_id;
```

**Cannot be updated (aggregate functions):**
```sql
-- All fail with error
INSERT INTO emp_summary VALUES (10, 5, 50000);  -- ❌
UPDATE emp_summary SET emp_count = 10 ...;     -- ❌
```

### Key Point: WHERE Clause in VIEW

When you INSERT into an updatable view with a WHERE clause, the WHERE condition is **applied automatically**:

```sql
CREATE OR REPLACE VIEW dept_10_view AS
  SELECT * FROM employees WHERE department_id = 10;

-- Insert through view
INSERT INTO dept_10_view VALUES (999, 'John', 'Doe', 'john@email', 123, SYSDATE, 'IT', 50000, NULL, NULL, 10);

-- The inserted row automatically has department_id = 10
-- Even if you try to set it differently in the INSERT, it gets corrected
```

---

**➡ Transition:** Updatable views allow DML. But sometimes we want to **restrict** what can be updated. That's where **WITH CHECK OPTION** comes in.

---

## 6. WITH CHECK OPTION

### What is WITH CHECK OPTION?

**WITH CHECK OPTION** is a constraint that enforces the view's WHERE condition on any DML operations (INSERT, UPDATE).

It prevents users from:
- Inserting rows that don't satisfy the view's WHERE clause
- Updating rows so they violate the view's WHERE clause

### Example Without CHECK OPTION

```sql
CREATE OR REPLACE VIEW dept_10_view AS
  SELECT * FROM employees WHERE department_id = 10;

-- Insert row with different department
INSERT INTO dept_10_view VALUES (999, 'John', ..., 20);  -- ✅ Allowed, but problematic
-- Row is inserted with department_id = 20
-- But the view only shows department_id = 10, so you can't see this row in the view
-- Confusing!
```

### Example WITH CHECK OPTION

```sql
CREATE OR REPLACE VIEW dept_10_view AS
  SELECT * FROM employees 
  WHERE department_id = 10
  WITH CHECK OPTION;

-- Try to insert row with different department
INSERT INTO dept_10_view VALUES (999, 'John', ..., 20);  -- ❌ REJECTED
-- Error: view WHERE clause violated

-- Insert row with matching department
INSERT INTO dept_10_view VALUES (999, 'John', ..., 10);  -- ✅ Allowed
```

### WITH CHECK OPTION Prevents Inconsistency

**Without it:**
```
View definition: WHERE department_id = 10
User inserts: department_id = 20
Result: Row exists but isn't visible in the view (confusing!)
```

**With it:**
```
View definition: WHERE department_id = 10
User tries to insert: department_id = 20
Result: ERROR (clean enforcement)
```

### Syntax

```sql
CREATE OR REPLACE VIEW view_name AS
  SELECT columns FROM table WHERE condition
  WITH CHECK OPTION;
```

---

**➡ Transition:** CHECK OPTION allows updates (with restrictions). But sometimes you want **no updates at all**—completely read-only views.

---

## 7. WITH READ ONLY

### What is WITH READ ONLY?

**WITH READ ONLY** makes a view completely read-only. **No INSERT, UPDATE, or DELETE** allowed.

### Example

```sql
CREATE OR REPLACE VIEW salary_view AS
  SELECT employee_id, first_name, salary
  FROM employees
  WHERE salary > 100000
  WITH READ ONLY;
```

**Usage:**
```sql
-- Read-only: Always allowed
SELECT * FROM salary_view;

-- All DML rejected
INSERT INTO salary_view VALUES (...);  -- ❌ Error
UPDATE salary_view SET salary = ...;   -- ❌ Error
DELETE FROM salary_view ...;           -- ❌ Error
```

### When to Use READ ONLY

- **Complex views** (aggregates, joins) that can't be updated anyway
- **Sensitive data** views where you only want to allow SELECT
- **Summary/reporting** views where data changes don't make sense
- **Audit trails** where historical data should never change

### Comparison: CHECK OPTION vs READ ONLY

| Feature | WITH CHECK OPTION | WITH READ ONLY |
| --- | --- | --- |
| **SELECT** | Allowed | Allowed |
| **INSERT** | Allowed (if matches WHERE) | NOT allowed |
| **UPDATE** | Allowed (if result matches WHERE) | NOT allowed |
| **DELETE** | Allowed | NOT allowed |
| **Use case** | Enforce WHERE logic on updates | Complete read-only |

---

**➡ Transition:** We've covered simple views. What happens when a view is based on a **join** and we try to update?

---

## 8. Updating Views with Joins

### The Problem: Which Table to Update?

```sql
CREATE OR REPLACE VIEW emp_dept AS
  SELECT e.employee_id, e.first_name, d.department_id, d.department_name
  FROM employees e
  JOIN departments d ON e.department_id = d.department_id;

-- If we UPDATE this view, which table do we update?
UPDATE emp_dept SET first_name = 'John' WHERE employee_id = 101;
-- Should update employees table ✅

UPDATE emp_dept SET department_name = 'HR' WHERE department_id = 10;
-- Should update departments table ✅

-- But what if we try both?
UPDATE emp_dept SET first_name = 'John', department_name = 'HR' WHERE employee_id = 101;
-- Which table for which column? Ambiguous!
```

### The Solution: Key-Preserved Tables

Oracle allows updates **only on key-preserved tables** in a join.

**Key-preserved table:** A table where the join condition preserves the uniqueness of the primary key.

### Example: Updatable Join View

```sql
-- employees.employee_id is PK (unique)
-- departments.department_id is PK (unique)
-- Join preserves both uniquenesses

CREATE OR REPLACE VIEW emp_dept_view AS
  SELECT e.employee_id, e.first_name, e.salary,
         d.department_id, d.department_name
  FROM employees e
  JOIN departments d ON e.department_id = d.department_id;

-- ✅ Can update employees (e.employee_id is PK, preserved by join)
UPDATE emp_dept_view SET first_name = 'John' WHERE employee_id = 101;

-- ✅ Can update departments (d.department_id is PK, preserved by join)
UPDATE emp_dept_view SET department_name = 'Sales' WHERE department_id = 10;

-- ❌ Cannot update both in one statement (ambiguous)
```

### Example: Non-Updatable Join View

```sql
CREATE OR REPLACE VIEW emp_salary_summary AS
  SELECT e.department_id, d.department_name,
         COUNT(*) AS emp_count,
         SUM(e.salary) AS total_salary
  FROM employees e
  JOIN departments d ON e.department_id = d.department_id
  GROUP BY e.department_id, d.department_name;

-- ❌ Cannot update (has aggregates)
UPDATE emp_salary_summary SET total_salary = 500000 WHERE department_id = 10;
```

### How to Update Non-Updatable Views: INSTEAD OF Triggers

For complex views, use **INSTEAD OF triggers** to define custom update logic:

```sql
CREATE OR REPLACE TRIGGER emp_salary_summary_update
INSTEAD OF UPDATE ON emp_salary_summary
FOR EACH ROW
BEGIN
  -- Custom logic to handle the update
  UPDATE employees SET salary = :NEW.total_salary / emp_count
  WHERE department_id = :NEW.department_id;
END;
/
```

---

**➡ Transition:** Regular views are always up-to-date but can be slow. What if we need **fast access** to frequently-queried complex data? That's where materialized views come in.

---

## 9. Why Materialized Views?

### The Problem: Slow Complex Queries

Complex queries that run repeatedly can be slow:

```sql
-- Joins 5 tables, aggregates, GROUP BY
-- Takes 30 seconds to run each time
SELECT d.department_name,
       COUNT(e.employee_id) AS emp_count,
       AVG(e.salary) AS avg_salary,
       SUM(e.salary) AS total_salary
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
LEFT JOIN salary_history sh ON e.employee_id = sh.employee_id
GROUP BY d.department_id, d.department_name;
```

Running this query 100 times per day = 50 minutes of wasted processing.

### The Solution: Materialized View

**Materialized view** stores the query results **physically** (like a table):

```
Regular View:      User → Query (execute each time) → Base tables
Materialized View: User → Physical table (pre-computed results) → Base tables
```

Benefits:
- **Fast:** Queries run on pre-computed data (nanoseconds vs seconds)
- **Reduced CPU:** No need to re-compute each time
- **Predictable performance:** Like querying a regular table

### Trade-off: Data Freshness

**Regular view:** Always current (executes now)
**Materialized view:** Potentially stale (needs refresh)

**Solution:** Refresh on schedule that fits your business needs.

---

**➡ Transition:** Materialized views trade freshness for speed. Let's see the differences clearly.

---

## 10. Materialized View vs Regular View

| Aspect | Regular View | Materialized View |
| --- | --- | --- |
| **Storage** | Query definition (no data) | Physical table (stores data) |
| **Data Freshness** | Always current | Stale until refresh |
| **Query Speed** | Depends on base tables | Very fast (pre-computed) |
| **Space** | No extra space | Uses disk space |
| **Maintenance** | None | Requires refresh strategy |
| **Use case** | Real-time data, security | Analytics, reporting, heavy queries |
| **DML** | Yes (sometimes) | No (data-only) |

### Decision Matrix: Which to Use?

**Use Regular View when:**
- Data must always be current
- Query is simple/fast
- Users need to INSERT/UPDATE/DELETE
- Space is limited

**Use Materialized View when:**
- Query is complex and slow
- Data is used for reporting (not transactions)
- Data can be 1 minute, 1 hour, or 1 day old
- Many users query the same result

---

## 11. Creating Materialized Views

### Basic Syntax

```sql
CREATE MATERIALIZED VIEW mv_emp_summary AS
  SELECT d.department_id,
         d.department_name,
         COUNT(*) AS emp_count,
         AVG(e.salary) AS avg_salary,
         SUM(e.salary) AS total_salary
  FROM departments d
  LEFT JOIN employees e ON d.department_id = e.department_id
  GROUP BY d.department_id, d.department_name;
```

### Query the Materialized View

```sql
SELECT * FROM mv_emp_summary;
-- Returns pre-computed results instantly
```

### Drop a Materialized View

```sql
DROP MATERIALIZED VIEW mv_emp_summary;
```

### View Materialized View Metadata

```sql
SELECT * FROM user_mviews;
SELECT * FROM user_mview_analysis;
```

---

**➡ Transition:** Once created, materialized views need **refreshing** to stay current. There are multiple strategies.

---

## 12. Refreshing Materialized Views

### The Refresh Problem

```
Time 0:  Materialized view created (shows current data)
Time 1:  User updates employees table
Time 2:  Another user queries materialized view
         Question: Does it show updated data?
         Answer: NO (stale data from Time 0)
```

Solution: **Refresh** the materialized view to re-execute the query.

### Refresh Method 1: Complete Refresh

Re-executes the entire query and replaces all data.

**Slowest but most reliable:**
```sql
-- Syntax 1: Using procedure
EXEC DBMS_MVIEW.REFRESH('mv_emp_summary', method => 'C');

-- Syntax 2: Using immediate
EXEC DBMS_MVIEW.REFRESH('mv_emp_summary', 'C');
```

**When to use:** When underlying data changes significantly, or when fast refresh isn't possible.

### Refresh Method 2: Fast Refresh

Updates **only the changed rows** since last refresh.

**Much faster for incremental updates:**
```sql
-- First, create a materialized view log on the base table
CREATE MATERIALIZED VIEW LOG ON employees
  WITH ROWID, PRIMARY KEY, SEQUENCE
  ENABLE QUERY REWRITE AS
  SELECT * FROM employees;

-- Now fast refresh works
EXEC DBMS_MVIEW.REFRESH('mv_emp_summary', method => 'F');
```

**How it works:**
1. Materialized view log tracks INSERT/UPDATE/DELETE on base table
2. Fast refresh reads the log (not the entire table)
3. Only changed rows are updated in the materialized view

**When to use:** When data changes are small/incremental (fast refresh is possible).

### Refresh Method 3: Force Refresh

Tries fast refresh; falls back to complete if fast not possible.

```sql
EXEC DBMS_MVIEW.REFRESH('mv_emp_summary', method => 'F');
-- Not to be confused with fast refresh 'F'
```

### Refresh Method 4: Never Refresh

Data never updated automatically (manual only):

```sql
EXEC DBMS_MVIEW.REFRESH('mv_emp_summary', method => 'N');
```

### Refresh Scheduling: When to Refresh

#### On-Demand Refresh

Manually refresh when needed:

```sql
-- User runs this when they need fresh data
EXEC DBMS_MVIEW.REFRESH('mv_emp_summary', 'C');
```

**Best for:** Nightly/weekly batch jobs, one-time reporting.

#### On-Commit Refresh

Automatically refresh after each transaction:

```sql
CREATE MATERIALIZED VIEW mv_emp_summary
  BUILD IMMEDIATE
  REFRESH FAST
  ON COMMIT
  AS
  SELECT ...;
```

**Best for:** Real-time reporting, critical data.

**Caution:** Adds overhead to every transaction.

#### Scheduled Refresh (Using DBMS_SCHEDULER)

Refresh on a schedule (e.g., every hour):

```sql
BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name => 'refresh_mv_job',
    job_type => 'PLSQL_BLOCK',
    job_action => 'BEGIN DBMS_MVIEW.REFRESH(''mv_emp_summary'', ''C''); END;',
    repeat_interval => 'FREQ=HOURLY'
  );
  DBMS_SCHEDULER.ENABLE('refresh_mv_job');
END;
/
```

**Best for:** Hourly/daily batch reporting.

### Complete Refresh Example

```sql
-- Update base table
UPDATE employees SET salary = 60000 WHERE employee_id = 101;
COMMIT;

-- Materialized view still shows old data
SELECT * FROM mv_emp_summary;  -- Stale

-- Refresh the materialized view
EXEC DBMS_MVIEW.REFRESH('mv_emp_summary', 'C');

-- Now shows updated data
SELECT * FROM mv_emp_summary;  -- Current
```

---

**➡ Transition:** Materialized views require maintenance. But what happens to views when **base tables change**? They can become invalid.

---

## 13. View Invalidation

### When Does a View Become Invalid?

A view becomes **invalid** when:

1. **Base table is dropped:**
```sql
DROP TABLE employees;
-- All views based on employees are now invalid
```

2. **Columns are dropped:**
```sql
ALTER TABLE employees DROP COLUMN first_name;
-- Views using first_name become invalid
```

3. **Column datatype changes:**
```sql
ALTER TABLE employees MODIFY salary NUMBER(12,2);
-- Views using salary might become invalid (depends on change)
```

### What Happens When a View is Invalid?

```sql
-- View is invalid
SELECT * FROM emp_view;
-- Error: ORA-04063: view "OWNER"."EMP_VIEW" has errors
```

### How to Check View Status

```sql
SELECT view_name, text FROM user_views;

SELECT * FROM user_errors WHERE name = 'EMP_VIEW';
```

### How to Fix Invalid Views

**Option 1: Recreate the base table**
```sql
CREATE TABLE employees (...);  -- Recreate with same columns
-- Views automatically become valid
```

**Option 2: Redefine the view**
```sql
CREATE OR REPLACE VIEW emp_view AS
  SELECT new_columns FROM employees;
-- View is now valid with new definition
```

### Advanced: FORCE Option (Expert Only)

Create a view even if base table doesn't exist (risky):

```sql
CREATE FORCE VIEW emp_view AS
  SELECT * FROM nonexistent_table;
-- View is created but invalid (base table doesn't exist)
```

**Why use FORCE?**
- Create views before base tables are ready
- Placeholder for future development

**Why avoid?**
- Views don't work until base table exists
- Easy to forget and leave invalid

---

## 14. Best Practices

### 1. Prefer Regular Views for Updatable Data

**Avoid:**
```sql
-- Materialized view that might be stale
CREATE MATERIALIZED VIEW customer_view AS SELECT * FROM customers;
```

**Prefer:**
```sql
-- Regular view, always current
CREATE OR REPLACE VIEW customer_view AS SELECT * FROM customers;
```

---

### 2. Use WITH CHECK OPTION to Prevent Inconsistency

**Avoid:**
```sql
CREATE OR REPLACE VIEW dept_10_view AS
  SELECT * FROM employees WHERE department_id = 10;
  -- Users can insert dept_id = 20, row not visible in view
```

**Prefer:**
```sql
CREATE OR REPLACE VIEW dept_10_view AS
  SELECT * FROM employees WHERE department_id = 10
  WITH CHECK OPTION;
  -- Enforces department_id = 10 on inserts/updates
```

---

### 3. Use WITH READ ONLY for Complex Views

**Avoid:**
```sql
CREATE OR REPLACE VIEW emp_summary AS
  SELECT dept_id, COUNT(*) FROM employees GROUP BY dept_id;
  -- Tempts users to UPDATE (which fails)
```

**Prefer:**
```sql
CREATE OR REPLACE VIEW emp_summary AS
  SELECT dept_id, COUNT(*) FROM employees GROUP BY dept_id
  WITH READ ONLY;
  -- Clear that view is read-only
```

---

### 4. Refresh Materialized Views on a Schedule

**Avoid:**
```sql
-- Materialized view never refreshed (stale forever)
CREATE MATERIALIZED VIEW report_view AS SELECT ...;
```

**Prefer:**
```sql
-- Materialized view refreshed hourly
CREATE MATERIALIZED VIEW report_view
  REFRESH FAST ON COMMIT
  AS SELECT ...;
```

---

### 5. Document View Purpose and Audience

```sql
-- Good practice: Include comment
COMMENT ON VIEW emp_view IS 'Employees in dept 10. For HR only. Auto-refreshed hourly.';
```

---

## 15. Common Mistakes

### Mistake 1: Using Materialized View for Real-Time Data

```sql
-- ❌ WRONG
CREATE MATERIALIZED VIEW current_orders AS
  SELECT * FROM orders WHERE order_status = 'PENDING';
-- Data can be 1 hour old, but users expect real-time

-- ✅ CORRECT
CREATE OR REPLACE VIEW current_orders AS
  SELECT * FROM orders WHERE order_status = 'PENDING';
-- Always current
```

---

### Mistake 2: Forgetting to Refresh Materialized Views

```sql
-- ❌ WRONG
CREATE MATERIALIZED VIEW sales_summary AS SELECT ...;
-- Never refreshed again, data becomes stale

-- ✅ CORRECT
CREATE MATERIALIZED VIEW sales_summary
  REFRESH FAST ON COMMIT
  AS SELECT ...;
```

---

### Mistake 3: Trying to Update Complex Views Without INSTEAD OF Trigger

```sql
-- ❌ WRONG
CREATE OR REPLACE VIEW emp_summary AS
  SELECT dept_id, COUNT(*) FROM employees GROUP BY dept_id;

UPDATE emp_summary SET COUNT(*) = 10 WHERE dept_id = 10;
-- ERROR: Cannot update aggregated view

-- ✅ CORRECT: Use INSTEAD OF trigger
CREATE OR REPLACE TRIGGER emp_summary_update
INSTEAD OF UPDATE ON emp_summary
FOR EACH ROW
BEGIN
  -- Custom logic
END;
```

---

### Mistake 4: Views on Views Getting Too Complex

```sql
-- ❌ WRONG (brittle)
CREATE VIEW v1 AS SELECT ...;
CREATE VIEW v2 AS SELECT * FROM v1 WHERE ...;
CREATE VIEW v3 AS SELECT * FROM v2 WHERE ...;
CREATE VIEW v4 AS SELECT * FROM v3 WHERE ...;
-- 4 levels deep, hard to maintain

-- ✅ BETTER
CREATE VIEW v1 AS SELECT ... (all logic in one place);
```

---

### Mistake 5: Not Testing View Updates

```sql
-- ❌ RISKY
CREATE OR REPLACE VIEW emp_view AS
  SELECT * FROM employees WHERE dept = 10;
-- Assume it's updatable without testing

UPDATE emp_view SET salary = 50000 WHERE emp_id = 101;
-- Might fail silently if view not updatable

-- ✅ SAFE
-- Test before deploying:
INSERT INTO emp_view VALUES (...);
UPDATE emp_view SET ...;
DELETE FROM emp_view WHERE ...;
```

---

## 16. Interview Q&A

### Conceptual

**Q: What's the difference between a view and a table?**

A:
- **Table:** Stores actual data on disk.
- **View:** Stores a query definition. Data comes from base tables, always current.

---

**Q: Can you update a view based on a join?**

A: Only on key-preserved tables in the join. If the join condition preserves the primary key uniqueness, you can update that table through the view.

---

**Q: What is WITH CHECK OPTION?**

A: Constraint that prevents INSERT/UPDATE through a view if the result would violate the view's WHERE clause.

---

### Comparison

**Q: Regular view vs materialized view?**

A:
- **Regular:** Virtual (no storage). Always current. Slower for complex queries.
- **Materialized:** Physical (stores data). Potentially stale. Fast queries.

---

**Q: Fast refresh vs complete refresh?**

A:
- **Fast:** Only changed rows (uses materialized view log). Much faster but only works for incremental changes.
- **Complete:** Re-executes entire query. Slower but always works.

---

### Scenario

**Q: You have a complex reporting query that 1000 users run daily. It takes 60 seconds each time. What's your solution?**

A: Materialized view with fast refresh. Query runs on pre-computed data (instant). Refresh hourly/daily depending on data change frequency.

---

**Q: A view is based on multiple tables and has aggregates. Can users update it?**

A: Not directly. You'd need to use INSTEAD OF triggers to define custom update logic.

---

## 17. Revision Summary

### 1-Minute Revision

**View = Virtual table. Materialized View = Physical table.**

1. **Regular View:** Query definition, no data storage, always current.
2. **Updatable view:** Single table, no aggregates, no joins (with conditions).
3. **WITH CHECK OPTION:** Enforces WHERE clause on INSERT/UPDATE.
4. **WITH READ ONLY:** Complete read-only access.
5. **Materialized View:** Stores data physically, needs refresh.
6. **Refresh methods:** Complete (all rows), Fast (changed rows only), Force (try fast, fallback to complete).
7. **Key-preserved table:** Can be updated through join view if uniqueness is preserved.
8. **View invalidation:** Happens when base table dropped or schema changes.

### Interview Keywords

- Virtual vs physical tables
- Updatable views (conditions)
- WITH CHECK OPTION, WITH READ ONLY
- Simple view (single table), complex view (joins, aggregates)
- Materialized view refresh (fast, complete, force)
- Materialized view log (enables fast refresh)
- Key-preserved tables (updatable in joins)
- INSTEAD OF triggers (complex view updates)

### Important Syntax

```sql
-- Simple updatable view
CREATE OR REPLACE VIEW emp_view AS
  SELECT employee_id, first_name, salary FROM employees WHERE department_id = 10
  WITH CHECK OPTION;

-- Read-only view
CREATE OR REPLACE VIEW salary_summary AS
  SELECT dept_id, COUNT(*), AVG(salary) FROM employees GROUP BY dept_id
  WITH READ ONLY;

-- Materialized view
CREATE MATERIALIZED VIEW mv_emp_summary AS
  SELECT ... FROM employees ... GROUP BY ...;

-- Refresh materialized view
EXEC DBMS_MVIEW.REFRESH('mv_emp_summary', 'C');  -- Complete
EXEC DBMS_MVIEW.REFRESH('mv_emp_summary', 'F');  -- Fast

-- Materialized view log
CREATE MATERIALIZED VIEW LOG ON employees
  WITH ROWID, PRIMARY KEY, SEQUENCE
  ENABLE QUERY REWRITE AS
  SELECT * FROM employees;
```

---

## 18. Related Notes

- Window functions: [Window Functions and Analytics](../09%20Performance/01_Window_Functions_and_Analytics.md)
- Indexes: [Indexes and Execution Plans](../08%20Indexes/01_Indexes_and_Execution_Plans.md)

## Views

### Definition of View

A **view** is a virtual table created using a SQL query that doesn't store data itself. It stores a SQL statement and shows the result of that query when accessed.

### Syntax of View

```sql
CREATE OR REPLACE VIEW view_name AS
SELECT column1, column2 FROM table_name;
```

### Example of View

```sql
CREATE OR REPLACE VIEW emp_view AS
SELECT employee_id, first_name, last_name, department_id, email 
FROM employees
WHERE department_id = 10;
```

### Access the View

```sql
SELECT * FROM emp_view;
```

### Drop the View

```sql
DROP VIEW emp_view;
```

### Update the View

```sql
CREATE OR REPLACE VIEW emp_view AS
SELECT employee_id, first_name, last_name, department_id, salary 
FROM employees;
```

---

## Why We Need Views?

1. **Security**: Views can restrict access to specific columns or rows in a table, providing a layer of security for sensitive data.

2. **Simplification**: Views can simplify complex queries by encapsulating them in a single view, making it easier for users to retrieve data without needing to understand the underlying complexity.

3. **Data Abstraction**: Views provide a level of abstraction, allowing users to interact with data in a more meaningful way without needing to know the details of the underlying tables.

4. **Reusability**: Views can be reused in multiple queries, reducing the need to write the same complex SQL statements repeatedly.

---

## Table vs View

| Aspect | Table | View |
| -------- | ------- | ------ |
| **Storage** | Stores data | Stores SQL query |
| **Space** | Occupies space | Doesn't occupy space |
| **Retrieval** | Faster retrieval | Slower retrieval |

---

## Types of Views

### 1. Simple View

A simple view is based on a single table and does not contain any aggregate functions or joins. It can be used to retrieve specific columns or rows from the underlying table.

### 2. Complex View

A complex view is based on multiple tables and can include:

- Aggregate functions
- Joins
- Set operators
- DISTINCT

It can be used to combine data from multiple sources and present it in a unified manner.

---

## Updating Views with Joins

Oracle allows updates only on the **key-preserved tables** in the join. A key-preserved table is a table that has a primary key or unique constraint defined on it, and the join condition preserves the uniqueness of the rows in that table.

### Example

If the `employees` table has a primary key on `employee_id` and the `departments` table has a primary key on `department_id`, you can update the `employees` table through a view that joins these tables because it is a key-preserved table in the join.

---

## DML Operations on Views

### Can We Do DML on Views?

We can perform DML operations (INSERT, UPDATE, DELETE) on a view **only if the view is updatable**.

An **updatable view** is one that:

- Is based on a single table
- Does not contain aggregate functions
- Does not contain joins
- Does not contain GROUP BY clauses

If the view is not updatable, we cannot perform DML operations directly on it.

### How to Do DML Operations on Simple View

```sql
SELECT * FROM emp_view;

INSERT INTO emp_view (EMPLOYEE_ID, FIRST_NAME, LAST_NAME, DEPARTMENT_ID, EMAIL) 
VALUES (201, 'Sowparnika', 'S', 20, 'sow@gmail.com');

UPDATE emp_view 
SET first_name = 'SowparnikaA' 
WHERE employee_id = 101;

SELECT * FROM employees WHERE employee_id = 200;
```

---

## Read-Only View

A **read-only view** is a view that does not allow any DML operations (INSERT, UPDATE, DELETE) to be performed on it. It is used to provide a read-only representation of the underlying data.

### Example of Read-Only View

```sql
CREATE OR REPLACE VIEW emp_read_only_view AS
SELECT employee_id, first_name, last_name, department_id 
FROM employees
WHERE department_id = 20 
WITH READ ONLY;
```

---

## Check Option

### Definition

The **CHECK OPTION** is a constraint that can be applied to a view to enforce that any DML operations (INSERT, UPDATE) performed through the view must satisfy the conditions defined in the view's SELECT statement. If a user attempts to insert or update a row that does not meet the view's criteria, the operation will be rejected.

**Note**: You can insert a row through the view, but you cannot see the same row when you access the view.

### Example

```sql
CREATE OR REPLACE VIEW emp_check_view AS
SELECT employee_id, first_name, last_name, department_id 
FROM employees
WHERE department_id = 30 
WITH CHECK OPTION;

SELECT * FROM emp_check_view;
```

---

## Read-Only vs Check Option

| Aspect | Read-Only | Check Option |
|--------|-----------|--------------|
| **DML Allowed** | NO | YES |
| **Type** | Complete restriction | Conditional restriction |

---

## Important Points About Views

1. If the base table is dropped, the view becomes **invalid**
2. Another view can be created on top of an existing view
3. No constraint can be applied on a view (except CHECK OPTION)
4. Even if the base table is dropped, using **FORCE** you can still create an invalid view (but it will remain invalid until the base table is recreated)
5. If the base table is altered, the view may become invalid if it references columns that no longer exist or have changed data types
6. DML operations can be performed on complex views using **INSTEAD OF triggers**

### Query View Information

```sql
SELECT * FROM user_views;
SELECT * FROM user_tables;
```

---

---

# Materialized Views (M-Views)

## Definition

A **materialized view** is a database object that stores the results of a query as a physical table.

Unlike regular views (which are virtual and do not store data), materialized views store the data returned by the query in a separate table. This allows for faster access to the data.

---

## Why We Need Materialized Views?

1. **Improve Performance**: Precompute and store results of complex queries in a physical table
2. **Reduce CPU Usage**: Minimize computational overhead
3. **Reduce Repeated Calculation**: Avoid recalculating the same results

---

## Disadvantages of Materialized Views

1. **Storage Space**: Required to store the materialized view data
2. **Data Staleness**: Data can be older than the base tables
3. **Maintenance Overhead**: Required to keep the materialized view up-to-date with the underlying data

---

## Real-Time Use Cases

- **Reporting and Analytics**
- **Data Warehousing**
- **Performance Optimization**
- **Monthly or Quarterly Summaries**

---

## When Do We Need a Materialized View?

**RULE-1**: If the query is slow and repeatedly performs expensive work

**RULE-2**: If the data is mostly for reporting purpose

**RULE-3**: If the data can be slightly old

---

## View vs Materialized View

| Aspect | View | Materialized View |
| -------- | ------ | ------------------- |
| **Storage** | Stores query | Stores data |
| **Space Needed** | No storage needed | Needs storage |
| **Data Freshness** | Always latest | Needs refresh |
| **Speed** | Usually slower | Usually faster |

---

## Syntax

```sql
CREATE MATERIALIZED VIEW mv_emp AS
SELECT department_id, 
       SUM(salary) total_sal
FROM employees
GROUP BY department_id;
```

---

## Refreshing Materialized Views

There are four refresh methods:

### 1. Complete Refresh

Refreshes the entire materialized view by re-executing the underlying query and replacing the existing data with the new results.

This method is typically used when the underlying data has changed significantly or when a fast refresh is not possible.

```sql
UPDATE employees SET salary = 5000 WHERE employee_id = 200;
COMMIT;

SELECT * FROM employees WHERE employee_id = 200;
SELECT * FROM mv_emp;

EXEC DBMS_MVIEW.REFRESH('MV_EMP', method => 'C');
```

### 2. Fast Refresh

Updates only the changes made to the underlying data since the last refresh, rather than re-executing the entire query.

This method is more efficient than a complete refresh, as it reduces the amount of data that needs to be processed. Fast refresh requires that the materialized view be created with certain options, such as the use of materialized view logs on the underlying tables.

#### Example for Fast Refresh

```sql
CREATE MATERIALIZED VIEW LOG ON employees 
WITH ROWID, PRIMARY KEY, SEQUENCE
ENABLE QUERY REWRITE AS 
SELECT * FROM employees;
```

**How it works**: The materialized view log is a special table that records changes made to the underlying table. When a materialized view is created with fast refresh enabled, it relies on the materialized view log to determine which rows have changed since the last refresh.

```sql
EXEC DBMS_MVIEW.REFRESH('MV_EMP', method => 'F');
```

### 3. Force Refresh

Attempts to perform a fast refresh if possible; if not, it falls back to a complete refresh.

```sql
EXEC DBMS_MVIEW.REFRESH('MV_EMP', method => 'F');
```

### 4. Never Refresh

Indicates that the materialized view should not be refreshed automatically.

---

## Refresh Modes - When to Refresh

### 1. On-Demand Refresh

The materialized view is refreshed only when explicitly requested by the user or application. This can be done using the `DBMS_MVIEW.REFRESH` procedure or by executing a manual refresh command.

### 2. On-Commit Refresh

The materialized view is refreshed automatically whenever a transaction that modifies the underlying tables is committed. This ensures that the materialized view always reflects the most recent changes to the data, but it can introduce additional overhead and may impact performance for high-transaction environments.
