# PL/SQL Pipelined Table Functions Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Table function** = A function whose result can be queried like a table.
- **Pipelined function** = Returns rows incrementally instead of building the full result first.
- **`PIPE ROW`** = Sends one result row to the SQL consumer.
- **`RETURN`** = Ends the function; a pipelined function returns control without a normal collection value.
- **Parallel execution** = Pipelined functions can support parallel row production when designed for it.
- **Best use:** Stream procedural results into SQL when ordinary set-based SQL cannot express the transformation.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Pipelined Functions?](#1-why-do-we-need-pipelined-functions)
2. [What Is a Pipelined Table Function?](#2-what-is-a-pipelined-table-function)
3. [Schema Types and PIPE ROW](#3-schema-types-and-pipe-row)
4. [Querying the Function](#4-querying-the-function)
5. [Performance and Parallelism](#5-performance-and-parallelism)
6. [Comparison Matrix](#6-comparison-matrix)
7. [Best Practices](#7-best-practices)
8. [Common Mistakes](#8-common-mistakes)
9. [Interview Q&A](#9-interview-qa)
10. [Revision Summary](#10-revision-summary)

---

## 1. Why Do We Need Pipelined Functions?

Some transformations require procedural logic but must still be consumed by SQL. Returning a huge collection first can increase memory use and delay the first result.

---

## 2. What Is a Pipelined Table Function?

A pipelined table function produces rows one at a time so SQL can consume them as they become available.

It is like a conveyor belt: rows move to the caller continuously instead of waiting for the entire result set to be assembled.

---

## 3. Schema Types and PIPE ROW

The output collection and row type normally need to be created at schema level.

```sql
CREATE OR REPLACE TYPE number_row AS OBJECT (n NUMBER);
/
CREATE OR REPLACE TYPE number_rows AS TABLE OF number_row;
/

CREATE OR REPLACE FUNCTION doubled_numbers(p_limit NUMBER)
  RETURN number_rows PIPELINED
AS
BEGIN
  FOR i IN 1 .. p_limit LOOP
    PIPE ROW(number_row(i * 2));
  END LOOP;
  RETURN;
END;
/
```

---

## 4. Querying the Function

Use the `TABLE` operator:

```sql
SELECT n
FROM TABLE(doubled_numbers(5));
```

Pipelined functions can accept collections or scalar parameters and can be used as an integration point between procedural code and SQL.

---

## 5. Performance and Parallelism

Pipelining can lower peak memory and improve time to first row. It does not automatically make a slow transformation fast. Measure CPU, I/O, context switching, and downstream demand. Parallel pipelined functions require partitioning and safe, independent processing.

---

## 6. Comparison Matrix

| Approach | Memory behavior | SQL composability | Best use |
| --- | --- | --- | --- |
| Normal collection function | Builds result first | Yes | Small/medium result |
| Pipelined function | Streams rows | Yes | Large procedural result |
| Cursor | Streams to procedural caller | Limited in SQL | Client or PL/SQL fetch |
| Set-based SQL | Optimizer-managed | Highest | Relational transformation |

---

## 7. Best Practices

1. Prefer set-based SQL when it expresses the rule.
2. Keep row types stable and documented.
3. Avoid hidden side effects in a query-facing function.
4. Bound input and handle exceptions clearly.
5. Benchmark memory and first-row latency.

---

## 8. Common Mistakes

- Forgetting the schema-level object and collection types.
- Calling the function without `TABLE(...)` in SQL.
- Assuming pipelining eliminates all context-switch overhead.
- Performing DML or commits unexpectedly while producing rows.
- Ignoring parallel-safety requirements.

---

## 9. Interview Q&A

**Q: What does `PIPE ROW` do?**

A: It sends one output row from the pipelined function to the SQL consumer.

**Q: Why use a pipelined function instead of returning a collection?**

A: It can reduce peak memory and let the caller receive rows before all processing completes.

**Q: Can pipelined functions replace set-based SQL?**

A: No. They are useful when procedural transformation is necessary; ordinary SQL is usually easier for relational work.

---

## 10. Revision Summary

- **Pipelined function** -> streams rows
- **`PIPE ROW`** -> emits one row
- **`TABLE(...)`** -> queries the result
- **Schema collection type** -> SQL-visible output type
- **Parallel pipelining** -> partitioned independent production

```sql
SELECT * FROM TABLE(doubled_numbers(10));
```
