# Advanced SQL Interview Queries Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Top-N per group** = Rank rows within each group and filter the rank.
- **Gaps and islands** = Find missing sequences or consecutive runs.
- **Anti-join** = Find rows with no related match.
- **Running total** = Use a windowed SUM ordered by time.
- **Duplicate deletion** = Identify duplicates with ROW_NUMBER, then delete by stable row identity.
- **Interview keyword** = Explain the logic, edge cases, duplicates, NULLs, and performance trade-offs.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Advanced Interview Queries?](#1-why-do-we-need-advanced-interview-queries)
2. [Top-N Per Group](#2-top-n-per-group)
3. [Rows With No Match](#3-rows-with-no-match)
4. [Running Totals and Previous Rows](#4-running-totals-and-previous-rows)
5. [Gaps and Consecutive Dates](#5-gaps-and-consecutive-dates)
6. [Safe Duplicate Removal](#6-safe-duplicate-removal)
7. [Comparison Matrix](#7-comparison-matrix)
8. [Best Practices](#8-best-practices)
9. [Common Mistakes](#9-common-mistakes)
10. [Interview Q&A](#10-interview-qa)
11. [Revision Summary](#11-revision-summary)

---

## 1. Why Do We Need Advanced Interview Queries?

### The Problem: Interviews Test Reasoning, Not Memorization

A query may need ranking, history, missing relationships, or duplicate control.

### The Solution

Break the problem into data shape, grouping, ranking, and edge cases before writing SQL.

### Real-World Scenarios

- Highest-paid employees per department
- Customers with no orders
- Daily revenue trends
- Duplicate cleanup

---

**➡ Transition:** Ranking within a group is one of the most common advanced patterns. 

---

## 2. Top-N Per Group

### Requirement

Find the top two salaries in each department.

### Query

```sql
SELECT employee_id, department_id, salary
FROM (
    SELECT e.*, DENSE_RANK() OVER (
        PARTITION BY department_id
        ORDER BY salary DESC
    ) AS salary_rank
    FROM employees e
)
WHERE salary_rank <= 2;
```

### Key Decision

Use `ROW_NUMBER` for exactly N rows, `RANK` or `DENSE_RANK` when ties matter.

---

**➡ Transition:** Anti-joins answer questions about missing relationships. 

---

## 3. Rows With No Match

### Requirement

Find customers who have never placed an order.

```sql
SELECT c.customer_id, c.customer_name
FROM customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.customer_id
);
```

### Alternative

```sql
SELECT c.customer_id, c.customer_name
FROM customers c
LEFT JOIN orders o
  ON o.customer_id = c.customer_id
WHERE o.customer_id IS NULL;
```

### Interview Point

`NOT EXISTS` avoids common `NOT IN` problems when NULLs appear in the subquery.

---

**➡ Transition:** Time-based questions usually need window functions. 

---

## 4. Running Totals and Previous Rows

### Running Total

```sql
SELECT order_date,
       order_amount,
       SUM(order_amount) OVER (
           ORDER BY order_date
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS running_total
FROM orders;
```

### Previous Value

```sql
SELECT employee_id,
       salary,
       LAG(salary) OVER (ORDER BY employee_id) AS previous_salary
FROM employees;
```

### Interview Point

Always define the ordering column and tie behavior for time-series calculations.

---

**➡ Transition:** Gaps-and-islands problems identify missing values or consecutive runs. 

---

## 5. Gaps and Consecutive Dates

### Find Missing IDs

```sql
SELECT employee_id + 1 AS missing_id
FROM employees e
WHERE NOT EXISTS (
    SELECT 1
    FROM employees e2
    WHERE e2.employee_id = e.employee_id + 1
);
```

### Consecutive Date Pattern

```sql
SELECT customer_id, order_date,
       order_date - ROW_NUMBER() OVER (
           PARTITION BY customer_id ORDER BY order_date
       ) AS island_key
FROM customer_orders;
```

Rows sharing the same `island_key` belong to a consecutive run.

### Important Caveat

Decide whether duplicate dates count once or multiple times before writing the query.

---

**➡ Transition:** Duplicate deletion requires extra care because a wrong DELETE can remove valid records. 

---

## 6. Safe Duplicate Removal

### Identify Duplicates

```sql
SELECT email, COUNT(*) AS duplicate_count
FROM customers
GROUP BY email
HAVING COUNT(*) > 1;
```

### Keep One Row

```sql
DELETE FROM customers
WHERE ROWID IN (
    SELECT duplicate_rowid
    FROM (
        SELECT ROWID AS duplicate_rowid,
               ROW_NUMBER() OVER (
                   PARTITION BY email
                   ORDER BY customer_id
               ) AS row_num
        FROM customers
    )
    WHERE row_num > 1
);
```

### Safety Rule

Run the inner SELECT first, back up affected data, and confirm the business definition of a duplicate.

---

## 7. Comparison Matrix

| Pattern | Main Tool | Typical Question |
| --- | --- | --- |
| Top-N per group | RANK / ROW_NUMBER | Highest salaries by department |
| Anti-join | NOT EXISTS | Customers without orders |
| Running total | SUM OVER | Cumulative revenue |
| Previous row | LAG | Compare current vs previous |
| Gaps/islands | Window functions | Missing IDs or consecutive dates |
| Duplicate cleanup | ROW_NUMBER + ROWID | Keep one copy |

---

## 8. Best Practices

### 1. Define tie behavior before choosing a ranking function

### 2. Prefer NOT EXISTS when NULLs may affect NOT IN

### 3. Preview every DELETE with a SELECT

### 4. Explain indexes and data volume in your interview answer

---

## 9. Common Mistakes

### Mistake 1: Using ROW_NUMBER when ties must be preserved

**Solution:** Use RANK or DENSE_RANK.

### Mistake 2: Using NOT IN with nullable values

**Solution:** Prefer NOT EXISTS or filter NULLs explicitly.

### Mistake 3: Deleting duplicates without a stable survivor rule

**Solution:** Define which row to keep using an ordered key.

---

## 10. Interview Q&A

**Q: Find the top three salaries per department.**
A: Use `DENSE_RANK()` partitioned by department and filter rank less than or equal to three.

**Q: How do you find customers without orders?**
A: Use `NOT EXISTS` correlated by customer ID.

**Q: How do you safely remove duplicates?**
A: Rank duplicates within each business-key group, preview rows where rank is greater than one, then delete using a stable row identifier.

**Q: How do you calculate a running total?**
A: Use `SUM(...) OVER (ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)`.

---

## 11. Revision Summary

- **Top-N per group** → partitioned ranking
- **Anti-join** → NOT EXISTS or LEFT JOIN with NULL check
- **Running total** → SUM OVER
- **Previous row** → LAG
- **Gaps and islands** → sequence and grouping logic
- **Duplicates** → ROW_NUMBER plus safe survivor rule

### Important Syntax

```sql
SELECT *
FROM (
    SELECT e.*,
           ROW_NUMBER() OVER (
               PARTITION BY department_id
               ORDER BY salary DESC
           ) AS rn
    FROM employees e
)
WHERE rn <= 3;
```

---

**Done!** Advanced interview SQL is about choosing the correct relational pattern and clearly defending its behavior for duplicates, NULLs, ties, and scale.
