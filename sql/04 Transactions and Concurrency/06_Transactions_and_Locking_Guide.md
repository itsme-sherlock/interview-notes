# SQL Transactions and Locking Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Transaction** = A logical unit of work that must succeed or fail as a whole.
- **COMMIT** = Saves all changes permanently.
- **ROLLBACK** = Undoes uncommitted changes.
- **SAVEPOINT** = Creates a restore point inside a transaction.
- **Lock** = Prevents two transactions from changing the same data simultaneously.
- **Deadlock** = Two sessions wait on each other and block progress.
- **Isolation level** = Controls how much one transaction can see from another.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Transactions and Locking?](#1-why-do-we-need-transactions-and-locking)
2. [What Is a Transaction?](#2-what-is-a-transaction)
3. [COMMIT, ROLLBACK, and SAVEPOINT](#3-commit-rollback-and-savepoint)
4. [ACID Properties](#4-acid-properties)
5. [Locking Basics](#5-locking-basics)
6. [Types of Locks](#6-types-of-locks)
7. [Isolation Levels](#7-isolation-levels)
8. [Deadlocks and Blocking](#8-deadlocks-and-blocking)
9. [Best Practices](#9-best-practices)
10. [Common Mistakes](#10-common-mistakes)
11. [Interview Q&A](#11-interview-qa)
12. [Revision Summary](#12-revision-summary)

---

## 1. Why Do We Need Transactions and Locking?

### The Problem: Multiple Users Change the Same Data

In a real database, different users can update the same row at the same time.

```sql
UPDATE employees
SET salary = salary + 1000
WHERE employee_id = 101;
```

If another user also updates the same employee simultaneously, the final result can be wrong or inconsistent.

**Problems with concurrent updates:**
- Lost updates
- Inconsistent values
- Partial data writes
- One user blocking another user

### The Solution: Transactions and Locking

A transaction groups database changes into a single unit, and locking prevents conflicts between sessions.

### Real-World Scenarios

- **Banking:** Transfer money from one account to another must succeed completely or not at all.
- **Inventory:** Update stock count and order record together.
- **HR:** Salary changes should not be partially saved.

---

**➡ Transition:** Let’s define what a transaction really is and why it matters so much in SQL. 

---

## 2. What Is a Transaction?

### Simple Definition

A **transaction** is a set of SQL statements treated as one logical unit. Either all changes are committed, or none are saved.

### Analogy: Real-World Comparison

**Think of a bank transfer**:
- Debit one account
- Credit another account
- If either step fails, the whole transfer must be reversed

### Key Characteristics

- **Atomic:** All-or-nothing behavior
- **Consistent:** Data remains valid after the transaction
- **Isolated:** Other users do not see partial changes
- **Durable:** Committed data survives system failures

### ACID Rule

Transactions follow the ACID model:
- Atomicity
- Consistency
- Isolation
- Durability

---

**➡ Transition:** The main commands that control a transaction are COMMIT, ROLLBACK, and SAVEPOINT. 

---

## 3. COMMIT, ROLLBACK, and SAVEPOINT

### The Challenge

You need control over when database changes become permanent and when they are discarded.

### How It Works

- `COMMIT` permanently saves the transaction.
- `ROLLBACK` cancels the transaction.
- `SAVEPOINT` marks a middle point so you can rollback only part of the work.

### Syntax/Usage

```sql
UPDATE employees
SET salary = salary + 500
WHERE employee_id = 101;

SAVEPOINT before_bonus;

UPDATE employees
SET salary = salary + 2000
WHERE employee_id = 102;

ROLLBACK TO before_bonus;
COMMIT;
```

### Example

```sql
UPDATE accounts
SET balance = balance - 1000
WHERE account_id = 1;

UPDATE accounts
SET balance = balance + 1000
WHERE account_id = 2;

COMMIT;
```

This ensures both updates are saved together.

### When to Use Savepoints

- Partial rollback in a long script
- Testing a risky update before final commit
- Recovery from a failed step in a multi-step operation

---

**➡ Transition:** Transactions are powerful because they preserve logical correctness. That is explained by the ACID properties. 

---

## 4. ACID Properties

### The Challenge

A database must behave predictably even when multiple users work at once.

### How It Works

ACID properties define reliable transaction behavior.

### A: Atomicity

All statements inside the transaction are treated as one unit.

### C: Consistency

The database moves from one valid state to another valid state.

### I: Isolation

One transaction is protected from seeing another transaction’s partial changes.

### D: Durability

Once committed, data is not lost even after a crash.

### Example

```sql
BEGIN
  UPDATE accounts SET balance = balance - 500 WHERE id = 1;
  UPDATE accounts SET balance = balance + 500 WHERE id = 2;
  COMMIT;
END;
```

If the second update fails, the entire transaction can be rolled back.

---

**➡ Transition:** To prevent conflicting changes, databases enforce locking. 

---

## 5. Locking Basics

### The Challenge

Two sessions should not both change the same row at the same time without coordination.

### How It Works

A lock tells the database: “This row/table is in use; do not modify it concurrently in a conflicting way.”

### Example

```sql
UPDATE employees
SET salary = salary + 1000
WHERE employee_id = 101;
```

While this update is in progress, other transactions may wait or be blocked depending on the lock type and isolation level.

### Why Locking Matters

- Prevents lost updates
- Protects data integrity
- Keeps concurrent transactions safe

---

**➡ Transition:** Different lock types are used depending on whether the operation is read-only or write-related. 

---

## 6. Types of Locks

### The Challenge

Not all operations need the same lock strength.

### How It Works

Database locks are usually categorized as row locks, table locks, shared locks, and exclusive locks.

### Common Lock Types

| Lock Type | Meaning | Typical Use |
| --- | --- | --- |
| Shared Lock | Read lock | SELECT queries |
| Exclusive Lock | Write lock | UPDATE / DELETE / INSERT |
| Row Lock | Lock one row | Single-row update |
| Table Lock | Lock whole table | Large destructive changes |

### Example

```sql
SELECT * FROM employees
FOR UPDATE;
```

This places a row-level lock on the selected rows so no other session can update them until the transaction ends.

### Key Point

Locks are usually automatic. You do not always write lock commands manually, but you need to understand the behavior.

---

**➡ Transition:** The balance between concurrency and consistency is controlled by isolation levels. 

---

## 7. Isolation Levels

### The Challenge

How much should one transaction see from another transaction that has not yet committed?

### How It Works

Isolation levels define visibility of uncommitted data and locking behavior.

### Common Isolation Levels

| Level | Behavior |
| --- | --- |
| READ COMMITTED | Default in Oracle. Sees committed data only. |
| SERIALIZABLE | Stronger guarantee; prevents phantom reads and inconsistent reads. |
| READ UNCOMMITTED | Not supported in Oracle as a standard isolation mode. |

### Oracle Behavior

Oracle primarily uses **READ COMMITTED** by default. It ensures a query sees only committed data as of the time the query started.

### Example

```sql
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
```

This increases consistency, but may reduce concurrency or create more blocking.

---

**➡ Transition:** The biggest operational problem with locking is when transactions block each other forever. 

---

## 8. Deadlocks and Blocking

### The Challenge

Two transactions may each hold a lock that the other transaction needs, creating a cycle.

### How It Works

This is called a **deadlock**. The database detects it and kills one transaction to break the cycle.

### Example

```text
Session A: updates row 1, waits for row 2
Session B: updates row 2, waits for row 1
```

Neither can proceed. Oracle detects the deadlock and chooses one to roll back.

### Blocking

A session may wait for another session to release a lock before continuing. This is called **blocking**.

### Why It Matters

- Deadlocks can fail transactions unexpectedly
- Blocking reduces throughput
- Application design should avoid long transactions and lock ordering issues

---

## 9. Best Practices

### 1. Keep transactions short

**Avoid:** Long transactions with many business checks and manual waits.

**Prefer:**
```sql
UPDATE employees
SET salary = salary + 500
WHERE employee_id = 101;
COMMIT;
```

**Why:** Short transactions reduce lock duration and blocking.

---

### 2. Use `WHERE` carefully in UPDATE and DELETE

```sql
UPDATE employees
SET salary = salary + 100
WHERE employee_id = 101;
```

**Why:** This avoids accidental updates to many rows and reduces lock scope.

---

### 3. Use savepoints for complex multi-step logic

```sql
SAVEPOINT before_repricing;
-- risky updates
ROLLBACK TO before_repricing;
```

**Why:** Savepoints let you back out a step without losing the full transaction.

---

## 10. Common Mistakes

### Mistake 1: Forgetting to COMMIT after changes

**Problem:** Data remains uncommitted and may not be visible to other sessions.

**Solution:**
```sql
UPDATE employees SET salary = salary + 500 WHERE employee_id = 101;
COMMIT;
```

---

### Mistake 2: Using a very broad UPDATE or DELETE

**Problem:** This locks more rows and creates more blocking.

**Solution:** Always scope the update to the correct rows.

---

### Mistake 3: Ignoring deadlock risk in multi-step transactions

**Problem:** Sessions may lock resources in different orders and deadlock.

**Solution:** Lock rows in a consistent order across the application.

---

## 11. Interview Q&A

### Conceptual Questions

**Q: What is a transaction?**
A: A transaction is a group of SQL statements that works as one unit. It is committed together or rolled back together.

---

**Q: What is a deadlock?**
A: A deadlock is a circular wait where two sessions hold locks needed by each other.

---

### Comparison Questions

**Q: What is the difference between COMMIT and ROLLBACK?**
A: `COMMIT` saves changes permanently. `ROLLBACK` undoes them.

---

### Scenario Questions

**Q: You need to transfer money from one account to another. What should you do?**
A: Use a transaction with both debit and credit operations, then commit only when both succeed. If either fails, rollback the whole transaction.

---

## 12. Revision Summary

### 1-Minute Recap

**Transaction** = One unit of work that must be all-or-nothing.

- **COMMIT** → save changes
- **ROLLBACK** → undo changes
- **SAVEPOINT** → partial rollback point
- **Lock** → protects concurrent data access
- **Deadlock** → circular waiting condition
- **Isolation** → controls how visible other transactions are

### Interview Keywords

- **Atomicity** → all changes succeed or fail together
- **Consistency** → valid database state
- **Isolation** → separate transaction visibility
- **Durability** → committed data persists
- **Blocking** → session waits for lock release

### Important Syntax

```sql
UPDATE accounts
SET balance = balance - 500
WHERE account_id = 1;

SAVEPOINT before_transfer;

UPDATE accounts
SET balance = balance + 500
WHERE account_id = 2;

COMMIT;
```

---

**Done!** Transactions and locking are the backbone of reliable database behavior under concurrent usage.
