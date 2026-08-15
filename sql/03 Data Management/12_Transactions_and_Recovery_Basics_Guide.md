# SQL Transactions and Recovery Basics Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Transaction** = A unit of work that must be committed or rolled back together.
- **Commit** = Saves transaction changes permanently.
- **Rollback** = Undoes uncommitted work.
- **Recovery** = Restoring data after failures or crashes.
- **Redo log** = Records changes so database state can be reconstructed.
- **Interview keyword** = A committed transaction is durable and should survive crashes.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Transactions and Recovery?](#1-why-do-we-need-transactions-and-recovery)
2. [What Is a Transaction?](#2-what-is-a-transaction)
3. [Commit and Rollback](#3-commit-and-rollback)
4. [Transaction States](#4-transaction-states)
5. [Recovery Basics](#5-recovery-basics)
6. [Redo Logs and Undo Information](#6-redo-logs-and-undo-information)
7. [Comparison Matrix](#7-comparison-matrix)
8. [Best Practices](#8-best-practices)
9. [Common Mistakes](#9-common-mistakes)
10. [Interview Q&A](#10-interview-qa)
11. [Revision Summary](#11-revision-summary)

---

## 1. Why Do We Need Transactions and Recovery?

### The Problem: Systems Fail Mid-Update

A database may crash while a transfer, update, or import is running.

```sql
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
```

If the system crashes after the first update but before the second, the data becomes inconsistent.

**Problems with partial writes:**
- Missing money or duplicated money
- Broken business processes
- Unclear final state after restart

### The Solution: Transactions and Recovery

Transactions guarantee atomicity, and recovery restores the database to a valid state after failures.

### Real-World Scenarios

- **Banking:** money transfer must be all-or-nothing
- **Order processing:** inventory plus order history must match
- **Critical ETL:** partial import should not leave a half-loaded dataset

---

**➡ Transition:** What exactly is a transaction from a database perspective? 

---

## 2. What Is a Transaction?

### Simple Definition

A **transaction** is a group of database operations treated as one logical unit.

### Key Characteristics

- It is atomic: all or nothing
- It preserves database consistency
- It can be committed or rolled back
- It is the basic unit of reliable database work

### Example

```sql
UPDATE accounts
SET balance = balance - 500
WHERE account_id = 1;

UPDATE accounts
SET balance = balance + 500
WHERE account_id = 2;

COMMIT;
```

If either update fails, the transaction can be rolled back.

---

**➡ Transition:** The transaction is controlled by COMMIT and ROLLBACK. 

---

## 3. Commit and Rollback

### The Challenge

You need a reliable way to finalize or cancel changes.

### How It Works

- `COMMIT` makes changes permanent
- `ROLLBACK` undoes uncommitted changes

### Example

```sql
UPDATE employees
SET salary = salary + 1000
WHERE employee_id = 101;

COMMIT;
```

### Rollback example

```sql
UPDATE employees
SET salary = salary + 1000
WHERE employee_id = 101;

ROLLBACK;
```

This returns the row to its old state.

### Why It Matters

- Prevents partial business updates
- Allows safe error recovery
- Preserves database correctness

---

**➡ Transition:** Transactions also have a lifecycle and state model. 

---

## 4. Transaction States

### The Challenge

A transaction moves through several states as it executes.

### How It Works

Typical states are:
- Active
- Partially committed
- Committed
- Rolled back

### Simple Logic

```text
BEGIN transaction
    -> execute SQL
    -> commit or rollback
    -> ends
```

### Important Idea

Until you commit, the database can still decide to roll back the work if an error occurs.

---

**➡ Transition:** Now let’s focus on recovery after a crash or system failure. 

---

## 5. Recovery Basics

### The Challenge

A database may fail unexpectedly in the middle of a job.

### How It Works

Recovery uses logs and saved data pages to restore the database to a consistent state.

### Core Recovery Principles

- Redo committed changes
- Undo uncommitted changes
- Ensure no partial transactions remain visible

### Example

If a transaction updated two tables but crashed before commit:
- Recovery will undo those changes
- If the transaction had already been committed, recovery will redo them

### Why Recovery Matters

It protects the database against power loss, crashes, and storage issues.

---

**➡ Transition:** Recovery relies on redo and undo information stored by the database engine. 

---

## 6. Redo Logs and Undo Information

### The Challenge

The database must know what happened before the crash and what should be saved.

### How It Works

- **Redo log** records changes so they can be replayed after recovery
- **Undo information** helps revert uncommitted changes

### Simplified Flow

```text
Transaction writes data -> log records created -> commit -> data is durable
```

### Why This Is Important

- Committed transactions are not lost
- Uncommitted transactions are not exposed after crash recovery
- The database returns to a correct known state

---

## 7. Comparison Matrix

### Transaction and Recovery Concepts

| Aspect | Commit | Rollback | Recovery |
| --- | --- | --- | --- |
| **Purpose** | Save work permanently | Undo current work | Restore consistent state |
| **When used** | After success | After failure/error | After crash or restart |
| **Result** | Durable data | No change to committed records | Valid database state |
| **Typical use** | Finalize a transfer | Cancel a failed operation | Restart after outage |

---

## 8. Best Practices

### 1. Keep transactions short and controlled

**Avoid:** long-running transactions with many unrelated operations.

**Prefer:**
```sql
UPDATE accounts SET balance = balance - 500 WHERE id = 1;
UPDATE accounts SET balance = balance + 500 WHERE id = 2;
COMMIT;
```

**Why:** shorter transactions reduce recovery time and lock duration.

---

### 2. Use explicit COMMIT only after all logic succeeds

**Why:** commit is the final state change. If an error happens earlier, rollback should be used.

---

### 3. Test failure scenarios in critical workflows

**Why:** Data integrity depends on transaction behavior under pressure.

---

## 9. Common Mistakes

### Mistake 1: Forgetting to commit after an update

**Problem:** The changes remain uncommitted and may not be visible to others.

**Solution:** Issue COMMIT when the operation is valid.

---

### Mistake 2: Assuming a crash will preserve partial updates

**Problem:** Recovery logic will undo uncommitted operations.

**Solution:** Write transactions so they are atomic and properly committed.

---

### Mistake 3: Running long transactions with many side effects

**Problem:** Recovery becomes more expensive and more users may be blocked.

**Solution:** Break work into smaller, well-defined transactions.

---

## 10. Interview Q&A

### Conceptual Questions

**Q: What is a transaction?**
A: A transaction is a set of SQL statements treated as one logical unit. It is either fully committed or fully rolled back.

---

**Q: What is recovery?**
A: Recovery is the database process of restoring consistency after a crash, power failure, or storage issue.

---

### Comparison Questions

**Q: What is the difference between COMMIT and ROLLBACK?**
A: COMMIT permanently saves the transaction. ROLLBACK cancels it.

---

### Scenario Questions

**Q: A transfer between two accounts fails midway. What should happen?**
A: The transaction should be rolled back so neither account is left partially updated.

---

## 11. Revision Summary

### 1-Minute Recap

**Transaction** = all-or-nothing work; **recovery** = restoring the database after a failure.

- **COMMIT** → save permanently
- **ROLLBACK** → undo uncommitted changes
- **Redo log** → record changes for recovery
- **Undo** → revert incomplete work
- **Durability** → committed data survives crashes

### Interview Keywords

- **Atomicity** → all-or-nothing rule
- **Durability** → committed data is persistent
- **Redo log** → replay changes after crash
- **Undo** → reverse uncommitted work
- **Crash recovery** → restore database consistency

### Important Syntax

```sql
UPDATE accounts
SET balance = balance - 100
WHERE id = 1;

UPDATE accounts
SET balance = balance + 100
WHERE id = 2;

COMMIT;
```

---

**Done!** Recovery is what makes relational databases trustworthy: even after failures, the database can return to a consistent, committed state.
