# PL/SQL Performance Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Set-based SQL** = Let Oracle process a whole data set in one statement.
- **Context switching** = Cost of crossing between PL/SQL and SQL engines.
- **`NOCOPY`** = Hint to pass large `OUT` or `IN OUT` values by reference.
- **Native compilation** = Compiles PL/SQL for faster execution in suitable workloads.
- **Result cache** = Reuses function results when inputs and dependencies remain valid.
- **Instrumentation** = Adds module, action, and timing context to production work.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need PL/SQL Performance?](#1-why-do-we-need-plsql-performance)
2. [What Controls Performance?](#2-what-controls-performance)
3. [Set-Based and Bulk Processing](#3-set-based-and-bulk-processing)
4. [Compilation, Parameters, and Caching](#4-compilation-parameters-and-caching)
5. [Instrumentation and Measurement](#5-instrumentation-and-measurement)
6. [Comparison Matrix](#6-comparison-matrix)
7. [Best Practices](#7-best-practices)
8. [Common Mistakes](#8-common-mistakes)
9. [Interview Q&A](#9-interview-qa)
10. [Revision Summary](#10-revision-summary)

---

## 1. Why Do We Need PL/SQL Performance?

A correct row-by-row procedure can still be too slow at scale. Performance work starts by identifying whether time is spent in SQL, PL/SQL, I/O, locks, or excessive context switches.

---

## 2. What Controls Performance?

The main controls are SQL shape, number of engine crossings, collection memory, transaction duration, parsing, and instrumentation quality. Measure before changing code.

---

## 3. Set-Based and Bulk Processing

Prefer one SQL statement for uniform work. If each row needs procedural decisions, use `BULK COLLECT` and `FORALL` with a bounded `LIMIT`. Avoid fetching columns or rows that are not needed.

```sql
UPDATE employees
SET salary = salary * 1.05
WHERE department_id = 10;
```

This is usually better than a loop that updates one employee at a time.

---

## 4. Compilation, Parameters, and Caching

`NOCOPY` can reduce copying of large parameters but changes exception behavior because the caller may see partial changes. Native compilation can help CPU-heavy PL/SQL but should be benchmarked. `DETERMINISTIC` is a promise about function behavior, not a general cache. Function result caching is useful only when dependencies and invalidation are understood.

---

## 5. Instrumentation and Measurement

Use `DBMS_APPLICATION_INFO.SET_MODULE` and `SET_ACTION` so sessions can be identified in monitoring tools. Capture elapsed time, row counts, and key phases. Compare plans and workload before and after changes.

```sql
BEGIN
  DBMS_APPLICATION_INFO.SET_MODULE('employee_batch', 'salary_update');
  -- Work here
  DBMS_APPLICATION_INFO.SET_MODULE(NULL, NULL);
END;
/
```

---

## 6. Comparison Matrix

| Technique | Benefit | Risk or limitation |
| --- | --- | --- |
| Set-based SQL | Lowest procedural overhead | Less flexible per-row logic |
| Bulk processing | Fewer context switches | Uses PGA memory |
| `NOCOPY` | Fewer parameter copies | Partial caller changes on error |
| Result cache | Avoids repeated calculation | Invalidation and correctness rules |
| Instrumentation | Faster diagnosis | Requires consistent adoption |

---

## 7. Best Practices

1. Measure with representative data.
2. Prefer set-based SQL, then bulk processing.
3. Bound collection memory with `LIMIT`.
4. Keep transactions and locks short.
5. Instrument phases and record row counts.
6. Treat caching hints as contracts that require proof.

---

## 8. Common Mistakes

- Optimizing PL/SQL before checking the SQL execution plan.
- Fetching an entire table into memory.
- Using `NOCOPY` without understanding aliasing and exceptions.
- Marking a function `DETERMINISTIC` when it depends on session state.
- Measuring only one warm-cache run.

---

## 9. Interview Q&A

**Q: Why is row-by-row processing slow?**

A: Every iteration may cross the PL/SQL/SQL boundary, multiplying overhead and parse or execution work.

**Q: When is `FORALL` appropriate?**

A: When procedural logic must prepare many DML operations and a single set-based statement cannot express the rule.

**Q: Is `DETERMINISTIC` a cache?**

A: No. It asserts that the same inputs produce the same output; Oracle may use that promise for optimization, so it must be true.

---

## 10. Revision Summary

- **Set-based first** -> whole data set in SQL
- **Context switch** -> engine crossing overhead
- **Bulk** -> fewer crossings
- **`NOCOPY`** -> less parameter copying
- **Result cache** -> reusable function output
- **Instrumentation** -> measurable production behavior

```sql
DBMS_APPLICATION_INFO.SET_MODULE('module_name', 'action_name');
```
