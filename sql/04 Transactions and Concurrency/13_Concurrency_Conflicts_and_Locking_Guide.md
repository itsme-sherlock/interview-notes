# SQL Concurrency Conflicts and Locking Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Concurrency** = Multiple users or sessions working on the same data at the same time.
- **Lock** = Prevents conflicting access to rows or tables.
- **Blocking** = One session waits for another to finish using a resource.
- **Deadlock** = Two sessions wait on each other and neither can continue.
- **Isolation** = Defines how much one transaction sees of another transaction’s work.
- **Interview keyword** = Concurrency problems are usually about timing, not logic.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Concurrency Control?](#1-why-do-we-need-concurrency-control)
2. [What Is Concurrency in SQL?](#2-what-is-concurrency-in-sql)
3. [Locking Fundamentals](#3-locking-fundamentals)
4. [Shared and Exclusive Locks](#4-shared-and-exclusive-locks)
5. [Blocking and Deadlocks](#5-blocking-and-deadlocks)
6. [Isolation Levels](#6-isolation-levels)
7. [Comparison Matrix](#7-comparison-matrix)
8. [Best Practices](#8-best-practices)
9. [Common Mistakes](#9-common-mistakes)
10. [Interview Q&A](#10-interview-qa)
11. [Revision Summary](#11-revision-summary)

---

## 1. Why Do We Need Concurrency Control?

### The Problem: Many Users Touch the Same Data

Suppose two users try to update the same employee record at the same time:

```sql
-- Session A
UPDATE employees SET salary = salary + 500 WHERE employee_id = 101;

-- Session B
UPDATE employees SET salary = salary + 1000 WHERE employee_id = 101;
```

If they do not coordinate, one update may overwrite the other unexpectedly.

**Problems with concurrent writes:**
- Lost updates
- Wrong final values
- Long waits and blocking
- Deadlock situations

### The Solution: Concurrency Control

Databases manage concurrent access using locks and isolation behavior.

### Real-World Scenarios

- **Banking:** two withdrawals on the same account
- **Inventory:** two sales reduce the same stock item
- **Support tickets:** two agents update the same case

---

**➡ Transition:** Concurrency means multiple sessions are active at once, and SQL must keep them safe. 

---

## 2. What Is Concurrency in SQL?

### Simple Definition

**Concurrency** is the ability of multiple transactions to operate on the same database at the same time without corrupting the data.

### Key Characteristics

- Many sessions can read or write at once
- The database uses locks to avoid data corruption
- Isolation changes how much of each other’s work transactions see
- Good design reduces blocking and deadlocks

### Example

```sql
-- Session 1
UPDATE employees SET salary = 15000 WHERE employee_id = 101;

-- Session 2
SELECT * FROM employees WHERE employee_id = 101;
```

The second session may wait or see the old value depending on isolation and timing.

---

**➡ Transition:** The database controls concurrency using locks. 

---

## 3. Locking Fundamentals

### The Challenge

You need to prevent conflicting changes to the same row or table.

### How It Works

A lock tells the database: this resource is in use, and other transactions must wait or use a compatible mode.

### Common Lock Types

| Lock Type | Meaning | Typical Use |
| --- | --- | --- |
| Shared lock | Allows reads | SELECT queries |
| Exclusive lock | Prevents conflicting writes | UPDATE / DELETE / INSERT |
| Row lock | Single row lock | Specific row update |
| Table lock | Entire table lock | Large DDL or bulk updates |

### Example

```sql
SELECT * FROM employees WHERE employee_id = 101 FOR UPDATE;
```

This locks the selected row until the transaction ends.

### Why It Matters

- Protects data integrity
- Prevents lost updates
- Ensures transactional consistency

---

**➡ Transition:** Now let’s separate read locks from write locks. 

---

## 4. Shared and Exclusive Locks

### The Challenge

Reads and writes do not always have the same concurrency rules.

### How It Works

- **Shared lock**: multiple sessions can read at the same time
- **Exclusive lock**: prevents other sessions from changing the same resource until released

### Example

```sql
SELECT * FROM employees WHERE department_id = 10;
```

This may take a shared lock or read consistency view, depending on database behavior.

### Update example

```sql
UPDATE employees
SET salary = salary + 1000
WHERE employee_id = 101;
```

This requires an exclusive lock on the relevant row.

### Key Principle

Exclusive locks are stricter because they protect write operations.

---

**➡ Transition:** When a transaction waits on a lock, it causes blocking. 

---

## 5. Blocking and Deadlocks

### The Challenge

Sessions may wait for each other instead of progressing.

### How It Works

**Blocking** occurs when one transaction holds a lock another needs.

```text
Session A locks row 1
Session B locks row 2
Session A waits for row 2
Session B waits for row 1
```

This is a **deadlock**.

### Example

```sql
-- Session A
UPDATE employees SET salary = salary + 500 WHERE employee_id = 101;
UPDATE employees SET salary = salary + 500 WHERE employee_id = 102;

-- Session B
UPDATE employees SET salary = salary + 500 WHERE employee_id = 102;
UPDATE employees SET salary = salary + 500 WHERE employee_id = 101;
```

### Result

Oracle detects the cycle and ends one transaction, allowing the other to continue.

### Why It Matters

- Blocking slows application throughput
- Deadlocks fail transactions unless designed carefully
- Ordering lock acquisition prevents many deadlocks

---

**➡ Transition:** Isolation levels define how much one transaction sees from another. 

---

## 6. Isolation Levels

### The Challenge

How much visibility should a transaction have to another transaction’s uncommitted changes?

### How It Works

Isolation controls how transactions interact with each other.

### Common Levels

| Level | Meaning |
| --- | --- |
| READ COMMITTED | Sees committed data only |
| SERIALIZABLE | Strong consistency, higher restrictions |
| READ UNCOMMITTED | Not used in Oracle as a business-safe standard |

### Oracle default

Oracle uses **READ COMMITTED** by default.

### Example

```sql
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
```

This can reduce inconsistent reads but may increase locking and wait time.

---

## 7. Comparison Matrix

### Concurrency Controls

| Aspect | Locking | Isolation | Deadlock |
| --- | --- | --- | --- |
| **Purpose** | Prevent conflicts | Control visibility | Resolve circular waits |
| **Used when** | During reads/writes | During transaction execution | During simultaneous updates |
| **Impact** | Waits or blocking | Read consistency vs concurrency | Failed transaction |
| **Best practice** | Short locks, consistent ordering | Choose the correct isolation | Avoid circular lock order |

---

## 8. Best Practices

### 1. Keep transactions short

**Why:** Shorter transactions hold locks for less time and reduce blocking.

---

### 2. Access rows in a consistent order

```sql
UPDATE employees SET ... WHERE employee_id = 101;
UPDATE employees SET ... WHERE employee_id = 102;
```

**Why:** Consistent ordering reduces deadlock risk.

---

### 3. Avoid unnecessary long reads in a transaction

**Why:** Long read transactions can create lock contention and performance issues.

---

## 9. Common Mistakes

### Mistake 1: Updating many rows without filtering

**Problem:** This increases lock scope and can block other sessions.

**Solution:** Use precise WHERE clauses.

---

### Mistake 2: Assuming no lock means no conflict

**Problem:** Reads and writes still have concurrency implications.

**Solution:** Understand the database’s isolation rules and lock behavior.

---

### Mistake 3: Ignoring deadlock risk in multi-step operations

**Problem:** Different session orderings cause circular waits.

**Solution:** Lock objects consistently across the application.

---

## 10. Interview Q&A

### Conceptual Questions

**Q: What is a lock in SQL?**
A: A lock is a database mechanism that prevents conflicting access to a row or table while a transaction is working with it.

---

**Q: What is a deadlock?**
A: A deadlock is a circular wait where two transactions hold locks that the others need.

---

### Comparison Questions

**Q: What is the difference between blocking and deadlock?**
A: Blocking is one session waiting for another session’s lock. Deadlock is a cycle of waits where neither transaction can proceed.

---

### Scenario Questions

**Q: Two users update the same row at the same time. What happens?**
A: One update may wait for the lock; the database protects correctness and may serialize the actions or detect a deadlock if the transaction ordering is bad.

---

## 11. Revision Summary

### 1-Minute Recap

**Concurrency** = multiple sessions working at once; **locking** keeps them safe.

- **Lock** → protects resources from conflicting operations
- **Blocking** → one session waits
- **Deadlock** → circular wait
- **Isolation** → how visible other transactions are

### Interview Keywords

- **Lost update** → overwritten change
- **Serializable** → stronger isolation
- **Read committed** → Oracle default consistency model
- **Row lock** → lock one record
- **Table lock** → lock the whole table

### Important Syntax

```sql
SELECT * FROM employees WHERE employee_id = 101 FOR UPDATE;

UPDATE employees
SET salary = salary + 500
WHERE employee_id = 101;
```

---

**Done!** Concurrency control is what allows a database to serve many users safely without corrupting data or creating inconsistent views.
