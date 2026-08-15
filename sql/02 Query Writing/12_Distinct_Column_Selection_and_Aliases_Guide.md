# SQL DISTINCT, Column Selection, and Aliases Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **SELECT** = Chooses the columns to return in the result.
- **DISTINCT** = Removes duplicate rows from the output.
- **Alias** = Gives a column or expression a temporary name.
- **Column selection** = Decides which data is exposed in the final query.
- **Interview keyword** = DISTINCT reduces duplicates, but it does not remove duplicates from the table itself.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need SELECT, DISTINCT, and Aliases?](#1-why-do-we-need-select-distinct-and-aliases)
2. [What Is SELECT?](#2-what-is-select)
3. [Selecting Columns](#3-selecting-columns)
4. [DISTINCT](#4-distinct)
5. [Aliases](#5-aliases)
6. [Using Expressions in SELECT](#6-using-expressions-in-select)
7. [Comparison Matrix](#7-comparison-matrix)
8. [Best Practices](#8-best-practices)
9. [Common Mistakes](#9-common-mistakes)
10. [Interview Q&A](#10-interview-qa)
11. [Revision Summary](#11-revision-summary)

---

## 1. Why Do We Need SELECT, DISTINCT, and Aliases?

### The Problem: Raw Data Is Often Messy and Repetitive

If you query a table with many rows, the output may have repeated values, unhelpful column names, or unnecessary data.

```sql
SELECT * FROM employees;
```

This may show more columns than needed and repeated departments or names.

**Problems with raw output:**
- Duplicate values clutter the report
- Column labels are not user-friendly
- Query results may be too wide or too noisy

### The Solution: Selective Output, Deduplication, and Aliases

`SELECT` defines what to show. `DISTINCT` removes repeated rows. Aliases rename output for readability.

### Real-World Scenarios

- **Reporting:** Show only department names once
- **Exports:** Rename columns for business users
- **Analysis:** Simplify the output for dashboard charts

---

**➡ Transition:** Let’s start with the core selected output: the SELECT statement. 

---

## 2. What Is SELECT?

### Simple Definition

`SELECT` tells the database which columns or expressions to return from a table or joined result.

### Key Characteristics

- Defines the output columns
- Can include expressions and calculations
- Can combine columns from multiple tables
- Does not change stored data

### Example

```sql
SELECT employee_id, first_name, salary
FROM employees;
```

This returns only the specific columns needed.

---

**➡ Transition:** We can select one column, multiple columns, or even expressions. 

---

## 3. Selecting Columns

### The Challenge

You often do not need every column from a table.

### How It Works

The `SELECT` list controls the output.

### Syntax/Usage

```sql
SELECT employee_id, first_name, last_name
FROM employees;
```

### Example

```sql
SELECT department_id, AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id;
```

This selects the department ID and the computed salary average.

### Why It Matters

- Reduces data load
- Makes results easier to read
- Improves query clarity

---

**➡ Transition:** Sometimes repeated rows are not helpful, so DISTINCT removes duplicates from the result set. 

---

## 4. DISTINCT

### The Challenge

Your query may return repeated values, even when they are not meaningful duplicates.

### How It Works

`DISTINCT` removes duplicate rows from the result set.

### Syntax/Usage

```sql
SELECT DISTINCT department_id
FROM employees;
```

### Example

```sql
SELECT DISTINCT first_name
FROM employees;
```

This returns each first name only once.

### Important Note

`DISTINCT` removes duplicates from the query output only. It does not permanently change data in the table.

### Example with multiple columns

```sql
SELECT DISTINCT department_id, job_id
FROM employees;
```

This removes duplicate combinations of both columns.

---

**➡ Transition:** Aliases help rename columns or expressions so reports are easier to read. 

---

## 5. Aliases

### The Challenge

Column names in a database may be technical or unclear to a user.

### How It Works

An **alias** is a temporary name assigned to a column or expression in the result set.

### Syntax/Usage

```sql
SELECT first_name AS name, salary AS monthly_salary
FROM employees;
```

### Example

```sql
SELECT first_name || ' ' || last_name AS full_name,
       salary * 12 AS yearly_salary
FROM employees;
```

This makes the output more business-friendly.

### Notes

- Aliases are temporary and only apply to the query output
- Use them for readability in reports
- They are especially helpful with calculations or expressions

---

**➡ Transition:** Expressions in SELECT often combine columns and functions into derived output. 

---

## 6. Using Expressions in SELECT

### The Challenge

You often want more than stored values—you want derived values.

### How It Works

The `SELECT` list can include expressions, calculations, and functions.

### Syntax/Usage

```sql
SELECT first_name,
       salary,
       salary * 12 AS annual_salary
FROM employees;
```

### Example

```sql
SELECT first_name || ' ' || last_name AS full_name,
       ROUND(salary / 12, 2) AS monthly_salary
FROM employees;
```

### Why It Matters

- Helps create reports without modifying base tables
- Simplifies dashboard and presentation logic
- Makes SQL expressive and reusable

---

## 7. Comparison Matrix

### SELECT, DISTINCT, and Aliases

| Feature | Purpose | Example |
| --- | --- | --- |
| SELECT | Choose output columns | `SELECT first_name, salary` |
| DISTINCT | Remove duplicate rows | `SELECT DISTINCT department_id` |
| Alias | Rename output | `AS full_name` |
| Expression | Compute values in result | `salary * 12 AS annual_salary` |

---

## 8. Best Practices

### 1. Select only needed columns

**Avoid:**
```sql
SELECT * FROM employees;
```

**Prefer:**
```sql
SELECT employee_id, first_name, salary FROM employees;
```

**Why:** Cleaner output and better performance.

---

### 2. Use aliases for readability

```sql
SELECT salary * 12 AS yearly_salary
FROM employees;
```

**Why:** Business users understand the meaning immediately.

---

### 3. Use DISTINCT only when needed

```sql
SELECT DISTINCT department_id
FROM employees;
```

**Why:** It is useful for unique values, but not a replacement for cleaning the actual data.

---

## 9. Common Mistakes

### Mistake 1: Using SELECT * unnecessarily

**Problem:** Returns too much data and hides the real output of interest.

**Solution:** Name the columns explicitly.

---

### Mistake 2: Expecting DISTINCT to remove duplicates from the table

**Problem:** It only removes duplicate rows in the result set.

**Solution:** Use a proper data cleaning or deduplication process at the table level if needed.

---

### Mistake 3: Forgetting that aliases are temporary

**Problem:** People assume alias names can be reused elsewhere in the same query without proper syntax.

**Solution:** Use aliases in the final output and in `ORDER BY` only when supported by the database.

---

## 10. Interview Q&A

### Conceptual Questions

**Q: What does DISTINCT do?**
A: It removes duplicate rows from the query output so only unique values remain.

---

**Q: Why use aliases in SQL?**
A: Aliases make query output easier to read and more user-friendly, especially for calculations and derived expressions.

---

### Comparison Questions

**Q: What is the difference between SELECT * and selecting specific columns?**
A: `SELECT *` returns every column, while selecting specific columns reduces clutter and often improves performance.

---

### Scenario Questions

**Q: Return a unique list of department IDs.**
A:
```sql
SELECT DISTINCT department_id
FROM employees;
```

---

## 11. Revision Summary

### 1-Minute Recap

**SELECT** chooses the result columns, **DISTINCT** removes duplicate rows, and **aliases** rename the output for readability.

- **SELECT** → choose what to return
- **DISTINCT** → remove duplicate rows from output
- **Alias** → rename column or expression
- **Expression** → derived output using function or operation

### Interview Keywords

- **Projection** → the columns selected by a query
- **Duplicate elimination** → DISTINCT
- **Output alias** → temporary result name
- **Derived column** → computed value in SELECT

### Important Syntax

```sql
SELECT employee_id, first_name, salary
FROM employees;

SELECT DISTINCT department_id
FROM employees;

SELECT first_name || ' ' || last_name AS full_name,
       salary * 12 AS annual_salary
FROM employees;
```

---

**Done!** A strong SQL query begins with clear column selection, and business-friendly aliases make the output meaningful for both reporting and interviews.
