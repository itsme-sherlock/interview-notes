# PL/SQL DBMS_SQL and Metadata-Driven SQL Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **`DBMS_SQL`** = Low-level API for parsing, binding, executing, and fetching dynamic SQL.
- **Metadata-driven SQL** = Code adapts to unknown columns or result shapes at runtime.
- **Parse** = Prepare dynamic SQL text.
- **Bind** = Supply values separately from SQL text.
- **Define and fetch** = Describe result columns and read rows dynamically.
- **Design rule:** Use `EXECUTE IMMEDIATE` unless runtime metadata genuinely requires `DBMS_SQL`.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need DBMS_SQL?](#1-why-do-we-need-dbms_sql)
2. [What Is DBMS_SQL?](#2-what-is-dbms_sql)
3. [Parse, Bind, and Execute](#3-parse-bind-and-execute)
4. [Metadata and Fetching](#4-metadata-and-fetching)
5. [Security and API Choice](#5-security-and-api-choice)
6. [Comparison Matrix](#6-comparison-matrix)
7. [Best Practices](#7-best-practices)
8. [Common Mistakes](#8-common-mistakes)
9. [Interview Q&A](#9-interview-qa)
10. [Revision Summary](#10-revision-summary)

---

## 1. Why Do We Need DBMS_SQL?

Generic utilities may not know the number, names, or data types of selected columns until runtime. A fixed `EXECUTE IMMEDIATE ... INTO` list cannot handle every result shape.

---

## 2. What Is DBMS_SQL?

`DBMS_SQL` exposes dynamic SQL as a sequence of operations: open a cursor, parse text, bind values, define output columns, execute, and fetch.

It provides more control than `EXECUTE IMMEDIATE` but requires more code and careful cleanup.

---

## 3. Parse, Bind, and Execute

```sql
DECLARE
  v_cursor INTEGER := DBMS_SQL.OPEN_CURSOR;
  v_sql    VARCHAR2(4000) :=
    'UPDATE employees SET salary = :salary WHERE employee_id = :id';
  v_rows   INTEGER;
BEGIN
  DBMS_SQL.PARSE(v_cursor, v_sql, DBMS_SQL.NATIVE);
  DBMS_SQL.BIND_VARIABLE(v_cursor, ':salary', 75000);
  DBMS_SQL.BIND_VARIABLE(v_cursor, ':id', 100);
  v_rows := DBMS_SQL.EXECUTE(v_cursor);
  DBMS_SQL.CLOSE_CURSOR(v_cursor);
EXCEPTION
  WHEN OTHERS THEN
    IF DBMS_SQL.IS_OPEN(v_cursor) THEN
      DBMS_SQL.CLOSE_CURSOR(v_cursor);
    END IF;
    RAISE;
END;
/
```

---

## 4. Metadata and Fetching

For queries, use `DBMS_SQL.DESCRIBE_COLUMNS` to discover column metadata, call `DEFINE_COLUMN`, execute, and fetch rows. Convert the cursor to a `SYS_REFCURSOR` with `DBMS_SQL.TO_REFCURSOR` when a higher-level caller needs it.

Dynamic metadata utilities should limit object access and output size because generic SQL can expose more data than intended.

---

## 5. Security and API Choice

Bind values, allow-list identifiers, validate object names, and use least privilege. Prefer static SQL for known structures and `EXECUTE IMMEDIATE` for simple dynamic statements. Choose `DBMS_SQL` only when metadata or cursor control requires it.

---

## 6. Comparison Matrix

| Aspect | Static SQL | `EXECUTE IMMEDIATE` | `DBMS_SQL` |
| --- | --- | --- | --- |
| Code size | Small | Small/medium | Large |
| Compile checking | Strong | Limited | Limited |
| Unknown result shape | Poor | Limited | Strong |
| Metadata access | Normal SQL metadata | Limited | Detailed |
| Cleanup burden | Low | Medium | High |

---

## 7. Best Practices

1. Use the simplest API that meets the requirement.
2. Bind values and validate identifiers.
3. Close cursors in success and exception paths.
4. Limit metadata and result exposure.
5. Test nulls, long values, conversion errors, and empty results.

---

## 8. Common Mistakes

- Building SQL with untrusted values.
- Forgetting to close a `DBMS_SQL` cursor.
- Calling `DEFINE_COLUMN` with the wrong datatype or length.
- Treating `DBMS_SQL.EXECUTE` as if it returns a query result set.
- Using `DBMS_SQL` when `EXECUTE IMMEDIATE` is clearer.

---

## 9. Interview Q&A

**Q: Why use `DBMS_SQL` instead of `EXECUTE IMMEDIATE`?**

A: Use it when column metadata or result shape is unknown at compile time and parse/define/fetch control is required.

**Q: What are the core DBMS_SQL phases?**

A: Open, parse, bind, define output columns, execute, fetch, and close.

**Q: How do you secure metadata-driven SQL?**

A: Bind values, allow-list identifiers, restrict privileges, limit exposed objects, and close cursors reliably.

---

## 10. Revision Summary

- **Open** -> allocate dynamic cursor
- **Parse** -> prepare SQL text
- **Bind** -> supply values safely
- **Describe/define** -> discover and prepare output
- **Fetch** -> read dynamic rows
- **Close** -> release cursor resources

```sql
v_cursor := DBMS_SQL.OPEN_CURSOR;
DBMS_SQL.PARSE(v_cursor, v_sql, DBMS_SQL.NATIVE);
```
