# SQL GROUP BY, HAVING, and Aggregate Functions Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Aggregate function** = Computes one value from multiple rows.
- **COUNT** = Counts rows or non-null values.
- **SUM** = Adds numeric values.
- **AVG** = Finds the average.
- **MIN / MAX** = Finds smallest or largest value.
- **GROUP BY** = Splits rows into groups before aggregation.
- **HAVING** = Filters aggregated result groups.
- **Interview keyword** = You cannot filter grouped results with WHERE; use HAVING instead.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Aggregation?](#1-why-do-we-need-aggregation)
2. [What Are Aggregate Functions?](#2-what-are-aggregate-functions)
3. [GROUP BY](#3-group-by)
4. [HAVING Clause](#4-having-clause)
5. [COUNT, SUM, AVG, MIN, MAX](#5-count-sum-avg-min-max)
6. [GROUP BY vs ORDER BY vs WHERE](#6-group-by-vs-order-by-vs-where)
7. [Comparison Matrix](#7-comparison-matrix)
8. [Best Practices](#8-best-practices)
9. [Common Mistakes](#9-common-mistakes)
10. [Interview Q&A](#10-interview-qa)
11. [Revision Summary](#11-revision-summary)

---

## 1. Why Do We Need Aggregation?

### The Problem: Raw Data Is Too Detailed

A table often contains many rows, but managers want one number per product, department, or bucket.

```sql
SELECT * FROM employees;
```

The raw result is too detailed to answer questions like:
- What is the total salary by department?
- How many employees work in each role?
- Who earns above the department average?

**Problems with raw row-level data:**
- Hard to summarize business performance
- Difficult to compare groups
- Reporting requires category-level metrics

### The Solution: Aggregate Functions and GROUP BY

Aggregation collapses many rows into one summary value per group.

### Real-World Scenarios

- **Sales:** Revenue per month
- **HR:** Headcount by department
- **Operations:** Average response time by region

---

**➡ Transition:** Let’s define what an aggregate function actually does. 

---

## 2. What Are Aggregate Functions?

### Simple Definition

An **aggregate function** combines multiple rows and returns a single value, such as a total, average, count, minimum, or maximum.

### Analogy: Real-World Comparison

**Think of a school report card**:
- Individual scores are row-level data
- Class average is an aggregate result
- Grouping creates separate averages for each class

### Key Characteristics

- Works on multiple rows
- Returns one value per group (or one value overall)
- Often used with `GROUP BY`
- Can ignore `NULL` depending on the function

### Common Aggregate Functions

| Function | Meaning | Example |
| --- | --- | --- |
| COUNT | Number of rows | Count employees |
| SUM | Total | Total salaries |
| AVG | Average | Average salary |
| MIN | Smallest | Minimum salary |
| MAX | Largest | Maximum salary |

---

**➡ Transition:** The grouping clause decides which rows belong together before aggregation. 

---

## 3. GROUP BY

### The Challenge

You need summaries for each category, not a single total across the whole table.

### How It Works

`GROUP BY` creates buckets based on one or more columns. The aggregate function runs separately for each bucket.

### Syntax/Usage

```sql
SELECT department_id, COUNT(*)
FROM employees
GROUP BY department_id;
```

### Example

**Example 1: Count employees by department**

```sql
SELECT department_id, COUNT(*) AS employee_count
FROM employees
GROUP BY department_id;
```

**Output:**

```text
DEPARTMENT_ID EMPLOYEE_COUNT
------------- --------------
10            3
20            2
30            6
```

**Example 2: Average salary by department**

```sql
SELECT department_id, ROUND(AVG(salary), 2) AS avg_salary
FROM employees
GROUP BY department_id;
```

This gives one average per department.

### Important Rule

Any column in the `SELECT` list that is not part of an aggregate function must appear in the `GROUP BY` clause.

---

**➡ Transition:** Once rows are grouped, how do you filter those grouped results? Use HAVING. 

---

## 4. HAVING Clause

### The Challenge

You want to filter groups after the aggregation is calculated.

### How It Works

`WHERE` filters rows before grouping. `HAVING` filters the grouped result after aggregation.

### Syntax/Usage

```sql
SELECT department_id, AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id
HAVING AVG(salary) > 8000;
```

### Example

```sql
SELECT department_id, COUNT(*) AS emp_count
FROM employees
GROUP BY department_id
HAVING COUNT(*) > 3;
```

**Output:**

```text
DEPARTMENT_ID EMP_COUNT
------------- --------
30            6
```

### Key Rule

- `WHERE` comes before `GROUP BY`
- `HAVING` comes after `GROUP BY`

### Why This Matters

This is one of the most common SQL interview distinctions:
- `WHERE` filters raw rows
- `HAVING` filters aggregated groups

---

**➡ Transition:** Let’s review the core aggregate functions and when to use each one. 

---

## 5. COUNT, SUM, AVG, MIN, MAX

### The Challenge

You need to summarize data in a measurable way.

### How It Works

These functions operate on all rows in a group.

### Syntax/Usage

```sql
SELECT COUNT(*), SUM(salary), AVG(salary), MIN(salary), MAX(salary)
FROM employees;
```

### Examples

**COUNT**
```sql
SELECT COUNT(*)
FROM employees;
```

**SUM**
```sql
SELECT SUM(salary)
FROM employees;
```

**AVG**
```sql
SELECT AVG(salary)
FROM employees;
```

**MIN / MAX**
```sql
SELECT MIN(salary), MAX(salary)
FROM employees;
```

### Important Notes

- `COUNT(*)` counts all rows, including duplicates and `NULL`s
- `COUNT(column)` counts non-NULL values
- `SUM` and `AVG` ignore `NULL` values
- `MIN` and `MAX` work with numeric, text, and date values

---

**➡ Transition:** Sometimes people mix up WHERE, GROUP BY, and ORDER BY. Let’s clarify the order and purpose. 

---

## 6. GROUP BY vs ORDER BY vs WHERE

### The Challenge

These clauses all look similar but they do different jobs.

### How They Work

```sql
SELECT department_id, COUNT(*)
FROM employees
WHERE salary > 5000
GROUP BY department_id
HAVING COUNT(*) > 1
ORDER BY department_id;
```

### Sequence

1. `WHERE` filters raw rows
2. `GROUP BY` creates groups
3. `HAVING` filters grouped results
4. `SELECT` returns final columns
5. `ORDER BY` sorts output

### Example

```sql
SELECT department_id, AVG(salary) AS avg_salary
FROM employees
WHERE salary > 3000
GROUP BY department_id
HAVING AVG(salary) > 7000
ORDER BY avg_salary DESC;
```

This shows only departments whose average salary is above a threshold.

---

## 7. Comparison Matrix

### Aggregation Concepts Compared

| Aspect | WHERE | GROUP BY | HAVING | ORDER BY |
| --- | --- | --- | --- | --- |
| **When it runs** | Before grouping | During grouping | After grouping | After final selection |
| **Filters** | Raw rows | Creates groups | Aggregated groups | Sorts output |
| **Can use aggregate?** | No | No direct filter | Yes | No |
| **Used with aggregates?** | No | Yes | Yes | No |
| **Typical purpose** | Row filter | Group rows | Filter groups | Sort final rows |

---

## 8. Best Practices

### 1. Filter rows before aggregating

**Avoid:**
```sql
SELECT department_id, AVG(salary)
FROM employees
GROUP BY department_id
HAVING salary > 5000;
```

**Prefer:**
```sql
SELECT department_id, AVG(salary)
FROM employees
WHERE salary > 5000
GROUP BY department_id;
```

**Why:** `WHERE` removes irrelevant rows before calculation.

---

### 2. Use HAVING only after grouping

```sql
SELECT department_id, COUNT(*)
FROM employees
GROUP BY department_id
HAVING COUNT(*) > 3;
```

**Why:** This allows filtering by aggregated values such as counts or averages.

---

### 3. Use aliases in ORDER BY for readability

```sql
SELECT department_id, AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id
ORDER BY avg_salary DESC;
```

**Why:** It makes reports easier to understand.

---

## 9. Common Mistakes

### Mistake 1: Using WHERE with aggregate conditions

**Problem:** This is invalid when filtering aggregate output.

```sql
SELECT department_id, AVG(salary)
FROM employees
WHERE AVG(salary) > 8000
GROUP BY department_id;
```

**Why it fails:** `WHERE` cannot use aggregate results because the aggregation happens later.

**Solution:**
```sql
SELECT department_id, AVG(salary)
FROM employees
GROUP BY department_id
HAVING AVG(salary) > 8000;
```

---

### Mistake 2: Grouping by a column not in SELECT without reason

**Problem:** It can create confusing or duplicate group results.

**Solution:** Keep the grouping columns aligned with the business question.

---

### Mistake 3: Forgetting that COUNT(column) ignores NULLs

```sql
SELECT COUNT(salary)
FROM employees;
```

This counts only non-null salaries. If you need all rows, use `COUNT(*)`.

---

## 10. Interview Q&A

### Conceptual Questions

**Q: What is the difference between WHERE and HAVING?**
A: `WHERE` filters rows before grouping. `HAVING` filters groups after aggregation is computed.

---

**Q: What does GROUP BY do?**
A: It groups rows with the same values in the specified columns so aggregate functions can produce one result per group.

---

### Comparison Questions

**Q: What is the difference between COUNT(*) and COUNT(column)?**
A: `COUNT(*)` counts all rows. `COUNT(column)` counts only non-null values in that column.

---

### Scenario Questions

**Q: Show departments with more than 5 employees.**
A:
```sql
SELECT department_id, COUNT(*) AS employee_count
FROM employees
GROUP BY department_id
HAVING COUNT(*) > 5;
```

This is a standard aggregation pattern in reporting and interviews.

---

## 11. Revision Summary

### 1-Minute Recap

**Aggregate functions** summarize many rows into one value.

- **COUNT** → number of rows
- **SUM** → total value
- **AVG** → average value
- **MIN / MAX** → smallest / largest value
- **GROUP BY** → creates row groups
- **HAVING** → filters grouped results

### Interview Keywords

- **Group summary** → one value per category
- **Row-level filter** → WHERE
- **Group-level filter** → HAVING
- **Null-safe count** → COUNT(*)
- **Business metric** → aggregate output

### Important Syntax

```sql
SELECT department_id, COUNT(*)
FROM employees
GROUP BY department_id;

SELECT department_id, AVG(salary)
FROM employees
GROUP BY department_id
HAVING AVG(salary) > 8000;

SELECT COUNT(*), SUM(salary), MIN(salary), MAX(salary)
FROM employees;
```

---

**Done!** Aggregation is one of the most important SQL skills because it turns raw records into business information.
