# Oracle Flashback Query and Recovery Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Flashback Query** = Query data as it existed at an earlier time.
- **AS OF TIMESTAMP** = Reads a previous database snapshot.
- **Flashback Table** = Restores a table to an earlier point.
- **Flashback Drop** = Recovers a dropped table from the recycle bin.
- **Undo data** = Makes historical query and recovery operations possible.
- **Interview keyword** = Flashback is logical recovery and investigation, not a replacement for backups.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Flashback?](#1-why-do-we-need-flashback)
2. [What Is Flashback?](#2-what-is-flashback)
3. [Flashback Query](#3-flashback-query)
4. [Flashback Table](#4-flashback-table)
5. [Flashback Drop](#5-flashback-drop)
6. [Comparison Matrix](#6-comparison-matrix)
7. [Best Practices](#7-best-practices)
8. [Common Mistakes](#8-common-mistakes)
9. [Interview Q&A](#9-interview-qa)
10. [Revision Summary](#10-revision-summary)

---

## 1. Why Do We Need Flashback?

### The Problem: Data Can Be Changed or Deleted by Mistake

```sql
DELETE FROM employees WHERE department_id = 10;
COMMIT;
```

After commit, a normal rollback cannot undo the deletion.

**Problems:**
- Accidental DML may be committed
- Historical values may be needed for investigation
- A dropped table may need recovery

### The Solution: Flashback

Flashback features use available undo and database metadata to inspect or restore earlier states.

### Real-World Scenarios

- Investigate an accidental update
- Recover a recently dropped table
- Compare current and historical values

---

**➡ Transition:** Flashback starts with querying an earlier version of a table. 

---

## 2. What Is Flashback?

### Simple Definition

**Flashback** lets you view or restore database objects to an earlier point in time, subject to available undo and configuration.

### Key Characteristics

- Supports historical investigation
- Can recover some accidental changes
- Does not replace backups or disaster recovery
- Retention depends on undo configuration and object state

---

**➡ Transition:** Flashback Query is the safest first step because it reads history without changing data. 

---

## 3. Flashback Query

### Syntax/Usage

```sql
SELECT employee_id, salary
FROM employees AS OF TIMESTAMP
     (SYSTIMESTAMP - INTERVAL '10' MINUTE)
WHERE employee_id = 101;
```

### Compare Current and Earlier Values

```sql
SELECT employee_id, salary
FROM employees AS OF TIMESTAMP
     (SYSTIMESTAMP - INTERVAL '1' HOUR)
MINUS
SELECT employee_id, salary
FROM employees;
```

### Why It Matters

It helps identify what changed before attempting a repair.

---

**➡ Transition:** When investigation confirms a mistake, Flashback Table may restore the table. 

---

## 4. Flashback Table

### Example

```sql
ALTER TABLE employees ENABLE ROW MOVEMENT;

FLASHBACK TABLE employees
TO TIMESTAMP (SYSTIMESTAMP - INTERVAL '10' MINUTE);
```

### Important Notes

- Requires appropriate privileges
- Can affect all rows in the table
- May require row movement
- Must be used carefully in production

---

**➡ Transition:** A dropped table can sometimes be restored without a full recovery operation. 

---

## 5. Flashback Drop

### Drop and Recover

```sql
DROP TABLE employees;

FLASHBACK TABLE employees
TO BEFORE DROP;
```

### Recycle Bin

```sql
SELECT object_name, original_name
FROM recyclebin;
```

### Limitation

Recovery may not be possible if the recycle-bin object was purged or storage was reused.

---

## 6. Comparison Matrix

| Feature | Purpose | Changes Data? |
| --- | --- | --- |
| Flashback Query | Read historical values | No |
| Flashback Table | Restore table state | Yes |
| Flashback Drop | Recover dropped table | Yes |
| Backup recovery | Full failure recovery | Yes |

---

## 7. Best Practices

### 1. Query history before restoring data

**Why:** Investigation prevents an incorrect recovery action.

### 2. Confirm undo retention and privileges

**Why:** Historical data may no longer be available.

### 3. Treat Flashback as a supplement to backups

**Why:** Flashback cannot replace disaster recovery.

---

## 8. Common Mistakes

### Mistake 1: Assuming Flashback can recover any historical point

**Solution:** Check undo retention and available recovery metadata.

### Mistake 2: Flashing back a table without validating impact

**Solution:** Test the historical query and coordinate the recovery.

### Mistake 3: Assuming DROP always means permanent loss

**Solution:** Check the recycle bin before using larger recovery procedures.

---

## 9. Interview Q&A

**Q: What is Flashback Query?**
A: It reads data as it existed at an earlier time without changing the current table.

**Q: What is Flashback Drop?**
A: It restores a recently dropped table from the recycle bin when recovery metadata remains available.

**Q: Is Flashback a replacement for backup?**
A: No. Flashback is useful for logical mistakes, while backups support broader failure recovery.

---

## 10. Revision Summary

- **AS OF TIMESTAMP** → read historical data
- **Flashback Table** → restore table state
- **Flashback Drop** → recover dropped table
- **Undo** → supports historical access
- **Backup** → required for full disaster recovery

### Important Syntax

```sql
SELECT *
FROM employees AS OF TIMESTAMP
     (SYSTIMESTAMP - INTERVAL '15' MINUTE);

FLASHBACK TABLE employees TO BEFORE DROP;
```

---

**Done!** Flashback provides a practical way to investigate and recover many logical data mistakes without immediately restoring the whole database.
