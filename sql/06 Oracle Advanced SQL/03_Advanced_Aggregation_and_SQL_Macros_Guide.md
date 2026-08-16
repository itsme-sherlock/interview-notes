# Oracle Advanced Aggregation and SQL Macros Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **PERCENTILE_CONT** = Calculates a continuous percentile using interpolation.
- **PERCENTILE_DISC** = Returns an actual value from the ordered data set.
- **LISTAGG** = Combines grouped values into one delimited string.
- **ON OVERFLOW TRUNCATE** = Controls oversized LISTAGG results.
- **Approximate aggregation** = Trades a small amount of precision for speed on large data.
- **SQL macro** = Reusable SQL logic expanded by Oracle into the calling statement.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Advanced Aggregation?](#1-why-do-we-need-advanced-aggregation)
2. [Percentile Functions](#2-percentile-functions)
3. [Advanced LISTAGG](#3-advanced-listagg)
4. [Approximate Aggregation](#4-approximate-aggregation)
5. [SQL Macros](#5-sql-macros)
6. [Comparison Matrix](#6-comparison-matrix)
7. [Best Practices](#7-best-practices)
8. [Common Mistakes](#8-common-mistakes)
9. [Interview Q&A](#9-interview-qa)
10. [Revision Summary](#10-revision-summary)

---

## 1. Why Do We Need Advanced Aggregation?

### The Problem: Basic AVG and SUM Do Not Answer Every Business Question

Analytics often needs percentiles, delimited lists, approximate counts, and reusable query logic.

### The Solution

Advanced aggregate functions summarize distributions and groups more precisely and flexibly.

### Real-World Scenarios

- 95th-percentile response time
- Employee names grouped by department
- Approximate distinct users in a large event stream
- Reusable filtering logic for reporting

---

**➡ Transition:** Percentiles describe the position of a value within an ordered distribution. 

---

## 2. Percentile Functions

### PERCENTILE_CONT

Returns an interpolated value.

```sql
SELECT PERCENTILE_CONT(0.95)
       WITHIN GROUP (ORDER BY response_time) AS p95_response_time
FROM api_requests;
```

### PERCENTILE_DISC

Returns an actual value from the data set.

```sql
SELECT PERCENTILE_DISC(0.95)
       WITHIN GROUP (ORDER BY response_time) AS p95_response_time
FROM api_requests;
```

### Difference

- `PERCENTILE_CONT` may return a value between two rows.
- `PERCENTILE_DISC` returns one existing value.

---

**➡ Transition:** LISTAGG answers the reporting question: which values belong to each group? 

---

## 3. Advanced LISTAGG

### Basic Usage

```sql
SELECT department_id,
       LISTAGG(last_name, ', ') WITHIN GROUP (ORDER BY last_name) AS employees
FROM employees
GROUP BY department_id;
```

### Overflow Handling

```sql
SELECT department_id,
       LISTAGG(last_name, ', ' ON OVERFLOW TRUNCATE '...')
           WITHIN GROUP (ORDER BY last_name) AS employees
FROM employees
GROUP BY department_id;
```

### Why It Matters

Ordering, duplicate handling, and overflow behavior should be intentional in production reports.

---

**➡ Transition:** Very large data sets may benefit from approximate calculations. 

---

## 4. Approximate Aggregation

### Approximate Count

```sql
SELECT APPROX_COUNT_DISTINCT(customer_id) AS approximate_customers
FROM events;
```

### Use Case

Approximate functions are useful for dashboards and large-scale analytics when small estimation error is acceptable.

### Trade-off

They can reduce resource usage, but they should not be used where exact financial or compliance numbers are required.

---

**➡ Transition:** SQL macros package reusable SQL logic without hiding the resulting relational query. 

---

## 5. SQL Macros

### Table SQL Macro Example

```sql
CREATE OR REPLACE FUNCTION high_salary_employees (
    minimum_salary NUMBER
) RETURN VARCHAR2 SQL_MACRO(TABLE)
IS
BEGIN
    RETURN q'[SELECT employee_id, first_name, salary
              FROM employees
              WHERE salary >= minimum_salary]';
END;
/
```

### Use the Macro

```sql
SELECT *
FROM high_salary_employees(10000);
```

### Why It Matters

SQL macros can standardize repeated query logic while allowing the optimizer to see the expanded SQL.

### Availability Note

SQL macro support depends on the Oracle Database version and configuration. Confirm the target version before adopting it.

---

## 6. Comparison Matrix

| Feature | Purpose | Precision |
| --- | --- | --- |
| PERCENTILE_CONT | Interpolated percentile | Continuous |
| PERCENTILE_DISC | Existing-value percentile | Discrete |
| LISTAGG | Delimited group output | Exact |
| APPROX_COUNT_DISTINCT | Fast distinct estimate | Approximate |
| SQL macro | Reusable SQL logic | Depends on query |

---

## 7. Best Practices

### 1. Define whether a metric must be exact

### 2. Specify ordering in percentile and LISTAGG expressions

### 3. Handle LISTAGG overflow deliberately

### 4. Test SQL macro syntax against the target Oracle version

---

## 8. Common Mistakes

### Mistake 1: Treating approximate results as exact financial values

**Solution:** Use exact aggregation for financial and compliance reporting.

### Mistake 2: Assuming continuous and discrete percentiles are identical

**Solution:** Choose the function based on whether interpolation is acceptable.

### Mistake 3: Ignoring LISTAGG overflow

**Solution:** Use overflow handling and define an appropriate output contract.

### Mistake 4: Using SQL macros without checking version support

**Solution:** Validate compilation and deployment compatibility first.

---

## 9. Interview Q&A

**Q: What is the difference between PERCENTILE_CONT and PERCENTILE_DISC?**
A: PERCENTILE_CONT can interpolate between values; PERCENTILE_DISC returns an existing ordered value.

**Q: How do you avoid LISTAGG overflow?**
A: Use `ON OVERFLOW TRUNCATE` and decide how truncated output should be represented.

**Q: When is approximate aggregation appropriate?**
A: For large analytical workloads where performance matters and a small estimation error is acceptable.

**Q: What is a SQL macro?**
A: A reusable SQL function whose logic is expanded into the calling statement, subject to Oracle-version support.

---

## 10. Revision Summary

- **PERCENTILE_CONT** → interpolated percentile
- **PERCENTILE_DISC** → actual ordered value
- **LISTAGG** → grouped delimited text
- **APPROX_COUNT_DISTINCT** → fast estimate
- **SQL macro** → reusable expanded SQL logic

### Important Syntax

```sql
SELECT PERCENTILE_CONT(0.95)
       WITHIN GROUP (ORDER BY response_time)
FROM api_requests;

SELECT LISTAGG(last_name, ', ' ON OVERFLOW TRUNCATE)
       WITHIN GROUP (ORDER BY last_name)
FROM employees;
```

---

**Done!** Advanced aggregation helps SQL answer analytical questions that ordinary COUNT, SUM, and AVG cannot express cleanly.
