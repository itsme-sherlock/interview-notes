# SQL Transactions and Locking Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Transaction** = Series of DML statements (INSERT/UPDATE/DELETE) treated as one atomic unit; COMMIT or ROLLBACK all-or-nothing.
- **ACID Properties** = Atomicity (all-or-nothing), Consistency (valid state), Isolation (no interference), Durability (persistent after COMMIT).
- **Lock** = Prevents concurrent access to data; row-level or table-level; acquired automatically on DML.
- **Row Lock** = Locks specific row; allows other rows to be accessed (more concurrency; row-level locking).
- **Table Lock** = Locks entire table; prevents all access (less concurrency; used for bulk operations).
- **Deadlock** = Two transactions wait for each other's locks; Oracle detects and kills one transaction (ORA-00060).
- **Isolation Level** = Determines visibility of uncommitted changes (READ COMMITTED vs SERIALIZABLE).
- **COMMIT** = Makes changes permanent and releases locks; other sessions see changes.
- **ROLLBACK** = Undoes changes and releases locks; reverts to before transaction start.
- **Interview keywords** = ACID, lock types, deadlock detection, isolation levels, wait-for-graph, redo logs.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Transactions?](#1-why-do-we-need-transactions)
2. [What Are Transactions?](#2-what-are-transactions)
3. [ACID Properties](#3-acid-properties)
4. [Starting and Ending Transactions](#4-starting-and-ending-transactions)
5. [COMMIT: Making Changes Permanent](#5-commit-making-changes-permanent)
6. [ROLLBACK: Undoing Changes](#6-rollback-undoing-changes)
7. [SAVEPOINT: Partial Rollback](#7-savepoint-partial-rollback)
8. [Introduction to Locks](#8-introduction-to-locks)
9. [Row-Level Locking](#9-row-level-locking)
10. [Table-Level Locking](#10-table-level-locking)
11. [Deadlock: Cause and Detection](#11-deadlock-cause-and-detection)
12. [Lock Wait and Timeout](#12-lock-wait-and-timeout)
13. [Common Mistakes](#13-common-mistakes)
14. [Interview Q&A](#14-interview-qa)
15. [Revision Summary](#15-revision-summary)

---

## 1. Why Do We Need Transactions?

### The Problem: Data Consistency Without Transactions

**Scenario:** Bank transfer: Move $100 from Account A to Account B.

**Steps:**
1. Debit Account A by $100
2. Credit Account B by $100

**Without transactions (disaster scenario):**
```sql
-- Step 1: Debit A
UPDATE accounts SET balance = balance - 100 WHERE account_id = 'A';
-- System crashes here!
-- Step 2 never executes
-- Result: $100 disappeared from system (consistency violation)

-- Step 2: Credit B (never runs because crash)
UPDATE accounts SET balance = balance + 100 WHERE account_id = 'B';
```

**Data inconsistency:** Money is missing; total balance is wrong.

### The Solution: Transaction (All-or-Nothing)

```sql
-- BEGIN implicit transaction
UPDATE accounts SET balance = balance - 100 WHERE account_id = 'A';
UPDATE accounts SET balance = balance + 100 WHERE account_id = 'B';
COMMIT;  -- Only if BOTH updates succeed

-- If crash before COMMIT: everything rolls back (neither statement takes effect)
-- If crash after COMMIT: both changes are permanent (durable)
```

**Guarantees:**
- Both updates happen, or neither happens (Atomicity)
- Money is conserved (Consistency)
- No interference from other transactions (Isolation)
- Once committed, changes survive crashes (Durability)

### Real-World Scenarios

- **Banking:** Transfers must be atomic (debit + credit)
- **Inventory:** Order placement (reserve stock + update order status)
- **Payroll:** Multiple employees; all raises happen or none
- **E-Commerce:** Order, payment, shipping coordination

---

**➡ Transition:** Transactions are based on ACID properties.

---

## 2. What Are Transactions?

### Simple Definition

A **transaction** is a logical unit of work consisting of one or more SQL statements. Either all statements execute successfully (COMMIT) or all are undone (ROLLBACK).

### Visual Flow

```
Transaction Start (Implicit)
  ↓
DML Statement 1 (INSERT/UPDATE/DELETE)
  ↓
DML Statement 2
  ↓
DML Statement N
  ↓
COMMIT (Success) → Changes permanent, locks released
   OR
ROLLBACK (Failure) → Changes undone, locks released
```

### Key Points

1. **Implicit start:** First DML starts transaction (no BEGIN needed in Oracle)
2. **Explicit end:** COMMIT or ROLLBACK ends transaction
3. **All-or-nothing:** One error can roll back entire transaction

---

**➡ Transition:** ACID explains WHY transactions matter.

---

## 3. ACID Properties

### Atomicity: All-or-Nothing

```sql
BEGIN
    UPDATE account_a SET balance = balance - 100;
    UPDATE account_b SET balance = balance + 100;
    COMMIT;
    -- BOTH succeed, or BOTH fail (never partially succeed)
END;
```

### Consistency: Valid State

**Scenario:** Business rule: balance >= 0 (can't be negative)

```sql
-- ❌ VIOLATES consistency
UPDATE accounts SET balance = -50 WHERE account_id = 'A';
COMMIT;  -- Database allows, but violates business rule

-- ✅ MAINTAINS consistency (check constraints)
ALTER TABLE accounts ADD CONSTRAINT check_balance CHECK (balance >= 0);
UPDATE accounts SET balance = -50;  -- Fails: violates constraint
```

### Isolation: No Interference

```sql
-- Transaction 1
BEGIN
    UPDATE employees SET salary = salary * 1.1 WHERE department_id = 10;
    -- Mid-transaction; changes not yet visible to others
END;

-- Transaction 2 (concurrent, other session)
BEGIN
    SELECT SUM(salary) FROM employees WHERE department_id = 10;
    -- Sees OLD salaries (before Transaction 1 commits)
END;
```

### Durability: Permanent After COMMIT

```sql
UPDATE accounts SET balance = balance + 1000;
COMMIT;  -- Written to redo log; surviving system crash

-- Even if server crashes 1 second after COMMIT
-- Changes are still in database (recovered from redo log)
```

---

**➡ Transition:** Let's control transactions explicitly.

---

## 4. Starting and Ending Transactions

### Implicit Transaction Start

In Oracle, first DML starts a transaction automatically:

```sql
-- No explicit BEGIN
UPDATE employees SET salary = salary * 1.1;  -- Transaction starts here
INSERT INTO audit_log VALUES (...);
DELETE FROM temp_data WHERE id = 1;
COMMIT;  -- Transaction ends here
```

### Explicit Transaction Control

```sql
SAVEPOINT sp1;  -- Marker (not really "start" but checkpoint)

UPDATE account_a SET balance = balance - 100;

SAVEPOINT sp2;  -- Another marker

UPDATE account_b SET balance = balance + 100;

COMMIT;  -- End transaction
```

### Ending Transaction

```sql
-- Option 1: COMMIT (success)
COMMIT;  -- Changes permanent; locks released

-- Option 2: ROLLBACK (failure)
ROLLBACK;  -- Undo all changes; locks released

-- Option 3: Exit session (auto-COMMIT or ROLLBACK depends on setting)
EXIT;  -- Default: auto-ROLLBACK on exit
```

---

**➡ Transition:** COMMIT makes changes permanent.

---

## 5. COMMIT: Making Changes Permanent

### What COMMIT Does

```sql
UPDATE products SET price = 100 WHERE product_id = 1;
-- Change is in memory buffer; not yet visible to others

COMMIT;
-- 1. Write to redo log (disk)
-- 2. Make changes visible to other sessions
-- 3. Release all locks
-- 4. Mark transaction complete
```

### Visibility After COMMIT

```sql
-- Session A
UPDATE customers SET name = 'John' WHERE customer_id = 1;
COMMIT;  -- Changes written; visible to others

-- Session B (concurrent)
SELECT name FROM customers WHERE customer_id = 1;
-- Sees 'John' (changes from Session A after COMMIT)
```

### Durability: Survives Crash

```sql
UPDATE bank_account SET balance = balance + 1000;
COMMIT;  -- Written to redo log

-- Server crashes 1 second later
-- Restart database
-- Balance change still there (recovered from redo log)
```

---

**➡ Transition:** ROLLBACK undoes changes.

---

## 6. ROLLBACK: Undoing Changes

### What ROLLBACK Does

```sql
UPDATE accounts SET balance = balance - 1000 WHERE account_id = 'A';
INSERT INTO audit_log VALUES ('Transfer A to B');
UPDATE accounts SET balance = balance + 1000 WHERE account_id = 'B';

-- Something goes wrong (validation error, etc.)
ROLLBACK;
-- 1. Undo ALL statements (back to start of transaction)
-- 2. Release all locks
-- 3. Mark transaction aborted
```

### Complete Reversal

```sql
-- Before transaction
SELECT * FROM accounts;
-- Account A: 5000, Account B: 2000

-- During transaction
UPDATE accounts SET balance = 5000 - 1000 WHERE account_id = 'A';  -- A: 4000
UPDATE accounts SET balance = 2000 + 1000 WHERE account_id = 'B';  -- B: 3000

-- After ROLLBACK
SELECT * FROM accounts;
-- Account A: 5000, Account B: 2000 (back to original)
```

### Error Recovery

```sql
BEGIN
    INSERT INTO orders VALUES (101, 'Product X', 50);
    UPDATE inventory SET quantity = quantity - 50 WHERE product_id = 'X';
    
    -- Check if inventory went negative
    IF (SELECT quantity FROM inventory WHERE product_id = 'X') < 0 THEN
        ROLLBACK;  -- Undo both statements
        RAISE_APPLICATION_ERROR(-20001, 'Insufficient inventory');
    END IF;
    
    COMMIT;  -- Only if both statements are valid
END;
```

---

**➡ Transition:** SAVEPOINT allows partial rollback.

---

## 7. SAVEPOINT: Partial Rollback

### Concept: Rollback to Checkpoint

```sql
UPDATE account_a SET balance = balance - 100;
SAVEPOINT sp1;  -- Checkpoint 1

UPDATE account_b SET balance = balance + 50;
SAVEPOINT sp2;  -- Checkpoint 2

UPDATE account_c SET balance = balance + 50;

-- If error here:
ROLLBACK TO sp2;  -- Undo account_c only; sp1 and account_a remain
COMMIT;  -- Commit account_a and account_b updates
```

### Flow with SAVEPOINT

```
Transaction Start
  ↓
UPDATE A (balance: 5000 → 4900)
  ↓
SAVEPOINT sp1
  ↓
UPDATE B (balance: 2000 → 2050)
  ↓
SAVEPOINT sp2
  ↓
UPDATE C (balance: 3000 → 3050)  ← ERROR here
  ↓
ROLLBACK TO sp2  ← Undo C; revert to sp2
  ↓
A and B changes remain
COMMIT ← Saves A and B; C never happened
```

### Example: Multi-Table Insert with Partial Rollback

```sql
INSERT INTO orders VALUES (101, 'Customer X', SYSDATE);
SAVEPOINT sp1;

INSERT INTO order_items VALUES (101, 'Product A', 2);
INSERT INTO order_items VALUES (101, 'Product B', 3);
SAVEPOINT sp2;

INSERT INTO order_items VALUES (101, 'Product C', -5);  -- ERROR: negative qty

ROLLBACK TO sp2;  -- Undo Product C insert
-- Products A and B remain

COMMIT;  -- Saves order and items A and B
```

---

**➡ Transition:** Locks prevent conflicts.

---

## 8. Introduction to Locks

### What Are Locks?

**Lock** = Mechanism to prevent concurrent access to data; acquired when DML runs; released at COMMIT/ROLLBACK.

### Lock Types

```
Locks
├─ Row Lock (row-level exclusive lock)
│  ├─ Acquired by UPDATE, DELETE, INSERT
│  ├─ Allows other rows to be accessed
│  └─ Better concurrency
└─ Table Lock (table-level, various modes)
   ├─ Acquired during DDL or explicit LOCK TABLE
   ├─ Locks entire table
   └─ Less concurrency
```

---

**➡ Transition:** Row locks are fine-grained.

---

## 9. Row-Level Locking

### Automatic Row Locking

```sql
-- Session A
UPDATE employees SET salary = salary * 1.1 WHERE employee_id = 1;
-- Row 1 is now locked (write lock)

-- Session B (concurrent, other session)
UPDATE employees SET salary = salary * 1.1 WHERE employee_id = 1;
-- WAITS for Session A's lock to be released
-- Blocks here until Session A COMMITs or ROLLBACKs

UPDATE employees SET salary = salary * 1.1 WHERE employee_id = 2;
-- This SUCCEEDS immediately (different row; no lock conflict)
```

### Lock Acquired on DML

```sql
-- Lock acquired (exclusive row lock on 1)
UPDATE employees SET salary = 50000 WHERE employee_id = 1;

-- Lock released
COMMIT;  -- or ROLLBACK

-- Session B can now access row 1
```

### Multiple Rows Locked

```sql
-- Multiple rows locked (one lock per row updated)
UPDATE employees SET salary = salary * 1.1 WHERE department_id = 10;
-- Locks all rows in department 10; releases when COMMIT/ROLLBACK
```

---

## 10. Table-Level Locking

### Explicit Table Lock

```sql
-- Lock entire table (exclusive mode)
LOCK TABLE employees IN EXCLUSIVE MODE;
-- Other sessions CANNOT read or write this table

UPDATE employees SET salary = salary * 1.1;

COMMIT;  -- Releases table lock
```

### Row-Level Lock (Default)

```sql
-- Update uses row-level lock (default)
UPDATE employees SET salary = salary * 1.1 WHERE department_id = 10;
-- Only rows in dept 10 are locked; other depts can be accessed
```

### When Oracle Uses Table Lock

- **DDL operations:** ALTER TABLE, CREATE INDEX
- **LOCK TABLE statement:** Explicit locking
- **Bulk operations:** Sometimes for efficiency

---

## 11. Deadlock: Cause and Detection

### What Is Deadlock?

**Deadlock** = Two or more transactions wait indefinitely for each other's locks.

### Deadlock Scenario

```
Transaction A                    Transaction B
─────────────────────────────────────────────
UPDATE accounts SET              UPDATE accounts SET
  balance = balance - 100        balance = balance + 50
WHERE account_id = 'A';          WHERE account_id = 'B';

-- Locks row A                    -- Locks row B

UPDATE accounts SET              UPDATE accounts SET
  balance = balance + 100        balance = balance - 50
WHERE account_id = 'B';          WHERE account_id = 'A';

-- WAITS for row B                -- WAITS for row A
   (held by Transaction B)          (held by Transaction A)

-- Both transactions wait indefinitely = DEADLOCK
```

### Oracle Detects Deadlock

```sql
-- Session A: Transfer from A to B
UPDATE accounts SET balance = balance - 100 WHERE account_id = 'A';
UPDATE accounts SET balance = balance + 100 WHERE account_id = 'B';
COMMIT;

-- Session B: Transfer from B to A (reverse order)
UPDATE accounts SET balance = balance - 100 WHERE account_id = 'B';
UPDATE accounts SET balance = balance + 100 WHERE account_id = 'A';  -- DEADLOCK!
-- Error: ORA-00060: Deadlock detected while waiting for resource
```

### Oracle Resolution

Oracle kills one transaction (chosen arbitrarily) and rolls it back:

```sql
-- Session B receives:
-- ORA-00060: Deadlock detected while waiting for resource

-- Session A continues and commits successfully

-- Retry logic needed
BEGIN
    -- Transfer logic
    UPDATE accounts SET balance = balance - 100 WHERE account_id = 'A';
    UPDATE accounts SET balance = balance + 100 WHERE account_id = 'B';
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -60 THEN  -- Deadlock code
            ROLLBACK;
            -- Retry or log error
        END IF;
END;
```

---

## 12. Lock Wait and Timeout

### Session Waiting for Lock

```sql
-- Session A (locks row 1)
UPDATE employees SET salary = 50000 WHERE employee_id = 1;

-- Session B (waits for row 1)
UPDATE employees SET salary = 60000 WHERE employee_id = 1;
-- WAITS indefinitely (or until Session A commits/rolls back)
```

### Lock Wait Timeout

```sql
-- Set timeout to 5 seconds
SET LOCK_WAIT_TIMEOUT 5;

-- If lock not released within 5 seconds:
-- ORA-01013: User requested cancel of current operation
-- (varies by Oracle version and setup)
```

### Explicit Timeout

```sql
BEGIN
    -- Use exception handling to catch timeout
    UPDATE employees SET salary = 50000 WHERE employee_id = 1;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        -- Might be timeout or deadlock
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLCODE);
        ROLLBACK;
END;
```

---

## 13. Common Mistakes

### Mistake 1: Holding Locks Too Long

```sql
-- ❌ WRONG: Long gap between DML and COMMIT
BEGIN
    UPDATE employees SET salary = 50000 WHERE employee_id = 1;
    
    -- Simulate long processing
    DBMS_LOCK.SLEEP(30);  -- 30-second delay
    
    COMMIT;  -- Locks held for 30 seconds!
END;

-- ✅ CORRECT: COMMIT immediately
BEGIN
    UPDATE employees SET salary = 50000 WHERE employee_id = 1;
    COMMIT;  -- Release locks ASAP
    
    -- Long processing AFTER commit (no locks held)
    DBMS_LOCK.SLEEP(30);
END;
```

---

### Mistake 2: No Deadlock Retry Logic

```sql
-- ❌ WRONG (fails on deadlock; no retry)
UPDATE account_a SET balance = balance - 100;
UPDATE account_b SET balance = balance + 100;
COMMIT;

-- ✅ CORRECT (retry on deadlock)
DECLARE
    retry_count NUMBER := 0;
BEGIN
    LOOP
        BEGIN
            UPDATE account_a SET balance = balance - 100;
            UPDATE account_b SET balance = balance + 100;
            COMMIT;
            EXIT;  -- Success
        EXCEPTION
            WHEN OTHERS THEN
                IF SQLCODE = -60 THEN  -- Deadlock
                    ROLLBACK;
                    retry_count := retry_count + 1;
                    IF retry_count > 3 THEN
                        RAISE;
                    END IF;
                ELSE
                    RAISE;
                END IF;
        END;
    END LOOP;
END;
```

---

### Mistake 3: No Error Handling on ROLLBACK

```sql
-- ❌ WRONG (silent failure)
BEGIN
    UPDATE employees SET salary = salary * 1.1;
    UPDATE departments SET budget = budget * 1.05;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        -- No message or logging; caller doesn't know what failed
END;

-- ✅ CORRECT (log and re-raise)
BEGIN
    UPDATE employees SET salary = salary * 1.1;
    UPDATE departments SET budget = budget * 1.05;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error in update: ' || SQLERRM);
        ROLLBACK;
        RAISE;  -- Let caller know there was an error
END;
```

---

## 14. Interview Q&A

### Q1: What are ACID properties and why are they important?

**A:**
- **Atomicity:** All-or-nothing (both statements or neither)
- **Consistency:** Data remains in valid state
- **Isolation:** Concurrent transactions don't interfere
- **Durability:** Changes survive system crashes

**They're important because they guarantee data integrity; your banking system can't lose or duplicate money.**

---

### Q2: What's the difference between COMMIT and ROLLBACK?

**A:**
- **COMMIT:** Makes changes permanent; releases locks; visible to other sessions
- **ROLLBACK:** Undoes changes; releases locks; reverts to transaction start

---

### Q3: What is a deadlock and how does Oracle handle it?

**A:** Deadlock = Two transactions wait for each other's locks.

**Example:**
- Transaction A locks row 1, waits for row 2 (locked by Transaction B)
- Transaction B locks row 2, waits for row 1 (locked by Transaction A)
- Both stuck indefinitely

**Oracle detects it and kills one transaction (ORA-00060); application should retry.**

---

### Q4: How do row-level and table-level locks differ?

**A:**
- **Row-level:** Locks specific row; other rows can be accessed (good concurrency)
- **Table-level:** Locks entire table; no one else can access (low concurrency)

**Oracle uses row-level by default (better).**

---

### Q5: What is SAVEPOINT and how is it different from COMMIT?

**A:**
- **SAVEPOINT:** Marker within transaction; can rollback TO it (partial undo)
- **COMMIT:** Ends transaction; makes all changes permanent (full undo impossible)

```sql
UPDATE A;
SAVEPOINT sp1;
UPDATE B;
ROLLBACK TO sp1;  -- Undo B only; A remains
COMMIT;  -- Saves A
```

---

### Q6: How would you prevent deadlocks?

**A:**
1. **Order access consistently:** Always lock rows in same order (A → B)
2. **Keep transactions short:** Release locks ASAP (COMMIT early)
3. **Add retry logic:** Catch deadlock (ORA-00060) and retry
4. **Use appropriate isolation level:** Avoid unnecessary conflicts

---

### Q7: What happens if I DON'T explicitly COMMIT?

**A:** Default behavior depends on client:
- **SQL*Plus:** Auto-ROLLBACK on exit (data is lost)
- **Application:** Usually auto-ROLLBACK (depends on driver)
- **Better:** Always explicitly COMMIT or ROLLBACK

---

### Q8: Can you have nested transactions?

**A:** Oracle supports SAVEPOINT (partial rollback) but not nested BEGIN-END transactions. SAVEPOINT provides checkpoint within transaction.

---

### Q9: What's the maximum transaction size?

**A:** No hard limit, but:
- **Undo space:** Must be available (undo records stored in undo tablespace)
- **Redo space:** Large transactions generate large redo logs
- **Best practice:** Keep transactions small and frequent COMMIT

---

### Q10: How do you find what locks are held?

**A:**

```sql
-- View current locks
SELECT * FROM v$lock;

-- View lock waits
SELECT * FROM v$lock_held;

-- Identify blocking sessions
SELECT * FROM v$session_wait WHERE event LIKE '%lock%';
```

---

## 15. Revision Summary

### Key Takeaways

1. **Transaction** = Series of DML statements; COMMIT (success) or ROLLBACK (failure)
2. **ACID** = Atomicity (all-or-nothing), Consistency (valid state), Isolation (no interference), Durability (permanent)
3. **COMMIT** = Makes changes permanent; releases locks; visible to others
4. **ROLLBACK** = Undoes all changes; releases locks; reverts to transaction start
5. **SAVEPOINT** = Checkpoint within transaction; can rollback TO it (partial undo)
6. **Lock** = Prevents concurrent access; acquired on DML; released on COMMIT/ROLLBACK
7. **Row-level lock** = Locks specific row; better concurrency (default in Oracle)
8. **Table-level lock** = Locks entire table; lower concurrency
9. **Deadlock** = Two transactions wait for each other's locks; Oracle detects (ORA-00060) and kills one
10. **Prevention** = Order access consistently; keep transactions short; add retry logic

### Best Practices

- **COMMIT early:** Release locks ASAP (don't hold locks during long processing)
- **Handle deadlock:** Catch ORA-00060 and retry (exponential backoff)
- **Use SAVEPOINT:** For partial rollback in complex logic
- **Test concurrency:** Test deadlock scenarios with multiple sessions
- **Monitor locks:** Use v$lock to identify blocking
