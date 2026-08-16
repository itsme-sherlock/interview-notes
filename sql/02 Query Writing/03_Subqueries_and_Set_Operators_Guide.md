# SQL Subqueries and Set Operators Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Subquery** = Query nested inside another query (SELECT, WHERE, FROM, HAVING); returns result set used by outer query.
- **Scalar subquery** = Returns single row, single column; usable in SELECT, WHERE like a column/value.
- **Inline view** = Subquery in FROM clause; acts like temporary table; must have alias (e.g., FROM (SELECT ...) t).
- **Correlated subquery** = References outer query columns; executes once per outer row (slower but powerful).
- **Non-correlated subquery** = Independent; executes once; result reused (faster).
- **IN vs EXISTS** = IN: checks membership in list; EXISTS: checks if subquery returns rows (EXISTS usually faster).
- **UNION** = Combines result sets; removes duplicates; requires matching columns/types.
- **UNION ALL** = Combines result sets; keeps duplicates; faster than UNION (no sort).
- **INTERSECT** = Returns rows appearing in BOTH queries; requires matching columns.
- **MINUS** = Returns rows in first query NOT in second query; set difference.
- **Interview Keywords** = Scalar vs inline vs correlated, subquery in FROM vs WHERE vs SELECT, performance implications.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Subqueries?](#1-why-do-we-need-subqueries)
2. [What Are Subqueries?](#2-what-are-subqueries)
3. [Scalar Subqueries](#3-scalar-subqueries)
4. [Inline View Subqueries (FROM)](#4-inline-view-subqueries-from)
5. [WHERE Clause Subqueries](#5-where-clause-subqueries)
6. [Correlated vs Non-Correlated Subqueries](#6-correlated-vs-non-correlated-subqueries)
7. [IN vs EXISTS Operators](#7-in-vs-exists-operators)
8. [UNION: Combining Result Sets](#8-union-combining-result-sets)
9. [UNION ALL, INTERSECT, MINUS](#9-union-all-intersect-minus)
10. [Set Operators Detailed](#10-set-operators-detailed)
11. [Performance Considerations](#11-performance-considerations)
12. [Common Mistakes](#12-common-mistakes)
13. [Interview Q&A](#13-interview-qa)
14. [Revision Summary](#14-revision-summary)

---

## 1. Why Do We Need Subqueries?

### The Problem: Multi-Step Logic Requires Multiple Queries

**Scenario:** You need to find employees earning more than the average salary.

```sql
-- WITHOUT subqueries (pseudo-code):
-- Step 1: Calculate average salary
DECLARE avg_salary NUMBER;
SELECT AVG(salary) INTO avg_salary FROM employees;

-- Step 2: Find employees above average
SELECT * FROM employees WHERE salary > avg_salary;
```

This requires two separate queries and intermediate storage.

### The Solution: Subqueries Solve It in One Query

```sql
-- WITH subquery:
SELECT * FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);
```

**Result:** One query, no intermediate variables, cleaner logic.

### Real-World Scenarios

- **Analytics:** "Show products with sales above average"
- **Validation:** "Show orders without matching payments"
- **Ranking:** "Show top 3 customers by spending"
- **Filtering:** "Show departments with employees earning > 100K"

---

**➡ Transition:** Subqueries come in different forms. Let's master each type.

---

## 2. What Are Subqueries?

### Simple Definition

A **subquery** is a query nested inside another query. It's enclosed in parentheses and can appear in SELECT, WHERE, FROM, HAVING, or WITH clauses.

### Subquery Categories

```
Subqueries
├─ Scalar (returns 1 row, 1 column)
│  ├─ Non-correlated (runs once)
│  └─ Correlated (runs per outer row)
├─ Inline view (in FROM; returns table)
└─ Exists check (in WHERE; checks for existence)
```

---

**➡ Transition:** Let's start with the simplest: scalar subqueries.

---

## 3. Scalar Subqueries

### Definition

**Scalar subquery** returns exactly ONE row and ONE column. Can be used wherever a value/column is expected.

### Example 1: In SELECT Clause

```sql
-- Q: Show each employee with average salary
SELECT 
    employee_id,
    name,
    salary,
    (SELECT AVG(salary) FROM employees) AS avg_salary,
    salary - (SELECT AVG(salary) FROM employees) AS diff_from_avg
FROM employees;
```

**Result:**
```
employee_id | name | salary | avg_salary | diff_from_avg
101 | John | 50000 | 52500 | -2500
102 | Jane | 60000 | 52500 | 7500
```

**Key:** Scalar subquery (returns 52500) used like a column.

### Example 2: In WHERE Clause

```sql
-- Q: Find employees earning more than average
SELECT *
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);
```

### Example 3: In HAVING Clause

```sql
-- Q: Show departments with average salary > company average
SELECT 
    department_id,
    AVG(salary) AS dept_avg_salary
FROM employees
GROUP BY department_id
HAVING AVG(salary) > (SELECT AVG(salary) FROM employees);
```

### Key Constraint: Must Return Exactly One Row

```sql
-- ❌ WRONG: Returns multiple rows (error)
SELECT * FROM employees
WHERE salary > (SELECT salary FROM employees);  -- Returns all salaries!
-- ORA-01427: single-row subquery returns more than one row

-- ✅ CORRECT: Wraps in aggregate (returns single row)
SELECT * FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);  -- Returns 52500
```

---

**➡ Transition:** Subqueries in FROM act like temporary tables.

---

## 4. Inline View Subqueries (FROM)

### Definition

**Inline view** is a subquery in the FROM clause. It acts as a derived table and must have an alias.

### Syntax

```sql
SELECT column_list
FROM (
    SELECT ... FROM ...
) alias_name;
```

### Example 1: Simple Inline View

```sql
-- Q: Find employees with above-average salary (using inline view)
SELECT *
FROM (
    SELECT employee_id, name, salary,
           (SELECT AVG(salary) FROM employees) AS avg_sal
    FROM employees
) emp
WHERE emp.salary > emp.avg_sal;
```

### Example 2: Aggregation in Inline View

```sql
-- Q: Show departments with employee count and average salary
SELECT 
    department_id,
    emp_count,
    avg_sal
FROM (
    SELECT 
        department_id,
        COUNT(*) AS emp_count,
        AVG(salary) AS avg_sal
    FROM employees
    GROUP BY department_id
) dept_stats
WHERE emp_count > 5;  -- Refer to derived column
```

### Example 3: Multiple Inline Views (Joined)

```sql
-- Q: Compare each dept to company average
SELECT 
    d.department_id,
    d.dept_avg,
    c.company_avg,
    d.dept_avg - c.company_avg AS diff
FROM (
    SELECT department_id, AVG(salary) AS dept_avg
    FROM employees
    GROUP BY department_id
) d,
(
    SELECT AVG(salary) AS company_avg FROM employees
) c;
```

---

**➡ Transition:** WHERE subqueries filter rows based on subquery results.

---

## 5. WHERE Clause Subqueries

### Comparison Operators with Subqueries

```sql
-- Single value comparison
WHERE column > (SELECT MAX(salary) FROM ...)
WHERE column IN (SELECT id FROM ...)
WHERE column EXISTS (SELECT 1 FROM ...)
```

### Example 1: Single Value Comparison

```sql
-- Q: Employees earning more than employee 101
SELECT *
FROM employees
WHERE salary > (SELECT salary FROM employees WHERE employee_id = 101);
```

### Example 2: IN Operator

```sql
-- Q: Find employees in departments 10, 20, 30
SELECT *
FROM employees
WHERE department_id IN (SELECT id FROM departments WHERE location = 'New York');
```

**vs EQUALS:**
```sql
-- ❌ WRONG (each employee can only be in one dept)
WHERE department_id = (SELECT id FROM departments ...);
-- Returns multiple rows; error

-- ✅ CORRECT (subquery might return multiple depts)
WHERE department_id IN (SELECT id FROM departments ...);
```

### Example 3: NOT IN

```sql
-- Q: Employees NOT in any department
SELECT *
FROM employees
WHERE department_id NOT IN (SELECT id FROM departments);
-- Note: if subquery contains NULL, NOT IN returns no rows!
```

---

**➡ Transition:** Correlated subqueries reference the outer query. They're powerful but slower.

---

## 6. Correlated vs Non-Correlated Subqueries

### Non-Correlated (Independent)

**Executes once; result reused.**

```sql
SELECT * FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);
-- Subquery runs ONCE; computes 52500; used for all 100 employees
```

**Performance:** Fast (one execution).

### Correlated (Dependent on Outer Query)

**Executes once per outer row; references outer columns.**

```sql
SELECT * FROM employees e
WHERE salary > (
    SELECT AVG(salary) FROM employees 
    WHERE department_id = e.department_id  -- References outer e.department_id
);
-- Subquery runs for EACH employee (100+ times)
-- Finds avg salary for THEIR department
```

**Performance:** Slower (multiple executions).

### Example Comparison

```sql
-- Q: Show each employee earning above their department average

-- Non-correlated approach (WRONG - compares to company average)
SELECT * FROM employees e
WHERE salary > (SELECT AVG(salary) FROM employees);

-- Correlated approach (CORRECT - compares to dept average)
SELECT * FROM employees e
WHERE salary > (
    SELECT AVG(salary) FROM employees 
    WHERE department_id = e.department_id
);
```

---

**➡ Transition:** EXISTS and IN are common WHERE operators. One is faster.

---

## 7. IN vs EXISTS Operators

### IN Operator

**Syntax:**
```sql
WHERE column IN (subquery)
```

**Behavior:** Returns TRUE if column matches any value in subquery result set.

```sql
-- Q: Employees in departments with > 5 employees
SELECT * FROM employees e
WHERE e.department_id IN (
    SELECT department_id FROM employees
    GROUP BY department_id
    HAVING COUNT(*) > 5
);
```

### EXISTS Operator

**Syntax:**
```sql
WHERE EXISTS (subquery)
```

**Behavior:** Returns TRUE if subquery returns ANY rows (doesn't care what). Usually uses correlated condition.

```sql
-- Q: Employees in departments with > 5 employees (using EXISTS)
SELECT * FROM employees e
WHERE EXISTS (
    SELECT 1 FROM employees e2
    WHERE e2.department_id = e.department_id
    GROUP BY e2.department_id
    HAVING COUNT(*) > 5
);
```

### Performance: EXISTS Usually Faster

```
IN:      Builds complete result set; checks membership
EXISTS:  Stops at first matching row; doesn't need all rows
```

**Rule of Thumb:** Use EXISTS for large subqueries; use IN for small/indexed lookups.

### NOT IN vs NOT EXISTS

```sql
-- NOT IN returns no rows if subquery contains NULL!
SELECT * FROM employees
WHERE department_id NOT IN (SELECT id FROM departments);
-- ❌ Dangerous: if departments.id has NULL, result is empty!

-- NOT EXISTS is safe
SELECT * FROM employees e
WHERE NOT EXISTS (SELECT 1 FROM departments d WHERE d.id = e.department_id);
-- ✅ Works correctly
```

---

**➡ Transition:** Set operators (UNION, INTERSECT, MINUS) combine entire result sets.

---

## 8. UNION: Combining Result Sets

### Definition

**UNION** combines rows from two or more queries. Removes duplicates automatically.

### Syntax

```sql
SELECT column_list FROM table1
UNION
SELECT column_list FROM table2;
```

### Requirements

- Same number of columns
- Compatible column types
- Same column order

### Example 1: Combining Similar Data

```sql
-- Q: List all employees and contractors (from separate tables)
SELECT employee_id AS person_id, name, 'Employee' AS type
FROM employees
UNION
SELECT contractor_id, name, 'Contractor'
FROM contractors;
```

**Result:**
```
person_id | name | type
101 | John | Employee
102 | Jane | Employee
201 | Bob | Contractor
(Duplicates removed if same person in both tables)
```

### Example 2: UNION with WHERE

```sql
-- Q: Show all departments and all employee names (different tables)
SELECT 'Department' AS type, department_name AS name FROM departments
UNION
SELECT 'Employee', name FROM employees;
```

### UNION Performance

```
UNION = Combines + Removes Duplicates (requires SORT)
        Slower for large result sets

UNION ALL = Combines + Keeps Duplicates (no sort)
           Faster; use if you know no duplicates exist
```

---

**➡ Transition:** Other set operators like INTERSECT and MINUS handle overlaps differently.

---

## 9. UNION ALL, INTERSECT, MINUS

### UNION ALL (Fast Combine)

```sql
SELECT * FROM employees
UNION ALL
SELECT * FROM contractor;
-- Combines all rows; keeps duplicates
-- No sort required; faster than UNION
```

### INTERSECT (Common Rows)

```sql
-- Q: Find values that appear in both queries
SELECT employee_id FROM employees
INTERSECT
SELECT contractor_id FROM contractors;
-- Result: IDs present in BOTH tables
```

### MINUS (Set Difference)

```sql
-- Q: Employees who are NOT contractors
SELECT employee_id FROM employees
MINUS
SELECT contractor_id FROM contractors;
-- Result: IDs in first query but NOT in second
```

---

## 10. Set Operators Detailed

### Comparison Matrix

| Operator | Purpose | Includes Duplicates | Performance |
| --- | --- | --- | --- |
| **UNION** | Combine + unique | No (removes) | Slow (sorts) |
| **UNION ALL** | Combine | Yes (keeps) | Fast |
| **INTERSECT** | Common rows | No (unique) | Slow (sorts) |
| **MINUS** | Rows in A not in B | No (unique) | Slow (sorts) |

### Example: All Four Operators

```sql
-- Table A: {1, 2, 3, 4}
-- Table B: {3, 4, 5, 6}

SELECT * FROM A UNION SELECT * FROM B;        -- {1, 2, 3, 4, 5, 6}
SELECT * FROM A UNION ALL SELECT * FROM B;    -- {1, 2, 3, 4, 3, 4, 5, 6}
SELECT * FROM A INTERSECT SELECT * FROM B;    -- {3, 4}
SELECT * FROM A MINUS SELECT * FROM B;        -- {1, 2}
```

---

## 11. Performance Considerations

### Subquery Performance Tips

```sql
-- FAST: Non-correlated subquery (runs once)
SELECT * FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);

-- SLOW: Correlated subquery (runs per row)
SELECT * FROM employees e
WHERE salary > (SELECT AVG(salary) FROM employees WHERE dept_id = e.dept_id);

-- OPTIMIZE: Use inline view or JOIN instead
SELECT e.* FROM employees e
JOIN (SELECT department_id, AVG(salary) AS avg_sal FROM employees GROUP BY department_id) d
ON e.department_id = d.department_id AND e.salary > d.avg_sal;
```

### Set Operator Performance

```sql
-- FAST: UNION ALL (no sorting)
SELECT * FROM employees
UNION ALL
SELECT * FROM contractors;

-- SLOW: UNION (removes duplicates via sort)
SELECT * FROM employees
UNION
SELECT * FROM contractors;
```

---

## 12. Common Mistakes

### Mistake 1: Scalar Subquery Returns Multiple Rows

```sql
-- ❌ ERROR: Returns multiple rows
SELECT * FROM employees
WHERE salary = (SELECT salary FROM employees);
-- ORA-01427: single-row subquery returns more than one row

-- ✅ CORRECT: Use IN or aggregate
SELECT * FROM employees
WHERE salary IN (SELECT salary FROM employees);
-- OR
WHERE salary > (SELECT AVG(salary) FROM employees);
```

---

### Mistake 2: Missing Inline View Alias

```sql
-- ❌ ERROR: Alias required
SELECT * FROM (SELECT * FROM employees);
-- ORA-00907: missing right parenthesis (or alias)

-- ✅ CORRECT
SELECT * FROM (SELECT * FROM employees) e;
```

---

### Mistake 3: NOT IN with NULL

```sql
-- ❌ WRONG: Returns no rows if subquery has NULL
SELECT * FROM employees
WHERE department_id NOT IN (SELECT id FROM departments);
-- If departments.id contains NULL, result is always FALSE (NULL semantics)

-- ✅ CORRECT: Use NOT EXISTS
SELECT * FROM employees e
WHERE NOT EXISTS (SELECT 1 FROM departments d WHERE d.id = e.department_id);
```

---

### Mistake 4: Referencing Outer Query Incorrectly in Non-Correlated

```sql
-- ❌ WRONG: References outer column (but not intentionally)
SELECT * FROM employees e
WHERE salary > (SELECT AVG(salary) FROM employees WHERE dept_id = e.dept_id);
-- This is actually CORRELATED; runs per row (slow!)

-- ✅ CORRECT (if non-correlated intended)
SELECT * FROM employees e
WHERE salary > (SELECT AVG(salary) FROM employees);
-- Doesn't reference e.*; runs once
```

---

### Mistake 5: Column Type Mismatch in UNION

```sql
-- ❌ ERROR: Incompatible types
SELECT employee_id (NUMBER) FROM employees
UNION
SELECT name (VARCHAR2) FROM employees;
-- ORA-01790: expression must have same datatype as corresponding expression

-- ✅ CORRECT: Cast to same type
SELECT CAST(employee_id AS VARCHAR2(10)) FROM employees
UNION
SELECT name FROM employees;
```

---

## 13. Interview Q&A

### Q1: What's the difference between a scalar subquery and an inline view?

**A:** 
- **Scalar subquery** = Returns 1 row, 1 column; used as a value
- **Inline view** = Subquery in FROM; returns table-like result; must have alias

```sql
-- Scalar (SELECT clause)
SELECT name, (SELECT AVG(salary) FROM employees) AS avg_sal FROM employees;

-- Inline view (FROM clause)
SELECT * FROM (SELECT name, salary FROM employees) e WHERE e.salary > 50000;
```

---

### Q2: When should you use EXISTS vs IN?

**A:** Use EXISTS for large subqueries; use IN for small/indexed lookups.

EXISTS is faster because it stops at first match; IN builds entire result set.

Also, NOT EXISTS is safer than NOT IN (NULL issues).

---

### Q3: What's the performance difference between correlated and non-correlated subqueries?

**A:** Non-correlated runs once (fast); correlated runs per outer row (slow). 

For large outer queries, replace correlated with JOIN/inline view.

---

### Q4: What happens if a scalar subquery returns 0 rows?

**A:** Depends on context:
- IN WHERE: Returns no rows from outer query
- Comparison (=, >, <): Returns FALSE
- SELECT clause: Returns NULL

```sql
SELECT salary, (SELECT AVG(salary) FROM employees WHERE 1=0) AS avg
FROM employees;
-- Result: avg is NULL for all rows
```

---

### Q5: How do you combine results from different tables with different column names?

**A:** UNION with column aliases:

```sql
SELECT employee_id AS person_id, name FROM employees
UNION
SELECT contractor_id, name FROM contractors;
```

---

### Q6: Can you use ORDER BY in a UNION?

**A:** Yes, but only at the end, and it applies to the entire result set:

```sql
SELECT name FROM employees
UNION
SELECT name FROM contractors
ORDER BY name;  -- Sorts combined result
```

---

### Q7: What's MINUS and when is it useful?

**A:** MINUS returns rows in first query but NOT in second (set difference).

**Use case:** Data reconciliation, finding missing records.

```sql
-- Employees NOT in contractors table
SELECT employee_id FROM employees
MINUS
SELECT contractor_id FROM contractors;
```

---

### Q8: What's the difference between INTERSECT and INNER JOIN?

**A:** 
- INTERSECT: Finds rows with matching values in both queries
- INNER JOIN: Combines columns from matching rows

```sql
-- INTERSECT: Just IDs (set comparison)
SELECT employee_id FROM employees INTERSECT SELECT contractor_id FROM contractors;

-- INNER JOIN: Full rows with columns from both tables
SELECT * FROM employees e INNER JOIN contractors c ON e.id = c.id;
```

---

### Q9: How do you optimize a slow subquery?

**A:**
1. Use non-correlated if possible (runs once)
2. Replace correlated with JOIN (faster execution)
3. Add indexes on join/filter columns
4. Use UNION ALL instead of UNION (avoid sort)
5. Use EXISTS instead of IN for large subqueries

---

### Q10: What's the difference between WHERE EXISTS and WHERE IN?

**A:** EXISTS checks for existence; IN checks membership.

```sql
-- EXISTS: Checks if ROWS exist (correlated)
WHERE EXISTS (SELECT 1 FROM departments WHERE dept_id = e.dept_id)

-- IN: Checks if value IN a list (non-correlated)
WHERE e.dept_id IN (SELECT id FROM departments)
```

EXISTS usually faster for complex subqueries.

---

## 14. Revision Summary

### Key Takeaways

1. **Subqueries** nest queries; scalar = 1 row/col; inline view = FROM table
2. **Non-correlated** runs once; faster; **correlated** runs per row; slower
3. **IN** checks membership; **EXISTS** checks existence (EXISTS usually faster)
4. **NOT IN** dangerous with NULL; use **NOT EXISTS** instead
5. **UNION** combines + removes duplicates; **UNION ALL** keeps duplicates (faster)
6. **INTERSECT** = common rows; **MINUS** = rows in A not in B
7. **Scalar subquery rule:** Must return exactly 1 row, 1 column
8. **Inline view rule:** Must have alias in FROM clause
9. **Performance:** Use JOINs/inline views instead of correlated subqueries
10. **Set operators:** Require same column count and compatible types
