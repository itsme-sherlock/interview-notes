# Oracle Window Functions and Analytics

<!-- QUICK_SHEET_START -->

## Quick Sheet
- Window function computes across related rows while preserving row detail.
- `OVER` defines partition and ordering scope.
- Ranking: `ROW_NUMBER`, `RANK`, `DENSE_RANK`.
- Relative row access: `LAG`, `LEAD`.
- Running totals: `SUM(...) OVER (...)`.

<!-- QUICK_SHEET_END -->

## Table of Contents
- [Main Content](#main-content)
- [OVER Clause Basics](#over-clause-basics)
- [Ranking Functions](#ranking-functions)
- [LAG and LEAD](#lag-and-lead)
- [Running Totals](#running-totals)
- [Interview Insights](#interview-insights)
- [Related Notes](#related-notes)

## Main Content

## OVER Clause Basics
`OVER` controls where and how the analytic function runs.

```sql
SELECT employee_id,
       department_id,
       salary,
       AVG(salary) OVER (PARTITION BY department_id) AS dept_avg_salary
FROM hr.employees;
```

## Ranking Functions
```sql
SELECT employee_id,
       department_id,
       salary,
       ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rn,
       RANK()       OVER (PARTITION BY department_id ORDER BY salary DESC) AS rnk,
       DENSE_RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS drnk
FROM hr.employees;
```

## LAG and LEAD
```sql
SELECT employee_id,
       department_id,
       salary,
       LAG(salary)  OVER (PARTITION BY department_id ORDER BY salary) AS prev_salary,
       LEAD(salary) OVER (PARTITION BY department_id ORDER BY salary) AS next_salary
FROM hr.employees;
```

## Running Totals
```sql
SELECT employee_id,
       department_id,
       salary,
       SUM(salary) OVER (
         PARTITION BY department_id
         ORDER BY salary
         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS running_salary
FROM hr.employees;
```

## Interview Insights
- `ROW_NUMBER` never ties, `RANK` skips numbers after ties, `DENSE_RANK` does not.
- Analytic functions do not reduce row count like `GROUP BY`.
- Window functions are common in top-N, trend, and comparative reporting.

## Related Notes
- Physical design context: [Indexes and Execution Plans](../08%20Indexes/01_Indexes_and_Execution_Plans.md)
- Large-table strategy: [Table Partitioning](02_Table_Partitioning.md)
