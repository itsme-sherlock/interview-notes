# SQL Ordering and LIMIT Clauses Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **ORDER BY** = Sorts the result set in ascending or descending order.
- **ASC** = Smallest to largest or alphabetical order.
- **DESC** = Largest to smallest or reverse alphabetical order.
- **LIMIT / FETCH FIRST** = Restricts the number of rows returned.
- **TOP** = Common SQL Server syntax for row limiting.
- **Interview keyword** = ORDER BY does not change table data; it only changes result output.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Ordering and Limits?](#1-why-do-we-need-ordering-and-limits)
2. [What Is ORDER BY?](#2-what-is-order-by)
3. [Single-Column and Multi-Column Sorting](#3-single-column-and-multi-column-sorting)
4. [ASC and DESC](#4-asc-and-desc)
5. [TOP, LIMIT, and FETCH FIRST](#5-top-limit-and-fetch-first)
6. [OFFSET and Pagination](#6-offset-and-pagination)
7. [Comparison Matrix](#7-comparison-matrix)
8. [Best Practices](#8-best-practices)
9. [Common Mistakes](#9-common-mistakes)
10. [Interview Q&A](#10-interview-qa)
11. [Revision Summary](#11-revision-summary)

---

## 1. Why Do We Need Ordering and Limits?

### The Problem: Query Results Are Hard to Read Without Order

If you fetch employee salaries without sorting, the records may appear in table storage order, which is not useful for analysis.

```sql
SELECT first_name, salary FROM employees;
```

This may be random from a business perspective.

**Problems with unsorted output:**
- Hard to find top or bottom performers
- Reports feel inconsistent
- Pagination is impossible without controlling row count

### The Solution: ORDER BY and Row Limits

SQL gives you control over output ordering and row count.

### Real-World Scenarios

- **Top 5 salaries**
- **Newest orders first**
- **Alphabetical employee list**
- **Pagination across pages**

---

**➡ Transition:** Let’s define what ORDER BY actually does in SQL. 

---

## 2. What Is ORDER BY?

### Simple Definition

`ORDER BY` sorts the final result set by one or more columns.

### Analogy: Real-World Comparison

**Think of a spreadsheet**:
- Without sorting, rows are simply listed in storage order
- With sorting, they are arranged by a chosen rule such as size, date, or name

### Key Characteristics

- Sorts only the output
- Does not change underlying table data
- Can use one or multiple columns
- Works with text, numbers, and dates

### Example

```sql
SELECT first_name, salary
FROM employees
ORDER BY salary DESC;
```

This orders employees from highest salary to lowest salary.

---

**➡ Transition:** We can sort by a single column or by multiple columns in sequence. 

---

## 3. Single-Column and Multi-Column Sorting

### The Challenge

You often need more than one level of ordering.

### How It Works

You can sort by one column or by multiple columns, in the order given.

### Syntax/Usage

```sql
SELECT department_id, first_name, salary
FROM employees
ORDER BY department_id ASC, salary DESC;
```

### Example

**Single-column sort**
```sql
SELECT first_name, salary
FROM employees
ORDER BY salary DESC;
```

**Multi-column sort**
```sql
SELECT department_id, first_name, salary
FROM employees
ORDER BY department_id ASC, salary DESC;
```

This sorts by department first, then by salary within each department.

### Why It Matters

- Useful for reporting by group and rank
- Gives stable, logical ordering
- Helps with ranking and grouped summaries

---

**➡ Transition:** Now let’s review ASC and DESC and how they change the output direction. 

---

## 4. ASC and DESC

### The Challenge

Sorting direction must be explicit when needed.

### How It Works

- `ASC` sorts ascending
- `DESC` sorts descending

### Syntax/Usage

```sql
SELECT first_name, salary
FROM employees
ORDER BY salary DESC;
```

### Example

```sql
SELECT first_name, hire_date
FROM employees
ORDER BY hire_date ASC;
```

This shows the oldest hires first.

### Notes

- `ASC` is the default if omitted
- `DESC` is common for top values, newest dates, or reverse alphabetical order

---

**➡ Transition:** If a report needs only the top N rows, we use row-limiting syntax. 

---

## 5. TOP, LIMIT, and FETCH FIRST

### The Challenge

You want to return only a fixed number of rows.

### How It Works

Different databases use different row-limiting syntax.

### Common Options

| Database | Syntax |
| --- | --- |
| SQL Server | `TOP` |
| MySQL/Postgres | `LIMIT` |
| Oracle 12c+ | `FETCH FIRST n ROWS ONLY` |

### Example: Oracle

```sql
SELECT first_name, salary
FROM employees
ORDER BY salary DESC
FETCH FIRST 5 ROWS ONLY;
```

### Example: MySQL

```sql
SELECT first_name, salary
FROM employees
ORDER BY salary DESC
LIMIT 5;
```

### Example: SQL Server

```sql
SELECT TOP 5 first_name, salary
FROM employees
ORDER BY salary DESC;
```

### Why It Matters

- Top N reports
- Pagination previews
- Finding highest-value rows quickly

---

**➡ Transition:** For page 2 or later results, use OFFSET with row limits. 

---

## 6. OFFSET and Pagination

### The Challenge

You want rows 11–20, not just the first 10.

### How It Works

`OFFSET` skips rows before returning the next page.

### Syntax/Usage

```sql
SELECT first_name, salary
FROM employees
ORDER BY salary DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
```

### Example

```sql
SELECT employee_id, first_name
FROM employees
ORDER BY employee_id
OFFSET 5 ROWS FETCH NEXT 5 ROWS ONLY;
```

This returns rows 6–10 from the sorted list.

### Why It Matters

- Web pages
- API pagination
- Large result sets split into pages

---

## 7. Comparison Matrix

### Ordering and Limits

| Feature | Purpose | Example |
| --- | --- | --- |
| ORDER BY | Sort output | `ORDER BY salary DESC` |
| ASC | Ascending order | Lowest first |
| DESC | Descending order | Highest first |
| LIMIT / TOP / FETCH FIRST | Restrict number of rows | Top 5 salaries |
| OFFSET | Skip rows before fetching | Page 2 results |

---

## 8. Best Practices

### 1. Always order before limiting in top-N queries

**Avoid:**
```sql
SELECT *
FROM employees
FETCH FIRST 5 ROWS ONLY;
```

**Prefer:**
```sql
SELECT *
FROM employees
ORDER BY salary DESC
FETCH FIRST 5 ROWS ONLY;
```

**Why:** Without order, the “top 5” is not meaningful.

---

### 2. Use multi-column ORDER BY when the result needs grouping and ranking

```sql
ORDER BY department_id, salary DESC
```

**Why:** This creates a useful hierarchical order.

---

### 3. Be explicit with pagination offsets

```sql
OFFSET 20 ROWS FETCH NEXT 10 ROWS ONLY
```

**Why:** It makes page boundaries clear and reproducible.

---

## 9. Common Mistakes

### Mistake 1: Using LIMIT without ORDER BY

**Problem:** The “first” rows may not be the ones you intended.

**Solution:** Always add `ORDER BY` before limiting.

---

### Mistake 2: Forgetting that ORDER BY is output-only

**Problem:** People assume the table order changes when it does not.

**Solution:** Use `ORDER BY` to sort results, not mutate stored data.

---

### Mistake 3: Using OFFSET without an ORDER BY

**Problem:** Pagination may skip rows unpredictably if the result order is undefined.

**Solution:** Always sort with a stable key.

---

## 10. Interview Q&A

### Conceptual Questions

**Q: What does ORDER BY do?**
A: It sorts the final result set by one or more columns in ascending or descending order.

---

**Q: What is the difference between ORDER BY and LIMIT?**
A: `ORDER BY` controls how rows are arranged, while `LIMIT` / `TOP` / `FETCH FIRST` controls how many rows are returned.

---

### Comparison Questions

**Q: What is the difference between ASC and DESC?**
A: `ASC` sorts from smallest to largest or A to Z; `DESC` sorts from largest to smallest or Z to A.

---

### Scenario Questions

**Q: Show the top 3 highest-paid employees.**
A:
```sql
SELECT first_name, salary
FROM employees
ORDER BY salary DESC
FETCH FIRST 3 ROWS ONLY;
```

---

## 11. Revision Summary

### 1-Minute Recap

**ORDER BY** = controls result sorting.

- **ASC** → ascending
- **DESC** → descending
- **TOP / LIMIT / FETCH FIRST** → row count limit
- **OFFSET** → skip rows for pagination
- **Sort order matters** for top-N reports and page results

### Interview Keywords

- **Sorting** → rearranging output
- **Top-N query** → select the first N rows
- **Pagination** → split large result sets into pages
- **Stable order** → predictable output across pages

### Important Syntax

```sql
SELECT first_name, salary
FROM employees
ORDER BY salary DESC;

SELECT first_name, salary
FROM employees
ORDER BY salary DESC
FETCH FIRST 5 ROWS ONLY;

SELECT first_name, salary
FROM employees
ORDER BY salary DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
```

---

**Done!** ORDER BY and row-limiting clauses are essential because business reports usually need the best, newest, highest, or earliest rows first.
