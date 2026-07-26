# Oracle Views Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet
- View: virtual table defined by a query; no data storage of its own.
- Use views for abstraction, security, and query simplification.
- Updatable views are usually simple single-table views.
- `WITH CHECK OPTION` enforces the view predicate on DML.
- Materialized views store query results physically and need a refresh strategy.

<!-- QUICK_SHEET_END -->

## Table of Contents
- [Views](#views)
- [Materialized Views (M-Views)](#materialized-views-m-views)
- [Why We Need Views?](#why-we-need-views)
- [Table vs View](#table-vs-view)
- [Types of Views](#types-of-views)
- [Updating Views with Joins](#updating-views-with-joins)
- [DML Operations on Views](#dml-operations-on-views)
- [Read-Only View](#read-only-view)
- [Check Option](#check-option)
- [Important Points About Views](#important-points-about-views)

## Views

### Definition of View

A **view** is a virtual table created using a SQL query that doesn't store data itself. It stores a SQL statement and shows the result of that query when accessed.

### Syntax of View

```sql
CREATE OR REPLACE VIEW view_name AS
SELECT column1, column2 FROM table_name;
```

### Example of View

```sql
CREATE OR REPLACE VIEW emp_view AS
SELECT employee_id, first_name, last_name, department_id, email 
FROM employees
WHERE department_id = 10;
```

### Access the View

```sql
SELECT * FROM emp_view;
```

### Drop the View

```sql
DROP VIEW emp_view;
```

### Update the View

```sql
CREATE OR REPLACE VIEW emp_view AS
SELECT employee_id, first_name, last_name, department_id, salary 
FROM employees;
```

---

## Why We Need Views?

1. **Security**: Views can restrict access to specific columns or rows in a table, providing a layer of security for sensitive data.

2. **Simplification**: Views can simplify complex queries by encapsulating them in a single view, making it easier for users to retrieve data without needing to understand the underlying complexity.

3. **Data Abstraction**: Views provide a level of abstraction, allowing users to interact with data in a more meaningful way without needing to know the details of the underlying tables.

4. **Reusability**: Views can be reused in multiple queries, reducing the need to write the same complex SQL statements repeatedly.

---

## Table vs View

| Aspect | Table | View |
|--------|-------|------|
| **Storage** | Stores data | Stores SQL query |
| **Space** | Occupies space | Doesn't occupy space |
| **Retrieval** | Faster retrieval | Slower retrieval |

---

## Types of Views

### 1. Simple View

A simple view is based on a single table and does not contain any aggregate functions or joins. It can be used to retrieve specific columns or rows from the underlying table.

### 2. Complex View

A complex view is based on multiple tables and can include:
- Aggregate functions
- Joins
- Set operators
- DISTINCT

It can be used to combine data from multiple sources and present it in a unified manner.

---

## Updating Views with Joins

Oracle allows updates only on the **key-preserved tables** in the join. A key-preserved table is a table that has a primary key or unique constraint defined on it, and the join condition preserves the uniqueness of the rows in that table.

### Example:
If the `employees` table has a primary key on `employee_id` and the `departments` table has a primary key on `department_id`, you can update the `employees` table through a view that joins these tables because it is a key-preserved table in the join.

---

## DML Operations on Views

### Can We Do DML on Views?

We can perform DML operations (INSERT, UPDATE, DELETE) on a view **only if the view is updatable**.

An **updatable view** is one that:
- Is based on a single table
- Does not contain aggregate functions
- Does not contain joins
- Does not contain GROUP BY clauses

If the view is not updatable, we cannot perform DML operations directly on it.

### How to Do DML Operations on Simple View

```sql
SELECT * FROM emp_view;

INSERT INTO emp_view (EMPLOYEE_ID, FIRST_NAME, LAST_NAME, DEPARTMENT_ID, EMAIL) 
VALUES (201, 'Sowparnika', 'S', 20, 'sow@gmail.com');

UPDATE emp_view 
SET first_name = 'SowparnikaA' 
WHERE employee_id = 101;

SELECT * FROM employees WHERE employee_id = 200;
```

---

## Read-Only View

A **read-only view** is a view that does not allow any DML operations (INSERT, UPDATE, DELETE) to be performed on it. It is used to provide a read-only representation of the underlying data.

### Example of Read-Only View

```sql
CREATE OR REPLACE VIEW emp_read_only_view AS
SELECT employee_id, first_name, last_name, department_id 
FROM employees
WHERE department_id = 20 
WITH READ ONLY;
```

---

## Check Option

### Definition

The **CHECK OPTION** is a constraint that can be applied to a view to enforce that any DML operations (INSERT, UPDATE) performed through the view must satisfy the conditions defined in the view's SELECT statement. If a user attempts to insert or update a row that does not meet the view's criteria, the operation will be rejected.

**Note**: You can insert a row through the view, but you cannot see the same row when you access the view.

### Example

```sql
CREATE OR REPLACE VIEW emp_check_view AS
SELECT employee_id, first_name, last_name, department_id 
FROM employees
WHERE department_id = 30 
WITH CHECK OPTION;

SELECT * FROM emp_check_view;
```

---

## Read-Only vs Check Option

| Aspect | Read-Only | Check Option |
|--------|-----------|--------------|
| **DML Allowed** | NO | YES |
| **Type** | Complete restriction | Conditional restriction |

---

## Important Points About Views

1. If the base table is dropped, the view becomes **invalid**
2. Another view can be created on top of an existing view
3. No constraint can be applied on a view (except CHECK OPTION)
4. Even if the base table is dropped, using **FORCE** you can still create an invalid view (but it will remain invalid until the base table is recreated)
5. If the base table is altered, the view may become invalid if it references columns that no longer exist or have changed data types
6. DML operations can be performed on complex views using **INSTEAD OF triggers**

### Query View Information

```sql
SELECT * FROM user_views;
SELECT * FROM user_tables;
```

---

---

# Materialized Views (M-Views)

## Definition

A **materialized view** is a database object that stores the results of a query as a physical table.

Unlike regular views (which are virtual and do not store data), materialized views store the data returned by the query in a separate table. This allows for faster access to the data.

---

## Why We Need Materialized Views?

1. **Improve Performance**: Precompute and store results of complex queries in a physical table
2. **Reduce CPU Usage**: Minimize computational overhead
3. **Reduce Repeated Calculation**: Avoid recalculating the same results

---

## Disadvantages of Materialized Views

1. **Storage Space**: Required to store the materialized view data
2. **Data Staleness**: Data can be older than the base tables
3. **Maintenance Overhead**: Required to keep the materialized view up-to-date with the underlying data

---

## Real-Time Use Cases

- **Reporting and Analytics**
- **Data Warehousing**
- **Performance Optimization**
- **Monthly or Quarterly Summaries**

---

## When Do We Need a Materialized View?

**RULE-1**: If the query is slow and repeatedly performs expensive work

**RULE-2**: If the data is mostly for reporting purpose

**RULE-3**: If the data can be slightly old

---

## View vs Materialized View

| Aspect | View | Materialized View |
|--------|------|-------------------|
| **Storage** | Stores query | Stores data |
| **Space Needed** | No storage needed | Needs storage |
| **Data Freshness** | Always latest | Needs refresh |
| **Speed** | Usually slower | Usually faster |

---

## Syntax

```sql
CREATE MATERIALIZED VIEW mv_emp AS
SELECT department_id, 
       SUM(salary) total_sal
FROM employees
GROUP BY department_id;
```

---

## Refreshing Materialized Views

There are four refresh methods:

### 1. Complete Refresh

Refreshes the entire materialized view by re-executing the underlying query and replacing the existing data with the new results.

This method is typically used when the underlying data has changed significantly or when a fast refresh is not possible.

```sql
UPDATE employees SET salary = 5000 WHERE employee_id = 200;
COMMIT;

SELECT * FROM employees WHERE employee_id = 200;
SELECT * FROM mv_emp;

EXEC DBMS_MVIEW.REFRESH('MV_EMP', method => 'C');
```

### 2. Fast Refresh

Updates only the changes made to the underlying data since the last refresh, rather than re-executing the entire query.

This method is more efficient than a complete refresh, as it reduces the amount of data that needs to be processed. Fast refresh requires that the materialized view be created with certain options, such as the use of materialized view logs on the underlying tables.

#### Example for Fast Refresh

```sql
CREATE MATERIALIZED VIEW LOG ON employees 
WITH ROWID, PRIMARY KEY, SEQUENCE
ENABLE QUERY REWRITE AS 
SELECT * FROM employees;
```

**How it works**: The materialized view log is a special table that records changes made to the underlying table. When a materialized view is created with fast refresh enabled, it relies on the materialized view log to determine which rows have changed since the last refresh.

```sql
EXEC DBMS_MVIEW.REFRESH('MV_EMP', method => 'F');
```

### 3. Force Refresh

Attempts to perform a fast refresh if possible; if not, it falls back to a complete refresh.

```sql
EXEC DBMS_MVIEW.REFRESH('MV_EMP', method => 'F');
```

### 4. Never Refresh

Indicates that the materialized view should not be refreshed automatically.

---

## Refresh Modes - When to Refresh

### 1. On-Demand Refresh

The materialized view is refreshed only when explicitly requested by the user or application. This can be done using the `DBMS_MVIEW.REFRESH` procedure or by executing a manual refresh command.

### 2. On-Commit Refresh

The materialized view is refreshed automatically whenever a transaction that modifies the underlying tables is committed. This ensures that the materialized view always reflects the most recent changes to the data, but it can introduce additional overhead and may impact performance for high-transaction environments.
