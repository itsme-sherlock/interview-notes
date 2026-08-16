# PL/SQL Dynamic SQL Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Dynamic SQL** = SQL text built or selected at runtime.
- **`EXECUTE IMMEDIATE`** = Main interface for dynamic SQL and DDL.
- **Bind variables** = Runtime values supplied separately from SQL text.
- **`DBMS_SQL`** = Lower-level API for highly dynamic statements and metadata.
- **Security rule:** Never concatenate untrusted values into SQL text.
- **Trade-off:** Flexibility increases parsing, testing, and injection risk.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Dynamic SQL?](#1-why-do-we-need-dynamic-sql)
2. [What Is Dynamic SQL?](#2-what-is-dynamic-sql)
3. [EXECUTE IMMEDIATE](#3-execute-immediate)
4. [Binds and Dynamic Queries](#4-binds-and-dynamic-queries)
5. [DBMS_SQL and Security](#5-dbms_sql-and-security)
6. [Comparison Matrix](#6-comparison-matrix)
7. [Best Practices](#7-best-practices)
8. [Common Mistakes](#8-common-mistakes)
9. [Interview Q&A](#9-interview-qa)
10. [Revision Summary](#10-revision-summary)

---

## 1. Why Do We Need Dynamic SQL?

Static SQL requires object names and statement structure to be known at compile time. Administrative tools and configurable applications may need a table or column selected at runtime.

---

## 2. What Is Dynamic SQL?

Dynamic SQL is a statement whose text or object identifiers are determined while the program runs. Values should still be passed as binds.

Use it for dynamic DDL, optional predicates, configurable table names, and generic utilities. Do not use it merely because static SQL feels inconvenient.

---

## 3. EXECUTE IMMEDIATE

```sql
DECLARE
  v_table_name VARCHAR2(128) := 'EMPLOYEES';
  v_sql VARCHAR2(4000);
BEGIN
  v_sql := 'DELETE FROM ' || DBMS_ASSERT.SQL_OBJECT_NAME(v_table_name)
        || ' WHERE department_id = :dept';
  EXECUTE IMMEDIATE v_sql USING 10;
END;
/
```

Dynamic DDL has no `USING` value for object names. `EXECUTE IMMEDIATE` can also return values:

```sql
EXECUTE IMMEDIATE
  'SELECT COUNT(*) FROM employees WHERE department_id = :1'
  INTO v_count USING p_department_id;
```

---

## 4. Binds and Dynamic Queries

Bind values, not identifiers:

```sql
-- Good: value is bound
v_sql := 'SELECT COUNT(*) FROM employees WHERE department_id = :1';
EXECUTE IMMEDIATE v_sql INTO v_count USING p_department_id;
```

Table names, column names, and sort directions cannot normally be bind variables. Validate them against an allow-list or use `DBMS_ASSERT` where appropriate.

For dynamic result shapes, return a `SYS_REFCURSOR` or use `DBMS_SQL`.

---

## 5. DBMS_SQL and Security

`DBMS_SQL` supports parse, bind, define, execute, and fetch steps and is useful when the number or types of columns are unknown at compile time.

Security controls:

- Allow-list object names and column names.
- Bind all user-supplied values.
- Use the least-privileged execution context.
- Log the operation without exposing secrets.
- Test malformed identifiers and unexpected input.

---

## 6. Comparison Matrix

| Aspect | Static SQL | `EXECUTE IMMEDIATE` | `DBMS_SQL` |
| --- | --- | --- | --- |
| Compile-time checking | Strong | Limited | Limited |
| Flexibility | Low | Medium/high | Highest |
| Ease of use | Easiest | Simple | Complex |
| Dynamic result shape | Limited | Limited | Strong |
| Injection risk | Low | Must manage | Must manage |

---

## 7. Best Practices

1. Prefer static SQL whenever the structure is known.
2. Bind every runtime value.
3. Allow-list identifiers and use `DBMS_ASSERT` as a defense-in-depth check.
4. Keep dynamic statements small and log normalized text.
5. Test privilege and injection boundaries.

---

## 8. Common Mistakes

- Concatenating a username or filter value into SQL text.
- Trying to bind a table name with `:table_name`.
- Forgetting `INTO` for a dynamic single-row query.
- Assuming dynamic DDL can be rolled back like ordinary DML.
- Using `DBMS_SQL` when `EXECUTE IMMEDIATE` is sufficient.

---

## 9. Interview Q&A

**Q: Why use dynamic SQL?**

A: When statement structure or object identifiers are not known until runtime, such as generic administration utilities.

**Q: Can a bind variable represent a table name?**

A: No. Bind variables represent values, not SQL identifiers. Validate identifiers separately.

**Q: When would you choose `DBMS_SQL`?**

A: When column count, metadata, or result types are not known at compile time and the lower-level API is necessary.

**Q: How do you prevent injection?**

A: Bind values, allow-list identifiers, validate input, restrict privileges, and avoid concatenating untrusted text.

---

## 10. Revision Summary

- **Dynamic SQL** -> runtime statement structure
- **`EXECUTE IMMEDIATE`** -> simple dynamic SQL API
- **Bind variable** -> safe runtime value
- **`DBMS_ASSERT`** -> identifier validation aid
- **`DBMS_SQL`** -> metadata-driven dynamic SQL

```sql
EXECUTE IMMEDIATE
  'UPDATE employees SET salary = :1 WHERE employee_id = :2'
  USING p_salary, p_employee_id;
```
