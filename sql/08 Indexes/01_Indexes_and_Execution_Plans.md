# Oracle Indexes and Execution Plans Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Index** = Separate data structure storing column value + ROWID for fast lookup.
- **Without index:** Oracle does full table scan (slow for large tables).
- **With index:** Oracle jumps directly to row using ROWID (fast).
- **B-tree** (default) = Best for high-cardinality data (many unique values).
- **Bitmap** = Best for low-cardinality analytics (few unique values like gender).
- **Composite index** = Multiple columns; leading column rule matters (search on first column works, last column alone doesn't).
- **Leading column rule** = First column in composite index is most selective for optimizer.
- **Scan methods:** Unique (one row), Range (multiple rows), Full (all index rows), Fast Full (parallel, no table access).
- **Execution plan** = Step-by-step instructions Oracle follows to execute query.
- **EXPLAIN PLAN** = Shows what index/scan method Oracle will use (doesn't execute query).

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Indexes?](#1-why-do-we-need-indexes)
2. [What is an Index?](#2-what-is-an-index)
3. [How Indexes Work Internally](#3-how-indexes-work-internally)
4. [Creating Indexes](#4-creating-indexes)
5. [Types of Indexes](#5-types-of-indexes)
6. [B-Tree Indexes](#6-b-tree-indexes)
7. [Bitmap Indexes](#7-bitmap-indexes)
8. [Composite Indexes and Leading Column Rule](#8-composite-indexes-and-leading-column-rule)
9. [Function-Based Indexes](#9-function-based-indexes)
10. [Reverse Key and Invisible Indexes](#10-reverse-key-and-invisible-indexes)
11. [Index Scan Methods](#11-index-scan-methods)
12. [Execution Plans](#12-execution-plans)
13. [When Oracle Uses Indexes](#13-when-oracle-uses-indexes)
14. [When Oracle Avoids Indexes](#14-when-oracle-avoids-indexes)
15. [Best Practices](#15-best-practices)
16. [Common Mistakes](#16-common-mistakes)
17. [Interview Q&A](#17-interview-qa)
18. [Revision Summary](#18-revision-summary)

---

## 1. Why Do We Need Indexes?

### The Problem: Slow Queries on Large Tables

Without indexes, searching a table is slow:

```sql
-- Table has 10 million employees
SELECT * FROM employees WHERE employee_id = 104;
```

**Without index:**
- Oracle checks **every single row** (10 million rows)
- Finds row 104 after checking millions of rows
- Takes 30 seconds ❌

**With index:**
- Oracle uses index to jump directly to ROWID
- Fetches row 104 in nanoseconds ✅

### The Business Problem

```
Slow queries →  Users wait →  Productivity loss →  Business impact
```

Real-world scenario:
- Payroll system needs to look up employee records
- Without index: Each lookup takes 30 seconds
- With 1000 employee lookups daily: 500 hours of processing
- Solution: Index on employee_id = instant lookups

### Why Indexes Matter

Indexes are the **#1 performance optimization tool** for databases:
- Speed up searches (SELECT with WHERE)
- Critical for high-volume OLTP systems
- Difference between seconds and nanoseconds

---

**➡ Transition:** Now that we understand the problem, what exactly **is** an index and how does it work?

---

## 2. What is an Index?

### Simple Definition

An **index** is a **separate data structure** that stores:
- **Indexed column value** (e.g., employee_id = 104)
- **ROWID** (physical address of that row in the table)

It's organized in a sorted, tree-like structure for fast searching.

### Analogy: Book Index vs Dictionary

A book index works like this:
```
Topic          Page Number
-----------    -----------
Indexes        45
Cursors        102
Functions      234
```

Instead of reading every page to find "Indexes," you look it up in the index and jump to page 45.

Database index works the same:
```
Employee_ID    ROWID
-----------    ------
101            AAA432
102            AAA901
103            AAA876
104            AAA654
```

Find 104 in index → Get ROWID AAA654 → Jump to that row

### Key Characteristics

- **Separate structure:** Index exists independently from table
- **Sorted:** Allows binary search (fast lookup)
- **Points to data:** Stores ROWID, not actual data
- **Overhead:** Takes disk space, slows down INSERT/UPDATE/DELETE
- **Trade-off:** Fast SELECT, slower writes

---

**➡ Transition:** How does this lookup actually work internally? Let's walk through the process step-by-step.

---

## 3. How Indexes Work Internally

### Step-by-Step: Query Execution with Index

**Query:**
```sql
SELECT * FROM employees WHERE employee_id = 104;
```

**Execution:**

```
Step 1: Search Index
        ↓
        Employee_ID index (sorted: 101, 102, 103, 104, 105, ...)
        ↓
Step 2: Find Value
        ↓
        Found: 104 → ROWID = AAA654
        ↓
Step 3: Jump to ROWID
        ↓
        Table Row at AAA654
        ↓
Step 4: Return Complete Row
        ↓
        Fetch all columns for employee 104
```

### Why Index Lookup is Fast

**Without index (Full Table Scan):**
```
Row 1 → Check? No
Row 2 → Check? No
Row 3 → Check? No
...
Row 9,999,999 → Check? No
Row 10,000,000 → Check? Yes (Employee 104)
```
Reads millions of rows before finding match.

**With index (Index Lookup):**
```
Index is sorted like: [1...50 | 51...100 | 101...150 | 151...]
Employee 104? → Go to 101-150 range → Found in 3-4 comparisons
```

Index structure is typically **B-tree** (balanced tree):
- Root node (narrow)
  - Branch nodes
    - Leaf nodes (wide)

This tree structure ensures balanced, fast searching.

### Index Data Structure: Simplified View

Conceptually (actual B-tree is more complex):

| Employee_ID | ROWID  |
| --- | --- |
| 101 | AAA432 |
| 102 | AAA901 |
| 103 | AAA876 |
| 104 | AAA654 |
| 105 | AAA123 |

Actual internal organization: B-tree nodes with pointers.

---

**➡ Transition:** Now let's create an index and see the syntax for different index types.

---

## 4. Creating Indexes

### Basic Syntax

```sql
CREATE INDEX index_name ON table_name (column_name);
```

### Example: Simple Index

```sql
CREATE INDEX idx_employee_id ON employees (employee_id);
```

Oracle creates index on employee_id column for fast lookup.

### Example: Composite Index

```sql
CREATE INDEX idx_emp_dept ON employees (first_name, last_name);
```

Index on two columns; order matters (we'll cover this later).

### Dropping an Index

```sql
DROP INDEX idx_employee_id;
```

### Checking Index Metadata

```sql
SELECT * FROM user_indexes;
SELECT * FROM user_ind_columns;
```

---

**➡ Transition:** Oracle offers different index types for different scenarios. Let's explore when to use each.

---

## 5. Types of Indexes

| Type | Best For | Example |
| --- | --- | --- |
| **B-tree** | High-cardinality, OLTP | employee_id (unique values) |
| **Bitmap** | Low-cardinality, Analytics | gender (M/F), country |
| **Composite** | Multi-column WHERE | first_name + last_name |
| **Function-Based** | Derived columns | UPPER(last_name) |
| **Reverse Key** | Sequential inserts | Auto-incrementing PK |
| **Invisible** | Testing impact | Disable without dropping |

---

## 6. B-Tree Indexes

### What is B-Tree?

**B-tree** = Balanced tree index. It's the **default index type** in Oracle.

**Best for:** High-cardinality columns (many unique values).

**Cardinality** = Number of distinct values in a column.

Examples:
- **High cardinality:** employee_id (each employee unique), email (each email unique)
- **Low cardinality:** gender (only M, F), marital_status (only Y, N)

### Why B-Tree is Default

B-tree indexes are efficient for:
- Single-value lookups (WHERE id = 104)
- Range queries (WHERE id BETWEEN 100 AND 200)
- Sorting (ORDER BY id)
- Most general-purpose queries

### Example

```sql
CREATE INDEX idx_employee_id ON employees (employee_id);
-- Default is B-tree

SELECT * FROM employees WHERE employee_id = 104;
-- Oracle uses idx_employee_id for fast lookup
```

### When to Use B-Tree

- OLTP systems (Online Transaction Processing)
- High-concurrency environments
- Frequently searched columns
- Primary keys and unique constraints

---

**➡ Transition:** B-tree works great for most cases, but for analytics with low-cardinality data, bitmap indexes shine.

---

## 7. Bitmap Indexes

### What is Bitmap Index?

Instead of storing ROWID list, bitmap index stores a **bitmap** (binary representation) for each distinct value.

**Best for:** Low-cardinality columns (few distinct values).

Example: Gender (M, F), Marital Status (Y, N), Country (10-20 distinct).

### How Bitmap Works: Example

**Table:**
```
| Row | Gender |
| --- | --- |
| 1 | M |
| 2 | F |
| 3 | M |
| 4 | F |
| 5 | M |
| 6 | F |
```

**Bitmap for 'M':**
```
101010  (rows 1, 3, 5 have M)
```

**Bitmap for 'F':**
```
010101  (rows 2, 4, 6 have F)
```

### Query: Find Males

```sql
SELECT * FROM employees WHERE gender = 'M';
```

**Execution:**
```
Step 1: Get bitmap for 'M' → 101010
Step 2: Every '1' means include that row
Step 3: Convert to ROWIDs: rows 1, 3, 5
Step 4: Fetch those rows from table
```

### Why Bitmap is Powerful: Bitwise AND

```sql
SELECT * FROM employees 
WHERE gender = 'M' AND married = 'Y';
```

**Bitmap for gender='M':** `101010`
**Bitmap for married='Y':** `110011`

**Bitwise AND:**
```
  101010
∧ 110011
---------
  100010  (only rows 1, 5 match both)
```

This bitwise operation is **extremely fast** even for millions of rows.

### Bitmap vs B-Tree

| Aspect | B-Tree | Bitmap |
| --- | --- | --- |
| **Storage** | Value → ROWID list | Value → Bitmap |
| **Cardinality** | High | Low |
| **Best for** | OLTP (frequent updates) | Analytics (read-only) |
| **Multiple conditions** | Multiple index accesses | Single bitwise AND |
| **Concurrency** | High | Medium (locks on update) |
| **Use case** | Employee lookup | Gender/country in reports |

### When to Use Bitmap

- Data warehouse / Analytics
- Read-only data
- Multiple low-cardinality columns in WHERE clause
- Rarely updated columns

---

**➡ Transition:** What if you search on multiple columns? That's where composite indexes come in, with an important rule about the leading column.

---

## 8. Composite Indexes and Leading Column Rule

### What is Composite Index?

An index on **multiple columns** (in specified order).

```sql
CREATE INDEX idx_emp ON employees (first_name, last_name);
```

This creates a single index on both columns, **in that order**.

### The Leading Column Rule

**Critical rule:** The **first column** in the index is the most selective for the optimizer.

**Leading column** = First column in composite index.

### How It Works

Index structure:
```
first_name='Alice'
  ├─ last_name='Anderson'  → ROWID
  ├─ last_name='Arnold'    → ROWID
first_name='Bob'
  ├─ last_name='Baker'     → ROWID
  ├─ last_name='Brown'     → ROWID
```

### Queries That Use the Index

**✅ Query on leading column (USES INDEX):**
```sql
SELECT * FROM employees WHERE first_name = 'John';
-- Uses index efficiently
```

**✅ Query on both columns (USES INDEX):**
```sql
SELECT * FROM employees 
WHERE first_name = 'John' AND last_name = 'Doe';
-- Uses index efficiently
```

**✅ Query on both (order doesn't matter in WHERE):**
```sql
SELECT * FROM employees 
WHERE last_name = 'Doe' AND first_name = 'John';
-- Still uses index (Oracle reorders internally)
```

**❌ Query ONLY on second column (MAY NOT USE INDEX):**
```sql
SELECT * FROM employees WHERE last_name = 'Doe';
-- Index idx_emp not useful
-- Oracle may do full table scan instead
```

### Why? Think of Phone Directory

Phone directory organized by: (City, Last_Name)

```
Austin
  ├─ Anderson
  ├─ Brown
Boston
  ├─ Baker
  ├─ Davis
```

- **Find Austin + Anderson?** → Look in Austin section (efficient)
- **Find Anderson alone?** → Have to search all cities (inefficient)

### Composite Index Strategy

**If your queries are:**
```sql
WHERE first_name = 'John' AND last_name = 'Doe';  ← Both
WHERE first_name = 'John';                         ← First only
```

**Use index:** `(first_name, last_name)` ✅

**If your queries are:**
```sql
WHERE last_name = 'Doe';   ← Second only (frequent)
```

**Create separate index:** `(last_name)` ✅

### Best Practice: Index Column Order

Order columns by:
1. **Selectivity** (Most filters on most selective column first)
2. **Query patterns** (How your queries combine columns)

Example:
```sql
-- If queries often: WHERE department_id = 10 AND salary > 50000
-- Make index: (department_id, salary)

CREATE INDEX idx_dept_sal ON employees (department_id, salary);
```

---

**➡ Transition:** What if you need to search on a derived column, like UPPER(last_name)? That's where function-based indexes come in.

---

## 9. Function-Based Indexes

### What is Function-Based Index?

An index on a **function or expression** rather than just a column.

**Use case:** Frequent queries with functions on indexed column.

### Problem Scenario

```sql
-- Frequent query: case-insensitive search
SELECT * FROM employees WHERE UPPER(last_name) = 'DOE';

-- Without function-based index: 
-- - Can't use index on last_name
-- - Must do full table scan
-- - Apply UPPER() to every row (slow)
```

### Solution: Function-Based Index

```sql
CREATE INDEX idx_upper_last_name ON employees (UPPER(last_name));
```

Now:
```sql
SELECT * FROM employees WHERE UPPER(last_name) = 'DOE';
-- Oracle can use idx_upper_last_name (fast)
```

### Other Examples

```sql
-- Index on calculated column
CREATE INDEX idx_salary_annual 
ON employees (salary * 12);

-- Index on date extraction
CREATE INDEX idx_hire_year 
ON employees (EXTRACT(YEAR FROM hire_date));
```

### Trade-Offs

**Pros:**
- Fast queries with functions
- Support derived queries

**Cons:**
- Extra disk space
- Slower INSERT/UPDATE/DELETE
- More maintenance overhead

---

**➡ Transition:** For special cases like sequential inserts or testing, Oracle has specialized index types.

---

## 10. Reverse Key and Invisible Indexes

### Reverse Key Index

**What:** Reverses the bytes of indexed value before storage.

```sql
CREATE INDEX idx_reverse_emp_id 
ON employees (employee_id) REVERSE;
```

**Problem it solves:** Sequentially increasing inserts (like auto-increment PKs) cause **hot spots** in the index.

All new inserts go to the rightmost leaf node, causing contention.

**Solution:** Reverse key index distributes inserts evenly across all leaf nodes.

**When to use:**
- Auto-incrementing primary keys with high concurrency
- Parallel inserts of sequential values
- Data warehouse bulk loads

**Trade-off:** Range queries become slow (not useful for BETWEEN).

---

### Invisible Index

**What:** Index exists but is not used by the optimizer.

```sql
ALTER INDEX idx_employee_id INVISIBLE;
```

**Why use:**
- Test impact of removing index without actually dropping it
- If performance improves without index, keep it invisible
- Easy to make visible again

```sql
-- Make visible again
ALTER INDEX idx_employee_id VISIBLE;
```

**Scenario:**
```
Step 1: Make index invisible
        ↓
Step 2: Monitor query performance
        ↓
Step 3: If performance OK without it, drop the index
        OR if performance degrades, make it visible again
```

---

**➡ Transition:** Once Oracle decides to use an index, how exactly does it fetch the data? Different scan methods exist.

---

## 11. Index Scan Methods

Oracle uses different scan methods depending on the query:

### 1. Index Unique Scan

**When:** Query expects **at most one row** (unique/primary key).

```sql
SELECT * FROM employees WHERE employee_id = 104;
-- Primary key is unique, returns 1 row
```

**Execution:**
```
Index lookup for 104 → ROWID found → Fetch row → Return
(Stops immediately, no need to continue)
```

**Speed:** Fastest (1-2 index block reads).

---

### 2. Index Range Scan

**When:** Query expects **multiple rows** within a range.

```sql
SELECT * FROM employees WHERE employee_id BETWEEN 100 AND 200;

SELECT * FROM employees WHERE first_name LIKE 'S%';

SELECT * FROM employees WHERE salary > 50000;
```

**Execution:**
```
Index lookup for range start (100) 
  ↓
Read index entries: 100, 101, 102, ... 200
  ↓
Convert to ROWIDs
  ↓
Fetch matching rows
```

**Speed:** Fast (reads only relevant index range).

---

### 3. Index Full Scan

**When:** Needs to read **entire index** (rare).

```sql
SELECT employee_id FROM employees 
ORDER BY employee_id;
-- If index on employee_id, Oracle scans entire index
```

**Execution:**
```
Read all index blocks from top to bottom
  ↓
Extract all ROWIDs
  ↓
Return rows in order
```

**Speed:** Slow (reads entire index), but faster than table scan.

**When used:**
- ORDER BY matches index column
- No WHERE clause filtering
- All columns needed are in index (covered query)

---

### 4. Index Fast Full Scan

**When:** Needs full index scan **without ordering**, reads in parallel.

```sql
SELECT employee_id, first_name FROM employees;
-- Reads index fast (doesn't need sequential order)
```

**Execution:**
```
Read index blocks in parallel (multiple threads)
  ↓
No need to respect index order
  ↓
Much faster than index full scan
```

**Speed:** Fastest full scan (parallel I/O).

**When used:**
- All needed columns in index (covered query)
- Order not needed
- Full index needed anyway

---

### Scan Methods Comparison

| Scan Type | Use Case | Speed | Example |
| --- | --- | --- | --- |
| **Unique** | WHERE on unique column | Fastest | `WHERE id = 104` |
| **Range** | WHERE on range | Fast | `WHERE id BETWEEN 100-200` |
| **Full** | All index, ordered | Medium | `ORDER BY id` |
| **Fast Full** | All index, unordered | Fast | Full index, no order |

---

**➡ Transition:** How does Oracle decide which scan method to use? That's the Execution Plan's job.

---

## 12. Execution Plans

### What is Execution Plan?

An **execution plan** is Oracle's step-by-step **strategy** for executing a query.

It specifies:
- Which indexes to use (if any)
- Which scan method (unique, range, full)
- Which table to read first
- How to join tables
- Order of operations

### Example Execution Plan

```
Query: SELECT * FROM employees WHERE employee_id = 104;

Plan:
  1. Index Unique Scan on idx_employee_id (seek value 104)
  2. Table Access by ROWID (fetch complete row)
  3. Return result to user
```

### EXPLAIN PLAN Command

**What it does:** Shows the plan Oracle **will** execute (doesn't run the query).

```sql
EXPLAIN PLAN FOR
  SELECT * FROM employees WHERE employee_id = 104;

-- Display the plan
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
```

**Output example:**
```
Plan hash value: 1234567890

---------+---------+----------+--+
| Id | Operation | Name |
|---------+---------+----------+--+
| 0 | SELECT STATEMENT |
| 1 | TABLE ACCESS BY ROWID | EMPLOYEES |
| 2 | INDEX UNIQUE SCAN | IDX_EMPLOYEE_ID |
---------+---------+----------+--+
```

### Reading Execution Plan

**Key things to look for:**

1. **Is it using an index?**
   - Good: INDEX UNIQUE SCAN, INDEX RANGE SCAN
   - Bad: FULL TABLE SCAN

2. **Which index?**
   - Is it the expected index?

3. **Access order:**
   - Which table read first?
   - How are tables joined?

### Example 1: Query USES Index (Good)

```sql
EXPLAIN PLAN FOR
  SELECT * FROM employees WHERE employee_id = 104;

Plan:
  INDEX UNIQUE SCAN idx_employee_id  ← Uses index ✅
  TABLE ACCESS BY ROWID employees
```

### Example 2: Query DOES NOT Use Index (Bad)

```sql
EXPLAIN PLAN FOR
  SELECT * FROM employees WHERE SALARY * 12 > 1000000;

Plan:
  FULL TABLE SCAN employees  ← No index ❌
  (Function on column prevents index use)
```

---

**➡ Transition:** When does Oracle actually choose to use an index? Understanding this helps you optimize queries.

---

## 13. When Oracle Uses Indexes

Oracle's optimizer uses indexes when:

### 1. Selective WHERE Clause

```sql
-- Index useful (filters to small % of rows)
SELECT * FROM employees WHERE employee_id = 104;

-- Index less useful (filters to many rows)
SELECT * FROM employees WHERE department_id IN (10, 20, 30);
```

The optimizer calculates **selectivity:**
```
Selectivity = Filtered Rows / Total Rows

High selectivity (< 5%): Use index  ✅
Low selectivity (> 20%): Full scan  ❌
```

### 2. Indexed Column in WHERE

```sql
-- Uses index if idx_employee_id exists
SELECT * FROM employees WHERE employee_id = 104;

-- No index on salary, full scan
SELECT * FROM employees WHERE salary > 50000;
```

### 3. Covering Query

**Covering query:** All needed columns in the index (no table access needed).

```sql
CREATE INDEX idx_emp_cover ON employees (employee_id, first_name, salary);

-- Covering query (all columns in index)
SELECT employee_id, first_name, salary 
FROM employees 
WHERE employee_id = 104;
-- Reads only index, never touches table ✅
```

### 4. ORDER BY Matches Index

```sql
CREATE INDEX idx_emp_id ON employees (employee_id);

SELECT * FROM employees 
ORDER BY employee_id;
-- Index already sorted, can return in order ✅
```

### 5. First Column in Composite Index

```sql
CREATE INDEX idx_name ON employees (first_name, last_name);

-- Uses index ✅
SELECT * FROM employees WHERE first_name = 'John';

-- May not use index ❌
SELECT * FROM employees WHERE last_name = 'Doe';
```

---

**➡ Transition:** But there are situations where Oracle deliberately avoids using an index, even if one exists.

---

## 14. When Oracle Avoids Indexes

Oracle **skips indexes** when:

### 1. Function on Indexed Column

```sql
-- ❌ Index not used (function prevents it)
SELECT * FROM employees WHERE UPPER(last_name) = 'DOE';

-- ✅ Solution: Function-based index
CREATE INDEX idx_upper_last_name ON employees (UPPER(last_name));
```

### 2. Wildcard at Start (LIKE '%...')

```sql
-- ❌ Index not useful (doesn't know where to start)
SELECT * FROM employees WHERE last_name LIKE '%son';

-- ✅ Index useful (wildcard at end)
SELECT * FROM employees WHERE last_name LIKE 'son%';
```

Why? Index is sorted alphabetically, can't find '...son' quickly.

### 3. Operator Changes Column

```sql
-- ❌ Index not used
SELECT * FROM employees WHERE salary + 1000 > 50000;

-- ✅ Index useful
SELECT * FROM employees WHERE salary > 49000;
```

### 4. NOT Operator

```sql
-- ❌ Index not useful
SELECT * FROM employees WHERE NOT (employee_id = 104);

-- ✅ Index useful
SELECT * FROM employees WHERE employee_id > 104 OR employee_id < 104;
```

### 5. Missing Leading Column (Composite Index)

```sql
CREATE INDEX idx_name ON employees (first_name, last_name);

-- ❌ Index not used (missing leading column)
SELECT * FROM employees WHERE last_name = 'Doe';

-- ✅ Index used
SELECT * FROM employees WHERE first_name = 'John' AND last_name = 'Doe';
```

### 6. Index Not Visible

```sql
ALTER INDEX idx_employee_id INVISIBLE;

-- ❌ Index not used (invisible)
SELECT * FROM employees WHERE employee_id = 104;
-- Does full table scan instead
```

### 7. Table Too Small

```sql
-- If table has < 1000 rows, full scan may be faster than index
SELECT * FROM small_table WHERE id = 104;
-- Optimizer chooses full scan (overhead not worth it)
```

### 8. Significant NULL Values

```sql
-- B-tree index doesn't store NULLs
UPDATE employees SET phone_number = NULL WHERE retired = 'Y';

-- Index on phone_number is less useful now
SELECT * FROM employees WHERE phone_number = '555-1234';
```

---

## 15. Best Practices

### 1. Create Indexes on Frequently Searched Columns

**Avoid:**
```sql
-- No indexes; searches are slow
SELECT * FROM employees WHERE employee_id = 104;
```

**Prefer:**
```sql
CREATE INDEX idx_employee_id ON employees (employee_id);
```

---

### 2. Use Composite Indexes for Multi-Column Filters

**Avoid:**
```sql
CREATE INDEX idx_first ON employees (first_name);
CREATE INDEX idx_last ON employees (last_name);
-- Two separate index lookups
```

**Prefer:**
```sql
CREATE INDEX idx_name ON employees (first_name, last_name);
-- One combined index lookup
```

---

### 3. Composite Index Column Order Matters

**Avoid:**
```sql
-- If queries mostly: WHERE employee_id = ? AND salary > ?
-- But index is: (salary, employee_id) - wrong order
CREATE INDEX idx_bad ON employees (salary, employee_id);
```

**Prefer:**
```sql
-- Most selective/filtered column first
CREATE INDEX idx_good ON employees (employee_id, salary);
```

---

### 4. Don't Over-Index

**Avoid:**
```sql
-- Every column has an index
CREATE INDEX idx_first ON employees (first_name);
CREATE INDEX idx_last ON employees (last_name);
CREATE INDEX idx_salary ON employees (salary);
CREATE INDEX idx_dept ON employees (department_id);
-- Slow INSERT/UPDATE/DELETE, wasted disk space
```

**Prefer:**
```sql
-- Index only frequently searched columns
CREATE INDEX idx_employee_id ON employees (employee_id);
CREATE INDEX idx_dept_salary ON employees (department_id, salary);
```

---

### 5. Monitor Index Usage

**Monitor what's used:**
```sql
SELECT * FROM v$index_stats 
WHERE access_count > 0;
-- See which indexes are actually used

-- Drop unused indexes
DROP INDEX unused_index;
```

---

## 16. Common Mistakes

### Mistake 1: Creating Index on Low-Cardinality Column

```sql
-- ❌ WRONG (gender has only 2 values: M, F)
CREATE INDEX idx_gender ON employees (gender);

-- Most queries return half the table anyway, full scan faster
SELECT * FROM employees WHERE gender = 'M';

-- ✅ CORRECT: Use bitmap for analytics
CREATE BITMAP INDEX idx_gender ON employees (gender);
```

---

### Mistake 2: Wrong Column Order in Composite Index

```sql
-- ❌ WRONG
CREATE INDEX idx_bad ON employees (salary, employee_id);

-- Then query:
SELECT * FROM employees WHERE employee_id = 104;
-- Index not used! (leading column is salary, not employee_id)

-- ✅ CORRECT: Most frequently filtered column first
CREATE INDEX idx_good ON employees (employee_id, salary);
```

---

### Mistake 3: Function on Indexed Column

```sql
-- ❌ WRONG: Index not used
SELECT * FROM employees 
WHERE UPPER(last_name) = 'DOE';

-- ✅ CORRECT: Use function-based index
CREATE INDEX idx_upper_last_name ON employees (UPPER(last_name));
```

---

### Mistake 4: Not Testing Index Impact

```sql
-- ❌ WRONG: Create index without testing
CREATE INDEX idx_test ON employees (some_column);
-- Doesn't improve query, wastes disk/maintenance

-- ✅ CORRECT: Test with EXPLAIN PLAN first
EXPLAIN PLAN FOR SELECT ...;
-- See if index would be used
```

---

### Mistake 5: Assuming Index Always Helps

```sql
-- ❌ WRONG
SELECT * FROM employees;  -- No WHERE, no index needed
-- Oracle scans entire table anyway

-- ✅ CORRECT: Indexes help with selective queries
SELECT * FROM employees WHERE employee_id = 104;
-- Index is useful here
```

---

## 17. Interview Q&A

### Conceptual

**Q: What is an index and why do we need it?**

A: An index is a separate data structure storing column values + ROWIDs sorted for fast lookup. Without indexes, queries do full table scans (checking every row). With indexes, Oracle jumps directly to needed rows (nanoseconds vs seconds).

---

**Q: What's the difference between B-tree and Bitmap index?**

A: B-tree (default) stores value → ROWID list, best for high-cardinality (unique values), OLTP. Bitmap stores value → bitmap, best for low-cardinality (few values like gender), analytics.

---

**Q: What is the leading column rule?**

A: In a composite index on (first_name, last_name), the first column (first_name) is the leading column. Queries filtering on the leading column can use the index efficiently. Queries only on last_name may not use it.

---

### Comparison

**Q: Index Unique Scan vs Index Range Scan?**

A: Unique scan used when query returns ≤1 row (primary key lookup, fastest). Range scan when returning multiple rows within a range (BETWEEN, <, >, slowest).

---

**Q: When should I create composite index vs separate indexes?**

A: Composite index (one index on multiple columns) is better if queries filter on those columns together. Separate indexes if queries filter on each column independently.

---

### Scenario

**Q: Query is slow: `SELECT * FROM employees WHERE department_id = 10 AND salary > 50000`. No index exists. What's your optimization?**

A: Create composite index `(department_id, salary)` on those two columns. Oracle can use this for both filter conditions. Or create separate indexes if queries often filter only on department_id or only on salary.

---

**Q: EXPLAIN PLAN shows full table scan, but I created an index. Why isn't it used?**

A: Common reasons: (1) function on indexed column, (2) wildcard at start of LIKE, (3) missing leading column in composite index, (4) index is invisible, (5) selectivity so low that full scan is faster, (6) table too small.

---

## 18. Revision Summary

### 1-Minute Revision

**Index = Sorted structure storing column value + ROWID for fast lookup.**

1. **Without index:** Full table scan (slow, checks every row)
2. **With index:** Direct lookup (fast, jumps to ROWID)
3. **B-tree:** Default, high-cardinality (unique values), OLTP
4. **Bitmap:** Low-cardinality (few values), analytics
5. **Composite index:** Multiple columns; leading column rule (first column most selective)
6. **Function-based:** Index on expression/function result
7. **Scan methods:** Unique (1 row, fastest), Range (multiple rows), Full, Fast Full
8. **Execution plan:** Oracle's strategy for executing query
9. **EXPLAIN PLAN:** Shows plan without executing
10. **Leading column rule:** In (A, B) composite index, must include leading column A for index to be used

### Interview Keywords

- Full Table Scan vs Index Lookup
- B-tree (high-cardinality, OLTP), Bitmap (low-cardinality, analytics)
- Cardinality (distinct values)
- Leading Column Rule (composite indexes)
- Index Unique Scan, Index Range Scan
- Execution Plan, EXPLAIN PLAN
- Index Selectivity
- Covering query (all columns in index)
- Function on indexed column (prevents index use)
- ROWID (address of row, stored in index)

### Important Syntax

```sql
-- Create B-tree index
CREATE INDEX idx_emp_id ON employees (employee_id);

-- Create composite index
CREATE INDEX idx_name ON employees (first_name, last_name);

-- Create function-based index
CREATE INDEX idx_upper_last ON employees (UPPER(last_name));

-- Create bitmap index
CREATE BITMAP INDEX idx_gender ON employees (gender);

-- Create reverse key index
CREATE INDEX idx_rev ON employees (employee_id) REVERSE;

-- Make index invisible
ALTER INDEX idx_emp_id INVISIBLE;

-- See execution plan
EXPLAIN PLAN FOR SELECT * FROM employees WHERE employee_id = 104;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Check index usage
SELECT * FROM v$index_stats WHERE access_count > 0;
```

## What happens without an Index?

Without an index, the database must perform a full table scan to find the required data.

This means that it will check each row in the table one by one until it finds the matching rows.

This can be very slow, especially for large tables.

---

## What happens when we create an index?

When you create an index on a column, Oracle creates a **separate data structure** (called a B-tree index).

This structure stores only two important pieces of information:

- The indexed column value
- The ROWID of the corresponding row in the table

For example, if you create an index on `EMPLOYEE_ID`, the index conceptually looks like this:

| Employee_ID | ROWID  |
| ----------- | ------ |
| 101         | AAA432 |
| 102         | AAA901 |
| 103         | AAA876 |
| 104         | AAA654 |
| ...         | ...    |

> Think of this as a simplified view. Internally Oracle stores it as a B-tree, not as a normal table.

---

### What happens when we execute?

```sql
SELECT *
FROM employees
WHERE employee_id = 104;
```

#### Step 1

Oracle first looks into the **index**, not the table.

It searches for the value **104**.

#### Step 2

The index quickly returns the ROWID.

```
104  →  AAA654
```

#### Step 3

Using that ROWID, Oracle directly jumps to the exact row in the table.

```
ROWID AAA654
```

#### Step 4

Oracle fetches the complete employee record and returns it to the user.

---

### Why is it faster?

Without an index:

```
Table

Row 1
Row 2
Row 3
...
Row 9,999,999
Row 10,000,000
```

Oracle may need to examine every row until it finds Employee 104.

This is called a **Full Table Scan**.

---

With an index:

```
Search index
        ↓
Find ROWID
        ↓
Jump directly to that row
        ↓
Fetch the record
```

Instead of scanning millions of rows, Oracle performs a quick lookup in the index and then goes straight to the required row.

---

### One important point to tell students

A common misconception is:

> "Oracle searches for the ROWID again."

No.

The ROWID is **already stored inside the index**. Oracle does **not** search the table to find the ROWID. It simply reads the ROWID from the index and uses it like a house address to directly locate the row.

Think of it like this:

```
Employee ID (104)
        │
        ▼
      Index
        │
        ▼
ROWID = AAA654
        │
        ▼
Jump directly to the row in the table
        │
        ▼
Return the employee details
```

This is the fundamental idea behind why indexes make data retrieval much faster.

---

## How to create an index?

```sql
CREATE INDEX idx_employee_id
ON employees (employee_id);
```

## Types of Indexes

1. B-tree Index (default)
2. Unique Index
3. Composite Index
4. Function-Based Index
5. Bitmap Index
6. Reverse Key Index
7. Invisible Index

---

### B-tree Index

It is used for **high-cardinality data** (columns with many unique values). It is the *default index* type in Oracle.

**Cardinality** refers to the number of unique values in a column. For example, a column storing employee IDs will have high cardinality because each employee has a unique ID.

> Example of high-cardinality data: employee_id, email, social_security_number

> Example of low-cardinality data: gender, marital_status, country

#### why is B-tree Index is default?

B-tree indexes are efficient for a wide range of queries,

They provide fast access to data and are suitable for most use cases

---

### Unique Index

It is used to enforce **uniqueness** on a column or a set of columns. When you create a unique index, Oracle ensures that no two rows can have the same value(s) in the indexed column(s).

Unique Index is ideally B-tree index but with a uniqueness constraint or without duplicacy.

```sql
CREATE UNIQUE INDEX idx_email
ON employees (email);
```

> When you create a unique constraint on a column, Oracle automatically creates a unique index to enforce that constraint.
---

### Composite Index

A composite index is an index on **multiple columns**.

It is useful when queries filter on more than one column.

For example, if you frequently query a table using both `last_name` and `first_name`, you can create a composite index on those two columns.

The order of the columns in the index matters, as it affects how the index can be used by the optimizer.

```sql
CREATE INDEX idx_emp ON employees(first_name,last_name)
```

#### Leading Column rule

It means that the first column in the index is the most important for the optimizer. If a query filters on the leading column, the index can be used effectively. If it filters only on the second column, the index may not be used.

for example, if you have a composite index on `(first_name, last_name)`, a query filtering on `first_name` can use the index, also the query filtering with both `first_name` and `last_name` can use the index.
But if you have a query filtering only on `last_name` may not.

```sql
SELECT * FROM employees WHERE first_name = 'John'; -- can use the index
SELECT * FROM employees WHERE first_name = 'John' AND last_name = 'Doe'; -- can use the index
SELECT * FROM employees WHERE last_name = 'Doe' and first_name = 'John'; -- can use the index
SELECT * FROM employees WHERE last_name = 'Doe'; -- may not use the index
```

---

### Function-Based Index

It is an index based on a function or expression rather than just a column.

For example, if you frequently query a table using the upper case of a column, you can create a function-based index on that expression.

```sql
CREATE INDEX idx_upper_last_name
ON employees (UPPER(last_name));
```

---

### Bitmap Index

Index that uses a bitmap for each key value instead of a list of ROWIDs. It is efficient for **low-cardinality data** (columns with few unique values).

Your explanation is heading in the right direction, but there are a couple of inaccuracies:

1. **Oracle does not store one bitmap column called `bitmap`.**
2. **Bitmap indexes still ultimately use ROWIDs to fetch table rows.** The bitmap is only used to identify *which rows qualify*. Oracle then converts those bits into ROWIDs before reading the table.
3. The biggest advantage of bitmap indexes is that Oracle can combine multiple bitmaps (`AND`, `OR`, `NOT`) extremely quickly.

Examples:

- Gender (M/F)
- Marital Status
- Yes/No
- Department Type
- Country Code (if only a few countries)

---

#### Example Table

| Row | Gender |
| --- | ------ |
| 1   | M      |
| 2   | F      |
| 3   | M      |
| 4   | F      |
| 5   | M      |
| 6   | F      |

Oracle internally creates a bitmap for **each distinct value**.

### Bitmap for 'M'

| Row | 1 | 2 | 3 | 4 | 5 | 6 |
| --- | - | - | - | - | - | - |
| Bit | 1 | 0 | 1 | 0 | 1 | 0 |

```
M → 101010
```

---

### Bitmap for 'F'

| Row | 1 | 2 | 3 | 4 | 5 | 6 |
| --- | - | - | - | - | - | - |
| Bit | 0 | 1 | 0 | 1 | 0 | 1 |

```
F → 010101
```

Notice:

There is **one bitmap for M** and **another bitmap for F**.

---

### What happens when we execute?

```sql
SELECT *
FROM employees
WHERE gender = 'M';
```

#### Step 1

Oracle goes to the bitmap index.

#### Step 2

It finds the bitmap for **M**.

```
101010
```

#### Step 3

Every **1** means

> "This row contains M."

Every **0** means

> "Ignore this row."

```
Row 1 → Yes

Row 2 → No

Row 3 → Yes

Row 4 → No

Row 5 → Yes

Row 6 → No
```

#### Step 4

Oracle converts these matching positions into ROWIDs internally and fetches only those rows from the table.

---

### Why is Bitmap Index powerful?

Suppose you have another column:

| Row | Gender | Married |
| --- | ------ | ------- |
| 1   | M      | Y       |
| 2   | F      | N       |
| 3   | M      | Y       |
| 4   | F      | Y       |
| 5   | M      | N       |
| 6   | F      | N       |

Bitmap for Gender='M'

```
101010
```

Bitmap for Married='Y'

```
101100
```

Query:

```sql
WHERE Gender='M'
AND Married='Y'
```

Oracle simply performs a **bitwise AND**.

```
101010
AND
101100
------
101000
```

Only Rows **1 and 3** satisfy both conditions.

This bitwise operation is extremely fast, even for millions of rows.

---

#### B-tree vs Bitmap

| B-tree Index                          | Bitmap Index                                        |
| ------------------------------------- | --------------------------------------------------- |
| Stores **Value → ROWID**              | Stores **Value → Bitmap**                           |
| Good for high-cardinality columns     | Good for low-cardinality columns                    |
| Best for OLTP systems                 | Best for Data Warehouses (OLAP)                     |
| Finds one ROWID quickly               | Combines multiple conditions very efficiently       |

---

#### Interview Question

**Does a Bitmap Index avoid ROWIDs?**

**Answer:** No. A bitmap index uses bitmaps to identify matching rows, but Oracle still translates those matching bits into ROWIDs to retrieve the actual rows from the table. The bitmap helps Oracle determine *which* rows qualify; the ROWID is still used to fetch the row data. This is a common interview question because many people mistakenly think bitmap indexes never use ROWIDs.

### Reverse Key Index

A reverse key index is a type of B-tree index where the bytes(digits) of the indexed column values are reversed before being stored in the index.

This can help distribute inserts more evenly across the index, reducing contention and improving performance for certain workloads.

use case: When you have a sequentially increasing value (like an auto-incrementing primary key) and you want to avoid hot spots in the index.

mostly when multiple sessions are inserting into the same index concurrently, a reverse key index can help reduce contention.

```sql
CREATE INDEX idx_reverse_emp_id
ON employees (REVERSE(employee_id)) REVERSE;
```

---

### Invisible Index

An invisible index is an index that exists in the database but is not used by the optimizer for query execution plans.

instead of dropping an index, you can make it invisible. This allows you to test the impact of removing the index without actually deleting it.

```sql
ALTER INDEX idx_employee_id INVISIBLE;
```

so after testing, if you want to make it visible again, you can do:

```sql
ALTER INDEX idx_employee_id VISIBLE;
```

## Index scan methods - How Oracle uses an index to retrieve data?

How Oracle internally finds the ROWID from the index and fetches the row from the table.

1. **Index Unique Scan**: Used when the query is expected to return at most one row. For example, when querying by a primary key or unique index.

For example:
In the where condition, if you are searching for a unique value, Oracle will use an Index Unique Scan to quickly locate the row.
Oracle knows there is only one row that matches the condition, so it can stop searching after finding that row.
It gets the rowid from the index and fetches the row directly.

1. **Index Range Scan**: Used when the query is expected to return multiple rows. For example, when querying a range of values.

```sql
SELECT *
FROM employees
WHERE employee_id BETWEEN 100 AND 200;

SELECT First_Name from employees
WHERE First_Name LIKE 'S%';

```

reads only the required portion of the index that contains the range of values, rather than scanning the entire index or table.

1. **Index Full Scan**: Used when the query needs to read all rows in the index. This can happen when the query does not have a selective condition or when the optimizer determines that scanning the entire index is more efficient than using a range scan.

```sql
SELECT employee_id
FROM employees order by employee_id; 
```

1. **Index Fast Full Scan**: Similar to an index full scan, but it can read the index blocks in parallel and does not need to access the table at all if all required columns are in the index.

```sql
SELECT employee_id, first_name
FROM employees order by employee_id;
```

## When Oracle uses an index?

When you run a query, Oracle's optimizer decides whether to use an index or not based on several factors:

1. The **selectivity** of the index (how many rows it filters out).
2. The **size of the table** and the **number of rows**.
3. The **cost of using the index** versus doing a full table scan.

## when oracle avoids an index?

When the optimizer determines that using the index would be less efficient than a full table scan, it may choose to avoid the index. This can happen in cases where:

1. The index is **not selective** enough (e.g., it filters out too few rows).
2. The table is **small enough** that a full scan is faster than using the index.
3. The query involves **operations that are not supported by the index** (e.g., functions on indexed columns).
4. **Missing of Leading Column** rule in case of Composite Index.
5. Wildcard beginning with %
6. when the index is invisible or disabled.

> **What is Optimizer?** The Optimizer is a component of Oracle that decides the best way to execute a SQL query for the best performance.

#### An Execution Plan

is the step-by-step instructions Oracle will follow to execute your SQL query.

For example, it may say:

> Use the EMPLOYEE_ID index.
nd the matching ROWID.Read the table row.
Return the result.

Think of it as Oracle's roadmap for executing the query.

#### What is EXPLAIN PLAN?

EXPLAIN PLAN is a command that shows you which execution plan the optimizer has chosen.

It doesn't execute the query. It only shows the plan Oracle intends to use.

Using EXPLAIN PLAN, you can see things like:

Will Oracle use an index?
Will it perform a full table scan?
Which table is read first?
Which join method is used?

This helps you understand and improve query performance.
