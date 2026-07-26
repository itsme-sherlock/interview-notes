# SQL Quick Revision

<!-- QUICK_SHEET_START -->

## Quick Sheet
- Single-row functions: UPPER, LOWER, SUBSTR, INSTR, NVL, COALESCE, TO_CHAR, TO_DATE.
- Views: virtual, no data storage; materialized views: physical storage + refresh.
- Indexes: B-tree for high cardinality, bitmap for low cardinality analytics.
- Window functions: ROW_NUMBER, RANK, DENSE_RANK, LAG, LEAD, SUM OVER.
- Partitioning: range/list/hash/composite; partition pruning is key optimization.

<!-- QUICK_SHEET_END -->

## Table of Contents
- [SQL Quick Revision](#sql-quick-revision)
  - [Quick Sheet](#quick-sheet)
  - [Table of Contents](#table-of-contents)
  - [Core Syntax](#core-syntax)
  - [High-Frequency Interview Questions](#high-frequency-interview-questions)
  - [Common Pitfalls](#common-pitfalls)
  - [Memory Cues](#memory-cues)

## Core Syntax
```sql
-- null handling
SELECT NVL(commission_pct, 0), COALESCE(col1, col2, 0) FROM dual;

-- view
CREATE OR REPLACE VIEW v_emp AS SELECT employee_id, salary FROM employees;

-- window function
SELECT employee_id,
       ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) rn
FROM employees;

-- index
CREATE INDEX idx_emp_dept ON employees(department_id);

-- partitioned table
CREATE TABLE sales_part (...) PARTITION BY RANGE (sale_date) (...);
```

## High-Frequency Interview Questions
- Why can a query still do full table scan even when an index exists?
- Difference between RANK and DENSE_RANK.
- View vs materialized view in performance-sensitive reporting.
- Why does partition pruning improve performance?

## Common Pitfalls
- Using functions on indexed columns without function-based index.
- Relying on `ROWNUM` after `ORDER BY` without subquery pattern.
- Ignoring refresh strategy for materialized views.

## Memory Cues
- "Index finds, ROWID fetches."
- "Window functions analyze, GROUP BY aggregates."
- "Partitioning reduces scan scope."
