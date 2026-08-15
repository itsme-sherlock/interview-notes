# SQL Joins Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **JOIN** = Combines rows from two or more tables using a common column or condition.
- **INNER JOIN** = Keeps only matching rows from both tables.
- **LEFT JOIN** = Keeps all rows from the left table and matching rows from the right table.
- **RIGHT JOIN** = Keeps all rows from the right table and matching rows from the left table.
- **FULL JOIN** = Keeps rows that match and rows that do not match on either side.
- **SELF JOIN** = Joins a table to itself to compare rows within the same table.
- **Interview keyword** = Use foreign keys and join conditions carefully; NULLs affect OUTER JOIN results.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Joins?](#1-why-do-we-need-joins)
2. [What Is a Join?](#2-what-is-a-join)
3. [INNER JOIN](#3-inner-join)
4. [OUTER JOINS](#4-outer-joins)
5. [SELF JOIN](#5-self-join)
6. [CROSS JOIN and Other Join Types](#6-cross-join-and-other-join-types)
7. [Comparison Matrix](#7-comparison-matrix)
8. [Best Practices](#8-best-practices)
9. [Common Mistakes](#9-common-mistakes)
10. [Interview Q&A](#10-interview-qa)
11. [Revision Summary](#11-revision-summary)

---

## 1. Why Do We Need Joins?

### The Problem: Data Exists in Multiple Tables

**Situation:** In a real database, employee data, department data, and manager data are usually stored separately.

If you only query one table at a time, you lose the business relationship between records.

```sql
SELECT * FROM employees;
SELECT * FROM departments;
```

**Problems with this approach:**
- You cannot see which employees belong to which department.
- You cannot compare manager records with employee records.
- Reports require combining multiple tables into a single result.

### The Solution: Joins

A **join** combines rows from two or more tables based on a related column, usually a primary key and foreign key.

### Real-World Scenarios

- **HR reporting:** Show each employee with their department name.
- **Sales analysis:** Match orders to customers.
- **Banking:** Connect account holders to accounts and transactions.

---

**➡ Transition:** Once we know why we combine tables, let’s define exactly what a join does and how Oracle matches rows. 

---

## 2. What Is a Join?

### Simple Definition

A **join** is a way to combine data from two or more tables using a condition such as `employees.department_id = departments.department_id`.

It answers questions like: “Which department does this employee belong to?” or “Which customer placed this order?”

### Analogy: Real-World Comparison

**Think of a school database** like a library catalog:
- One table contains student records
- Another table contains class records
- A join connects the student to the class using a shared identifier

### Key Characteristics

- **Relates tables:** Usually uses a PK/FK relationship
- **Returns combined rows:** Not just separate queries
- **Can filter or expand data:** Depending on join type
- **Important for reporting:** Most real-world SQL uses joins

### Types or Variations

| Type | When to Use | Example |
| --- | --- | --- |
| INNER JOIN | Only matching rows | Employee + department |
| LEFT JOIN | Keep every left row | All customers, match orders if present |
| RIGHT JOIN | Keep every right row | All departments, show employees if present |
| FULL JOIN | Keep unmatched rows on both sides | Compare two datasets |
| SELF JOIN | Compare rows in same table | Employee manager relationship |

---

**➡ Transition:** Let’s look at the most common join: the INNER JOIN. 

---

## 3. INNER JOIN

### The Challenge

If you only want rows that have matching values in both tables, you need a way to filter out unmatched records.

### How It Works

An `INNER JOIN` matches rows where the join condition is true.

```text
Table A          Table B
ID  Name         ID  Department
1  Alice         10  HR
2  Bob           20  IT
3  Carol         30  Finance

JOIN on A.ID = B.ID
```

Only matching rows remain.

### Syntax/Usage

```sql
SELECT e.employee_id, e.first_name, d.department_name
FROM employees e
INNER JOIN departments d
    ON e.department_id = d.department_id;
```

### Example

**Example 1: Simple case**

```sql
SELECT e.employee_id, e.first_name, d.department_name
FROM employees e
INNER JOIN departments d
    ON e.department_id = d.department_id;
```

**Output:**

```text
EMPLOYEE_ID FIRST_NAME DEPARTMENT_NAME
----------- ---------- ---------------
100         Steven     IT
101         Neena      IT
102         Lex        IT
... 
```

**Example 2: Real-world scenario**

```sql
SELECT c.customer_id, c.customer_name, o.order_id
FROM customers c
INNER JOIN orders o
    ON c.customer_id = o.customer_id;
```

This returns only customers who actually placed orders.

### Common Points to Remember

- **Most common join type**
- **Filters out non-matching rows**
- **Good for reporting where both tables must exist**

---

**➡ Transition:** What if you want every row from one table even when there is no match? That is where OUTER JOIN comes in. 

---

## 4. OUTER JOINS

### The Challenge

Sometimes you need to include rows that do not have a matching row in the related table.

### How It Works

A left, right, or full outer join keeps unmatched rows and fills missing values with `NULL`.

```text
LEFT JOIN = preserve left table rows
RIGHT JOIN = preserve right table rows
FULL JOIN = preserve both sides
```

### Syntax/Usage

```sql
SELECT e.employee_id, e.first_name, d.department_name
FROM employees e
LEFT JOIN departments d
    ON e.department_id = d.department_id;
```

### Example

**Example 1: LEFT JOIN**

```sql
SELECT e.employee_id, e.first_name, d.department_name
FROM employees e
LEFT JOIN departments d
    ON e.department_id = d.department_id;
```

**Output:**

```text
EMPLOYEE_ID FIRST_NAME DEPARTMENT_NAME
----------- ---------- ---------------
100         Steven     IT
101         Neena      IT
102         Lex        IT
103         Alexander  NULL
```

`NULL` means there is no matching department row for that employee.

**Example 2: RIGHT JOIN**

```sql
SELECT e.employee_id, e.first_name, d.department_name
FROM employees e
RIGHT JOIN departments d
    ON e.department_id = d.department_id;
```

This keeps all departments, even those with no employee.

**Example 3: FULL JOIN**

```sql
SELECT e.employee_id, e.first_name, d.department_name
FROM employees e
FULL JOIN departments d
    ON e.department_id = d.department_id;
```

This keeps both unmatched employee rows and unmatched department rows.

### Common Parameter/Condition Logic

| Join Type | Rows Kept | Missing Columns |
| --- | --- | --- |
| INNER JOIN | Matching only | No unmatched rows |
| LEFT JOIN | All left rows | Right side becomes NULL |
| RIGHT JOIN | All right rows | Left side becomes NULL |
| FULL JOIN | All rows from both sides | Missing values become NULL |

---

**➡ Transition:** Some problems need the table to relate to itself. That is exactly what SELF JOIN handles. 

---

## 5. SELF JOIN

### The Challenge

A table may contain rows that are related to other rows in the same table.

Example: Employees have managers who are also employees.

### How It Works

You alias the same table twice and join one instance to another:

```sql
SELECT e.employee_id, e.first_name, m.first_name AS manager_name
FROM employees e
LEFT JOIN employees m
    ON e.manager_id = m.employee_id;
```

### Syntax/Usage

```sql
SELECT a.column1, b.column2
FROM table_name a
JOIN table_name b
    ON a.related_id = b.other_id;
```

### Example

```sql
SELECT e.first_name AS employee, m.first_name AS manager
FROM employees e
LEFT JOIN employees m
    ON e.manager_id = m.employee_id;
```

**Output:**

```text
EMPLOYEE     MANAGER
----------   ----------
John         Steven
Alice        Steven
Bob          Neena
```

### Why It Matters

Self joins are common for:
- Employee-manager hierarchies
- Parent-child relationships
- Comparing rows within the same table

---

**➡ Transition:** There are also join types that do not require matching keys at all. 

---

## 6. CROSS JOIN and Other Join Types

### The Challenge

Sometimes you want every combination of rows from two tables.

### How It Works

A **CROSS JOIN** multiplies rows from one table by rows from another table.

```sql
SELECT *
FROM customers
CROSS JOIN products;
```

This creates every customer-product pairing.

### Example

```sql
SELECT c.customer_name, p.product_name
FROM customers c
CROSS JOIN products p;
```

**Output:**

```text
Alice  Laptop
Alice  Phone
Alice  Tablet
Bob    Laptop
Bob    Phone
Bob    Tablet
```

### Other Join Variations

- **NATURAL JOIN**: Auto-matches same-named columns
- **USING clause**: Join on same-named column explicitly
- **Theta join**: Any boolean condition

### Example with USING

```sql
SELECT e.employee_id, d.department_name
FROM employees e
JOIN departments d
    USING (department_id);
```

This is cleaner when both tables share the same column name.

---

## 7. Comparison Matrix

### Join Types Compared

| Aspect | INNER JOIN | LEFT JOIN | RIGHT JOIN | FULL JOIN | CROSS JOIN |
| --- | --- | --- | --- | --- | --- |
| **When to use** | Only matching rows | All left rows | All right rows | All rows both sides | All combinations |
| **Performance** | Usually best | Good | Good | More expensive | Expensive |
| **NULL handling** | None | Right side NULL | Left side NULL | Both sides NULL | No match issue |
| **Best for** | Standard relationships | Reporting | Reverse reporting | Data comparison | Cartesian product |
| **Limitation** | Drops unmatched rows | Can overinflate left side | Can overinflate right side | Can be large | Large result set |

---

## 8. Best Practices

### 1. Join on keys, not on text columns when possible

**Avoid:**
```sql
SELECT *
FROM employees e
JOIN departments d
    ON e.department_name = d.department_name;
```

**Prefer:**
```sql
SELECT *
FROM employees e
JOIN departments d
    ON e.department_id = d.department_id;
```

**Why:** Numeric IDs are faster and more stable than names.

---

### 2. Always alias tables for readability

```sql
SELECT e.employee_id, d.department_name
FROM employees e
JOIN departments d
    ON e.department_id = d.department_id;
```

**Why:** Shorter, clearer, and easier to maintain.

---

### 3. Be careful with NULLs in OUTER JOIN

```sql
SELECT e.employee_id, d.department_name
FROM employees e
LEFT JOIN departments d
    ON e.department_id = d.department_id;
```

**Why:** Unmatched rows appear with `NULL`, so filters must handle them correctly.

---

## 9. Common Mistakes

### Mistake 1: Forgetting the join condition

**Problem:** This creates a cartesian product and multiplies rows.

```sql
SELECT e.first_name, d.department_name
FROM employees e
JOIN departments d;
```

**Why it fails:** Oracle cannot know how to match row pairs without `ON`.

**Solution:**
```sql
SELECT e.first_name, d.department_name
FROM employees e
JOIN departments d
    ON e.department_id = d.department_id;
```

---

### Mistake 2: Using INNER JOIN when LEFT JOIN is needed

**Problem:** You lose records with no match.

**Solution:**
```sql
SELECT c.customer_name, o.order_id
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id;
```

---

### Mistake 3: Filtering outer join results in the wrong place

**Problem:** `WHERE` after a `LEFT JOIN` can accidentally remove rows you meant to keep.

```sql
SELECT c.customer_name, o.order_id
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
WHERE o.order_id IS NOT NULL;
```

This removes customers with no orders, which may be wrong if you wanted all customers.

---

## 10. Interview Q&A

### Conceptual Questions

**Q: What is a join in SQL?**
A: A join combines rows from multiple tables using a related column. It is how databases express relationships between data sets.

---

**Q: Why do we use LEFT JOIN instead of INNER JOIN?**
A: We use LEFT JOIN when we want to keep all rows from the left table, even if there is no match in the right table. This is common in reporting and customer analysis.

---

### Comparison Questions

**Q: What is the difference between INNER JOIN and LEFT JOIN?**
A: `INNER JOIN` returns only matching rows. `LEFT JOIN` returns all left table rows and the matching right rows, with `NULL` when no match exists.

---

### Scenario Questions

**Q: A report must show all employees, even if they are not assigned to a department. What join should be used?**
A: Use `LEFT JOIN` from `employees` to `departments`. This preserves all employees and shows department names when available.

---

## 11. Revision Summary

### 1-Minute Recap

**Join** = A way to combine related rows from multiple tables.

- **INNER JOIN** → only matching rows
- **LEFT JOIN** → keep all left rows
- **RIGHT JOIN** → keep all right rows
- **FULL JOIN** → keep both unmatched sides
- **SELF JOIN** → join a table to itself
- **CROSS JOIN** → all combinations

### Interview Keywords

- **PK/FK relationship** → Primary key to foreign key matching
- **NULL** → Missing value in unmatched rows
- **Cartesian product** → Unfiltered join causing row multiplication
- **Alias** → Temporary table name for readability

### Important Syntax

```sql
SELECT e.employee_id, d.department_name
FROM employees e
INNER JOIN departments d
    ON e.department_id = d.department_id;

SELECT e.employee_id, d.department_name
FROM employees e
LEFT JOIN departments d
    ON e.department_id = d.department_id;

SELECT e1.first_name, e2.first_name AS manager
FROM employees e1
LEFT JOIN employees e2
    ON e1.manager_id = e2.employee_id;
```

---

**Done!** Joins are the foundation of relational SQL. Learn the join type, the matching condition, and the NULL behavior, and you can solve most reporting queries.
