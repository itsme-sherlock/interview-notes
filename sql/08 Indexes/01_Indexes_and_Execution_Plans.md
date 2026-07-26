# Oracle Indexes and Execution Plans

<!-- QUICK_SHEET_START -->

## Quick Sheet
- Index stores key values with ROWID references.
- B-tree: default, best for high-cardinality columns.
- Bitmap: best for low-cardinality analytic workloads.
- Composite index depends on leading-column usage.
- Optimizer may still choose full table scan based on cost.

<!-- QUICK_SHEET_END -->

## Table of Contents
- [Main Content](#main-content)
- [Why Indexes Improve Reads](#why-indexes-improve-reads)
- [Index Types](#index-types)
- [Index Scan Methods](#index-scan-methods)
- [When Oracle Avoids Indexes](#when-oracle-avoids-indexes)
- [Execution Plan Basics](#execution-plan-basics)
- [Interview Insights](#interview-insights)
- [Related Notes](#related-notes)

## Main Content

## Why Indexes Improve Reads
Without index, Oracle may scan many table blocks.
With index, Oracle finds key -> ROWID -> row.

```sql
CREATE INDEX idx_emp_id ON employees(employee_id);
SELECT * FROM employees WHERE employee_id = 104;
```

## Index Types
### B-tree
- Default index type.
- Good for high-cardinality values like IDs and emails.

### Unique Index
```sql
CREATE UNIQUE INDEX idx_emp_email ON employees(email);
```

### Composite Index
```sql
CREATE INDEX idx_emp_name ON employees(first_name, last_name);
```
Leading-column rule: filter on `first_name` (or both columns) to benefit most.

### Function-Based Index
```sql
CREATE INDEX idx_emp_upper_last_name ON employees(UPPER(last_name));
```

### Bitmap Index
Use in read-heavy analytics with low-cardinality columns.
Avoid in high-concurrency OLTP updates.

## Index Scan Methods
- Index Unique Scan
- Index Range Scan
- Index Full Scan
- Index Fast Full Scan

## When Oracle Avoids Indexes
- Low selectivity predicate.
- Very small table.
- Function applied without matching function-based index.
- Leading column missing in composite-index access.
- Predicate like `LIKE '%abc'`.

## Execution Plan Basics
`EXPLAIN PLAN` shows estimated path, not actual runtime statistics.

```sql
EXPLAIN PLAN FOR
SELECT * FROM employees WHERE employee_id = 104;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
```

## Interview Insights
- Index is not always faster; optimizer chooses lowest estimated cost.
- Bitmap index still resolves to ROWIDs for final row fetch.
- Use plan output to validate assumptions before tuning.

## Related Notes
- Query rewrite and abstraction: [Views and Materialized Views](../07%20Views/01_Views_and_Materialized_Views.md)
- Large-table strategy: [Table Partitioning](../09%20Performance/02_Table_Partitioning.md)
