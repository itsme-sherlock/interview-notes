# Oracle Advanced DML and Bulk Loading Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **INSERT ... SELECT** = Loads rows from a query into another table.
- **Multi-table insert** = Inserts rows into more than one target table from one source query.
- **Direct-path insert** = Appends data using a faster loading path when appropriate.
- **DML error logging** = Keeps bad rows aside while valid rows continue.
- **Bulk loading** = Moves large volumes efficiently with controlled logging and batching.
- **Interview keyword** = Validate source data and transaction boundaries before bulk changes.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Advanced DML?](#1-why-do-we-need-advanced-dml)
2. [INSERT SELECT](#2-insert-select)
3. [Multi-Table Inserts](#3-multi-table-inserts)
4. [Direct-Path Inserts](#4-direct-path-inserts)
5. [DML Error Logging](#5-dml-error-logging)
6. [Bulk Loading Strategy](#6-bulk-loading-strategy)
7. [Comparison Matrix](#7-comparison-matrix)
8. [Best Practices](#8-best-practices)
9. [Common Mistakes](#9-common-mistakes)
10. [Interview Q&A](#10-interview-qa)
11. [Revision Summary](#11-revision-summary)

---

## 1. Why Do We Need Advanced DML?

### The Problem: Large Data Changes Need Control

Row-by-row inserts can be slow and difficult to recover when thousands of records are involved.

**Problems:**
- Excessive application round trips
- Long-running transactions
- One bad row can stop a whole load
- Hard-to-audit partial results

### The Solution: Set-Based and Bulk DML

Advanced DML uses SQL to move and validate sets of rows efficiently.

### Real-World Scenarios

- Load a staging table into production tables
- Split one source feed into multiple targets
- Continue a load while recording rejected rows

---

**➡ Transition:** The most common set-based load uses INSERT SELECT. 

---

## 2. INSERT SELECT

### Syntax/Usage

```sql
INSERT INTO employees_archive (employee_id, first_name, salary)
SELECT employee_id, first_name, salary
FROM employees
WHERE status = 'INACTIVE';
```

### Why It Matters

- Avoids row-by-row application loops
- Uses the optimizer for the source query
- Works well for archive and staging operations

### Important Rule

The target column list and selected source expressions must be compatible in number and data type.

---

**➡ Transition:** A single source query can also distribute rows to several targets. 

---

## 3. Multi-Table Inserts

### Syntax/Usage

```sql
INSERT ALL
    INTO employee_archive (employee_id, first_name)
    VALUES (employee_id, first_name)
    INTO employee_audit (employee_id, action_name)
    VALUES (employee_id, 'ARCHIVED')
SELECT employee_id, first_name
FROM employees
WHERE status = 'INACTIVE';
```

### Conditional Insert

```sql
INSERT ALL
    WHEN salary >= 10000 THEN
        INTO high_salary_employees (employee_id, salary)
        VALUES (employee_id, salary)
    WHEN salary < 10000 THEN
        INTO standard_salary_employees (employee_id, salary)
        VALUES (employee_id, salary)
SELECT employee_id, salary
FROM employees;
```

### Use Case

One source scan can populate multiple destinations.

---

**➡ Transition:** For very large loads, direct-path insertion may reduce overhead. 

---

## 4. Direct-Path Inserts

### Syntax/Usage

```sql
INSERT /*+ APPEND */ INTO sales_archive
SELECT *
FROM sales_stage;
```

### How It Works

The `APPEND` hint requests direct-path insertion, which can append data above the high-water mark and reduce some conventional insert overhead.

### Trade-offs

- May use more space
- Can affect concurrency
- Requires careful transaction and constraint planning
- Should be tested with production-sized data

---

**➡ Transition:** A bulk load may contain a few invalid rows, so error logging can isolate them. 

---

## 5. DML Error Logging

### Create Error Table

```sql
BEGIN
    DBMS_ERRLOG.CREATE_ERROR_LOG('EMPLOYEES');
END;
/
```

### Insert with Error Logging

```sql
INSERT INTO employees (employee_id, first_name, salary)
SELECT employee_id, first_name, salary
FROM employee_stage
LOG ERRORS INTO err$_employees ('NIGHTLY_LOAD')
REJECT LIMIT UNLIMITED;
```

### Review Rejected Rows

```sql
SELECT *
FROM err$_employees
WHERE ora_err_tag$ = 'NIGHTLY_LOAD';
```

### Why It Matters

Valid rows can continue while invalid rows are captured for correction, depending on the statement and constraint situation.

---

**➡ Transition:** Good bulk loading combines set-based SQL, validation, and controlled commits. 

---

## 6. Bulk Loading Strategy

### Recommended Flow

```text
Source -> staging -> validate -> transform -> load -> audit -> commit
```

### Key Decisions

- Load into a staging table first
- Validate keys and data types
- Decide whether errors stop the batch
- Choose a transaction size
- Capture counts and rejected rows
- Gather statistics after a major load when appropriate

### Example Validation

```sql
SELECT COUNT(*) AS invalid_count
FROM employee_stage
WHERE employee_id IS NULL
   OR salary < 0;
```

---

## 7. Comparison Matrix

| Feature | Best Use | Main Concern |
| --- | --- | --- |
| INSERT SELECT | Set-based copy | Source/target compatibility |
| Multi-table insert | One source to many targets | Complex routing rules |
| APPEND | Large append load | Space and concurrency |
| Error logging | Isolate bad rows | Rejected-row review |
| MERGE | Synchronize source and target | Match-key correctness |

---

## 8. Best Practices

### 1. Validate in staging before changing production

**Why:** It reduces the risk of partial or invalid loads.

### 2. Use explicit target columns

**Why:** It protects against source or target column-order changes.

### 3. Record load counts and error tags

**Why:** Auditing makes failures diagnosable and repeatable.

### 4. Test APPEND and commit size with realistic data

**Why:** Direct-path and large transactions affect space, locks, and recovery.

---

## 9. Common Mistakes

### Mistake 1: Using SELECT * in a production load

**Solution:** Specify source and target columns explicitly.

### Mistake 2: Committing a large load without validation

**Solution:** Validate staging data and define recovery steps first.

### Mistake 3: Ignoring the error table after a load

**Solution:** Review, reconcile, and report rejected rows.

---

## 10. Interview Q&A

**Q: Why use INSERT SELECT?**
A: It performs a set-based load without transferring each row through application code.

**Q: What does the APPEND hint do?**
A: It requests direct-path insertion, which may improve large append loads but can change space and concurrency behavior.

**Q: How can a load continue when some rows are invalid?**
A: Use Oracle DML error logging and review the generated error table afterward.

---

## 11. Revision Summary

- **INSERT SELECT** → set-based data movement
- **INSERT ALL** → one source to many targets
- **APPEND** → direct-path load request
- **DML error logging** → capture rejected rows
- **Staging** → validate before production
- **Audit counts** → prove load completeness

### Important Syntax

```sql
INSERT INTO target_table (id, name)
SELECT id, name
FROM source_table;

INSERT INTO target_table (id, name)
SELECT id, name
FROM source_table
LOG ERRORS INTO err$_target_table ('LOAD_1')
REJECT LIMIT UNLIMITED;
```

---

**Done!** Advanced DML makes large data movement faster, safer, and easier to audit when the load is designed as a controlled set-based process.
