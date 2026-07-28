# Window Functions and Analytics Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Window function** = Aggregate + detail together (unlike GROUP BY which collapses rows).
- **OVER clause** = Defines partition (groups) and ordering for window.
- **PARTITION BY** = Split data into groups (similar to GROUP BY)
- **ORDER BY** = Sort rows within partition (for ranking/comparison)
- **Ranking:** ROW_NUMBER (unique 1,2,3...), RANK (ties get same rank, skip next: 1,1,3...), DENSE_RANK (ties get same rank, no skip: 1,1,2...)
- **Comparison:** LAG (previous row), LEAD (next row)
- **Running totals:** SUM/AVG/COUNT with ROWS BETWEEN clause
- **LISTAGG** = Concatenate values into string
- **PIVOT** = Row values → Columns (wide format)
- **UNPIVOT** = Columns → Row values (normalized format)

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Window Functions?](#1-why-do-we-need-window-functions)
2. [What is a Window Function?](#2-what-is-a-window-function)
3. [The OVER Clause](#3-the-over-clause)
4. [PARTITION BY vs GROUP BY](#4-partition-by-vs-group-by)
5. [Ranking Functions](#5-ranking-functions)
6. [ROW_NUMBER() Function](#6-row_number-function)
7. [RANK() Function](#7-rank-function)
8. [DENSE_RANK() Function](#8-dense_rank-function)
9. [Comparison Functions: LAG and LEAD](#9-comparison-functions-lag-and-lead)
10. [Aggregate Window Functions](#10-aggregate-window-functions)
11. [Frames: ROWS BETWEEN](#11-frames-rows-between)
12. [LISTAGG Function](#12-listagg-function)
13. [PIVOT: Rows to Columns](#13-pivot-rows-to-columns)
14. [UNPIVOT: Columns to Rows](#14-unpivot-columns-to-rows)
15. [Best Practices](#15-best-practices)
16. [Common Mistakes](#16-common-mistakes)
17. [Interview Q&A](#17-interview-qa)
18. [Revision Summary](#18-revision-summary)

---

## 1. Why Do We Need Window Functions?

### The Problem: Aggregate Functions Lose Detail

**Scenario:** Show department, salary, AND highest salary in department.

**Using GROUP BY (doesn't work):**
```sql
SELECT department_id, 
       MAX(salary) AS max_salary,
       salary  -- ❌ This column causes error!
FROM employees
GROUP BY department_id;
-- Error: non-aggregated column in GROUP BY clause
```

**Why?** GROUP BY collapses rows into one row per group. Can't show individual salaries.

**Using self-join (works but slow):**
```sql
SELECT e.employee_id,
       e.salary,
       m.max_salary
FROM employees e
JOIN (
  SELECT department_id, MAX(salary) AS max_salary
  FROM employees
  GROUP BY department_id
) m ON e.department_id = m.department_id;
-- Works but requires complex join, slow for large tables
```

### The Solution: Window Functions

**Window function** lets you:
- Keep **all rows** (don't collapse)
- Show **individual data** (salary, name)
- Show **aggregate data** (max salary, count, rank) in each row

```sql
-- Shows individual salary AND department max salary
SELECT employee_id,
       department_id,
       salary,
       MAX(salary) OVER (PARTITION BY department_id) AS dept_max_salary
FROM employees;
```

**Result:**
```
Employee_ID | Department | Salary | Dept_Max
------------|------------|--------|----------
101         | 10         | 45000  | 50000
102         | 10         | 50000  | 50000
103         | 20         | 60000  | 65000
104         | 20         | 65000  | 65000
```

### Real-World Benefits

- **Ranking:** Show rank + individual data (top 3 per department)
- **Running totals:** Cumulative sales this year
- **Trend analysis:** Compare to previous month/quarter
- **Percentiles:** Show how salary compares to peers
- **Performance:** No slow joins or GROUP BY

---

**➡ Transition:** Now that we understand the problem, what exactly is a window function and how does the OVER clause work?

---

## 2. What is a Window Function?

### Simple Definition

A **window function** is a function that:
- Operates on a **set of rows** (called a "window")
- Returns a **result for each row** (unlike GROUP BY)
- Keeps **all rows in output** (no collapsing)
- Can perform **ranking, aggregating, comparing**

### Analogy: Sliding Window

Imagine a window sliding across your data:

```
Employee  Salary
--------  ------
Alice     50000  ← Window 1 (first employee)
Bob       45000  ← Window 2 (Bob + Alice + Carol)
Carol     55000  ← Window 3 (Bob + Carol + David)
David     60000  ← Window 4 (Carol + David + Eve)
Eve       48000  ← Window 5 (last employee)
```

Window function evaluates for each row, but sees multiple rows.

### Basic Syntax

```sql
SELECT column_name,
       window_function() OVER (partition_clause order_clause) AS result_column
FROM table_name;
```

### Example

```sql
SELECT employee_id,
       salary,
       ROW_NUMBER() OVER (ORDER BY salary DESC) AS rank
FROM employees;
```

**Explanation:**
- `ROW_NUMBER()` = Window function (gives sequence number)
- `OVER (ORDER BY salary DESC)` = Defines the window (order by salary, highest first)
- For each row, assigns a rank (1, 2, 3, ...)

---

**➡ Transition:** The OVER clause is critical—it defines which rows the window function sees and how they're organized.

---

## 3. The OVER Clause

### What OVER Does

The **OVER clause** defines:
- **Which rows** are included in the window (PARTITION BY)
- **How rows are ordered** in the window (ORDER BY)
- **Which rows to include** in calculation (ROWS BETWEEN)

### Syntax

```sql
OVER (
  [PARTITION BY column1, column2, ...]
  [ORDER BY column1 [ASC|DESC], ...]
  [ROWS BETWEEN ... AND ...]
)
```

### Component 1: PARTITION BY

**Splits data into groups** (like GROUP BY, but keeps all rows).

```sql
SELECT department_id,
       employee_id,
       salary,
       MAX(salary) OVER (PARTITION BY department_id) AS dept_max_salary
FROM employees;
```

**Without PARTITION BY:** Window includes all rows (one big group)
**With PARTITION BY department_id:** Separate window per department

### Component 2: ORDER BY

**Orders rows within each partition**.

```sql
SELECT department_id,
       employee_id,
       salary,
       ROW_NUMBER() OVER (
         PARTITION BY department_id 
         ORDER BY salary DESC  -- Highest salary first
       ) AS rank
FROM employees;
```

### Component 3: ROWS BETWEEN (Advanced)

**Defines frame (which rows to include in calculation)**.

```sql
SUM(salary) OVER (
  PARTITION BY department_id
  ORDER BY hire_date
  ROWS BETWEEN 2 PRECEDING AND CURRENT ROW  -- Include previous 2 + current
) AS moving_sum
```

---

**➡ Transition:** PARTITION BY vs GROUP BY looks similar, but they're fundamentally different. Let's understand the difference.

---

## 4. PARTITION BY vs GROUP BY

### GROUP BY (Collapses Rows)

```sql
SELECT department_id,
       COUNT(*) AS emp_count,
       AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id;
```

**Result (3 rows for 3 departments):**
```
Department | Count | Avg_Salary
-----------|-------|----------
10         | 5     | 50000
20         | 6     | 60000
30         | 4     | 55000
```

**Loses:** Employee names, individual salaries, details.

---

### PARTITION BY (Keeps Rows)

```sql
SELECT department_id,
       employee_id,
       salary,
       COUNT(*) OVER (PARTITION BY department_id) AS emp_count,
       AVG(salary) OVER (PARTITION BY department_id) AS avg_salary
FROM employees;
```

**Result (15 rows for 15 employees):**
```
Dept | Employee | Salary | Count | Avg_Salary
-----|----------|--------|-------|----------
10   | 101      | 45000  | 5     | 50000
10   | 102      | 50000  | 5     | 50000
10   | 103      | 55000  | 5     | 50000
20   | 104      | 60000  | 6     | 60000
...
```

**Keeps:** All employee details + department aggregates.

---

### Comparison

| Aspect | GROUP BY | PARTITION BY |
| --- | --- | --- |
| **Rows in output** | 1 per group | All rows |
| **Detail columns** | Can't show individual data | Can show individual data |
| **Aggregates** | Yes | Yes |
| **Use case** | Summary reports | Detail + summary together |

---

**➡ Transition:** Now let's explore ranking functions, which are the most common window functions used in interviews.

---

## 5. Ranking Functions

Three ranking functions help assign positions:

| Function | Ties | Skip | Example |
| --- | --- | --- | --- |
| **ROW_NUMBER** | Different numbers | Yes | 1, 2, 3, 4, 5 |
| **RANK** | Same rank | Yes | 1, 1, 3, 4, 5 |
| **DENSE_RANK** | Same rank | No | 1, 1, 2, 3, 4 |

### Scenario: Employee Salaries

```
Employee | Salary
---------|-------
Alice    | 50000  ← Rank 1
Bob      | 50000  ← Rank ? (tie with Alice)
Carol    | 55000  ← Rank ? (after tie)
David    | 60000  ← Rank ?
```

---

## 6. ROW_NUMBER() Function

### What It Does

Assigns a **unique sequential number** to each row, even if values are tied.

### Example: Rank Employees by Salary

```sql
SELECT employee_id,
       first_name,
       salary,
       ROW_NUMBER() OVER (ORDER BY salary DESC) AS salary_rank
FROM employees;
```

**Result:**
```
Employee_ID | Name   | Salary | Rank
------------|--------|--------|-----
103         | Carol  | 65000  | 1
104         | David  | 60000  | 2
101         | Alice  | 50000  | 3
102         | Bob    | 50000  | 4  ← Different number even though same salary
```

### With PARTITION BY: Top 2 Per Department

```sql
SELECT department_id,
       employee_id,
       first_name,
       salary,
       ROW_NUMBER() OVER (
         PARTITION BY department_id 
         ORDER BY salary DESC
       ) AS rank
FROM employees;

-- Get only top 2
WHERE rank <= 2;
```

### Use Cases

- Top N per group (top 3 employees per department)
- Pagination (page 1: rows 1-10, page 2: rows 11-20)
- Removing duplicates

---

## 7. RANK() Function

### What It Does

Assigns ranks; **ties get same rank**, then **skips next numbers**.

### Example: Same Salaries

```sql
SELECT employee_id,
       first_name,
       salary,
       RANK() OVER (ORDER BY salary DESC) AS salary_rank
FROM employees;
```

**Result:**
```
Employee_ID | Name   | Salary | Rank
------------|--------|--------|-----
103         | Carol  | 65000  | 1
104         | David  | 60000  | 2
101         | Alice  | 50000  | 3
102         | Bob    | 50000  | 3  ← Same rank (tie)
105         | Eve    | 48000  | 5  ← Skips rank 4
```

### Why Rank Skips

When two people tie for 3rd place, next person is 5th place (not 4th).

**Analogy:** Olympic medal standings (Gold=1, Silver=2, tied Bronze=3, 3rd Bronze also=3, next person=5).

### Use Cases

- Sports rankings (Olympic medals)
- Percentile reporting (top 10% = ranks 1-X)
- Awards (top 3 positions)

---

## 8. DENSE_RANK() Function

### What It Does

Assigns ranks; **ties get same rank**, but **no gaps in sequence**.

### Example: Same Salaries

```sql
SELECT employee_id,
       first_name,
       salary,
       DENSE_RANK() OVER (ORDER BY salary DESC) AS salary_rank
FROM employees;
```

**Result:**
```
Employee_ID | Name   | Salary | Rank
------------|--------|--------|-----
103         | Carol  | 65000  | 1
104         | David  | 60000  | 2
101         | Alice  | 50000  | 3
102         | Bob    | 50000  | 3  ← Same rank (tie)
105         | Eve    | 48000  | 4  ← No gap, continues from 3
```

### ROW_NUMBER vs RANK vs DENSE_RANK

**Given:**
```
Alice:   50000
Bob:     50000 (tie)
Carol:   55000
```

| Function | Rank for Alice | Rank for Bob | Rank for Carol |
| --- | --- | --- | --- |
| ROW_NUMBER | 1 | 2 | 3 |
| RANK | 1 | 1 | 3 |
| DENSE_RANK | 1 | 1 | 2 |

### Use Cases

- Tier-based analysis (tier 1, tier 2, tier 3... no gaps)
- Salary bands
- Performance reviews (ranks 1-5, multiple people per rank)

---

**➡ Transition:** Ranking compares rows horizontally. But sometimes you need to look at adjacent rows—previous or next. That's where LAG and LEAD come in.

---

## 9. Comparison Functions: LAG and LEAD

### What They Do

- **LAG(column, offset)** = Get value from **previous** row
- **LEAD(column, offset)** = Get value from **next** row

No need for self-joins; much cleaner and faster.

### Example: Month-over-Month Sales Comparison

```sql
SELECT month,
       sales,
       LAG(sales) OVER (ORDER BY month) AS prev_month_sales,
       LEAD(sales) OVER (ORDER BY month) AS next_month_sales,
       sales - LAG(sales) OVER (ORDER BY month) AS growth
FROM monthly_sales;
```

**Result:**
```
Month | Sales  | Prev_Sales | Next_Sales | Growth
------|--------|------------|------------|-------
Jan   | 10000  | NULL       | 15000      | NULL
Feb   | 15000  | 10000      | 12000      | 5000
Mar   | 12000  | 15000      | 18000      | -3000
Apr   | 18000  | 12000      | NULL       | 6000
May   | NULL   | 18000      | NULL       | NULL
```

### With PARTITION BY: Department Comparison

```sql
SELECT department_id,
       employee_id,
       salary,
       LAG(salary) OVER (
         PARTITION BY department_id 
         ORDER BY salary
       ) AS prev_salary,
       salary - LAG(salary) OVER (PARTITION BY department_id ORDER BY salary) AS salary_diff
FROM employees;
```

Shows salary difference from previous employee in same department.

### LAG/LEAD with Offset

```sql
-- Get value from 2 rows back (not just 1)
LAG(salary, 2) OVER (ORDER BY hire_date) AS salary_2_years_ago

-- Get value from next row with default if NULL
LEAD(salary, 1, 0) OVER (ORDER BY hire_date) AS next_salary_or_zero
```

### Use Cases

- Trend analysis (month-over-month, year-over-year)
- Period comparisons (this quarter vs last quarter)
- Transaction history (identify unusual changes)
- Patient history (medication changes, lab results)

---

**➡ Transition:** Ranking and comparison work on individual rows. But sometimes you need **running totals** or **aggregate ranges**—that's where frame clauses come in.

---

## 10. Aggregate Window Functions

### Using Aggregates in Window Functions

Standard aggregate functions (SUM, AVG, COUNT, MIN, MAX) can be used as window functions:

```sql
SELECT employee_id,
       salary,
       SUM(salary) OVER (PARTITION BY department_id) AS total_dept_salary,
       AVG(salary) OVER (PARTITION BY department_id) AS avg_dept_salary,
       COUNT(*) OVER (PARTITION BY department_id) AS dept_employee_count
FROM employees;
```

### Example: Salary vs Department Average

```sql
SELECT employee_id,
       first_name,
       salary,
       AVG(salary) OVER (PARTITION BY department_id) AS avg_salary,
       salary - AVG(salary) OVER (PARTITION BY department_id) AS variance
FROM employees;
```

**Result:**
```
ID  | Name   | Salary | Avg_Salary | Variance
----|--------|--------|------------|----------
101 | Alice  | 45000  | 50000      | -5000  (below avg)
102 | Bob    | 55000  | 50000      | 5000   (above avg)
103 | Carol  | 50000  | 50000      | 0      (at avg)
```

---

## 11. Frames: ROWS BETWEEN

### What is a Frame?

A **frame** defines which rows to include in the window calculation.

**Without frame:** All rows in partition included (global aggregate).
**With frame:** Only specific rows included (running total).

### ROWS BETWEEN Syntax

```sql
ROWS BETWEEN [start] AND [end]
```

**Options for start/end:**
- `UNBOUNDED PRECEDING` = All rows from start
- `n PRECEDING` = n rows before current
- `CURRENT ROW` = Current row only
- `n FOLLOWING` = n rows after current
- `UNBOUNDED FOLLOWING` = All rows to end

### Example: Running Total (Cumulative Sum)

```sql
SELECT month,
       sales,
       SUM(sales) OVER (
         ORDER BY month
         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS cumulative_sales
FROM monthly_sales;
```

**Result:**
```
Month | Sales  | Cumulative
------|--------|----------
Jan   | 10000  | 10000
Feb   | 15000  | 25000
Mar   | 12000  | 37000
Apr   | 18000  | 55000
```

### Example: Moving Average (Last 3 Months)

```sql
SELECT month,
       sales,
       AVG(sales) OVER (
         ORDER BY month
         ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
       ) AS moving_avg_3m
FROM monthly_sales;
```

**Result:**
```
Month | Sales  | Moving_Avg
------|--------|----------
Jan   | 10000  | 10000
Feb   | 15000  | 12500
Mar   | 12000  | 12333
Apr   | 18000  | 15000  (avg of Feb, Mar, Apr)
```

### Common Frames

| Frame | Use Case |
| --- | --- |
| `UNBOUNDED PRECEDING AND CURRENT ROW` | Cumulative total |
| `1 PRECEDING AND 1 FOLLOWING` | Average of current + neighbors |
| `2 PRECEDING AND CURRENT ROW` | Moving average (last 3 rows) |

---

**➡ Transition:** We've covered typical aggregates and frames. Now let's look at LISTAGG for combining multiple values into one string.

---

## 12. LISTAGG Function

### What It Does

**LISTAGG** concatenates values from multiple rows into a single string, separated by a delimiter.

### Example: Employee Names Per Department

```sql
SELECT department_id,
       LISTAGG(first_name, ', ') WITHIN GROUP (ORDER BY first_name) AS employee_names
FROM employees
GROUP BY department_id;
```

**Result:**
```
Department | Employee_Names
-----------|-------------------------------------
10         | Alice, Bob, Carol
20         | David, Eve, Frank
30         | Grace, Henry
```

### Syntax Explained

- `LISTAGG(column, delimiter)` = Concatenate values with delimiter
- `WITHIN GROUP (ORDER BY column)` = Order values before concatenating
- Must use with `GROUP BY`

### Example: Comma-Separated Projects Per Employee

```sql
SELECT employee_id,
       LISTAGG(project_name, '; ') WITHIN GROUP (ORDER BY project_name) AS projects
FROM employee_projects
GROUP BY employee_id;
```

**Result:**
```
Employee | Projects
---------|--------------------------------------------------
101      | Database Migration; Email System; Web Portal
102      | Email System; Mobile App; Security Audit
```

### Use Cases

- Generate comma-separated lists
- Create reports with grouped values
- Build email recipient lists
- Display hierarchical structures

---

**➡ Transition:** LISTAGG transforms rows to a single concatenated value. PIVOT does something different—it transforms rows to multiple columns.

---

## 13. PIVOT: Rows to Columns

### What PIVOT Does

**PIVOT** converts row values into **columns** (transposing data from long format to wide format).

### Before PIVOT: Long Format

```sql
SELECT department_id, job_id, COUNT(*) AS count
FROM employees
GROUP BY department_id, job_id;
```

**Result (8 rows):**
```
Dept | Job      | Count
-----|----------|------
10   | Manager  | 2
10   | Analyst  | 1
20   | Manager  | 1
20   | Engineer | 3
30   | Manager  | 1
30   | Analyst  | 2
...
```

### After PIVOT: Wide Format

```sql
SELECT *
FROM (
  SELECT department_id, job_id, COUNT(*) AS count
  FROM employees
  GROUP BY department_id, job_id
)
PIVOT (
  SUM(count)  -- Aggregate function
  FOR job_id IN (  -- Column to pivot
    'Manager' AS manager,
    'Analyst' AS analyst,
    'Engineer' AS engineer
  )
);
```

**Result (3 rows):**
```
Dept | Manager | Analyst | Engineer
-----|---------|---------|----------
10   | 2       | 1       | NULL
20   | 1       | NULL    | 3
30   | 1       | 2       | NULL
```

### PIVOT Syntax

```sql
PIVOT (
  aggregate_function(column)  -- How to combine values
  FOR pivot_column IN (       -- Which column values become columns
    value1 AS col1,
    value2 AS col2,
    ...
  )
)
```

### Use Cases

- Cross-tabulation reports (rows = category, columns = metric)
- Sales by region/product
- Budget vs actual reporting
- Survey results (responses per answer)

---

**➡ Transition:** PIVOT turns rows to columns. UNPIVOT does the opposite—turns columns back into rows.

---

## 14. UNPIVOT: Columns to Rows

### What UNPIVOT Does

**UNPIVOT** converts **columns into rows** (transposing wide format to long format).

This is useful when you have data in wide format but need it normalized for analysis.

### Before UNPIVOT: Wide Format

```
Employee | Q1_Sales | Q2_Sales | Q3_Sales | Q4_Sales
---------|----------|----------|----------|----------
Alice    | 10000    | 15000    | 12000    | 18000
Bob      | 12000    | 14000    | 16000    | 20000
```

### After UNPIVOT: Long Format

```sql
SELECT *
FROM (
  SELECT employee_id, q1_sales, q2_sales, q3_sales, q4_sales
  FROM sales_wide
)
UNPIVOT (
  sales FOR quarter IN (
    q1_sales AS 'Q1',
    q2_sales AS 'Q2',
    q3_sales AS 'Q3',
    q4_sales AS 'Q4'
  )
);
```

**Result:**
```
Employee | Quarter | Sales
---------|---------|------
Alice    | Q1      | 10000
Alice    | Q2      | 15000
Alice    | Q3      | 12000
Alice    | Q4      | 18000
Bob      | Q1      | 12000
Bob      | Q2      | 14000
...
```

### UNPIVOT Syntax

```sql
UNPIVOT (
  values_column_name  -- Name of new column with values
  FOR pivot_column_name IN (  -- Name of new column with old column names
    old_column_1 AS value1,
    old_column_2 AS value2,
    ...
  )
)
```

### Use Cases

- Normalize wide data for analysis
- Convert reports to data warehouse format
- Prepare data for charting
- Simplify multi-period data

---

## 15. Best Practices

### 1. Use Window Functions Instead of Self-Joins

**Avoid:**
```sql
-- Slow self-join
SELECT e.employee_id, e.salary,
       m.max_salary
FROM employees e
JOIN (SELECT department_id, MAX(salary) AS max_salary FROM employees GROUP BY department_id) m
  ON e.department_id = m.department_id;
```

**Prefer:**
```sql
-- Fast window function
SELECT employee_id, salary,
       MAX(salary) OVER (PARTITION BY department_id) AS max_salary
FROM employees;
```

---

### 2. ORDER BY Matters for Ranking/LAG/LEAD

**Avoid:**
```sql
-- Without ORDER BY, ranking is undefined
SELECT employee_id, salary,
       ROW_NUMBER() OVER (PARTITION BY department_id) AS rank
FROM employees;
```

**Prefer:**
```sql
-- Always ORDER BY to get predictable ranking
SELECT employee_id, salary,
       ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rank
FROM employees;
```

---

### 3. Use Appropriate Ranking Function

**Avoid:**
```sql
-- ROW_NUMBER breaks ties arbitrarily
SELECT name, score,
       ROW_NUMBER() OVER (ORDER BY score DESC) AS rank
FROM quiz_results;
-- Two people with same score get different ranks (1, 2)
```

**Prefer:**
```sql
-- DENSE_RANK for tier-based (1, 1, 2, 3...)
SELECT name, score,
       DENSE_RANK() OVER (ORDER BY score DESC) AS rank
FROM quiz_results;
```

---

### 4. PARTITION BY for Multi-Level Analysis

**Avoid:**
```sql
-- All data in one window (no grouping)
SELECT department_id, employee_id, salary,
       RANK() OVER (ORDER BY salary DESC) AS global_rank
FROM employees;
```

**Prefer:**
```sql
-- Separate ranking per department
SELECT department_id, employee_id, salary,
       RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS dept_rank
FROM employees;
```

---

### 5. Named Window for Readability

**Avoid:**
```sql
-- Same OVER clause repeated
SELECT employee_id, salary,
       ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rank,
       RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS dense_rank
FROM employees;
```

**Prefer:**
```sql
-- Define once, reuse with window name
SELECT employee_id, salary,
       ROW_NUMBER() OVER (w) AS rank,
       RANK() OVER (w) AS dense_rank
FROM employees
WINDOW w AS (PARTITION BY department_id ORDER BY salary DESC);
```

---

## 16. Common Mistakes

### Mistake 1: Forgetting ORDER BY

```sql
-- ❌ WRONG: Without ORDER BY, ranking is unpredictable
SELECT employee_id, salary,
       ROW_NUMBER() OVER (PARTITION BY department_id) AS rank
FROM employees;
-- Result: unpredictable ordering

-- ✅ CORRECT: ORDER BY defines ranking order
SELECT employee_id, salary,
       ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rank
FROM employees;
```

---

### Mistake 2: Using GROUP BY When Window Function Needed

```sql
-- ❌ WRONG: Can't show individual salary + department average with GROUP BY
SELECT department_id, AVG(salary), salary
FROM employees
GROUP BY department_id;
-- Error: non-aggregated column

-- ✅ CORRECT: Use window function
SELECT department_id, salary,
       AVG(salary) OVER (PARTITION BY department_id) AS dept_avg
FROM employees;
```

---

### Mistake 3: Wrong Ranking Function for Use Case

```sql
-- ❌ WRONG: ROW_NUMBER for medals (where ties should have same rank)
SELECT athlete, medal_time,
       ROW_NUMBER() OVER (ORDER BY medal_time) AS place
FROM race_results;
-- Two athletes with same time get different places (1, 2) - unfair!

-- ✅ CORRECT: DENSE_RANK for tied results
SELECT athlete, medal_time,
       DENSE_RANK() OVER (ORDER BY medal_time) AS place
FROM race_results;
```

---

### Mistake 4: Misunderstanding PARTITION BY

```sql
-- ❌ WRONG: Thinking PARTITION BY works like filter
SELECT department_id, employee_id,
       MAX(salary) OVER (PARTITION BY department_id = 10)
FROM employees;
-- This doesn't limit rows, it just groups calculation

-- ✅ CORRECT: Use WHERE to filter rows
SELECT department_id, employee_id,
       MAX(salary) OVER (PARTITION BY department_id) AS dept_max
FROM employees
WHERE department_id = 10;
```

---

### Mistake 5: Not Understanding Frame Impact

```sql
-- ❌ WRONG: Without frame specification, assumes UNBOUNDED
SELECT month, sales,
       SUM(sales) OVER (ORDER BY month) AS cumulative
FROM monthly_sales;
-- Returns cumulative (correct for this case, but confusing)

-- ✅ CORRECT: Explicitly specify frame for clarity
SELECT month, sales,
       SUM(sales) OVER (
         ORDER BY month
         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS cumulative
FROM monthly_sales;
```

---

## 17. Interview Q&A

### Conceptual

**Q: What's the difference between window functions and GROUP BY?**

A: GROUP BY collapses rows into one row per group; can't show individual values. Window functions keep all rows; can show individual data + aggregates in same row.

---

**Q: When would you use ROW_NUMBER vs RANK vs DENSE_RANK?**

A: ROW_NUMBER for unique sequencing (pagination). RANK for ties with gaps (Olympic medals). DENSE_RANK for tier-based rankings without gaps (performance tiers).

---

**Q: What does PARTITION BY do?**

A: Splits data into logical groups (like GROUP BY), then applies window function separately to each group. Rows within partition see only their partition's window.

---

### Comparison

**Q: LAG/LEAD vs self-join?**

A: LAG/LEAD are cleaner, faster, and more readable. Self-join requires complex join logic and is slower on large tables.

---

**Q: PIVOT vs GROUP BY?**

A: GROUP BY for row-based results. PIVOT for column-based results (transforming rows to columns for reports).

---

### Scenario

**Q: Show top 3 employees per department by salary with department average. Use single query.**

A: Use RANK() OVER (PARTITION BY dept ORDER BY salary DESC) for ranking, then AVG() OVER (PARTITION BY dept) for average, then WHERE rank <= 3.

---

**Q: Calculate month-over-month growth rate for sales. Handle NULL previous months.**

A: Use LAG(sales) OVER (ORDER BY month), then COALESCE(sales - LAG_value, 0) for growth calculation.

---

## 18. Revision Summary

### 1-Minute Revision

**Window functions = Keep all rows + show aggregates together (unlike GROUP BY).**

1. **OVER clause** = Defines partition (groups) and ordering
2. **PARTITION BY** = Split into groups (like GROUP BY)
3. **ORDER BY** = Sort rows within partition (critical for ranking/LAG/LEAD)
4. **ROW_NUMBER** = Unique sequential (1,2,3...)
5. **RANK** = Same rank for ties, skip next (1,1,3...)
6. **DENSE_RANK** = Same rank for ties, no skip (1,1,2...)
7. **LAG/LEAD** = Previous/next row value (no self-join needed)
8. **ROWS BETWEEN** = Specify frame (cumulative, moving average)
9. **LISTAGG** = Concatenate values into string
10. **PIVOT** = Rows → Columns (long format to wide)
11. **UNPIVOT** = Columns → Rows (wide format to long)

### Interview Keywords

- Window function vs GROUP BY
- OVER clause (PARTITION BY + ORDER BY + ROWS BETWEEN)
- Ranking: ROW_NUMBER, RANK, DENSE_RANK (differences)
- LAG/LEAD for comparison (previous/next)
- Running totals (ROWS BETWEEN UNBOUNDED PRECEDING)
- LISTAGG for concatenation
- PIVOT for reports (transposing)
- Frame specification (CURRENT ROW, PRECEDING, FOLLOWING)

### Important Syntax

```sql
-- ROW_NUMBER with PARTITION BY and ORDER BY
SELECT employee_id, salary,
  ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rank
FROM employees;

-- Running total with ROWS BETWEEN
SELECT month, sales,
  SUM(sales) OVER (ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative
FROM monthly_sales;

-- LAG for previous month comparison
SELECT month, sales,
  LAG(sales) OVER (ORDER BY month) AS prev_sales,
  sales - LAG(sales) OVER (ORDER BY month) AS growth
FROM monthly_sales;

-- LISTAGG to concatenate
SELECT department_id,
  LISTAGG(first_name, ', ') WITHIN GROUP (ORDER BY first_name) AS employees
FROM employees
GROUP BY department_id;

-- PIVOT for column transformation
SELECT * FROM (
  SELECT department_id, job_id, COUNT(*) AS cnt FROM employees GROUP BY department_id, job_id
)
PIVOT (SUM(cnt) FOR job_id IN ('Manager', 'Analyst', 'Engineer'));
```

## What Is a Window Function?

A window function performs calculations across a set of related rows while still returning each row in the output.

- It does not collapse rows like a normal `GROUP BY` aggregate query.
- It is useful for ranking, running totals, comparisons with previous/next rows, and reporting.

## What Does the OVER Clause Do?

The `OVER` clause defines the window (set of rows) used by the function.

- `PARTITION BY`: Splits data into groups (like departments).
- `ORDER BY`: Defines row order inside each partition.

## ROW_NUMBER()

`ROW_NUMBER()` assigns a unique sequential number to each row in a partition, starting at `1`.

### Example: Salary Rank Per Department

```sql
SELECT employee_id,
       first_name,
       last_name,
       department_id,
       salary,
       ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS salary_rank
FROM hr.employees
ORDER BY department_id, salary_rank;
```

### Example: Top 3 Highest-Paid Employees Per Department

```sql
SELECT *
FROM (
    SELECT employee_id,
           first_name,
           last_name,
           department_id,
           salary,
           ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS salary_rank
    FROM hr.employees
) ranked_employees
WHERE salary_rank <= 3
ORDER BY department_id, salary_rank;
```

## RANK()

`RANK()` gives the same rank for ties and skips the next rank value.

Example: if two rows are rank `1`, the next row becomes rank `3`.

```sql
SELECT employee_id,
       first_name,
       last_name,
       department_id,
       salary,
       RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS salary_rank
FROM hr.employees
ORDER BY department_id, salary_rank;
```

## DENSE_RANK()

`DENSE_RANK()` gives the same rank for ties but does not skip rank values.

Example: if two rows are rank `1`, the next row becomes rank `2`.

```sql
SELECT employee_id,
       first_name,
       last_name,
       department_id,
       salary,
       DENSE_RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS salary_rank
FROM hr.employees
ORDER BY department_id, salary_rank;
```

## LEAD() and LAG()

`LEAD()` and `LAG()` read values from nearby rows without self-joins.

- `LEAD(col)`: Value from next row.
- `LAG(col)`: Value from previous row.

### Common Use Cases

1. Trend analysis
2. Banking transaction comparison
3. Patient history comparison

### Example: Compare Salary With Previous and Next Employee in Department

```sql
SELECT employee_id,
       first_name,
       last_name,
       department_id,
       salary,
       LEAD(salary) OVER (PARTITION BY department_id ORDER BY salary) AS next_salary,
       LAG(salary)  OVER (PARTITION BY department_id ORDER BY salary) AS previous_salary
FROM hr.employees
ORDER BY department_id, salary;
```

## SUM() as a Window Function

`SUM()` with `OVER` can return running totals.

### Example: Running Salary Total Per Department

```sql
SELECT employee_id,
       first_name,
       last_name,
       department_id,
       salary,
       SUM(salary) OVER (
           PARTITION BY department_id
           ORDER BY salary
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS cumulative_salary
FROM hr.employees
ORDER BY department_id, salary;
```

### Example: Mix of Window Calculations

```sql
SELECT employee_id,
       first_name,
       last_name,
       department_id,
       salary,
       ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary) AS row_num,
       MAX(salary)  OVER (PARTITION BY department_id) AS max_salary,
       MIN(salary)  OVER (PARTITION BY department_id) AS min_salary,
       AVG(salary)  OVER (PARTITION BY department_id) AS avg_salary
FROM hr.employees
ORDER BY department_id, salary;
```

## LISTAGG()

`LISTAGG()` combines multiple row values into a single string.

```sql
SELECT department_id,
       LISTAGG(first_name, ',') WITHIN GROUP (ORDER BY first_name) AS employee_names
FROM hr.employees
GROUP BY department_id
ORDER BY department_id;
```

## PIVOT

`PIVOT` converts row values into columns for reporting.

### Before Pivot

```sql
SELECT department_id,
       job_id,
       COUNT(*) AS employee_count
FROM hr.employees
GROUP BY department_id, job_id
ORDER BY department_id, job_id;
```

### After Pivot

```sql
SELECT *
FROM (
    SELECT department_id,
           job_id,
           COUNT(*) AS employee_count
    FROM hr.employees
    GROUP BY department_id, job_id
)
PIVOT (
    SUM(employee_count)
    FOR job_id IN (
        'AD_ASST' AS ad_asst,
        'IT_PROG' AS it_programmer,
        'AD_VP'   AS admin_vp,
        'AD_PRES' AS admin_president
    )
) pivot_table
ORDER BY department_id;
```

## UNPIVOT

`UNPIVOT` converts columns into rows. It is useful when data is in a wide format and you want a normalized format for analysis.
