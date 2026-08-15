# SQL Subqueries and Set Operators Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Subquery** = A query nested inside another query.
- **Single-row subquery** = Returns one value, used with =, >, <.
- **Multi-row subquery** = Returns multiple values, used with IN, ANY, ALL.
- **Correlated subquery** = References columns from the outer query and runs row by row.
- **UNION** = Combines distinct rows from two queries.
- **UNION ALL** = Combines all rows, including duplicates.
- **INTERSECT** = Rows common to both result sets.
- **MINUS** = Rows present in the first query but not the second.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Subqueries and Set Operators?](#1-why-do-we-need-subqueries-and-set-operators)
2. [What Is a Subquery?](#2-what-is-a-subquery)
3. [Single-Row and Multi-Row Subqueries](#3-single-row-and-multi-row-subqueries)
4. [Correlated Subqueries](#4-correlated-subqueries)
5. [EXISTS and NOT EXISTS](#5-exists-and-not-exists)
6. [Set Operators](#6-set-operators)
7. [Comparison Matrix](#7-comparison-matrix)
8. [Best Practices](#8-best-practices)
9. [Common Mistakes](#9-common-mistakes)
10. [Interview Q&A](#10-interview-qa)
11. [Revision Summary](#11-revision-summary)

---

## 1. Why Do We Need Subqueries and Set Operators?

### The Problem: One Query Is Not Enough

A single query sometimes cannot express “find employees whose salary is above the department average” or “show customers who have orders but not returns.”

```sql
SELECT *
FROM employees
WHERE salary > 8000;
```

This can work, but many real questions require comparing against a dynamic result from another query.

**Problems with a single query approach:**
- Hard to express derived conditions
- Difficult to compare against aggregate results
- Data may need to be combined from multiple result sets

### The Solution: Subqueries and Set Operators

Subqueries let us nest one query inside another. Set operators let us combine entire result sets.

### Real-World Scenarios

- **HR reporting:** Find employees earning more than the company average.
- **Sales analysis:** Get customers who placed orders in the last quarter.
- **Audit queries:** Compare rows in one table versus another.

---

**➡ Transition:** Now that we know why nested queries matter, let’s define a subquery clearly. 

---

## 2. What Is a Subquery?

### Simple Definition

A **subquery** is a query written inside another SQL statement. The inner query produces a result used by the outer query.

It is often used in `WHERE`, `FROM`, or `SELECT` clauses.

### Analogy: Real-World Comparison

**Think of a nested filter**:
- Outer query = “Which employees?”
- Inner query = “What is the salary threshold?”

The inner query calculates the threshold first, then the outer query uses it.

### Key Characteristics

- **Nested:** Executes inside another query
- **Reusable:** Can compute a dynamic value
- **Flexible:** Works with comparisons and filtering
- **Powerful:** Used for derived tables and logic checks

### Types or Variations

| Type | Purpose | Example |
| --- | --- | --- |
| Single-row | One value | Salary > average salary |
| Multi-row | Several values | Department IDs in a list |
| Correlated | Uses outer row context | Compare each employee to department average |
| Derived table | Query inside FROM | `SELECT * FROM (SELECT ...)` |

---

**➡ Transition:** The most common subquery forms are single-row and multi-row queries. 

---

## 3. Single-Row and Multi-Row Subqueries

### The Challenge

The query may need one value or a list of values from another table.

### How It Works

Oracle evaluates the inner query first. The outer query then compares the result using operators like `=`, `>`, `IN`, `ANY`, or `ALL`.

### Syntax/Usage

```sql
SELECT employee_id, first_name, salary
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);
```

### Example

**Example 1: Single-row subquery**

```sql
SELECT first_name, salary
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);
```

**Output:**

```text
FIRST_NAME  SALARY
----------  -------
Steven      24000
Neena       17000
```

**Example 2: Multi-row subquery**

```sql
SELECT employee_id, first_name
FROM employees
WHERE department_id IN (
    SELECT department_id
    FROM departments
    WHERE location_id = 1700
);
```

This returns employees in departments located in a specific city or location group.

### Operators with multi-row subqueries

```sql
WHERE dept_id IN (SELECT dept_id FROM ...)
WHERE salary > ANY (SELECT salary FROM ...)
WHERE salary > ALL (SELECT salary FROM ...)
```

- **IN**: any listed value
- **ANY**: compare with at least one value
- **ALL**: compare with every value in the returned set

---

**➡ Transition:** Some subqueries depend on the current row from the outer query. Those are correlated subqueries. 

---

## 4. Correlated Subqueries

### The Challenge

Sometimes the inner query must use data from the outer query row by row.

### How It Works

A correlated subquery references the outer query’s columns. Oracle executes the inner query repeatedly, once per row of the outer query.

### Syntax/Usage

```sql
SELECT e.employee_id, e.first_name
FROM employees e
WHERE e.salary > (
    SELECT AVG(salary)
    FROM employees e2
    WHERE e2.department_id = e.department_id
);
```

### Example

```sql
SELECT e.first_name, e.salary
FROM employees e
WHERE e.salary > (
    SELECT AVG(salary)
    FROM employees e2
    WHERE e2.department_id = e.department_id
);
```

**Output:**

```text
FIRST_NAME  SALARY
----------  ------
Steven      24000
Neena       17000
```

### When to Use Correlated Subqueries

- Compare each row to a group-specific value
- Find rows that exist only in certain contexts
- Complex filtering logic that depends on current row

### Caveat

Correlated subqueries can be slower because the inner query runs many times. In many cases, a join or aggregate may be more efficient.

---

**➡ Transition:** Another useful pattern is checking if a row exists in a related table. 

---

## 5. EXISTS and NOT EXISTS

### The Challenge

You may need to know whether related rows exist, without caring about the actual values.

### How It Works

`EXISTS` returns true if the subquery finds at least one row. `NOT EXISTS` returns true if no matching row exists.

### Syntax/Usage

```sql
SELECT d.department_name
FROM departments d
WHERE EXISTS (
    SELECT 1
    FROM employees e
    WHERE e.department_id = d.department_id
);
```

### Example

**Example 1: EXISTS**

```sql
SELECT c.customer_name
FROM customers c
WHERE EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.customer_id
);
```

This returns customers who have placed orders.

**Example 2: NOT EXISTS**

```sql
SELECT c.customer_name
FROM customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.customer_id
);
```

This returns customers with no orders.

### Why It Is Useful

- Efficient for existence checking
- Often clearer than `IN` when the subquery is large
- Good for anti-join patterns

---

**➡ Transition:** The next idea is combining entire result sets using set operators. 

---

## 6. Set Operators

### The Challenge

Sometimes you need to combine results from multiple SELECT statements into one output.

### How It Works

Set operators work on result sets, not on rows individually in a table.

### Syntax/Usage

```sql
SELECT column_list FROM table_a
UNION
SELECT column_list FROM table_b;
```

### Types of Set Operators

#### UNION

```sql
SELECT employee_id FROM employees
UNION
SELECT manager_id FROM employees;
```

- Removes duplicates
- Returns distinct rows

#### UNION ALL

```sql
SELECT employee_id FROM employees
UNION ALL
SELECT manager_id FROM employees;
```

- Keeps duplicates
- Faster than `UNION` when duplicates are not a problem

#### INTERSECT

```sql
SELECT employee_id FROM employees
INTERSECT
SELECT manager_id FROM employees;
```

- Returns common values between both queries

#### MINUS

```sql
SELECT employee_id FROM employees
MINUS
SELECT manager_id FROM employees;
```

- Returns rows in the first query not in the second

### Example: Customer and Order IDs

```sql
SELECT customer_id FROM customers
UNION
SELECT customer_id FROM orders;
```

This gives all customer IDs that appear in either table.

---

## 7. Comparison Matrix

### Subqueries vs Set Operators

| Aspect | Subquery | UNION | INTERSECT | MINUS |
| --- | --- | --- | --- | --- |
| **Purpose** | Filter rows using nested query | Combine results | Common rows | Difference rows |
| **Runs inside** | Another SQL statement | Separate SELECTs | Separate SELECTs | Separate SELECTs |
| **Dups** | Depends on outer logic | Removes duplicates | Removes duplicates | Removes duplicates |
| **Best for** | Derived values | Merging result sets | Matching results | Excluding results |
| **Performance** | Can be expensive if correlated | Usually efficient | Usually efficient | Usually efficient |

---

## 8. Best Practices

### 1. Prefer joins when a subquery is just a relationship check

**Avoid:**
```sql
SELECT *
FROM employees e
WHERE department_id IN (
    SELECT department_id
    FROM departments
);
```

**Prefer:**
```sql
SELECT e.*
FROM employees e
JOIN departments d
    ON e.department_id = d.department_id;
```

**Why:** Joins are often clearer and more efficient than nested filters.

---

### 2. Use `EXISTS` for existence checks

```sql
SELECT c.customer_name
FROM customers c
WHERE EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.customer_id
);
```

**Why:** It clearly communicates the business rule: “customer has orders”.

---

### 3. Use `UNION ALL` when duplicates are not needed

```sql
SELECT customer_id FROM customers
UNION ALL
SELECT customer_id FROM orders;
```

**Why:** It avoids the extra duplicate removal step that `UNION` performs.

---

## 9. Common Mistakes

### Mistake 1: Using `=` with a multi-row subquery

**Problem:** This fails when the inner query returns more than one row.

```sql
SELECT *
FROM employees
WHERE department_id = (
    SELECT department_id
    FROM departments
);
```

**Why it fails:** The subquery returns multiple values, but `=` expects a single scalar.

**Solution:**
```sql
SELECT *
FROM employees
WHERE department_id IN (
    SELECT department_id
    FROM departments
);
```

---

### Mistake 2: Using `UNION` when `UNION ALL` is enough

**Problem:** Extra duplicate removal adds cost.

**Solution:**
```sql
SELECT customer_id FROM customers
UNION ALL
SELECT customer_id FROM orders;
```

---

### Mistake 3: Forgetting ORDER BY behavior with set operators

**Problem:** `ORDER BY` must be placed at the end of the full query.

```sql
SELECT employee_id FROM employees
UNION
SELECT manager_id FROM employees
ORDER BY employee_id;
```

This is valid because the ordering applies to the combined result set.

---

## 10. Interview Q&A

### Conceptual Questions

**Q: What is a subquery?**
A: A subquery is a query inside another query. It is used to generate a value, a list, or a filtering condition for the outer query.

---

**Q: When should you use `EXISTS` instead of `IN`?**
A: Use `EXISTS` when you only care whether related rows exist, especially in large datasets or anti-join logic.

---

### Comparison Questions

**Q: What is the difference between `UNION` and `UNION ALL`?**
A: `UNION` removes duplicates; `UNION ALL` keeps all rows. `UNION ALL` is usually faster because it avoids the duplicate scan.

---

### Scenario Questions

**Q: Find all customers who have placed at least one order.**
A:
```sql
SELECT c.customer_name
FROM customers c
WHERE EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.customer_id
);
```

This checks existence instead of materializing a full list of IDs.

---

## 11. Revision Summary

### 1-Minute Recap

**Subquery** = A nested query used to compute or test values. 

- **Single-row subquery** → one result value
- **Multi-row subquery** → several values, use IN / ANY / ALL
- **Correlated subquery** → depends on the outer row
- **EXISTS** → checks if any matching row exists
- **UNION** → combines distinct result sets
- **UNION ALL** → combines all rows, including duplicates

### Interview Keywords

- **Nested query** → Subquery embedded inside another query
- **Scalar** → Single value
- **Correlated** → Inner query depends on outer query row
- **Anti-join** → Rows that do not exist in another table
- **Set logic** → UNION, INTERSECT, MINUS

### Important Syntax

```sql
SELECT first_name
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);

SELECT employee_id
FROM employees
WHERE department_id IN (SELECT department_id FROM departments);

SELECT customer_id FROM customers
UNION ALL
SELECT customer_id FROM orders;
```

---

**Done!** Subqueries and set operators let you solve many business questions by comparing one result set to another or by layering logic inside logic.
