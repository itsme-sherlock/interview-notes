# SQL CTEs and Recursive SQL Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **CTE (Common Table Expression)** = Named query defined in WITH clause; improves readability; can be referenced multiple times.
- **Syntax:** WITH cte_name AS (SELECT ...) SELECT ... FROM cte_name;
- **Simple CTE** = Non-recursive; like a named subquery; executes once.
- **Recursive CTE** = References itself; iterates until termination condition; useful for hierarchies (org charts, trees).
- **Recursive structure:** Anchor (base case) UNION ALL Recursive member (recursive case) with CONNECT BY logic.
- **Performance** = CTEs don't always improve performance (Oracle may inline); use for readability/maintainability.
- **Advantages** = More readable than nested subqueries; reusable within same query; easier to debug.
- **Use cases** = Hierarchical data (org charts, BOM), iterative calculations, multi-level aggregations.
- **Termination condition** = WHERE clause in recursive member stops recursion; prevents infinite loops.
- **Interview keywords** = Anchor member, recursive member, termination condition, depth-first vs breadth-first, hierarchies.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need CTEs?](#1-why-do-we-need-ctes)
2. [What Are CTEs?](#2-what-are-ctes)
3. [Simple (Non-Recursive) CTEs](#3-simple-non-recursive-ctes)
4. [Recursive CTEs: Structure and Mechanics](#4-recursive-ctes-structure-and-mechanics)
5. [Anchor Member: The Base Case](#5-anchor-member-the-base-case)
6. [Recursive Member: The Iteration](#6-recursive-member-the-iteration)
7. [Termination Conditions](#7-termination-conditions)
8. [Practical: Organizational Hierarchies](#8-practical-organizational-hierarchies)
9. [Practical: BOM (Bill of Materials)](#9-practical-bill-of-materials)
10. [Practical: Iterative Calculations](#10-practical-iterative-calculations)
11. [Multiple CTEs in One Query](#11-multiple-ctes-in-one-query)
12. [CONNECT BY vs Recursive CTEs](#12-connect-by-vs-recursive-ctes)
13. [Performance and Optimization](#13-performance-and-optimization)
14. [Common Mistakes](#14-common-mistakes)
15. [Interview Q&A](#15-interview-qa)
16. [Revision Summary](#16-revision-summary)

---

## 1. Why Do We Need CTEs?

### The Problem: Complex Nested Subqueries are Hard to Read

**Scenario:** Find employees with salary > dept average, then rank by salary, then filter top 2 per dept.

```sql
-- WITHOUT CTEs (nested subqueries - hard to follow)
SELECT 
    employee_id, 
    name, 
    salary,
    rank
FROM (
    SELECT 
        e.employee_id,
        e.name,
        e.salary,
        ROW_NUMBER() OVER (PARTITION BY e.department_id ORDER BY e.salary DESC) AS rank
    FROM (
        SELECT * FROM employees e
        WHERE e.salary > (
            SELECT AVG(salary) FROM employees 
            WHERE department_id = e.department_id
        )
    ) e
) ranked
WHERE rank <= 2;
```

**Problems:**
- Hard to read (deeply nested)
- Logic flow unclear
- Debugging difficult
- Reusability poor

### The Solution: CTEs Organize Logic Clearly

```sql
-- WITH CTEs (clear, step-by-step)
WITH above_avg_employees AS (
    SELECT *
    FROM employees e
    WHERE e.salary > (
        SELECT AVG(salary) FROM employees 
        WHERE department_id = e.department_id
    )
),
ranked_employees AS (
    SELECT 
        employee_id, name, salary, department_id,
        ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rank
    FROM above_avg_employees
)
SELECT * FROM ranked_employees WHERE rank <= 2;
```

**Benefits:**
- Readable (named steps)
- Logical flow clear
- Easy to debug (test each CTE independently)
- Reusable (reference multiple times)

### Real-World Scenarios

- **Org Charts:** Find manager → employees → team members (hierarchical)
- **Supply Chains:** Product → components → sub-components (BOM)
- **Financial Reconciliation:** Transactions → rollups → variance analysis
- **Data Pipelines:** Staging → transformation → final output

---

**➡ Transition:** CTEs are easier than they look. Let's start with simple ones.

---

## 2. What Are CTEs?

### Simple Definition

A **CTE (Common Table Expression)** is a named, temporary result set that you define in a WITH clause and reference in the main query.

### Mental Model

```
WITH cte_name AS (
    -- CTE definition (temporary table)
    SELECT ...
)
SELECT ... FROM cte_name;  -- Reference CTE
```

**Think of it as:** CREATE TEMPORARY TABLE defined inline.

### CTE Types

```
CTEs
├─ Simple (non-recursive)
│  ├─ Single CTE
│  └─ Multiple CTEs
└─ Recursive
   ├─ Anchor member (base case)
   └─ Recursive member (iteration)
```

---

**➡ Transition:** Simple CTEs are like named subqueries. Let's master them first.

---

## 3. Simple (Non-Recursive) CTEs

### Example 1: Single CTE

```sql
-- Q: Show employees earning above average
WITH above_avg AS (
    SELECT employee_id, name, salary
    FROM employees
    WHERE salary > (SELECT AVG(salary) FROM employees)
)
SELECT * FROM above_avg ORDER BY salary DESC;
```

**Equivalent without CTE:**
```sql
SELECT * FROM (
    SELECT employee_id, name, salary
    FROM employees
    WHERE salary > (SELECT AVG(salary) FROM employees)
) above_avg
ORDER BY salary DESC;
```

**Benefit:** WITH is more readable than nested subqueries.

### Example 2: CTE with Aggregation

```sql
-- Q: Show departments with employee count
WITH dept_stats AS (
    SELECT 
        department_id,
        COUNT(*) AS emp_count,
        AVG(salary) AS avg_salary,
        MAX(salary) AS max_salary
    FROM employees
    GROUP BY department_id
)
SELECT *
FROM dept_stats
WHERE emp_count > 5
ORDER BY avg_salary DESC;
```

### Example 3: Chaining CTEs (Multiple References)

```sql
-- Q: Show employees earning > dept average, ranked by salary
WITH dept_avg AS (
    SELECT department_id, AVG(salary) AS avg_sal
    FROM employees
    GROUP BY department_id
),
high_earners AS (
    SELECT e.employee_id, e.name, e.salary, e.department_id
    FROM employees e
    JOIN dept_avg d ON e.department_id = d.department_id
    WHERE e.salary > d.avg_sal
)
SELECT 
    employee_id, name, salary,
    ROW_NUMBER() OVER (ORDER BY salary DESC) AS rank
FROM high_earners;
```

---

**➡ Transition:** Recursive CTEs can reference themselves. They're powerful for hierarchies.

---

## 4. Recursive CTEs: Structure and Mechanics

### General Structure

```sql
WITH RECURSIVE cte_name AS (
    -- ANCHOR MEMBER (base case)
    SELECT ...
    UNION ALL
    -- RECURSIVE MEMBER (iteration)
    SELECT ... FROM cte_name WHERE [termination condition]
)
SELECT ... FROM cte_name;
```

### Execution Flow

```
Iteration 1:
├─ Execute ANCHOR (base case)
├─ Store result in cte_name
└─ Iteration result R1 = {rows from anchor}

Iteration 2:
├─ Execute RECURSIVE using R1
├─ Store new result in cte_name
├─ Iteration result R2 = {rows from recursive member}
└─ Terminate if R2 is empty

Iteration N:
└─ Stop when recursive member returns 0 rows
```

---

**➡ Transition:** The anchor member is the base case (where recursion starts).

---

## 5. Anchor Member: The Base Case

### Definition

**Anchor member** is the first SELECT in a recursive CTE. It provides the initial result set for recursion.

### Example: Starting Point

```sql
WITH RECURSIVE hierarchy AS (
    -- ANCHOR: Start with CEO (employee_id = 1, manager_id = NULL)
    SELECT 
        employee_id,
        name,
        manager_id,
        1 AS level  -- Start at level 1
    FROM employees
    WHERE manager_id IS NULL  -- CEO has no manager
    
    UNION ALL
    
    -- RECURSIVE (defined below)
    SELECT ...
)
SELECT * FROM hierarchy;
```

**Anchor Result (first iteration):**
```
employee_id | name | manager_id | level
1 | CEO | NULL | 1
```

---

**➡ Transition:** The recursive member extends the anchor result.

---

## 6. Recursive Member: The Iteration

### Definition

**Recursive member** is the second SELECT in a recursive CTE. It references the CTE itself and extends the result set.

### Example: Building the Tree

```sql
WITH RECURSIVE hierarchy AS (
    -- ANCHOR
    SELECT 
        employee_id, name, manager_id, 1 AS level
    FROM employees
    WHERE manager_id IS NULL
    
    UNION ALL
    
    -- RECURSIVE: Find employees managed by people in previous iteration
    SELECT 
        e.employee_id,
        e.name,
        e.manager_id,
        h.level + 1 AS level
    FROM employees e
    INNER JOIN hierarchy h ON e.manager_id = h.employee_id
    WHERE h.level < 5  -- Limit recursion depth
)
SELECT * FROM hierarchy;
```

**Iteration 2 (finds direct reports of CEO):**
```
employee_id | name | manager_id | level
2 | VP Sales | 1 | 2
3 | VP IT | 1 | 2
```

**Iteration 3 (finds reports of VPs):**
```
employee_id | name | manager_id | level
4 | Sales Manager | 2 | 3
5 | IT Manager | 3 | 3
```

---

**➡ Transition:** Recursion must stop. Termination conditions prevent infinite loops.

---

## 7. Termination Conditions

### Explicit Termination (WHERE)

```sql
-- Stop when level reaches 5
WHERE h.level < 5
```

### Implicit Termination (No Matching Rows)

```sql
-- Stops when INNER JOIN finds no more employees
INNER JOIN hierarchy h ON e.manager_id = h.employee_id
-- When all employees have been visited, JOIN returns 0 rows; recursion stops
```

### Example: Date Range Iteration

```sql
-- Q: Generate dates from 2026-01-01 to 2026-12-31
WITH RECURSIVE date_range AS (
    -- ANCHOR: Start date
    SELECT TO_DATE('2026-01-01', 'YYYY-MM-DD') AS date_val
    
    UNION ALL
    
    -- RECURSIVE: Add one day each iteration
    SELECT date_val + 1
    FROM date_range
    WHERE date_val + 1 <= TO_DATE('2026-12-31', 'YYYY-MM-DD')  -- Termination
)
SELECT * FROM date_range;
```

**Result:** 365 rows (one per day).

---

**➡ Transition:** Real-world example: org charts.

---

## 8. Practical: Organizational Hierarchies

### Full Org Chart Query

```sql
-- Q: Show entire org chart with manager names
WITH RECURSIVE org_chart AS (
    -- ANCHOR: CEO (root)
    SELECT 
        employee_id,
        name,
        manager_id,
        1 AS level,
        name AS path  -- Track ancestry
    FROM employees
    WHERE manager_id IS NULL
    
    UNION ALL
    
    -- RECURSIVE: Direct reports
    SELECT 
        e.employee_id,
        e.name,
        e.manager_id,
        oc.level + 1 AS level,
        oc.path || ' > ' || e.name AS path
    FROM employees e
    INNER JOIN org_chart oc ON e.manager_id = oc.employee_id
    WHERE oc.level < 10  -- Prevent runaway recursion
)
SELECT 
    employee_id,
    LPAD(' ', (level - 1) * 2) || name AS employee_name,
    level,
    path
FROM org_chart
ORDER BY path;
```

**Result:**
```
employee_id | employee_name | level | path
1 | CEO | 1 | CEO
2 |   VP Sales | 2 | CEO > VP Sales
3 |   VP IT | 2 | CEO > VP IT
4 |     Sales Manager | 3 | CEO > VP Sales > Sales Manager
```

---

**➡ Transition:** BOM (Bill of Materials) is another hierarchy.

---

## 9. Practical: BOM (Bill of Materials)

### Scenario

Product structure: Car → Engines, Wheels, Interior → Subcomponents

### Table Structure

```sql
CREATE TABLE products (
    product_id NUMBER PRIMARY KEY,
    product_name VARCHAR2(100),
    parent_product_id NUMBER  -- NULL for top-level
);

INSERT INTO products VALUES
(1, 'Car', NULL),
(2, 'Engine', 1),
(3, 'Wheels', 1),
(4, 'Piston', 2),  -- Component of Engine
(5, 'Valve', 2);   -- Component of Engine
```

### Query: Show All Components

```sql
WITH RECURSIVE bom AS (
    -- ANCHOR: Top-level products
    SELECT 
        product_id,
        product_name,
        parent_product_id,
        1 AS level
    FROM products
    WHERE parent_product_id IS NULL
    
    UNION ALL
    
    -- RECURSIVE: Child products
    SELECT 
        p.product_id,
        p.product_name,
        p.parent_product_id,
        b.level + 1 AS level
    FROM products p
    INNER JOIN bom b ON p.parent_product_id = b.product_id
)
SELECT 
    LPAD(' ', (level - 1) * 2) || product_name AS component,
    level
FROM bom
ORDER BY product_id;
```

**Result:**
```
component | level
Car | 1
  Engine | 2
    Piston | 3
    Valve | 3
  Wheels | 2
```

---

**➡ Transition:** Recursive CTEs can also do iterative calculations.

---

## 10. Practical: Iterative Calculations

### Example: Fibonacci Sequence

```sql
-- Q: Generate first 15 Fibonacci numbers
WITH RECURSIVE fibonacci AS (
    -- ANCHOR: First two numbers
    SELECT 1 AS num, 1 AS fib_value, 1 AS prev_value
    
    UNION ALL
    
    -- RECURSIVE: Add previous two
    SELECT 
        num + 1,
        fib_value + prev_value,  -- Next = Current + Previous
        fib_value
    FROM fibonacci
    WHERE num < 15
)
SELECT * FROM fibonacci;
```

**Result:**
```
num | fib_value | prev_value
1 | 1 | 1
2 | 2 | 1
3 | 3 | 2
4 | 5 | 3
5 | 8 | 5
...
```

---

## 11. Multiple CTEs in One Query

### Example: Sequential CTEs

```sql
WITH first_cte AS (
    SELECT ...
),
second_cte AS (
    SELECT ... FROM first_cte  -- Can reference previous CTE
),
third_cte AS (
    SELECT ... FROM second_cte  -- Can reference previous
)
SELECT * FROM third_cte;
```

### Real Example: Multi-Step Aggregation

```sql
WITH monthly_sales AS (
    SELECT 
        TRUNC(order_date, 'MONTH') AS month,
        SUM(amount) AS total_sales
    FROM orders
    GROUP BY TRUNC(order_date, 'MONTH')
),
sales_with_avg AS (
    SELECT 
        month,
        total_sales,
        AVG(total_sales) OVER (ORDER BY month ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS rolling_avg
    FROM monthly_sales
),
sales_vs_avg AS (
    SELECT 
        month,
        total_sales,
        rolling_avg,
        total_sales - rolling_avg AS variance
    FROM sales_with_avg
)
SELECT * FROM sales_vs_avg WHERE variance > 10000;
```

---

## 12. CONNECT BY vs Recursive CTEs

### Oracle CONNECT BY (Legacy)

```sql
-- CONNECT BY: Oracle-specific syntax
SELECT employee_id, name, manager_id, LEVEL
FROM employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id
ORDER BY LEVEL;
```

### Recursive CTE (SQL Standard)

```sql
-- Recursive CTE: ANSI SQL standard
WITH RECURSIVE hierarchy AS (
    SELECT employee_id, name, manager_id, 1 AS level
    FROM employees
    WHERE manager_id IS NULL
    UNION ALL
    SELECT e.employee_id, e.name, e.manager_id, h.level + 1
    FROM employees e
    JOIN hierarchy h ON e.manager_id = h.employee_id
)
SELECT * FROM hierarchy ORDER BY level;
```

### Comparison

| Aspect | CONNECT BY | Recursive CTE |
| --- | --- | --- |
| **Standard** | Oracle-specific | ANSI SQL |
| **Readability** | Less explicit | More explicit |
| **Flexibility** | Limited | More powerful |
| **Portability** | Oracle only | Portable to other DBs |

**Recommendation:** Use Recursive CTEs for new code (ANSI standard).

---

## 13. Performance and Optimization

### CTEs Don't Always Improve Performance

```sql
-- Oracle may inline CTE (treat as subquery)
-- No performance guarantee
WITH emp_dept AS (
    SELECT e.*, d.department_name
    FROM employees e
    JOIN departments d ON e.department_id = d.department_id
)
SELECT * FROM emp_dept;
-- May execute same as:
SELECT * FROM (SELECT ...) JOIN ...;
```

### Use CTEs for Readability, Not Speed

**When to use CTEs:**
- Multi-step logic (improved readability)
- Recursive hierarchies (required)
- Reusable intermediate results

**When to use subqueries:**
- Simple, single queries
- Performance-critical (test both)

### Optimization Tips

```sql
-- GOOD: Filter in CTE (push conditions down)
WITH high_earners AS (
    SELECT * FROM employees WHERE salary > 50000  -- Filter early
)
SELECT * FROM high_earners;

-- AVOID: Filter after CTE (includes all rows)
WITH all_emp AS (
    SELECT * FROM employees  -- No filter
)
SELECT * FROM all_emp WHERE salary > 50000;  -- Filter late
```

---

## 14. Common Mistakes

### Mistake 1: Infinite Recursion (No Termination)

```sql
-- ❌ WRONG: No termination condition
WITH RECURSIVE infinite AS (
    SELECT 1 AS num
    UNION ALL
    SELECT num + 1 FROM infinite  -- INFINITE LOOP!
)
SELECT * FROM infinite;

-- ✅ CORRECT: Add termination
WHERE num < 1000
```

---

### Mistake 2: Forgetting RECURSIVE Keyword

```sql
-- ❌ WRONG: Omits RECURSIVE
WITH org_chart AS (
    SELECT ... UNION ALL SELECT ... FROM org_chart  -- References itself; error
)

-- ✅ CORRECT
WITH RECURSIVE org_chart AS (
    SELECT ... UNION ALL SELECT ... FROM org_chart
)
```

---

### Mistake 3: Missing Termination in Recursive Member

```sql
-- ❌ WRONG: No WHERE clause in recursive member
WITH RECURSIVE nums AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM nums  -- Never stops!
)
SELECT * FROM nums;

-- ✅ CORRECT
WHERE n < 100
```

---

### Mistake 4: Anchor and Recursive Member Column Mismatch

```sql
-- ❌ WRONG: Different columns
WITH RECURSIVE cte AS (
    SELECT employee_id, name FROM employees
    UNION ALL
    SELECT employee_id FROM employees  -- Missing 'name'
)

-- ✅ CORRECT: Same columns, same types
WITH RECURSIVE cte AS (
    SELECT employee_id, name FROM employees
    UNION ALL
    SELECT employee_id, name FROM employees
)
```

---

## 15. Interview Q&A

### Q1: What's the difference between a CTE and a subquery?

**A:** Both are temporary result sets, but:
- **CTE (WITH clause):** More readable, reusable, named
- **Subquery:** Nested in query, single use

```sql
-- CTE
WITH high_earners AS (SELECT * FROM employees WHERE salary > 50000)
SELECT * FROM high_earners;

-- Subquery
SELECT * FROM (SELECT * FROM employees WHERE salary > 50000);
```

---

### Q2: What are anchor and recursive members?

**A:**
- **Anchor member:** Initial query (base case) that starts recursion
- **Recursive member:** Extends the result by referencing the CTE itself

```sql
WITH RECURSIVE hierarchy AS (
    SELECT ... FROM employees WHERE manager_id IS NULL  -- Anchor (CEO)
    UNION ALL
    SELECT ... FROM employees e JOIN hierarchy h ON ...  -- Recursive (reports)
)
SELECT * FROM hierarchy;
```

---

### Q3: How do you prevent infinite recursion in a recursive CTE?

**A:** Add a termination condition in the WHERE clause:

```sql
WHERE level < 10  -- Limit depth
-- OR
WHERE date_val <= TO_DATE('2026-12-31')  -- Stop at date
-- OR
-- Rely on implicit termination (no matching rows in JOIN)
```

---

### Q4: When would you use a recursive CTE?

**A:** For hierarchical data:
- Org charts (manager → employees)
- BOM (product → components)
- Treemaps (category → subcategory)
- Date ranges/sequences

---

### Q5: What's the performance impact of CTEs?

**A:** None guaranteed. Oracle may inline CTEs (treat as subqueries). Use CTEs for readability/maintainability, not performance.

Test both CTE and subquery versions to compare performance.

---

### Q6: Can a CTE reference another CTE?

**A:** Yes, if defined sequentially:

```sql
WITH first_cte AS (...),
     second_cte AS (SELECT ... FROM first_cte),  -- ✅ OK
     third_cte AS (SELECT ... FROM second_cte)   -- ✅ OK
SELECT * FROM third_cte;
```

But NOT backwards:
```sql
WITH first_cte AS (SELECT ... FROM second_cte),  -- ❌ ERROR: second_cte not yet defined
     second_cte AS (...)
```

---

### Q7: What's the difference between WITH RECURSIVE and CONNECT BY?

**A:** CONNECT BY is Oracle-specific; WITH RECURSIVE is ANSI standard.

- **CONNECT BY:** Less explicit; Oracle-specific
- **WITH RECURSIVE:** More readable; portable

Use WITH RECURSIVE for new code.

---

### Q8: How do you handle cycles in recursive CTEs?

**A:** Add a visited set or depth limit:

```sql
WITH RECURSIVE hierarchy AS (
    SELECT employee_id, manager_id, 1 AS level
    FROM employees
    WHERE manager_id IS NULL
    
    UNION ALL
    
    SELECT e.employee_id, e.manager_id, h.level + 1
    FROM employees e
    JOIN hierarchy h ON e.manager_id = h.employee_id
    WHERE h.level < 100  -- Depth limit prevents cycles
)
SELECT * FROM hierarchy;
```

---

### Q9: Can you use ORDER BY in a recursive CTE?

**A:** Not in the CTE definition itself, but in the final SELECT:

```sql
WITH RECURSIVE cte AS (
    SELECT ...
    UNION ALL
    SELECT ...
)
SELECT * FROM cte ORDER BY ...;  -- ✅ OK
```

---

### Q10: How do you format output for hierarchical data?

**A:** Use LPAD or similar to indent:

```sql
SELECT 
    LPAD(' ', (level - 1) * 2) || name AS formatted_name
FROM hierarchy
ORDER BY ...;

-- Result:
-- CEO
--   VP Sales
--     Sales Manager
--   VP IT
--     IT Manager
```

---

## 16. Revision Summary

### Key Takeaways

1. **CTE = WITH clause definition** + reference in query; improves readability
2. **Simple CTEs:** Non-recursive; like named subqueries
3. **Recursive CTEs:** Anchor member (base) + Recursive member (extension) + Termination
4. **Anchor member:** Initial SELECT (base case)
5. **Recursive member:** Extends result by joining to CTE; must have termination condition
6. **Termination:** WHERE clause prevents infinite recursion
7. **Performance:** CTEs don't guarantee speed; use for readability
8. **Use cases:** Hierarchies (org charts, BOM), sequences, iterative calculations
9. **vs CONNECT BY:** CTEs are ANSI standard; more portable
10. **Multiple CTEs:** Reference sequentially (forward only)

### Quick Reference

```sql
-- Simple CTE
WITH simple AS (SELECT ...) SELECT ... FROM simple;

-- Recursive CTE
WITH RECURSIVE rec AS (
    SELECT ... -- Anchor
    UNION ALL
    SELECT ... FROM rec WHERE ... -- Recursive + Termination
)
SELECT * FROM rec;
```
