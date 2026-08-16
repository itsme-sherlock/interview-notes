# PL/SQL Transactions and Autonomous Transactions Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Transaction** = A logical unit of work committed or rolled back as one unit.
- **`COMMIT`** = Makes changes durable and releases transaction locks.
- **`ROLLBACK`** = Undoes uncommitted changes.
- **`SAVEPOINT`** = Marks a point for partial rollback.
- **Autonomous transaction** = Independent transaction inside a PL/SQL routine.
- **Atomicity rule:** A reusable routine should not commit work it does not own.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Transaction Control?](#1-why-do-we-need-transaction-control)
2. [What Is a Transaction?](#2-what-is-a-transaction)
3. [COMMIT, ROLLBACK, and SAVEPOINT](#3-commit-rollback-and-savepoint)
4. [Autonomous Transactions](#4-autonomous-transactions)
5. [Transaction Design](#5-transaction-design)
6. [Comparison Matrix](#6-comparison-matrix)
7. [Best Practices](#7-best-practices)
8. [Common Mistakes](#8-common-mistakes)
9. [Interview Q&A](#9-interview-qa)
10. [Revision Summary](#10-revision-summary)

---

## 1. Why Do We Need Transaction Control?

An employee transfer may update a department, salary, and audit record. Committing after only one step can leave inconsistent data if a later step fails.

---

## 2. What Is a Transaction?

A transaction is a group of DML changes treated as one logical unit. The caller decides when the unit succeeds or fails.

```text
Begin work -> validate -> perform DML -> commit
                         \-> error -> rollback
```

DDL generally performs implicit commits, so dynamic DDL must be designed carefully.

---

## 3. COMMIT, ROLLBACK, and SAVEPOINT

```sql
SAVEPOINT before_bonus;

UPDATE employees SET salary = salary * 1.05
WHERE department_id = 10;

-- Undo only work after the savepoint when validation fails.
ROLLBACK TO before_bonus;

-- Or make all remaining work durable.
COMMIT;
```

`ROLLBACK` without a savepoint undoes all uncommitted work in the transaction. A savepoint is not durable and is cleared by commit.

---

## 4. Autonomous Transactions

```sql
CREATE OR REPLACE PROCEDURE log_error(p_message VARCHAR2)
IS
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  INSERT INTO error_log(message, created_at)
  VALUES (p_message, SYSTIMESTAMP);
  COMMIT;
END;
/
```

The logger can commit even if the caller later rolls back. It must commit or roll back before returning, and it can deadlock if it tries to access rows locked by its parent transaction.

---

## 5. Transaction Design

Define the transaction boundary at the business operation level. A procedure that is one complete command may own the transaction; a reusable helper normally should not. Use savepoints for controlled partial recovery and explicit error propagation.

---

## 6. Comparison Matrix

| Operation | Effect | Typical use |
| --- | --- | --- |
| `COMMIT` | Persist all pending DML | Successful business unit |
| `ROLLBACK` | Undo all pending DML | Failed operation |
| `ROLLBACK TO` | Undo after savepoint | Partial recovery |
| Autonomous commit | Persist independent work | Error/audit log |

---

## 7. Best Practices

1. Document who owns commit and rollback.
2. Keep transactions short to reduce locks.
3. Use savepoints sparingly and name them clearly.
4. Make autonomous logging small and independent.
5. Never hide a failed transaction by swallowing the exception.

---

## 8. Common Mistakes

- Committing inside a low-level helper.
- Assuming a procedure call automatically commits.
- Using autonomous transactions to bypass normal consistency.
- Forgetting to commit or roll back an autonomous routine.
- Performing DDL in the middle of a DML transaction without considering implicit commits.

---

## 9. Interview Q&A

**Q: What does `ROLLBACK TO SAVEPOINT` do?**

A: It undoes changes after the named savepoint while retaining earlier changes in the transaction.

**Q: Why use an autonomous transaction for error logging?**

A: The log can remain committed even when the parent transaction fails and rolls back.

**Q: Why can an autonomous logger deadlock?**

A: It is a separate transaction but may need a row lock held by the parent transaction that is waiting for the logger to finish.

**Q: Who should commit in a reusable procedure?**

A: Usually the caller, unless the procedure explicitly owns the entire business transaction.

---

## 10. Revision Summary

- **Transaction** -> logical unit of DML
- **Commit** -> durable success
- **Rollback** -> undo pending work
- **Savepoint** -> partial rollback marker
- **Autonomous transaction** -> independent commit scope

```sql
BEGIN
  do_work;
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END;
/
```
