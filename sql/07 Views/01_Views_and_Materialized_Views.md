# Oracle Views and Materialized Views

<!-- QUICK_SHEET_START -->

## Quick Sheet
- View: virtual table storing query text.
- Materialized view: physical data snapshot with refresh strategy.
- Simple view is usually updatable; complex view often needs `INSTEAD OF` trigger.
- `WITH CHECK OPTION`: enforce view filter for DML through the view.
- `WITH READ ONLY`: block DML through the view.

<!-- QUICK_SHEET_END -->

## Table of Contents
- [Main Content](#main-content)
- [Views](#views)
- [DML Rules for Views](#dml-rules-for-views)
- [Check Option and Read Only](#check-option-and-read-only)
- [Materialized Views](#materialized-views)
- [Refresh Methods](#refresh-methods)
- [Interview Insights](#interview-insights)
- [Related Notes](#related-notes)

## Main Content

## Views
```sql
CREATE OR REPLACE VIEW v_emp_dept10 AS
SELECT employee_id, first_name, department_id, salary
FROM employees
WHERE department_id = 10;
```

## DML Rules for Views
A view is typically updatable when it is:
- Based on one table.
- Free of aggregate functions.
- Free of `GROUP BY`, set operators, and complex joins.

For complex joins, use `INSTEAD OF` triggers when DML is needed.

## Check Option and Read Only
```sql
CREATE OR REPLACE VIEW v_emp_check AS
SELECT employee_id, first_name, department_id
FROM employees
WHERE department_id = 30
WITH CHECK OPTION;

CREATE OR REPLACE VIEW v_emp_ro AS
SELECT employee_id, first_name, department_id
FROM employees
WITH READ ONLY;
```

## Materialized Views
Materialized views store query results physically for faster reporting.

```sql
CREATE MATERIALIZED VIEW mv_dept_salary
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
SELECT department_id, SUM(salary) total_salary
FROM employees
GROUP BY department_id;
```

## Refresh Methods
- Complete (`C`): rebuild full result.
- Fast (`F`): apply changes incrementally (requires MV logs and eligibility).
- Force (`?` in API behavior): try fast, else complete.

```sql
EXEC DBMS_MVIEW.REFRESH('MV_DEPT_SALARY', method => 'C');
```

## Interview Insights
- View improves abstraction and security, not guaranteed speed.
- Materialized view trades freshness for performance.
- Use explicit refresh strategy based on reporting SLA.

## Related Notes
- Optimizer and access paths: [Indexes and Execution Plans](../08%20Indexes/01_Indexes_and_Execution_Plans.md)
- Analytic reporting patterns: [Window Functions and Analytics](../09%20Performance/01_Window_Functions_and_Analytics.md)
