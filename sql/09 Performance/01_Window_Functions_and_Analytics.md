# Window Functions in Oracle SQL

<!-- QUICK_SHEET_START -->

## Quick Sheet
- Window functions compute across related rows while keeping row detail.
- `OVER` defines the partition and ordering scope.
- Key ranking functions: `ROW_NUMBER`, `RANK`, `DENSE_RANK`.
- `LAG` and `LEAD` compare previous and next rows.
- Running totals are built with `SUM(...) OVER (...)`.

<!-- QUICK_SHEET_END -->

## Table of Contents
- [What Is a Window Function?](#what-is-a-window-function)
- [What Does the OVER Clause Do?](#what-does-the-over-clause-do)
- [ROW_NUMBER()](#row_number)
- [RANK()](#rank)
- [DENSE_RANK()](#dense_rank)
- [LEAD() and LAG()](#lead-and-lag)
- [SUM() as a Window Function](#sum-as-a-window-function)
- [LISTAGG()](#listagg)
- [PIVOT](#pivot)
- [UNPIVOT](#unpivot)

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






