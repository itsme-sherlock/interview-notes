# INDEX (oracle sql)

<!-- QUICK_SHEET_START -->

## Quick Sheet
- Index speeds up reads by storing key value + ROWID.
- B-tree is the default and suits high-cardinality columns.
- Bitmap is better for low-cardinality analytics, not high-concurrency OLTP.
- Composite indexes depend on the leading-column rule.
- Execution plan and optimizer choice determine whether an index is used.

<!-- QUICK_SHEET_END -->

## Table of Contents
- [What happens without an Index?](#what-happens-without-an-index)
- [What happens when we create an index?](#what-happens-when-we-create-an-index)
- [How to create an index?](#how-to-create-an-index)
- [Types of Indexes](#types-of-indexes)
- [Index scan methods - How Oracle uses an index to retrieve data?](#index-scan-methods---how-oracle-uses-an-index-to-retrieve-data)
- [When Oracle uses an index?](#when-oracle-uses-an-index)
- [when oracle avoids an index?](#when-oracle-avoids-an-index)

## Main Content
- [INDEX (oracle sql)](#index-oracle-sql)
  - [Quick Sheet](#quick-sheet)
  - [Table of Contents](#table-of-contents)
  - [Main Content](#main-content)
- [INDEX (oracle sql)](#index-oracle-sql-1)
  - [What happens without an Index?](#what-happens-without-an-index)
  - [What happens when we create an index?](#what-happens-when-we-create-an-index)
    - [What happens when we execute?](#what-happens-when-we-execute)
      - [Step 1](#step-1)
      - [Step 2](#step-2)
      - [Step 3](#step-3)
      - [Step 4](#step-4)
    - [Why is it faster?](#why-is-it-faster)
    - [One important point to tell students](#one-important-point-to-tell-students)
  - [How to create an index?](#how-to-create-an-index)
  - [Types of Indexes](#types-of-indexes)
    - [B-tree Index](#b-tree-index)
      - [why is B-tree Index is default?](#why-is-b-tree-index-is-default)
    - [Unique Index](#unique-index)
    - [Composite Index](#composite-index)
      - [Leading Column rule](#leading-column-rule)
    - [Function-Based Index](#function-based-index)
    - [Bitmap Index](#bitmap-index)
      - [Example Table](#example-table)
    - [Bitmap for 'M'](#bitmap-for-m)
    - [Bitmap for 'F'](#bitmap-for-f)
    - [What happens when we execute?](#what-happens-when-we-execute-1)
      - [Step 1](#step-1-1)
      - [Step 2](#step-2-1)
      - [Step 3](#step-3-1)
      - [Step 4](#step-4-1)
    - [Why is Bitmap Index powerful?](#why-is-bitmap-index-powerful)
      - [B-tree vs Bitmap](#b-tree-vs-bitmap)
      - [Interview Question](#interview-question)
    - [Reverse Key Index](#reverse-key-index)
    - [Invisible Index](#invisible-index)
  - [Index scan methods - How Oracle uses an index to retrieve data?](#index-scan-methods---how-oracle-uses-an-index-to-retrieve-data)
  - [When Oracle uses an index?](#when-oracle-uses-an-index)
  - [when oracle avoids an index?](#when-oracle-avoids-an-index)
      - [An Execution Plan](#an-execution-plan)
      - [What is EXPLAIN PLAN?](#what-is-explain-plan)

# INDEX (oracle sql)
Index is a **database object** that improves the **speed of data retrieval** operations on a table at the cost of additional writes and storage space to maintain the index data structure. 

Indexes can be created using one or more columns of a database table, providing a quick way to look up data. 


## What happens without an Index?
Without an index, the database must perform a full table scan to find the required data. 

This means that it will check each row in the table one by one until it finds the matching rows.

This can be very slow, especially for large tables.

---

## What happens when we create an index?

When you create an index on a column, Oracle creates a **separate data structure** (called a B-tree index).

This structure stores only two important pieces of information:

* The indexed column value
* The ROWID of the corresponding row in the table

For example, if you create an index on `EMPLOYEE_ID`, the index conceptually looks like this:

| Employee_ID | ROWID  |
| ----------- | ------ |
| 101         | AAA432 |
| 102         | AAA901 |
| 103         | AAA876 |
| 104         | AAA654 |
| ...         | ...    |

> Think of this as a simplified view. Internally Oracle stores it as a B-tree, not as a normal table.

---

### What happens when we execute?

```sql
SELECT *
FROM employees
WHERE employee_id = 104;
```

#### Step 1

Oracle first looks into the **index**, not the table.

It searches for the value **104**.

#### Step 2

The index quickly returns the ROWID.

```
104  →  AAA654
```

#### Step 3

Using that ROWID, Oracle directly jumps to the exact row in the table.

```
ROWID AAA654
```

#### Step 4

Oracle fetches the complete employee record and returns it to the user.

---

### Why is it faster?

Without an index:

```
Table

Row 1
Row 2
Row 3
...
Row 9,999,999
Row 10,000,000
```

Oracle may need to examine every row until it finds Employee 104.

This is called a **Full Table Scan**.

---

With an index:

```
Search index
        ↓
Find ROWID
        ↓
Jump directly to that row
        ↓
Fetch the record
```

Instead of scanning millions of rows, Oracle performs a quick lookup in the index and then goes straight to the required row.

---

### One important point to tell students

A common misconception is:

> "Oracle searches for the ROWID again."

No.

The ROWID is **already stored inside the index**. Oracle does **not** search the table to find the ROWID. It simply reads the ROWID from the index and uses it like a house address to directly locate the row.

Think of it like this:

```
Employee ID (104)
        │
        ▼
      Index
        │
        ▼
ROWID = AAA654
        │
        ▼
Jump directly to the row in the table
        │
        ▼
Return the employee details
```

This is the fundamental idea behind why indexes make data retrieval much faster.

---

## How to create an index?

```sql
CREATE INDEX idx_employee_id
ON employees (employee_id);
```

## Types of Indexes

1. B-tree Index (default)
2. Unique Index
3. Composite Index
4. Function-Based Index
5. Bitmap Index
6. Reverse Key Index
7. Invisible Index
---

### B-tree Index
It is used for **high-cardinality data** (columns with many unique values). It is the *default index* type in Oracle.

**Cardinality** refers to the number of unique values in a column. For example, a column storing employee IDs will have high cardinality because each employee has a unique ID.

> Example of high-cardinality data: employee_id, email, social_security_number

> Example of low-cardinality data: gender, marital_status, country

#### why is B-tree Index is default?
B-tree indexes are efficient for a wide range of queries,

They provide fast access to data and are suitable for most use cases

---

### Unique Index
It is used to enforce **uniqueness** on a column or a set of columns. When you create a unique index, Oracle ensures that no two rows can have the same value(s) in the indexed column(s).

Unique Index is ideally B-tree index but with a uniqueness constraint or without duplicacy.

```sql
CREATE UNIQUE INDEX idx_email
ON employees (email);
```
> When you create a unique constraint on a column, Oracle automatically creates a unique index to enforce that constraint.
---
### Composite Index
A composite index is an index on **multiple columns**. 

It is useful when queries filter on more than one column. 

For example, if you frequently query a table using both `last_name` and `first_name`, you can create a composite index on those two columns.


The order of the columns in the index matters, as it affects how the index can be used by the optimizer.

```sql
CREATE INDEX idx_emp ON employees(first_name,last_name)
```

#### Leading Column rule
It means that the first column in the index is the most important for the optimizer. If a query filters on the leading column, the index can be used effectively. If it filters only on the second column, the index may not be used.

for example, if you have a composite index on `(first_name, last_name)`, a query filtering on `first_name` can use the index, also the query filtering with both `first_name` and `last_name` can use the index.
But if you have a query filtering only on `last_name` may not.

```sql
SELECT * FROM employees WHERE first_name = 'John'; -- can use the index
SELECT * FROM employees WHERE first_name = 'John' AND last_name = 'Doe'; -- can use the index
SELECT * FROM employees WHERE last_name = 'Doe' and first_name = 'John'; -- can use the index
SELECT * FROM employees WHERE last_name = 'Doe'; -- may not use the index
```

---

### Function-Based Index
It is an index based on a function or expression rather than just a column.

For example, if you frequently query a table using the upper case of a column, you can create a function-based index on that expression.

```sql
CREATE INDEX idx_upper_last_name
ON employees (UPPER(last_name));
```

---
### Bitmap Index
Index that uses a bitmap for each key value instead of a list of ROWIDs. It is efficient for **low-cardinality data** (columns with few unique values).

Your explanation is heading in the right direction, but there are a couple of inaccuracies:

1. **Oracle does not store one bitmap column called `bitmap`.**
2. **Bitmap indexes still ultimately use ROWIDs to fetch table rows.** The bitmap is only used to identify *which rows qualify*. Oracle then converts those bits into ROWIDs before reading the table.
3. The biggest advantage of bitmap indexes is that Oracle can combine multiple bitmaps (`AND`, `OR`, `NOT`) extremely quickly.

Examples:

* Gender (M/F)
* Marital Status
* Yes/No
* Department Type
* Country Code (if only a few countries)

---

#### Example Table

| Row | Gender |
| --- | ------ |
| 1   | M      |
| 2   | F      |
| 3   | M      |
| 4   | F      |
| 5   | M      |
| 6   | F      |

Oracle internally creates a bitmap for **each distinct value**.

### Bitmap for 'M'

| Row | 1 | 2 | 3 | 4 | 5 | 6 |
| --- | - | - | - | - | - | - |
| Bit | 1 | 0 | 1 | 0 | 1 | 0 |

```
M → 101010
```

---

### Bitmap for 'F'

| Row | 1 | 2 | 3 | 4 | 5 | 6 |
| --- | - | - | - | - | - | - |
| Bit | 0 | 1 | 0 | 1 | 0 | 1 |

```
F → 010101
```

Notice:

There is **one bitmap for M** and **another bitmap for F**.

---

### What happens when we execute?

```sql
SELECT *
FROM employees
WHERE gender = 'M';
```

#### Step 1

Oracle goes to the bitmap index.

#### Step 2

It finds the bitmap for **M**.

```
101010
```

#### Step 3

Every **1** means

> "This row contains M."

Every **0** means

> "Ignore this row."

```
Row 1 → Yes

Row 2 → No

Row 3 → Yes

Row 4 → No

Row 5 → Yes

Row 6 → No
```

#### Step 4

Oracle converts these matching positions into ROWIDs internally and fetches only those rows from the table.

---

### Why is Bitmap Index powerful?

Suppose you have another column:

| Row | Gender | Married |
| --- | ------ | ------- |
| 1   | M      | Y       |
| 2   | F      | N       |
| 3   | M      | Y       |
| 4   | F      | Y       |
| 5   | M      | N       |
| 6   | F      | N       |

Bitmap for Gender='M'

```
101010
```

Bitmap for Married='Y'

```
101100
```

Query:

```sql
WHERE Gender='M'
AND Married='Y'
```

Oracle simply performs a **bitwise AND**.

```
101010
AND
101100
------
101000
```

Only Rows **1 and 3** satisfy both conditions.

This bitwise operation is extremely fast, even for millions of rows.

---

#### B-tree vs Bitmap

| B-tree Index                          | Bitmap Index                                        |
| ------------------------------------- | --------------------------------------------------- |
| Stores **Value → ROWID**              | Stores **Value → Bitmap**                           |
| Good for high-cardinality columns     | Good for low-cardinality columns                    |
| Best for OLTP systems                 | Best for Data Warehouses (OLAP)                     |
| Finds one ROWID quickly               | Combines multiple conditions very efficiently       |

---

#### Interview Question

**Does a Bitmap Index avoid ROWIDs?**

**Answer:** No. A bitmap index uses bitmaps to identify matching rows, but Oracle still translates those matching bits into ROWIDs to retrieve the actual rows from the table. The bitmap helps Oracle determine *which* rows qualify; the ROWID is still used to fetch the row data. This is a common interview question because many people mistakenly think bitmap indexes never use ROWIDs.

### Reverse Key Index
A reverse key index is a type of B-tree index where the bytes(digits) of the indexed column values are reversed before being stored in the index. 

This can help distribute inserts more evenly across the index, reducing contention and improving performance for certain workloads.

use case: When you have a sequentially increasing value (like an auto-incrementing primary key) and you want to avoid hot spots in the index.

mostly when multiple sessions are inserting into the same index concurrently, a reverse key index can help reduce contention.

```sql
CREATE INDEX idx_reverse_emp_id
ON employees (REVERSE(employee_id)) REVERSE;
```

---

### Invisible Index
An invisible index is an index that exists in the database but is not used by the optimizer for query execution plans.

instead of dropping an index, you can make it invisible. This allows you to test the impact of removing the index without actually deleting it.

```sql
ALTER INDEX idx_employee_id INVISIBLE;
```
so after testing, if you want to make it visible again, you can do:

```sql
ALTER INDEX idx_employee_id VISIBLE;
```
## Index scan methods - How Oracle uses an index to retrieve data?
How Oracle internally finds the ROWID from the index and fetches the row from the table. 

1. **Index Unique Scan**: Used when the query is expected to return at most one row. For example, when querying by a primary key or unique index.

For example:
In the where condition, if you are searching for a unique value, Oracle will use an Index Unique Scan to quickly locate the row.
Oracle knows there is only one row that matches the condition, so it can stop searching after finding that row.
It gets the rowid from the index and fetches the row directly.

2. **Index Range Scan**: Used when the query is expected to return multiple rows. For example, when querying a range of values.

```sql
SELECT *
FROM employees
WHERE employee_id BETWEEN 100 AND 200;

SELECT First_Name from employees
WHERE First_Name LIKE 'S%';

```
reads only the required portion of the index that contains the range of values, rather than scanning the entire index or table.

3. **Index Full Scan**: Used when the query needs to read all rows in the index. This can happen when the query does not have a selective condition or when the optimizer determines that scanning the entire index is more efficient than using a range scan.

```sql
SELECT employee_id
FROM employees order by employee_id; 
```

4. **Index Fast Full Scan**: Similar to an index full scan, but it can read the index blocks in parallel and does not need to access the table at all if all required columns are in the index.

```sql
SELECT employee_id, first_name
FROM employees order by employee_id;
```


## When Oracle uses an index?
When you run a query, Oracle's optimizer decides whether to use an index or not based on several factors:
1. The **selectivity** of the index (how many rows it filters out).
2. The **size of the table** and the **number of rows**.
3. The **cost of using the index** versus doing a full table scan.

## when oracle avoids an index?
When the optimizer determines that using the index would be less efficient than a full table scan, it may choose to avoid the index. This can happen in cases where:
1. The index is **not selective** enough (e.g., it filters out too few rows).
2. The table is **small enough** that a full scan is faster than using the index.
3. The query involves **operations that are not supported by the index** (e.g., functions on indexed columns).
4. **Missing of Leading Column** rule in case of Composite Index.
5. Wildcard beginning with %
6. when the index is invisible or disabled.

> **What is Optimizer?** The Optimizer is a component of Oracle that decides the best way to execute a SQL query for the best performance.

#### An Execution Plan 
is the step-by-step instructions Oracle will follow to execute your SQL query.

For example, it may say:

> Use the EMPLOYEE_ID index.
nd the matching ROWID.Read the table row.
Return the result.

Think of it as Oracle's roadmap for executing the query.

#### What is EXPLAIN PLAN?

EXPLAIN PLAN is a command that shows you which execution plan the optimizer has chosen.

It doesn't execute the query. It only shows the plan Oracle intends to use.

Using EXPLAIN PLAN, you can see things like:

Will Oracle use an index?
Will it perform a full table scan?
Which table is read first?
Which join method is used?

This helps you understand and improve query performance. 