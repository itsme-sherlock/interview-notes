# SQL MERGE and UPSERT Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **MERGE** = Inserts, updates, or deletes rows in one statement based on matching conditions.
- **UPSERT** = Common term for “update if exists, otherwise insert.”
- **Best use case** = Synchronizing staging tables with master tables.
- **Interview keyword** = MERGE is efficient when you want one statement to handle both insert and update logic.
- **Key benefit** = Reduces multiple round trips between application and database.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need MERGE?](#1-why-do-we-need-merge)
2. [What Is MERGE?](#2-what-is-merge)
3. [Basic MERGE Syntax](#3-basic-merge-syntax)
4. [WHEN MATCHED and WHEN NOT MATCHED](#4-when-matched-and-when-not-matched)
5. [MERGE vs INSERT / UPDATE / DELETE](#5-merge-vs-insert--update--delete)
6. [Comparison Matrix](#7-comparison-matrix)
7. [Best Practices](#8-best-practices)
8. [Common Mistakes](#9-common-mistakes)
9. [Interview Q&A](#10-interview-qa)
10. [Revision Summary](#11-revision-summary)

---

## 1. Why Do We Need MERGE?

### The Problem: Data Needs to Stay in Sync

In ETL or integration workflows, a source table may contain new rows and updates that should be reflected in a target table.

```sql
-- Source data loaded from external system
SELECT * FROM staging_customers;
```

You do not want to write separate logic for:
- insert new rows
- update existing rows
- ignore unchanged data

### The Solution: MERGE

`MERGE` lets you handle all three patterns in one statement based on matching keys.

### Real-World Scenarios

- **Sales data synchronization** between staging and production tables
- **Customer master data updates**
- **Daily batch processing**

---

**➡ Transition:** Now that we know why MERGE is useful, let’s define it properly. 

---

## 2. What Is MERGE?

### Simple Definition

A **MERGE** statement compares data in a source and target table, then performs the appropriate action: insert, update, or delete.

### Analogy: Real-World Comparison

**Think of a data sync process**:
- Source table = latest arriving data
- Target table = stored master table
- MERGE = reconcile them in one step

### Key Characteristics

- Uses a condition such as `WHEN MATCHED THEN ...`
- Supports insert and update logic together
- Common in data loading and warehouse tasks
- Helps reduce multiple SQL calls in application code

---

**➡ Transition:** The basic MERGE syntax shows the structure clearly. 

---

## 3. Basic MERGE Syntax

### The Challenge

You need to update target rows when they match and insert unmatched source rows.

### How It Works

```sql
MERGE INTO target_table t
USING source_table s
ON (t.id = s.id)
WHEN MATCHED THEN
    UPDATE SET t.name = s.name, t.salary = s.salary
WHEN NOT MATCHED THEN
    INSERT (id, name, salary)
    VALUES (s.id, s.name, s.salary);
```

### Example

```sql
MERGE INTO employees_target e
USING employees_stage s
ON (e.employee_id = s.employee_id)
WHEN MATCHED THEN
    UPDATE SET e.first_name = s.first_name,
               e.salary = s.salary
WHEN NOT MATCHED THEN
    INSERT (employee_id, first_name, salary)
    VALUES (s.employee_id, s.first_name, s.salary);
```

### Why It Matters

This is the standard upsert pattern in Oracle SQL.

---

**➡ Transition:** The key building blocks are the WHEN MATCHED and WHEN NOT MATCHED branches. 

---

## 4. WHEN MATCHED and WHEN NOT MATCHED

### The Challenge

You need a rule for each match or non-match outcome.

### How It Works

- `WHEN MATCHED THEN UPDATE` updates existing rows
- `WHEN NOT MATCHED THEN INSERT` adds new rows
- You can also add `WHEN NOT MATCHED BY SOURCE THEN DELETE` if needed

### Example

```sql
MERGE INTO employee_master m
USING employee_delta d
ON (m.employee_id = d.employee_id)
WHEN MATCHED THEN
    UPDATE SET m.salary = d.salary,
               m.department_id = d.department_id
WHEN NOT MATCHED THEN
    INSERT (employee_id, salary, department_id)
    VALUES (d.employee_id, d.salary, d.department_id);
```

### Optional Delete Pattern

```sql
MERGE INTO target t
USING source s
ON (t.id = s.id)
WHEN MATCHED THEN
    UPDATE SET t.value = s.value
WHEN NOT MATCHED THEN
    INSERT (id, value) VALUES (s.id, s.value)
WHEN NOT MATCHED BY SOURCE THEN
    DELETE;
```

This pattern is useful for full synchronization from a source table.

---

**➡ Transition:** MERGE is convenient, but it is important to understand how it differs from standard update/insert logic. 

---

## 5. MERGE vs INSERT / UPDATE / DELETE

### The Challenge

You may wonder whether MERGE is necessary or if simpler DML works just as well.

### How It Works

- `INSERT` adds new rows only
- `UPDATE` modifies rows only
- `DELETE` removes rows only
- `MERGE` combines logic in one statement based on matching keys

### Example

```sql
UPDATE employees
SET salary = salary + 500
WHERE employee_id = 101;

INSERT INTO employees (employee_id, first_name)
VALUES (102, 'Alice');
```

This is fine for small operations, but `MERGE` is better for batch synchronization.

### Best Use Cases for MERGE

- Staging-to-production sync
- ETL jobs
- Dimension table refreshes
- Reconciliation tasks

---

## 6. Comparison Matrix

### MERGE vs Separate DML

| Aspect | MERGE | Separate DML |
| --- | --- | --- |
| **Purpose** | Reconcile source and target | Handle each action individually |
| **Compound logic** | Yes | Usually multiple statements |
| **Efficiency** | Good for bulk sync | More round trips |
| **Complexity** | Moderate | Simpler for small cases |
| **Best for** | Staging and batch loads | One-off updates/inserts |

---

## 7. Best Practices

### 1. Always match on a reliable unique key

```sql
ON (t.employee_id = s.employee_id)
```

**Why:** Matching on unstable or duplicate columns causes incorrect updates.

---

### 2. Keep the MERGE logic predictable and testable

**Why:** Large merge operations can accidentally update too many rows if the condition is broad.

---

### 3. Use a staging table when possible for bulk syncs

**Why:** This reduces risk and makes the process easier to validate before committing to the target.

---

## 8. Common Mistakes

### Mistake 1: Matching on non-unique columns

**Problem:** More than one row may match, causing unexpected updates.

**Solution:** Match on a primary key or unique business key.

---

### Mistake 2: Running MERGE without testing the source data

**Problem:** Unexpected rows may insert or overwrite target values.

**Solution:** Review the staged data first, then run an audited merge.

---

### Mistake 3: Overusing MERGE for simple single-row changes

**Problem:** Simpler `INSERT` or `UPDATE` statements are easier to understand.

**Solution:** Use MERGE when you truly need a reconcile pattern.

---

## 9. Interview Q&A

### Conceptual Questions

**Q: What is MERGE in SQL?**
A: MERGE is a statement that synchronizes a target table with a source table, inserting new rows, updating matches, and optionally deleting unmatched rows.

---

**Q: What does UPSERT mean?**
A: UPSERT means “update if exists, otherwise insert.” This is essentially what a typical MERGE statement does.

---

### Comparison Questions

**Q: Why use MERGE instead of separate INSERT and UPDATE statements?**
A: MERGE combines the logic into one statement, which is useful for batch reconciliation and reduces code complexity.

---

### Scenario Questions

**Q: A sales staging table needs to update a target master table. What approach would you use?**
A: Use a MERGE statement matching on the product or customer key. Update rows that match and insert rows that are new.

---

## 10. Revision Summary

### 1-Minute Recap

**MERGE** = one statement that synchronizes source and target data.

- **WHEN MATCHED** → update existing rows
- **WHEN NOT MATCHED** → insert new rows
- **WHEN NOT MATCHED BY SOURCE** → optional delete
- **Best use** → ETL and data synchronization

### Interview Keywords

- **UPSERT** → update or insert
- **Staging table** → temporary incoming data
- **Target table** → final destination dataset
- **Reconciliation** → compare source and target data

### Important Syntax

```sql
MERGE INTO target t
USING source s
ON (t.id = s.id)
WHEN MATCHED THEN
    UPDATE SET t.value = s.value
WHEN NOT MATCHED THEN
    INSERT (id, value)
    VALUES (s.id, s.value);
```

---

**Done!** MERGE is a powerful data synchronization tool when the business requirement is to reconcile two related datasets in one intelligent step.
