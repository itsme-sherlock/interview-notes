# Oracle Advanced Execution Plan Analysis Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Execution plan** = The operations Oracle chooses to run a SQL statement.
- **Estimated plan** = Plan predicted before execution.
- **Actual plan** = Plan and runtime statistics from an executed cursor.
- **DBMS_XPLAN** = Displays readable execution-plan details.
- **Join method** = Nested loops, hash join, or sort merge join.
- **Cardinality** = Estimated or actual number of rows at a plan step.
- **Bind variable** = Placeholder that improves cursor reuse.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Plan Analysis?](#1-why-do-we-need-plan-analysis)
2. [What Is an Execution Plan?](#2-what-is-an-execution-plan)
3. [Estimated vs Actual Plans](#3-estimated-vs-actual-plans)
4. [Join Methods](#4-join-methods)
5. [AUTOTRACE and DBMS_XPLAN](#5-autotrace-and-dbms_xplan)
6. [Statistics, Cardinality, and Binds](#6-statistics-cardinality-and-binds)
7. [Comparison Matrix](#7-comparison-matrix)
8. [Best Practices](#8-best-practices)
9. [Common Mistakes](#9-common-mistakes)
10. [Interview Q&A](#10-interview-qa)
11. [Revision Summary](#11-revision-summary)

---

## 1. Why Do We Need Plan Analysis?

### The Problem: A Query Can Be Logically Correct but Slow

```sql
SELECT e.first_name, d.department_name
FROM employees e
JOIN departments d ON d.department_id = e.department_id
WHERE e.salary > 10000;
```

The result may be correct, but Oracle could choose an inefficient full scan or join method.

**Problems:**
- Excessive I/O
- Poor response time
- Unnecessary CPU use
- Different behavior as data grows

### The Solution: Read the Execution Plan

Plan analysis shows how Oracle accesses tables, joins rows, and estimates cost.

---

**➡ Transition:** An execution plan is the optimizer’s selected path through the query. 

---

## 2. What Is an Execution Plan?

### Simple Definition

An **execution plan** is the ordered set of operations Oracle uses to produce a query result.

### Common Operations

- Table access full
- Index range scan
- Index unique scan
- Table access by rowid
- Hash join
- Nested loops
- Sort and aggregation

### Basic Example

```sql
EXPLAIN PLAN FOR
SELECT * FROM employees WHERE employee_id = 101;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
```

### Important Limitation

`EXPLAIN PLAN` predicts a plan; it does not prove what happened during actual execution.

---

**➡ Transition:** To diagnose estimation errors, compare the predicted plan with runtime statistics. 

---

## 3. Estimated vs Actual Plans

### Estimated Plan

```sql
EXPLAIN PLAN FOR
SELECT * FROM employees WHERE department_id = 10;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
```

### Actual Cursor Plan

```sql
SELECT /*+ GATHER_PLAN_STATISTICS */ *
FROM employees
WHERE department_id = 10;

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));
```

### What to Compare

- Estimated rows vs actual rows
- Estimated cost vs elapsed time
- Buffer gets
- Number of executions
- Starts at each plan step

Large estimate errors often indicate stale statistics, skewed data, or an unsuitable predicate.

---

**➡ Transition:** Join methods are selected according to data volume, indexes, and estimated cardinality. 

---

## 4. Join Methods

### Nested Loops

Best when the driving row source is small and the inner table has a useful index.

```text
For each row from the outer table, find matching rows in the inner table.
```

### Hash Join

Often effective for larger, unsorted data sets and equality joins.

```text
Build a hash structure from one input, then probe it with the other input.
```

### Sort Merge Join

Useful when inputs are sorted or when an equality join is not the only option.

### Comparison

| Method | Best For | Risk |
| --- | --- | --- |
| Nested loops | Small outer set, indexed inner table | Many random lookups |
| Hash join | Large equality joins | Memory pressure |
| Sort merge | Sorted inputs or range-style joins | Sort cost |

---

**➡ Transition:** Oracle provides tools to inspect both plan output and runtime behavior. 

---

## 5. AUTOTRACE and DBMS_XPLAN

### AUTOTRACE

In SQL*Plus or compatible tools:

```sql
SET AUTOTRACE ON
SELECT * FROM employees WHERE employee_id = 101;
SET AUTOTRACE OFF
```

It can display the plan and statistics for the statement.

### DBMS_XPLAN

```sql
SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST')); 
```

### Why DBMS_XPLAN Is Important

It can expose actual rows, buffer gets, predicates, and execution details for a real cursor.

---

**➡ Transition:** Plan quality depends heavily on statistics and accurate row estimates. 

---

## 6. Statistics, Cardinality, and Binds

### Statistics

Optimizer statistics describe table size, column distribution, and indexes.

```sql
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'EMPLOYEES');
END;
/
```

### Cardinality

Cardinality is the number of rows Oracle expects at a plan step. A large difference between estimated and actual rows can lead to a poor plan.

### Bind Variables

```sql
SELECT * FROM employees WHERE employee_id = :employee_id;
```

Bind variables reduce hard parsing and encourage cursor reuse, but skewed data may require adaptive behavior or different plans.

### Hints

```sql
SELECT /*+ INDEX(e employees_pk) */ *
FROM employees e
WHERE employee_id = :employee_id;
```

Hints should be used only after diagnosing the root cause because they can become stale as data changes.

---

## 7. Comparison Matrix

| Aspect | EXPLAIN PLAN | DBMS_XPLAN DISPLAY_CURSOR | AUTOTRACE |
| --- | --- | --- | --- |
| Shows | Estimated plan | Actual cursor details | Plan and statistics |
| Executes query | No | Query already executed | Yes |
| Runtime rows | No | Yes, with statistics | Often available |
| Best use | Initial inspection | Root-cause analysis | Quick investigation |

---

## 8. Best Practices

### 1. Compare estimated and actual rows

**Why:** Estimation errors often explain bad join choices.

### 2. Check logical behavior before adding hints

**Why:** A hint can hide stale statistics or a poor predicate.

### 3. Test plans with representative data

**Why:** A plan that works for a small test table may fail at production volume.

---

## 9. Common Mistakes

### Mistake 1: Treating EXPLAIN PLAN as actual runtime evidence

**Solution:** Use `DBMS_XPLAN.DISPLAY_CURSOR` with runtime statistics.

### Mistake 2: Choosing an index because it exists

**Solution:** Confirm selectivity, cardinality, and actual plan behavior.

### Mistake 3: Adding hints before checking statistics

**Solution:** Gather or validate statistics first.

---

## 10. Interview Q&A

**Q: What is the difference between EXPLAIN PLAN and an actual execution plan?**
A: EXPLAIN PLAN is an optimizer prediction. An actual cursor plan includes runtime information from an executed statement.

**Q: When are nested loops useful?**
A: When the outer row source is small and the inner table has an efficient index.

**Q: What does cardinality mean?**
A: It is the number of rows estimated or observed at a plan step.

---

## 11. Revision Summary

**Execution-plan analysis** = understand how Oracle actually runs SQL.

- **EXPLAIN PLAN** → estimated plan
- **DBMS_XPLAN** → readable plan details
- **AUTOTRACE** → plan plus statistics
- **Cardinality** → row estimate
- **Join methods** → nested loops, hash, sort merge
- **Binds and statistics** → influence plan selection

### Important Syntax

```sql
EXPLAIN PLAN FOR SELECT * FROM employees WHERE employee_id = 101;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

SELECT /*+ GATHER_PLAN_STATISTICS */ *
FROM employees
WHERE department_id = 10;

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));
```

---

**Done!** Reliable tuning starts with actual plan evidence, not assumptions based only on indexes or query text.
