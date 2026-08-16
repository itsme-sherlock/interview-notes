# SQL Transaction Isolation and Consistency Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Isolation level** = How much one transaction can see from another.
- **Read Committed** = Oracle default; sees committed data only.
- **Serializable** = Stronger consistency, more locking, less concurrency.
- **Consistency** = Data remains valid and logical across transactions.
- **Interview keyword** = Isolation is a trade-off between consistency and concurrency.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Isolation?](#1-why-do-we-need-isolation)
2. [What Is Transaction Isolation?](#2-what-is-transaction-isolation)
3. [Read Committed](#3-read-committed)
4. [Serializable](#4-serializable)
5. [Consistency vs Concurrency](#5-consistency-vs-concurrency)
6. [Comparison Matrix](#7-comparison-matrix)
7. [Best Practices](#8-best-practices)
8. [Common Mistakes](#9-common-mistakes)
9. [Interview Q&A](#10-interview-qa)
10. [Revision Summary](#11-revision-summary)

---

## 1. Why Do We Need Isolation?

### The Problem: Users See Each Other’s Half-Finished Work

Imagine one transaction is updating salaries and another is reading them at the same time.

```sql
-- Session A
UPDATE employees SET salary = salary + 500 WHERE department_id = 10;

-- Session B
SELECT * FROM employees WHERE department_id = 10;
```

A user may see partial state or inconsistent results if isolation is weak.

**Problems with weak isolation:**
- Dirty reads
- Inconsistent reads
- Contradictory report numbers
- Data not matching business truth

### The Solution: Isolation Levels

Isolation defines how much of another transaction’s uncommitted or concurrent work is visible.

### Real-World Scenarios

- **Accounting:** reads must reflect committed records, not uncommitted ones
- **Reporting:** managers may need stable data snapshots
- **Batch jobs:** avoid conflict with active transactional updates

---

**➡ Transition:** Now let’s define what transaction isolation means in practical terms. 

---

## 2. What Is Transaction Isolation?

### Simple Definition

**Isolation** is the rule that controls how one transaction interacts with other transactions while they are running concurrently.

### Key Characteristics

- Protects data consistency
- Prevents dirty reads
- Balances performance and correctness
- Chosen per transaction or database configuration

### Why It Matters

A database without isolation rules would expose half-finished changes and create confusing, unreliable results.

---

**➡ Transition:** Oracle’s default isolation is READ COMMITTED, which is the most common model. 

---

## 3. Read Committed

### The Challenge

You want each query to see committed data only, while still allowing concurrency.

### How It Works

In Oracle, a query sees only committed data as of the time the statement started.

### Example

```sql
SELECT * FROM employees WHERE department_id = 10;
```

This query will not see an uncommitted update from another session.

### Benefits

- Good concurrency
- Prevents dirty reads
- Default for many systems

### Limitation

The same query run twice in the same transaction may see different data if another transaction committed in between.

---

**➡ Transition:** Stronger isolation is sometimes needed for consistent read snapshots across a transaction. 

---

## 4. Serializable

### The Challenge

You need a transaction to behave as if no other transaction is modifying the data concurrently.

### How It Works

`SERIALIZABLE` isolation provides a stronger guarantee that reads are repeatable and other concurrent work does not interfere with the transaction.

### Example

```sql
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT * FROM employees;
```

### Benefits

- More predictable for reporting and financial logic
- Reduces anomalies from concurrent modifications
- Useful for batch and reconciliation processes

### Cost

- More locking
- Lower concurrency
- Higher chance of blocking / wait time

---

**➡ Transition:** The real trade-off is between strict consistency and throughput. 

---

## 5. Consistency vs Concurrency

### The Challenge

A database must decide how much locking and waiting is acceptable.

### How It Works

Stronger isolation gives better consistency, but sacrifices concurrency.

### Example

| Level | Consistency | Concurrency |
| --- | --- | --- |
| READ COMMITTED | Good | High |
| SERIALIZABLE | Strongest | Lower |

### Why It Matters

In OLTP systems, high concurrency is often more important than very strict consistency. In financial or reconciliation workloads, stronger isolation may be required.

### Rule of Thumb

- Choose the weakest isolation that still satisfies the business rule
- Avoid overly strict isolation unless the application truly needs it

---

## 6. Comparison Matrix

### Isolation Models

| Aspect | READ COMMITTED | SERIALIZABLE |
| --- | --- | --- |
| **Sees uncommitted data?** | No | No |
| **Repeats read** | May vary | Stable within transaction |
| **Concurrency** | Higher | Lower |
| **Locking** | Lower | Higher |
| **Typical use** | OLTP | Strict reporting / critical logic |

---

## 7. Best Practices

### 1. Use the default Oracle isolation unless the business rule requires more

**Why:** Default isolation usually delivers good balance between consistency and throughput.

---

### 2. Keep transactions short when using strong isolation

**Why:** Longer transactions increase lock duration and blocking risk.

---

### 3. Consider business semantics before setting serializable mode

**Why:** Stronger isolation is not always necessary and may reduce performance.

---

## 8. Common Mistakes

### Mistake 1: Assuming a read always sees the latest committed result in a transaction

**Problem:** In read committed mode, a statement sees the committed state as of statement start.

**Solution:** Understand the database semantics before assuming consistency across multiple queries.

---

### Mistake 2: Using serializable mode for every workload

**Problem:** This unnecessarily increases lock contention.

**Solution:** Use stronger isolation only when required.

---

### Mistake 3: Ignoring the concurrency cost of stricter isolation

**Problem:** The application may become slow under load.

**Solution:** Choose the minimum needed isolation based on business requirements.

---

## 9. Interview Q&A

### Conceptual Questions

**Q: What is isolation in a database?**
A: Isolation is the degree to which transactions are protected from interference by other transactions.

---

**Q: What is the default isolation in Oracle?**
A: Oracle commonly uses READ COMMITTED as the default behavior.

---

### Comparison Questions

**Q: Why would you choose SERIALIZABLE over READ COMMITTED?**
A: SERIALIZABLE gives stronger consistency and repeatable reads, which may be useful in financial or reconciliation logic.

---

### Scenario Questions

**Q: A reporting transaction must show a stable view of the data even while other sessions are updating it. What isolation is appropriate?**
A: A more restrictive isolation, such as SERIALIZABLE, may be appropriate if the business requires a stable snapshot.

---

## 10. Revision Summary

### 1-Minute Recap

**Isolation** = how transactions are protected from each other.

- **READ COMMITTED** → default Oracle model, sees committed data only
- **SERIALIZABLE** → stronger consistency, lower concurrency
- **Consistency vs concurrency** → always a trade-off

### Interview Keywords

- **Dirty read** → reading uncommitted data
- **Repeatable read** → stable result within transaction
- **Lock contention** → waiting for locks
- **Consistency model** → rules governing transaction visibility

### Important Syntax

```sql
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
```

---

**Done!** Isolation is the database rule that decides how much concurrent activity is visible, and it is central to safe multi-user systems.
