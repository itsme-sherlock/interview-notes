# PL/SQL Bulk Processing Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Context switch** = The cost of moving between the PL/SQL engine and SQL engine.
- **`BULK COLLECT`** = Fetches many rows into collections in one operation.
- **`FORALL`** = Sends many DML operations to SQL with fewer context switches.
- **`LIMIT`** = Controls batch size during bulk fetches.
- **`SAVE EXCEPTIONS`** = Continues a bulk DML operation and reports row errors afterward.
- **`SQL%BULK_EXCEPTIONS`** = Holds failed iteration indexes and error codes.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Bulk Processing?](#1-why-do-we-need-bulk-processing)
2. [What Is Bulk Processing?](#2-what-is-bulk-processing)
3. [BULK COLLECT](#3-bulk-collect)
4. [FORALL and Error Handling](#4-forall-and-error-handling)
5. [Batch Size and Performance](#5-batch-size-and-performance)
6. [Comparison Matrix](#6-comparison-matrix)
7. [Best Practices](#7-best-practices)
8. [Common Mistakes](#8-common-mistakes)
9. [Interview Q&A](#9-interview-qa)
10. [Revision Summary](#10-revision-summary)

---

## 1. Why Do We Need Bulk Processing?

A loop that executes one SQL statement per row repeatedly crosses the PL/SQL/SQL boundary. For thousands of rows, the overhead can dominate the actual DML.

---

## 2. What Is Bulk Processing?

Bulk processing transfers many rows between engines in fewer calls. It is a performance technique, not a replacement for set-based SQL.

```text
Row-by-row:  PL/SQL -> SQL -> PL/SQL -> SQL -> ...
Bulk:       PL/SQL -> SQL for a batch -> PL/SQL
```

---

## 3. BULK COLLECT

```sql
DECLARE
  TYPE id_list IS TABLE OF employees.employee_id%TYPE;
  v_ids id_list;
BEGIN
  SELECT employee_id
  BULK COLLECT INTO v_ids
  FROM employees
  WHERE department_id = 10;

  FOR i IN 1 .. v_ids.COUNT LOOP
    DBMS_OUTPUT.PUT_LINE(v_ids(i));
  END LOOP;
END;
/
```

For large result sets, fetch in batches:

```sql
DECLARE
  CURSOR c_emp IS SELECT employee_id FROM employees;
  TYPE id_list IS TABLE OF employees.employee_id%TYPE;
  v_ids id_list;
BEGIN
  OPEN c_emp;
  LOOP
    FETCH c_emp BULK COLLECT INTO v_ids LIMIT 500;
    EXIT WHEN v_ids.COUNT = 0;
    FOR i IN 1 .. v_ids.COUNT LOOP
      NULL;
    END LOOP;
  END LOOP;
  CLOSE c_emp;
END;
/
```

---

## 4. FORALL and Error Handling

`FORALL` applies one DML statement to collection indexes.

```sql
DECLARE
  TYPE id_list IS TABLE OF employees.employee_id%TYPE;
  v_ids id_list := id_list(100, 101, 102);
BEGIN
  FORALL i IN 1 .. v_ids.COUNT
    UPDATE employees
    SET salary = salary * 1.05
    WHERE employee_id = v_ids(i);
END;
/
```

Use `SAVE EXCEPTIONS` when valid rows should continue after an individual failure.

```sql
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE = -24381 THEN
      FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(
          SQL%BULK_EXCEPTIONS(i).ERROR_INDEX || ': ' ||
          SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
      END LOOP;
    ELSE
      RAISE;
    END IF;
```

---

## 5. Batch Size and Performance

A larger batch reduces context switches but consumes more PGA memory. Measure realistic batch sizes such as 100, 500, or 1000. Use SQL directly when a single `UPDATE`, `INSERT INTO SELECT`, or `MERGE` expresses the operation.

---

## 6. Comparison Matrix

| Approach | Context switches | Memory | Best use |
| --- | --- | --- | --- |
| Set-based SQL | Lowest | Database-managed | Uniform transformation |
| Row-by-row loop | Highest | Low | Complex per-row logic |
| Bulk processing | Low | Moderate/high | Per-row logic at scale |

---

## 7. Best Practices

1. Prefer one set-based SQL statement first.
2. Use `LIMIT` for potentially large fetches.
3. Choose batch size from measurement, not guesswork.
4. Handle `NO_DATA_FOUND` and empty collections correctly.
5. Use `SAVE EXCEPTIONS` only when partial success is acceptable.
6. Log failed indexes with enough business context to replay them.

---

## 8. Common Mistakes

- Using `FORALL` for a statement that could be one set-based update.
- Fetching millions of rows without `LIMIT`.
- Assuming `SQL%BULK_EXCEPTIONS` contains the business key automatically.
- Looping from `1 .. collection.COUNT` over a sparse collection.
- Swallowing bulk errors with `WHEN OTHERS THEN NULL`.

---

## 9. Interview Q&A

**Q: What is the difference between `BULK COLLECT` and `FORALL`?**

A: `BULK COLLECT` moves query results into collections; `FORALL` sends collection-driven DML efficiently to SQL.

**Q: Why is set-based SQL usually preferred?**

A: It avoids procedural loops and minimizes engine crossings while allowing Oracle to optimize the whole operation.

**Q: What does `SAVE EXCEPTIONS` do?**

A: It allows other iterations to continue, then raises an aggregate error whose details are available through `SQL%BULK_EXCEPTIONS`.

---

## 10. Revision Summary

- **Context switch** -> PL/SQL/SQL handoff cost
- **`BULK COLLECT`** -> query to collection
- **`FORALL`** -> collection to bulk DML
- **`LIMIT`** -> bounded fetch batch
- **`SAVE EXCEPTIONS`** -> collect row failures

```sql
FETCH c BULK COLLECT INTO v_rows LIMIT 500;
FORALL i IN 1 .. v_rows.COUNT
  UPDATE target SET processed = 'Y' WHERE id = v_rows(i).id;
```
