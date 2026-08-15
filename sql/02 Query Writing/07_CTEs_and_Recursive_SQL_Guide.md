# SQL CTEs and Recursive SQL Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **CTE** = A temporary result set defined with a WITH clause.
- **Why CTEs matter** = They make complex queries easier to read and maintain.
- **Recursive CTE** = A CTE that references itself to walk hierarchical or iterative data.
- **Best use case** = Employee-manager hierarchy, tree structures, repeated calculations.
- **Key interview keyword** = CTEs improve readability, but they do not replace proper indexing or query design.
- **Oracle note** = Recursive queries are often used with hierarchical data and can also use CONNECT BY in older patterns.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need CTEs?](#1-why-do-we-need-ctes)
2. [What Is a CTE?](#2-what-is-a-cte)
3. [Simple CTE Syntax](#3-simple-cte-syntax)
4. [Multiple CTEs](#4-multiple-ctes)
5. [Recursive CTEs](#5-recursive-ctes)
6. [Oracle Hierarchy Pattern](#6-oracle-hierarchy-pattern)
7. [Comparison Matrix](#7-comparison-matrix)
8. [Best Practices](#8-best-practices)
9. [Common Mistakes](#9-common-mistakes)
10. [Interview Q&A](#10-interview-qa)
11. [Revision Summary](#11-revision-summary)

---

## 1. Why Do We Need CTEs?

### The Problem: Complex Queries Become Difficult to Read

As queries become larger, nested subqueries and repeated logic become hard to follow.

```sql
SELECT *
FROM employees
WHERE department_id IN (
    SELECT department_id
    FROM departments
    WHERE location_id = 1700
);
```

This works, but it can be confusing when there are many layers of logic.

**Problems with long SQL:**
- Hard to debug
- Hard to reuse logic
- Easy to make mistakes in nested expressions

### The Solution: CTEs

A **CTE (Common Table Expression)** creates a named temporary result set that can be referenced like a table in the main query.

### Real-World Scenarios

- Reporting with multiple steps of filtering
- Hierarchy queries like employee-manager trees
- Breaking complex SQL into understandable clauses

---

**➡ Transition:** The next question is: what exactly is a CTE and how is it different from a subquery? 

---

## 2. What Is a CTE?

### Simple Definition

A **CTE** is a temporary named result set defined using the `WITH` clause. It is available only within the scope of the statement.

### Analogy: Real-World Comparison

**Think of a helper table**:
- A subquery is like a hidden calculation inside a formula
- A CTE is like a labeled intermediate table you can reuse and explain clearly

### Key Characteristics

- Only exists for the current query
- Improves readability
- Can be referenced multiple times
- Helpful in recursive and hierarchical logic

### Types or Variations

| Type | Purpose | Example |
| --- | --- | --- |
| Non-recursive CTE | Break up logic | Top departments by salary |
| Recursive CTE | Traverse hierarchy | Employee-manager tree |

---

**➡ Transition:** Let’s look at the basic syntax for a single CTE. 

---

## 3. Simple CTE Syntax

### The Challenge

You want to build a temporary result before the main query runs.

### How It Works

The `WITH` clause defines a name and a query. The outer query then selects from that CTE.

### Syntax/Usage

```sql
WITH dept_summary AS (
    SELECT department_id, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY department_id
)
SELECT *
FROM dept_summary
WHERE avg_salary > 8000;
```

### Example

```sql
WITH high_salary AS (
    SELECT employee_id, first_name, salary
    FROM employees
    WHERE salary > 10000
)
SELECT *
FROM high_salary
ORDER BY salary DESC;
```

**Output:**

```text
EMPLOYEE_ID FIRST_NAME SALARY
----------- ---------- --------
100         Steven     24000
101         Neena      17000
```

### Why It Helps

- Breaks complex logic into readable steps
- Allows reuse of the same intermediate result several times
- Makes SQL easier to troubleshoot

---

**➡ Transition:** CTEs become even more powerful when you use multiple named blocks inside one query. 

---

## 4. Multiple CTEs

### The Challenge

A query may require multiple intermediate datasets.

### How It Works

You can define several CTEs separated by commas.

### Syntax/Usage

```sql
WITH dept_avg AS (
    SELECT department_id, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY department_id
),

high_dept AS (
    SELECT department_id
    FROM dept_avg
    WHERE avg_salary > 8000
)
SELECT e.employee_id, e.first_name, e.salary
FROM employees e
JOIN high_dept hd
    ON e.department_id = hd.department_id;
```

### Example

```sql
WITH avg_by_dept AS (
    SELECT department_id, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY department_id
),
filtered_depts AS (
    SELECT department_id
    FROM avg_by_dept
    WHERE avg_salary >= 9000
)
SELECT *
FROM filtered_depts;
```

This is easier than nesting many subqueries inside one SELECT.

---

**➡ Transition:** Recursive CTEs let you traverse hierarchical relationships such as employee-manager chains. 

---

## 5. Recursive CTEs

### The Challenge

You need to repeatedly expand a result set until a condition is met.

### How It Works

A recursive CTE has two parts:
1. Anchor member: initial rows
2. Recursive member: repeatedly adds related rows

### Syntax/Usage

```sql
WITH emp_hierarchy AS (
    SELECT employee_id, manager_id, first_name, 1 AS level
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    SELECT e.employee_id, e.manager_id, e.first_name, eh.level + 1
    FROM employees e
    JOIN emp_hierarchy eh
      ON e.manager_id = eh.employee_id
)
SELECT *
FROM emp_hierarchy;
```

### Example

```sql
WITH manager_tree AS (
    SELECT employee_id, manager_id, first_name, 0 AS lvl
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    SELECT e.employee_id, e.manager_id, e.first_name, mt.lvl + 1
    FROM employees e
    JOIN manager_tree mt
      ON e.manager_id = mt.employee_id
)
SELECT *
FROM manager_tree;
```

### Why It Matters

- Works with hierarchical data
- Keeps recursion logic readable
- Helps solve tree and organization questions

### Important Rule

The recursive member must reduce the problem toward a termination condition. Otherwise the query can loop forever.

---

**➡ Transition:** Oracle commonly uses hierarchy patterns with employee-manager relationships, which are similar to recursive CTE logic. 

---

## 6. Oracle Hierarchy Pattern

### The Challenge

You need to list all employees under a manager, or show the full path from top manager to employee.

### How It Works

Oracle supports hierarchical queries with `CONNECT BY` and `START WITH`, while recursive CTEs provide a modern SQL approach.

### Example with CONNECT BY

```sql
SELECT employee_id, first_name, manager_id
FROM employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id;
```

This returns the whole hierarchy starting from top-level managers.

### Example with recursive CTE

```sql
WITH emp_tree AS (
    SELECT employee_id, manager_id, first_name, first_name AS path
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    SELECT e.employee_id, e.manager_id, e.first_name,
           et.path || ' -> ' || e.first_name
    FROM employees e
    JOIN emp_tree et
      ON e.manager_id = et.employee_id
)
SELECT *
FROM emp_tree;
```

### Why Both Matter

- `CONNECT BY` is classic Oracle hierarchical syntax
- Recursive CTEs are clearer and more portable in modern SQL patterns

---

## 7. Comparison Matrix

### CTE vs Subquery vs Recursive Query

| Aspect | CTE | Subquery | Recursive CTE |
| --- | --- | --- | --- |
| **Purpose** | Name a temporary result | Nested inline result | Expand hierarchy/iteration |
| **Readable** | Very readable | Can be messy | Better for tree logic |
| **Reuse** | Reusable in same statement | One-time use | Self-refers multiple times |
| **Complexity** | Moderate | Low to moderate | Higher |
| **Best for** | Step-by-step logic | Quick filters | Hierarchical data |

---

## 8. Best Practices

### 1. Use CTEs to break complex SQL into steps

**Avoid:**
```sql
SELECT *
FROM employees e
WHERE e.salary > (
    SELECT AVG(salary)
    FROM employees e2
    WHERE e2.department_id = e.department_id
);
```

**Prefer:**
```sql
WITH dept_avg AS (
    SELECT department_id, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY department_id
)
SELECT e.*
FROM employees e
JOIN dept_avg d
  ON e.department_id = d.department_id
WHERE e.salary > d.avg_salary;
```

**Why:** Better readability and easier debugging.

---

### 2. Control recursion carefully

```sql
WITH emp_tree AS (
    SELECT employee_id, manager_id
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    SELECT e.employee_id, e.manager_id
    FROM employees e
    JOIN emp_tree et
      ON e.manager_id = et.employee_id
)
SELECT * FROM emp_tree;
```

**Why:** The recursion must terminate or it will repeat endlessly.

---

## 9. Common Mistakes

### Mistake 1: Using recursive CTE without a termination condition

**Problem:** The query keeps expanding and never ends.

**Solution:** Ensure each recursive step moves closer to a base case.

---

### Mistake 2: Confusing CTE with permanent table

**Problem:** A CTE exists only for the current statement.

**Solution:** Use a real table or materialized view if you need persistent storage.

---

### Mistake 3: Overusing CTEs for simple logic

**Problem:** It can make the query unnecessarily verbose.

**Solution:** Use CTEs when they improve readability or enable recursion.

---

## 10. Interview Q&A

### Conceptual Questions

**Q: What is a CTE?**
A: A CTE is a temporary named result set created by a WITH clause and used within the scope of a single SQL statement.

---

**Q: Why are CTEs useful in SQL interviews?**
A: They simplify complex logic, improve readability, and are particularly useful for hierarchical queries and multi-step calculations.

---

### Comparison Questions

**Q: How is a CTE different from a subquery?**
A: A subquery is inline and usually referenced once. A CTE is named, reusable, and easier to read in multi-step logic.

---

### Scenario Questions

**Q: How would you find the full employee-manager chain?**
A: Use a recursive CTE or Oracle `CONNECT BY` query starting from the top manager and expanding downward.

---

## 11. Revision Summary

### 1-Minute Recap

**CTE** = A temporary named result set inside a statement.

- **Simple CTE** → break logic into readable steps
- **Multiple CTEs** → chain intermediate results
- **Recursive CTE** → walk parent-child or manager-employee trees
- **Oracle hierarchy** → `CONNECT BY` and `START WITH` are related patterns

### Interview Keywords

- **WITH clause** → defines the CTE
- **Recursive member** → repeated expansion step
- **Anchor member** → initial base rows
- **Hierarchy** → parent-child relationships
- **Readability** → main benefit of a CTE

### Important Syntax

```sql
WITH dept_summary AS (
    SELECT department_id, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY department_id
)
SELECT *
FROM dept_summary;

WITH emp_tree AS (
    SELECT employee_id, manager_id
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    SELECT e.employee_id, e.manager_id
    FROM employees e
    JOIN emp_tree et
      ON e.manager_id = et.employee_id
)
SELECT * FROM emp_tree;
```

---

**Done!** CTEs are one of the clearest ways to structure readable, maintainable SQL, especially when a query has multiple logical steps or a hierarchy to traverse.
