# PL/SQL Collections and Records Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Record** = One structure containing related fields.
- **Collection** = An in-memory set of values or records.
- **Associative array** = Key-value collection for fast PL/SQL lookup.
- **Nested table** = Unbounded collection that can be used in SQL when defined at schema level.
- **VARRAY** = Ordered collection with a declared maximum size.
- **Collection methods** = `COUNT`, `FIRST`, `LAST`, `NEXT`, `PRIOR`, `EXISTS`, `DELETE`, `EXTEND`, and `TRIM`.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Collections and Records?](#1-why-do-we-need-collections-and-records)
2. [What Are They?](#2-what-are-they)
3. [Records](#3-records)
4. [Collection Types](#4-collection-types)
5. [Collection Methods and Passing Values](#5-collection-methods-and-passing-values)
6. [Comparison Matrix](#6-comparison-matrix)
7. [Best Practices](#7-best-practices)
8. [Common Mistakes](#8-common-mistakes)
9. [Interview Q&A](#9-interview-qa)
10. [Revision Summary](#10-revision-summary)

---

## 1. Why Do We Need Collections and Records?

A scalar variable holds one value, but batch logic often needs one row or many rows in memory. Records group columns; collections hold multiple elements.

---

## 2. What Are They?

A **record** is like one form with several fields. A **collection** is like a table or array held in PL/SQL memory.

| Type | Shape | Typical use |
| --- | --- | --- |
| Record | One composite value | One employee row |
| Associative array | Key-value map | Fast lookup |
| Nested table | Unbounded list | Bulk rows |
| VARRAY | Ordered bounded list | Small fixed list |

---

## 3. Records

Use `%ROWTYPE` for a table-shaped record or define only the fields needed.

```sql
DECLARE
  v_employee employees%ROWTYPE;
BEGIN
  SELECT * INTO v_employee
  FROM employees
  WHERE employee_id = 100;

  DBMS_OUTPUT.PUT_LINE(v_employee.first_name);
END;
/
```

Custom records are useful at API boundaries:

```sql
DECLARE
  TYPE employee_summary IS RECORD (
    employee_id employees.employee_id%TYPE,
    display_name VARCHAR2(200),
    salary employees.salary%TYPE
  );
  v_summary employee_summary;
BEGIN
  NULL;
END;
/
```

---

## 4. Collection Types

```sql
DECLARE
  TYPE salary_map IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  v_salaries salary_map;

  TYPE id_list IS TABLE OF employees.employee_id%TYPE;
  v_ids id_list := id_list(100, 101, 102);

  TYPE skill_list IS VARRAY(5) OF VARCHAR2(50);
  v_skills skill_list := skill_list('SQL', 'PL/SQL');
BEGIN
  v_salaries(100) := 75000;
  DBMS_OUTPUT.PUT_LINE(v_ids(1));
  DBMS_OUTPUT.PUT_LINE(v_skills(2));
END;
/
```

Associative arrays are PL/SQL-only in common usage. Nested tables and VARRAYs can also be schema-level SQL types.

---

## 5. Collection Methods and Passing Values

```sql
DECLARE
  TYPE names_type IS TABLE OF VARCHAR2(50) INDEX BY PLS_INTEGER;
  v_names names_type;
  v_index PLS_INTEGER;
BEGIN
  v_names(1) := 'Asha';
  v_names(3) := 'Luis';
  v_index := v_names.FIRST;
  WHILE v_index IS NOT NULL LOOP
    DBMS_OUTPUT.PUT_LINE(v_names(v_index));
    v_index := v_names.NEXT(v_index);
  END LOOP;
END;
/
```

Use `EXISTS` before reading a sparse index. Pass collections as parameters with named collection types when a routine contract needs them.

---

## 6. Comparison Matrix

| Aspect | Associative array | Nested table | VARRAY |
| --- | --- | --- | --- |
| Index | Integer or string key | Integer index | Integer index |
| Size | Unbounded | Unbounded | Fixed maximum |
| Ordering | Key order | Logical order | Preserved order |
| Best for | Fast PL/SQL lookup | Bulk row sets | Small ordered lists |
| SQL use | Limited | Yes when schema-level | Yes when schema-level |

---

## 7. Best Practices

1. Use `%TYPE` and `%ROWTYPE` for schema alignment.
2. Use `EXISTS` with sparse collections.
3. Use `COUNT` only after checking whether a collection is null when appropriate.
4. Keep collection element types stable and documented.
5. Prefer set-based SQL when no procedural decision is required.

---

## 8. Common Mistakes

- Reading a missing sparse index and raising `NO_DATA_FOUND`.
- Calling methods on an uninitialized nested table and raising `COLLECTION_IS_NULL`.
- Assuming collection indexes always start at one.
- Using a VARRAY when the size is naturally unbounded.
- Passing an incompatible collection type to a procedure.

---

## 9. Interview Q&A

**Q: Record versus collection?**

A: A record groups fields for one logical row; a collection stores multiple elements.

**Q: Nested table versus VARRAY?**

A: A nested table is unbounded and can be sparse after deletion; a VARRAY has a maximum size and preserves dense order.

**Q: Why use an associative array?**

A: It provides fast in-memory key-value lookup inside PL/SQL without requiring a database table.

**Q: How do you iterate a sparse collection?**

A: Start with `FIRST`, then use `NEXT` until the index becomes null.

---

## 10. Revision Summary

- **Record** -> one composite row
- **Associative array** -> key-value map
- **Nested table** -> unbounded collection
- **VARRAY** -> bounded ordered collection
- **`EXISTS`** -> safe index check
- **`FIRST/NEXT`** -> sparse traversal

```sql
IF v_values.EXISTS(v_index) THEN
  DBMS_OUTPUT.PUT_LINE(v_values(v_index));
END IF;
```
