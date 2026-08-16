# SQL Interview Queries – How to Think (Step by Step)


> **Question → Break the problem into small steps → Write SQL for each step → Combine them.**

---

# 1. Find the Second Highest Salary

## How to think

### Step 1: Understand the question

You need the **second largest salary**, not the highest.

Think:

> "I can't find the second highest until I know what the highest is."

---

### Step 2: Find the highest salary

```sql
SELECT MAX(salary) AS highest_salary
FROM employees;
```

Suppose the result is:

| Salary |
| ------ |
| 100000 |

---

### Step 3: Ignore the highest salary

Now tell SQL:

> "Don't consider 100000 anymore."

```sql
WHERE salary < 100000
```

Instead of hardcoding the value, get it dynamically.

```sql
WHERE salary < (
    SELECT MAX(salary)
    FROM employees
)
```

---

### Step 4: From the remaining salaries, find the largest

```sql
SELECT MAX(salary)
FROM employees
WHERE salary < (
    SELECT MAX(salary)
    FROM employees
);
```

---

## Final Query

```sql
SELECT MAX(salary) AS second_highest_salary
FROM employees
WHERE salary < (
    SELECT MAX(salary)
    FROM employees
);
```

---

## Thinking Formula

```
Need second highest?

↓

Find highest

↓

Remove highest

↓

Find highest again
```

---

# 2. Find the Second Highest Salary (Without MAX())

## How to think

Since MAX() is not allowed,

Ask yourself:

> "Can I arrange salaries from highest to lowest?"

Yes.

Use

```
ORDER BY salary DESC
```

Example

| Salary |
| ------ |
| 100000 |
| 90000  |
| 85000  |
| 70000  |

Now the second row is the second highest salary.

---

### Step 1

Sort salaries.

```sql
SELECT DISTINCT salary
FROM employees
ORDER BY salary DESC;
```

---

### Step 2

Take only the first two rows.

```sql
FETCH FIRST 2 ROWS ONLY
```

Result

| Salary |
| ------ |
| 100000 |
| 90000  |

The second row is your answer.

---

### Better Interview Query (Oracle 12c+)

```sql
SELECT salary
FROM (
    SELECT DISTINCT salary
    FROM employees
    ORDER BY salary DESC
)
OFFSET 1 ROW
FETCH NEXT 1 ROW ONLY;
```

---

## Thinking Formula

```
No MAX()

↓

Sort salaries

↓

Skip first

↓

Take second
```

---

# 3. Find the Nth Highest Salary

Suppose the interviewer asks:

* 3rd highest
* 5th highest
* 10th highest

Now MAX() becomes impractical.

---

## How to think

### Step 1

Can we repeatedly use MAX()?

Technically yes.

But if N = 100?

Impossible to write.

Need a smarter approach.

---

### Step 2

Assign a rank to every salary.

```
Highest salary → Rank 1

Second highest → Rank 2

Third highest → Rank 3
```

SQL has ranking functions.

Use

```
DENSE_RANK()
```

because duplicate salaries receive the same rank.

---

Example

| Salary | Rank |
| ------ | ---- |
| 100000 | 1    |
| 90000  | 2    |
| 90000  | 2    |
| 85000  | 3    |
| 70000  | 4    |

---

### Step 3

Now simply filter the required rank.

```
WHERE salary_rank = N
```

---

## Final Query

```sql
SELECT *
FROM (
    SELECT salary,
           DENSE_RANK() OVER (ORDER BY salary DESC) AS salary_rank
    FROM employees
) sub
WHERE salary_rank = 4;
```

---

## Using CTE

```sql
WITH salary_cte AS
(
    SELECT salary,
           DENSE_RANK() OVER (ORDER BY salary DESC) AS salary_rank
    FROM employees
)
SELECT *
FROM salary_cte
WHERE salary_rank = 4;
```

---

## Thinking Formula

```
Need Nth highest?

↓

Sort salaries

↓

Assign rank

↓

Pick required rank
```

---

# 4. Find Employees Earning More Than the Average Salary

## How to think

### Step 1

Find the average salary.

```sql
SELECT AVG(salary)
FROM employees;
```

Suppose

```
Average = 55,000
```

---

### Step 2

Now ask:

> "Which employees earn more than 55,000?"

Instead of writing 55000 manually,

calculate it using a subquery.

---

## Final Query

```sql
SELECT *
FROM employees
WHERE salary >
(
    SELECT AVG(salary)
    FROM employees
);
```

---

## Thinking Formula

```
Need salary > average?

↓

Find average

↓

Use average as filter
```

---

# 5. Display Current Date and Time

Oracle

```sql
SELECT CURRENT_TIMESTAMP
FROM dual;
```

Other useful Oracle functions

Current Date

```sql
SELECT CURRENT_DATE
FROM dual;
```

System Date

```sql
SELECT SYSDATE
FROM dual;
```

Current Timestamp

```sql
SELECT SYSTIMESTAMP
FROM dual;
```

---

# 6. Find Duplicate Records

## Method 1 — GROUP BY + HAVING (Most Common)

## How to think

### Step 1

Group identical values together.

```sql
GROUP BY column_name
```

Example

| Email |
| ----- |
| A     |
| A     |
| B     |
| C     |
| C     |
| C     |

After grouping

```
A → 2

B → 1

C → 3
```

---

### Step 2

Count each group.

```sql
COUNT(*)
```

---

### Step 3

Keep only groups where the count is greater than 1.

```sql
HAVING COUNT(*) > 1
```

---

## Final Query

```sql
SELECT column_name,
       COUNT(*) AS duplicate_count
FROM table_name
GROUP BY column_name
HAVING COUNT(*) > 1;
```

---

## Thinking Formula

```
Need duplicates?

↓

Group same values

↓

Count each group

↓

Keep count > 1
```

---

# Method 2 — ROW_NUMBER()

Use this when you need the **actual duplicate rows**, not just the duplicated values.

---

## How to think

### Step 1

Group identical values.

```
PARTITION BY column_name
```

---

### Step 2

Number each row.

```
ROW_NUMBER()
```

Example

| Email | Row Number |
| ----- | ---------- |
| A     | 1          |
| A     | 2          |
| A     | 3          |
| B     | 1          |
| C     | 1          |
| C     | 2          |

---

### Step 3

The first row is the original.

Every row after that is a duplicate.

```
WHERE row_num > 1
```

---

## Final Query

```sql
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY column_name
               ORDER BY column_name
           ) AS row_num
    FROM table_name
) sub
WHERE row_num > 1;
```

---

# Quick Thinking Cheat Sheet

| Interview Question      | How to Think                                                      |
| ----------------------- | ----------------------------------------------------------------- |
| Second Highest Salary   | Find highest → Remove it → Find highest again                     |
| Second Highest (No MAX) | Sort descending → Skip first → Take second                        |
| Nth Highest Salary      | Rank salaries → Filter required rank                              |
| Salary > Average        | Find average → Use it in `WHERE`                                  |
| Current Date & Time     | Use built-in date/time functions (`SYSDATE`, `CURRENT_TIMESTAMP`) |
| Find Duplicate Values   | Group → Count → Keep count > 1                                    |
| Find Duplicate Rows     | Partition → Number rows → Keep row number > 1                     |

## Interview Tip

When the interviewer asks a SQL question, don't jump into writing code immediately. Spend a few seconds explaining your thought process, for example:

1. **Understand the requirement** – What exactly is being asked?
2. **Break it into smaller problems** – What information do I need first?
3. **Choose the right SQL concept** – Aggregate function, subquery, join, window function, grouping, etc.
4. **Build the query step by step** – Solve each small problem and combine them.
5. **Consider edge cases** – Duplicate values, `NULL`s, empty tables, or ties in ranking.

Interviewers often value this structured thinking as much as the final SQL query.
