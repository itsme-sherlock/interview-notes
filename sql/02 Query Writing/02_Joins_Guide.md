# SQL Joins Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Join** = Combines rows from two or more tables based on matching columns; creates result set with columns from all tables.
- **INNER JOIN** = Returns rows where join condition matches in BOTH tables; ignores unmatched rows from either side.
- **LEFT JOIN (OUTER)** = Returns ALL rows from left table + matching rows from right; unmatched right rows show NULL.
- **RIGHT JOIN (OUTER)** = Returns ALL rows from right table + matching rows from left; unmatched left rows show NULL.
- **FULL OUTER JOIN** = Returns ALL rows from both tables; unmatched rows show NULL on one side.
- **CROSS JOIN** = Cartesian product; combines every row from left table with every row from right (rarely used, powerful but dangerous).
- **Self-join** = Join table to itself; useful for hierarchical data (manager-employee, parent-child) or comparisons.
- **Join Performance** = Use indexed columns for join predicates; INNER JOINs faster than OUTER; avoid unnecessary joins.
- **NULL handling** = OUTER joins produce NULLs; use COALESCE to merge columns; NULL comparisons fail (IS NULL needed).
- **Interview Keywords** = Cartesian product, join order, predicate pushdown, hash join vs nested loop, join hints.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Joins?](#1-why-do-we-need-joins)
2. [What Are Joins?](#2-what-are-joins)
3. [INNER JOIN: Matching Rows Only](#3-inner-join-matching-rows-only)
4. [LEFT OUTER JOIN: Keep All Left Rows](#4-left-outer-join-keep-all-left-rows)
5. [RIGHT OUTER JOIN: Keep All Right Rows](#5-right-outer-join-keep-all-right-rows)
6. [FULL OUTER JOIN: Keep All Rows](#6-full-outer-join-keep-all-rows)
7. [CROSS JOIN: Cartesian Product](#7-cross-join-cartesian-product)
8. [Self-Joins: Table to Itself](#8-self-joins-table-to-itself)
9. [Multi-Table Joins](#9-multi-table-joins)
10. [Join Conditions and Predicates](#10-join-conditions-and-predicates)
11. [NULL Handling in Joins](#11-null-handling-in-joins)
12. [Join Performance and Optimization](#12-join-performance-and-optimization)
13. [Comparison Matrix](#13-comparison-matrix)
14. [Common Mistakes](#14-common-mistakes)
15. [Interview Q&A](#15-interview-qa)
16. [Revision Summary](#16-revision-summary)

---

## 1. Why Do We Need Joins?

### The Problem: Data is Normalized Across Multiple Tables

**Scenario:** You're building a payroll system.

```sql
-- Data structure (normalized)
EMPLOYEES table:
  employee_id | name | department_id | salary
  101 | John | 10 | 50000
  102 | Jane | 20 | 60000
  103 | Bob | 10 | 55000

DEPARTMENTS table:
  department_id | department_name | manager_id
  10 | Sales | 101
  20 | IT | 102
  30 | HR | NULL

SALARIES_HISTORY table:
  employee_id | salary_date | amount
  101 | 2025-01-01 | 45000
  101 | 2026-01-01 | 50000
  102 | 2025-01-01 | 55000
```

**The Problem:** To answer "Show employee name, current salary, department name, and manager name", you need data from 3+ tables.

```sql
-- WITHOUT joins (pseudo-code)
DECLARE
    v_name VARCHAR2(50);
    v_salary NUMBER;
    v_dept_name VARCHAR2(50);
    v_manager_name VARCHAR2(50);
BEGIN
    SELECT name INTO v_name FROM employees WHERE employee_id = 101;
    SELECT salary INTO v_salary FROM employees WHERE employee_id = 101;
    SELECT department_name INTO v_dept_name FROM departments WHERE department_id = (SELECT department_id FROM employees WHERE employee_id = 101);
    SELECT name INTO v_manager_name FROM employees WHERE employee_id = (SELECT manager_id FROM departments WHERE department_id = (SELECT department_id FROM employees WHERE employee_id = 101));
    -- Nightmare!
END;
```

### The Solution: Joins Combine Tables in One Query

```sql
SELECT 
    e.name,
    e.salary,
    d.department_name,
    m.name AS manager_name
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id
LEFT JOIN employees m ON d.manager_id = m.employee_id
WHERE e.employee_id = 101;
```

**Result:** One query, clean data from multiple tables.

### Real-World Scenarios

- **E-Commerce:** Join orders, customers, products, shipments to answer "Show all orders by customer with product details and tracking"
- **Healthcare:** Join patients, appointments, doctors, diagnoses to answer "Which diagnoses does Dr. Smith treat most?"
- **Finance:** Join accounts, transactions, customers to reconcile and audit
- **HR:** Join employees, departments, salary_history, job_titles to build payroll and org charts

---

**➡ Transition:** Joins are fundamental. Let's understand the different types.

---

## 2. What Are Joins?

### Simple Definition

A **join** combines rows from two or more tables by matching a condition (usually column equality). The result has columns from all tables and rows that satisfy the join condition.

### Mental Model: Venn Diagrams

```
INNER JOIN
┌─────────────────────┐
│      Table A        │
│   ┌─────────────┐   │
│   │   Match     │   │  ← Only intersection
│   └─────────────┘   │
│      Table B        │
└─────────────────────┘

LEFT JOIN
┌──────────────────────────────┐
│        Table A               │
│   ┌─────────────────────┐    │
│   │  ALL A + Match     │    │  ← All A + intersection
│   └─────────────────────┘    │
│        Table B               │
└──────────────────────────────┘

FULL OUTER JOIN
┌──────────────────────────────────────┐
│  ALL A + Match + ALL B  │  ← Everything
└──────────────────────────────────────┘
```

### General Syntax

```sql
SELECT column_list
FROM table1
[INNER | LEFT | RIGHT | FULL] JOIN table2
  ON join_condition
[WHERE additional_conditions]
[ORDER BY ...];
```

---

**➡ Transition:** INNER JOIN is the most common. Let's master it first.

---

## 3. INNER JOIN: Matching Rows Only

### Definition

**INNER JOIN** returns only rows where the join condition is TRUE in BOTH tables. Unmatched rows from either table are excluded.

### Syntax

```sql
SELECT column_list
FROM table1
INNER JOIN table2
  ON table1.column = table2.column;
```

### Example 1: Simple INNER JOIN

```sql
-- Q: Show employees and their department names
SELECT 
    e.employee_id,
    e.name,
    d.department_id,
    d.department_name
FROM employees e
INNER JOIN departments d
  ON e.department_id = d.department_id;
```

**Result:**
```
employee_id | name | department_id | department_name
101 | John | 10 | Sales
102 | Jane | 20 | IT
103 | Bob | 10 | Sales
-- Employee with dept_id = 30 (unmatched) is excluded
```

**Key Insight:** Only rows where `e.department_id = d.department_id` appear.

### Example 2: Multiple INNER JOINs

```sql
-- Q: Show employees, their departments, and their current salary history
SELECT 
    e.employee_id,
    e.name,
    d.department_name,
    sh.salary_date,
    sh.amount
FROM employees e
INNER JOIN departments d
  ON e.department_id = d.department_id
INNER JOIN salaries_history sh
  ON e.employee_id = sh.employee_id;
```

**Data Filtering:** If an employee has no salary history, they don't appear.

### Example 3: INNER JOIN with WHERE Clause

```sql
-- Q: Show employees in Sales department with salary > 50000
SELECT 
    e.employee_id,
    e.name,
    e.salary,
    d.department_name
FROM employees e
INNER JOIN departments d
  ON e.department_id = d.department_id
WHERE d.department_name = 'Sales'
  AND e.salary > 50000;
```

---

**➡ Transition:** INNER JOIN loses unmatched rows. Sometimes you need all rows from one side. That's LEFT JOIN.

---

## 4. LEFT OUTER JOIN: Keep All Left Rows

### Definition

**LEFT OUTER JOIN** returns ALL rows from the left table, plus matching rows from the right table. Unmatched right rows show NULL in the result.

### Syntax

```sql
SELECT column_list
FROM table1
LEFT [OUTER] JOIN table2
  ON table1.column = table2.column;
```

### Example 1: Simple LEFT JOIN

```sql
-- Q: Show all employees and their department names (even if dept doesn't exist)
SELECT 
    e.employee_id,
    e.name,
    d.department_id,
    d.department_name
FROM employees e
LEFT JOIN departments d
  ON e.department_id = d.department_id;
```

**Result:**
```
employee_id | name | department_id | department_name
101 | John | 10 | Sales
102 | Jane | 20 | IT
103 | Bob | 10 | Sales
104 | Alice | NULL | NULL  -- No matching dept; shows NULL
-- Unlike INNER JOIN, Alice still appears
```

**Key Difference:** Alice (no department) appears with NULLs, unlike INNER JOIN.

### Example 2: LEFT JOIN Detecting Orphaned Records

```sql
-- Q: Find employees NOT assigned to any department (orphaned records)
SELECT 
    e.employee_id,
    e.name,
    d.department_id
FROM employees e
LEFT JOIN departments d
  ON e.department_id = d.department_id
WHERE d.department_id IS NULL;
```

**Result:**
```
employee_id | name | department_id
104 | Alice | NULL
-- Only unmatched rows appear
```

**Use Case:** Data quality checks, finding missing references.

### Example 3: LEFT JOIN with Aggregation

```sql
-- Q: Show each department with count of employees (even if no employees)
SELECT 
    d.department_id,
    d.department_name,
    COUNT(e.employee_id) AS employee_count
FROM departments d
LEFT JOIN employees e
  ON d.department_id = e.department_id
GROUP BY d.department_id, d.department_name;
```

**Result:**
```
department_id | department_name | employee_count
10 | Sales | 2
20 | IT | 1
30 | HR | 0  -- No employees, but dept still appears
```

---

**➡ Transition:** LEFT keeps left table intact. RIGHT does the same for the right table.

---

## 5. RIGHT OUTER JOIN: Keep All Right Rows

### Definition

**RIGHT OUTER JOIN** returns ALL rows from the right table, plus matching rows from the left table. Unmatched left rows show NULL.

### Syntax

```sql
SELECT column_list
FROM table1
RIGHT [OUTER] JOIN table2
  ON table1.column = table2.column;
```

### Example

```sql
-- Q: Show all departments and their employees (even if no employees)
SELECT 
    e.employee_id,
    e.name,
    d.department_id,
    d.department_name
FROM employees e
RIGHT JOIN departments d
  ON e.department_id = d.department_id;
```

**Result:**
```
employee_id | name | department_id | department_name
101 | John | 10 | Sales
102 | Jane | 20 | IT
103 | Bob | 10 | Sales
NULL | NULL | 30 | HR  -- All depts shown; unmatched employees are NULL
```

**Key Insight:** Similar to LEFT JOIN but with right table prioritized.

### RIGHT JOIN vs LEFT JOIN

```sql
-- These are EQUIVALENT:
SELECT * FROM employees e
RIGHT JOIN departments d ON e.department_id = d.department_id;

-- Is the same as:
SELECT * FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id;
```

**Convention:** Use LEFT JOIN; avoid RIGHT (less readable when complex).

---

**➡ Transition:** What if you need ALL rows from both tables?

---

## 6. FULL OUTER JOIN: Keep All Rows

### Definition

**FULL OUTER JOIN** returns ALL rows from both tables. Unmatched rows show NULL on the missing side.

### Syntax

```sql
SELECT column_list
FROM table1
FULL [OUTER] JOIN table2
  ON table1.column = table2.column;
```

### Example

```sql
-- Q: Show all employees and all departments (reconciliation)
SELECT 
    e.employee_id,
    e.name,
    d.department_id,
    d.department_name
FROM employees e
FULL OUTER JOIN departments d
  ON e.department_id = d.department_id;
```

**Result:**
```
employee_id | name | department_id | department_name
101 | John | 10 | Sales
102 | Jane | 20 | IT
103 | Bob | 10 | Sales
104 | Alice | NULL | NULL  -- Employee with no dept
NULL | NULL | 30 | HR  -- Dept with no employees
```

### Use Cases for FULL OUTER JOIN

- **Reconciliation:** Find mismatches between systems
- **Merge/Sync:** Identify rows to insert, update, or delete
- **Audit:** Compare two tables for discrepancies

### Oracle-Specific Note

Oracle doesn't support `FULL OUTER JOIN` with (+) operator; use `FULL OUTER JOIN` keyword or simulate with `UNION`:

```sql
-- Simulating FULL OUTER JOIN with UNION (for DBs without FULL support)
SELECT 
    e.employee_id, e.name, d.department_id, d.department_name
FROM employees e
LEFT JOIN departments d ON e.department_id = d.department_id
UNION
SELECT 
    e.employee_id, e.name, d.department_id, d.department_name
FROM employees e
RIGHT JOIN departments d ON e.department_id = d.department_id
WHERE e.employee_id IS NULL;
```

---

**➡ Transition:** CROSS JOIN is special—no join condition. Every row from one table combines with every row from the other.

---

## 7. CROSS JOIN: Cartesian Product

### Definition

**CROSS JOIN** produces a Cartesian product: every row from table1 combined with every row from table2. **No join condition needed.**

### Syntax

```sql
SELECT column_list
FROM table1
CROSS JOIN table2;
-- OR (older syntax)
SELECT column_list FROM table1, table2;
```

### Example: Dangerous Use Case

```sql
-- ⚠️ DANGEROUS: Combinatorial explosion
SELECT * FROM employees CROSS JOIN departments;
```

**Result:** If employees has 100 rows and departments has 30 rows, result has 100 × 30 = **3,000 rows**.

**Performance Impact:** CROSS JOINs are rarely used intentionally but can happen accidentally with missing WHERE conditions.

### Example: Legitimate Use Case (Date Ranges)

```sql
-- Q: Generate all combinations of employees and work dates in 2026
SELECT 
    e.employee_id,
    e.name,
    d.work_date
FROM employees e
CROSS JOIN (
    SELECT TRUNC(SYSDATE) + LEVEL - 1 AS work_date
    FROM DUAL
    CONNECT BY LEVEL <= 365
) d
WHERE EXTRACT(YEAR FROM d.work_date) = 2026;
```

**Result:** Each employee × each day in 2026 = employee schedule template.

---

**➡ Transition:** Self-joins are INNER/LEFT/FULL joins, but with a table joined to itself.

---

## 8. Self-Joins: Table to Itself

### Definition

**Self-join** joins a table to itself using two aliases. Useful for hierarchical data or comparisons within the same table.

### Example 1: Manager-Employee Hierarchy

```sql
-- Q: Show each employee and their manager name
SELECT 
    e.employee_id,
    e.name AS employee_name,
    e.manager_id,
    m.name AS manager_name
FROM employees e
LEFT JOIN employees m
  ON e.manager_id = m.employee_id;
```

**Result:**
```
employee_id | employee_name | manager_id | manager_name
101 | John | 102 | Jane
102 | Jane | 101 | John
103 | Bob | 101 | John
104 | Alice | NULL | NULL  -- No manager (top of hierarchy)
```

**Key:** Same table, two aliases (e for employee, m for manager).

### Example 2: Finding Duplicates (Self-Join Comparison)

```sql
-- Q: Find employees with the same salary (potential duplicates)
SELECT 
    e1.employee_id,
    e1.name,
    e1.salary,
    e2.employee_id AS duplicate_id,
    e2.name AS duplicate_name
FROM employees e1
INNER JOIN employees e2
  ON e1.salary = e2.salary
  AND e1.employee_id < e2.employee_id;  -- Avoid duplicating pairs
```

**Result:**
```
employee_id | name | salary | duplicate_id | duplicate_name
101 | John | 50000 | 103 | Bob
-- John and Bob have same salary
```

---

**➡ Transition:** Real queries often need more than 2 tables. Let's join 3+.

---

## 9. Multi-Table Joins

### Example: Joining 4 Tables

```sql
-- Q: Show employees, departments, job titles, and salary history
SELECT 
    e.employee_id,
    e.name,
    d.department_name,
    j.job_title,
    sh.salary_date,
    sh.amount
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id
INNER JOIN job_titles j ON e.job_id = j.job_id
LEFT JOIN salaries_history sh ON e.employee_id = sh.employee_id
ORDER BY e.employee_id, sh.salary_date;
```

**Join Order Matters:** Oracle optimizes based on join order, but you should write for readability.

### Performance Note: 2+ INNER JOINs are Fast

```sql
-- FAST: Multiple INNER JOINs (filters early)
SELECT * FROM employees e
INNER JOIN departments d ON ...
INNER JOIN job_titles j ON ...;  -- Rows eliminated at each step

-- SLOW: INNER then OUTER (can't eliminate early)
SELECT * FROM employees e
LEFT JOIN departments d ON ...
INNER JOIN job_titles j ON ...;  -- LEFT JOIN can't eliminate, then filter
```

---

## 10. Join Conditions and Predicates

### Standard Join Condition (Equality)

```sql
FROM table1 t1
INNER JOIN table2 t2 ON t1.id = t2.id;
```

### Non-Equality Join Condition

```sql
-- Q: Find employees and salary history where salary amount matches
FROM employees e
INNER JOIN salaries_history sh ON e.employee_id = sh.employee_id
  AND e.salary = sh.amount;

-- Q: Find pairs of employees with salary differences
FROM employees e1
INNER JOIN employees e2 ON e1.department_id = e2.department_id
  AND e1.salary > e2.salary;  -- Non-equality condition
```

### Multiple Join Conditions

```sql
FROM employees e
INNER JOIN departments d
  ON e.department_id = d.department_id
  AND e.company_id = d.company_id;  -- Two conditions
```

### Filtering with WHERE vs ON

```sql
-- Filter in ON: Applied during join
SELECT * FROM employees e
LEFT JOIN departments d ON e.department_id = d.department_id
  AND d.department_name = 'Sales';  -- Filter in ON
-- Result: All employees; dept columns NULL if dept != 'Sales'

-- Filter in WHERE: Applied after join
SELECT * FROM employees e
LEFT JOIN departments d ON e.department_id = d.department_id
WHERE d.department_name = 'Sales';  -- Filter in WHERE
-- Result: Only employees in Sales (eliminates unmatched rows)
```

**Key Difference:** Filter in ON for OUTER joins to preserve rows; filter in WHERE to eliminate rows.

---

## 11. NULL Handling in Joins

### Problem: NULL in Join Columns

```sql
-- Employee with department_id = NULL
SELECT * FROM employees WHERE department_id IS NULL;
-- Result: 104 | Alice | NULL

-- When joined:
SELECT * FROM employees e
LEFT JOIN departments d ON e.department_id = d.department_id;
-- Result: Alice's row still appears, but d.* columns are NULL
-- (NULL = NULL is never TRUE in SQL)
```

### COALESCE for Unified Column

```sql
SELECT 
    COALESCE(e.employee_id, -1) AS employee_id,
    COALESCE(e.name, 'Unknown') AS name,
    COALESCE(d.department_name, 'Unassigned') AS department
FROM employees e
FULL OUTER JOIN departments d ON e.department_id = d.department_id;
```

**Result:** NULLs replaced with defaults.

### NVL vs COALESCE

```sql
NVL(column, default)        -- Returns default if column is NULL
COALESCE(col1, col2, ...)  -- Returns first non-NULL value
```

---

## 12. Join Performance and Optimization

### Rule 1: Use Indexed Columns for Joins

```sql
-- FAST: Joining on indexed columns (e.g., foreign keys)
SELECT * FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id;
-- department_id is usually indexed

-- SLOW: Joining on function results
SELECT * FROM employees e
INNER JOIN departments d ON UPPER(e.dept_name) = UPPER(d.name);
-- Functions prevent index usage
```

### Rule 2: INNER JOINs are Faster than OUTER

```sql
-- FAST: INNER (rows eliminated early)
SELECT * FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id;

-- SLOWER: OUTER (all rows kept)
SELECT * FROM employees e
LEFT JOIN departments d ON e.department_id = d.department_id;
```

### Rule 3: Join Order Matters in Some Cases

```sql
-- Query optimizer reorders automatically, but write readable code
-- GOOD: Filter early (smaller intermediate results)
SELECT * FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id
WHERE e.salary > 50000;  -- Filter employees first

-- LESS EFFICIENT: Big joins first
SELECT * FROM salaries_history sh
INNER JOIN employees e ON sh.employee_id = e.employee_id
INNER JOIN departments d ON e.department_id = d.department_id
WHERE sh.salary > 50000;  -- Filter last
```

### Join Hints (Oracle)

```sql
-- Force specific join algorithm
SELECT /*+ USE_HASH(e d) */ * FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id;
-- USE_HASH: Hash join (better for large tables)
-- USE_NL: Nested loop (better for small tables + indexed lookup)
```

---

## 13. Comparison Matrix

| Join Type | Returns | Use Case | Key Characteristic |
| --- | --- | --- | --- |
| **INNER** | Matching rows only | Default; excludes unmatched | Both sides match |
| **LEFT** | All left + matching right | Preserve left table | Left table complete |
| **RIGHT** | All right + matching left | Preserve right table | Right table complete |
| **FULL** | All from both tables | Reconciliation | Both tables complete |
| **CROSS** | Cartesian product | Date ranges, matrices | Every combination |
| **Self** | Table to itself | Hierarchies, comparisons | Same table, two aliases |

---

## 14. Common Mistakes

### Mistake 1: Forgetting the ON Clause (Accidental CROSS JOIN)

```sql
-- ❌ WRONG: Missing ON produces CROSS JOIN
SELECT * FROM employees e
INNER JOIN departments d;
-- Result: 100 employees × 30 departments = 3,000 rows!

-- ✅ CORRECT
SELECT * FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id;
```

---

### Mistake 2: Using = with NULL (Never Matches)

```sql
-- ❌ WRONG
SELECT * FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id;
-- Employees with department_id = NULL don't appear (NULL = NULL is never TRUE)

-- ✅ CORRECT for NULL handling
SELECT * FROM employees e
LEFT JOIN departments d ON e.department_id = d.department_id
UNION ALL
SELECT * FROM employees e WHERE e.department_id IS NULL;
-- OR use FULL OUTER JOIN
```

---

### Mistake 3: Filtering in WHERE Kills OUTER JOIN Benefit

```sql
-- ❌ WRONG: WHERE eliminates OUTER JOIN benefit
SELECT * FROM employees e
LEFT JOIN departments d ON e.department_id = d.department_id
WHERE d.department_name = 'Sales';
-- Result: Only Sales employees (unmatched rows eliminated)

-- ✅ CORRECT: Filter in ON for OUTER JOINs
SELECT * FROM employees e
LEFT JOIN departments d ON e.department_id = d.department_id
  AND d.department_name = 'Sales';
-- Result: All employees; Sales depts appear, others NULL
```

---

### Mistake 4: Ambiguous Column Names

```sql
-- ❌ WRONG
SELECT employee_id, name, salary, department_id, department_name
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id;
-- Which table is department_id from? (Ambiguous)

-- ✅ CORRECT
SELECT 
    e.employee_id, 
    e.name, 
    e.salary, 
    d.department_id, 
    d.department_name
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id;
```

---

### Mistake 5: Wrong Join Type for Requirement

```sql
-- ❌ WRONG: INNER hides orphaned records
SELECT * FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id;
-- Employees with no dept don't appear

-- ✅ CORRECT: Use LEFT for data quality checks
SELECT * FROM employees e
LEFT JOIN departments d ON e.department_id = d.department_id
WHERE d.department_id IS NULL;  -- Find orphans
```

---

## 15. Interview Q&A

### Q1: What's the difference between INNER and LEFT JOIN?

**A:** INNER JOIN returns only matching rows (both tables must have match). LEFT JOIN returns all rows from the left table plus matches from the right; unmatched right rows show NULL.

**Example:**
```sql
-- INNER: Loses unmatched
SELECT * FROM employees e INNER JOIN departments d ON e.dept_id = d.id;
-- Result: Only employees with valid departments

-- LEFT: Keeps all employees
SELECT * FROM employees e LEFT JOIN departments d ON e.dept_id = d.id;
-- Result: All employees; dept columns NULL if no match
```

---

### Q2: When would you use FULL OUTER JOIN?

**A:** For reconciliation between two data sources. It shows:
- Rows in left only (NULL on right)
- Matching rows
- Rows in right only (NULL on left)

**Use case:** Merge two customer lists and identify new/deleted/updated records.

---

### Q3: What's a Cartesian product and when is it a problem?

**A:** Cartesian product (CROSS JOIN) combines every row from table1 with every row from table2. If you forget the ON clause, you accidentally create one.

```sql
-- ❌ Cartesian: 100 employees × 30 departments = 3,000 rows
SELECT * FROM employees, departments;

-- ✅ Correct
SELECT * FROM employees JOIN departments ON emp.dept_id = dept.id;
```

Problem: Performance disaster if tables are large.

---

### Q4: Why doesn't NULL = NULL in joins?

**A:** SQL treats NULL as unknown. `NULL = NULL` evaluates to NULL (not TRUE), so rows with NULL in join columns never match.

```sql
-- Employee with dept_id = NULL doesn't match any department
SELECT * FROM employees e
WHERE e.dept_id = 5;  -- NULL ≠ 5; doesn't match

SELECT * FROM employees e WHERE e.dept_id IS NULL;  -- Correct
```

---

### Q5: Should you filter in ON or WHERE clause for OUTER JOINs?

**A:** For OUTER JOINs:
- **ON:** Filter applied during join; preserves unmatched rows
- **WHERE:** Filter applied after join; eliminates unmatched rows

```sql
-- ON: Unmatched rows preserved
SELECT * FROM employees e
LEFT JOIN departments d ON e.dept_id = d.id AND d.name = 'Sales';
-- Result: All employees; Sales depts appear, others NULL

-- WHERE: Unmatched rows eliminated
SELECT * FROM employees e
LEFT JOIN departments d ON e.dept_id = d.id
WHERE d.name = 'Sales';
-- Result: Only Sales employees (same as INNER JOIN!)
```

---

### Q6: Explain a self-join with an example.

**A:** Self-join joins a table to itself using aliases. Common for hierarchies and comparisons.

```sql
-- Manager-employee hierarchy
SELECT 
    emp.name AS employee,
    mgr.name AS manager
FROM employees emp
LEFT JOIN employees mgr ON emp.manager_id = mgr.employee_id;

-- Employees with same salary
SELECT e1.name, e1.salary, e2.name
FROM employees e1
INNER JOIN employees e2 ON e1.salary = e2.salary AND e1.id < e2.id;
```

---

### Q7: What happens if you join on a non-unique column?

**A:** If the join column has duplicates, the result is a Cartesian product of matching rows.

```sql
-- employees table: 2 employees in Sales
-- departments table: 1 Sales dept
-- Result: 2 × 1 = 2 rows

SELECT * FROM employees e
INNER JOIN departments d ON e.dept_name = d.name;
```

---

### Q8: How do you find unmatched rows between two tables?

**A:** Use LEFT/RIGHT JOIN with IS NULL condition.

```sql
-- Employees not in departments
SELECT * FROM employees e
LEFT JOIN departments d ON e.dept_id = d.id
WHERE d.id IS NULL;

-- Departments with no employees
SELECT * FROM departments d
LEFT JOIN employees e ON e.dept_id = d.id
WHERE e.id IS NULL;
```

---

### Q9: What's the performance difference between INNER and OUTER JOINs?

**A:** INNER JOINs are typically faster because:
- Rows are eliminated early in processing
- Optimizer has more flexibility in join order
- OUTER JOINs must preserve unmatched rows (can't filter aggressively)

---

### Q10: How do you optimize a slow JOIN query?

**A:**
1. **Index join columns** (especially foreign keys)
2. **Use INNER when possible** (filters more aggressively)
3. **Filter in WHERE early** (reduce input to joins)
4. **Check execution plan** (EXPLAIN PLAN)
5. **Use hints if needed** (/*+ USE_HASH */)

---

## 16. Revision Summary

### Key Takeaways

1. **INNER JOIN** = matching rows only; excludes unmatched
2. **LEFT JOIN** = all left rows + matching right; NULLs for unmatched right
3. **RIGHT JOIN** = all right rows + matching left; NULLs for unmatched left
4. **FULL JOIN** = all rows from both; NULLs for unmatched
5. **CROSS JOIN** = Cartesian product (dangerous if accidental)
6. **Self-join** = join table to itself; use for hierarchies
7. **ON vs WHERE:** ON for join condition; WHERE for filtering
8. **NULL doesn't match:** NULL = NULL is never TRUE; use IS NULL
9. **Performance:** INNER > OUTER; index join columns; filter early
10. **Real-world use:** Reconciliation (FULL), hierarchies (self-join), data quality (LEFT with IS NULL)

### Quick Decision Tree

```
Do you need unmatched rows?
  NO  → INNER JOIN
  YES → Which table?
         Left only  → LEFT JOIN
         Right only → RIGHT JOIN
         Both       → FULL OUTER JOIN

Is it same table?
  YES → Self-join
  
Do you need every combination?
  YES → CROSS JOIN (rare)
```
