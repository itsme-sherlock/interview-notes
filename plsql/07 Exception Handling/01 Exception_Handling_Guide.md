# Exception Handling in Oracle PL/SQL Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Exception** = Error/event that interrupts normal program flow (like "file not found", "division by zero", "constraint violation").
- **Predefined exceptions** = Oracle-defined errors with PL/SQL names: NO_DATA_FOUND, TOO_MANY_ROWS, ZERO_DIVIDE, DUP_VAL_ON_INDEX, VALUE_ERROR, etc.
- **Non-predefined exceptions** = Oracle errors without built-in PL/SQL names; assign them using PRAGMA EXCEPTION_INIT (e.g., lock timeout, resource limit exceeded).
- **User-defined exceptions** = Custom errors you create for business logic (e.g., INVALID_SALARY, DUPLICATE_ACCOUNT, AGE_OUT_OF_RANGE).
- **EXCEPTION block** = Catches errors raised in BEGIN block; matches exception by name with WHEN clause; if matched, executes recovery code.
- **RAISE statement** = Throws an exception (predefined, non-predefined, or user-defined); stops execution; propagates to caller if not caught.
- **Exception scope** = Caught at block level; if not caught in current block, propagates to outer block; if uncaught, terminates program and rolls back uncommitted changes.
- **WHEN OTHERS** = Catch-all clause for exceptions not explicitly listed; captures all unmatched exceptions (use cautiously; may hide bugs).

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Exception Handling?](#1-why-do-we-need-exception-handling)
2. [What Is Exception Handling?](#2-what-is-exception-handling)
3. [Predefined Exceptions: Common Oracle Errors](#3-predefined-exceptions-common-oracle-errors)
4. [Catching Predefined Exceptions](#4-catching-predefined-exceptions)
5. [Non-Predefined Exceptions: Oracle Errors with No Built-In Names](#5-non-predefined-exceptions-oracle-errors-with-no-built-in-names)
6. [User-Defined Exceptions: Custom Business Rules](#6-user-defined-exceptions-custom-business-rules)
7. [Raising Exceptions: RAISE Statement](#7-raising-exceptions-raise-statement)
8. [Exception Propagation: Scope and Nested Blocks](#8-exception-propagation-scope-and-nested-blocks)
9. [Exception Functions: SQLCODE and SQLERRM](#9-exception-functions-sqlcode-and-sqlerrm)
10. [Common Exception Patterns in Production](#10-common-exception-patterns-in-production)
11. [Comparison: Predefined vs Non-Predefined vs User-Defined](#11-comparison-predefined-vs-non-predefined-vs-user-defined)
12. [Best Practices](#12-best-practices)
13. [Common Mistakes](#13-common-mistakes)
14. [Interview Q&A](#14-interview-qa)
15. [Revision Summary](#15-revision-summary)

---

## 1. Why Do We Need Exception Handling?

### The Problem: Unhandled Errors Leave Systems in Inconsistent States

**Scenario:** You're building a bank transfer system.

```sql
-- Without proper exception handling
DECLARE
    v_from_account_id NUMBER := 101;
    v_to_account_id NUMBER := 102;
    v_amount NUMBER := 1000;
BEGIN
    -- Step 1: Debit from account
    UPDATE accounts
    SET balance = balance - v_amount
    WHERE account_id = v_from_account_id;
    -- ✅ Debit successful
    
    -- Step 2: Credit to account (but fails due to constraint violation)
    UPDATE accounts
    SET balance = balance + v_amount
    WHERE account_id = v_to_account_id;
    -- ❌ Fails! (e.g., account locked, constraint violation)
    
    -- Step 3: Log transaction (never reached)
    INSERT INTO transaction_log VALUES (...);
    -- SKIPPED
    
    -- Step 4: Send confirmation (never reached)
    DBMS_OUTPUT.PUT_LINE('Transfer complete');
    -- SKIPPED
    
    COMMIT;  -- What gets committed?
END;
/
```

**What happens:**
- `UPDATE` from account: ✅ Success
- `UPDATE` to account: ❌ Fails (program stops here)
- `INSERT` log: ❌ Never runs
- `DBMS_OUTPUT`: ❌ Never runs
- `COMMIT`: ❌ AUTOMATICALLY ROLLED BACK by Oracle (uncommitted DML is lost)

**Result:** Account A was debited, but Account B wasn't credited, and no audit trail exists. 💥 **Financial disaster.**

---

### The Solution: Exception Handling

```sql
DECLARE
    v_from_account_id NUMBER := 101;
    v_to_account_id NUMBER := 102;
    v_amount NUMBER := 1000;
    e_invalid_account EXCEPTION;
    e_insufficient_balance EXCEPTION;
BEGIN
    -- Step 1: Debit
    UPDATE accounts
    SET balance = balance - v_amount
    WHERE account_id = v_from_account_id;
    
    -- Step 2: Credit (catches error if it fails)
    UPDATE accounts
    SET balance = balance + v_amount
    WHERE account_id = v_to_account_id;
    
    -- Step 3: Log (only runs if steps 1-2 succeed)
    INSERT INTO transaction_log
    VALUES (v_from_account_id, v_to_account_id, v_amount, SYSDATE, 'SUCCESS');
    
    -- Step 4: Commit
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Transfer complete');
    
EXCEPTION
    WHEN e_insufficient_balance THEN
        -- Handle insufficient balance
        ROLLBACK;
        INSERT INTO transaction_log
        VALUES (v_from_account_id, v_to_account_id, v_amount, SYSDATE, 'FAILED: Insufficient balance');
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('ERROR: Insufficient balance in source account');
        
    WHEN DUP_VAL_ON_INDEX THEN
        -- Handle duplicate value (shouldn't happen, but just in case)
        ROLLBACK;
        INSERT INTO transaction_log
        VALUES (v_from_account_id, v_to_account_id, v_amount, SYSDATE, 'FAILED: Duplicate entry');
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('ERROR: Duplicate transaction detected');
        
    WHEN OTHERS THEN
        -- Catch any unexpected error
        ROLLBACK;
        INSERT INTO transaction_log
        VALUES (v_from_account_id, v_to_account_id, v_amount, SYSDATE, 'FAILED: ' || SQLERRM);
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
END;
/
```

**Result:** Whatever happens, the transaction log is updated, and the system remains consistent. ✅

---

### Real-World Scenarios Where Exception Handling Matters

| Scenario | Risk | Solution |
| --- | --- | --- |
| **Data Load** | File parsing fails, corrupts data | Catch error, skip record, log, continue |
| **Batch Processing** | One record fails, entire batch stops | Catch per-record, skip failed, process rest |
| **API Calls** | External service timeout | Catch timeout, retry, or fallback to cache |
| **Locking** | Lock timeout on UPDATE | Catch, wait, retry, or skip |
| **Constraint Violation** | Insert violates FK, unique key | Catch, validate before insert, or merge |
| **Report Generation** | One record calculation fails | Catch, log error, skip record, continue report |
| **Data Migration** | Convert old format to new | Catch conversion errors, log bad records |

---

**➡ Transition:** Now we understand the problem. Let's understand how exception handling works in PL/SQL.

---

## 2. What Is Exception Handling?

### Simple Definition

**Exception handling** is the process of detecting, capturing, and responding to errors in a controlled way, allowing programs to continue execution or fail gracefully instead of crashing and leaving the system inconsistent.

### The PL/SQL Exception Flow

```
START BLOCK
    ↓
DECLARE section (optional)
    ↓
BEGIN section
    │
    ├─ Statement 1 ✅ (success)
    ├─ Statement 2 ❌ (error occurs HERE)
    │
    ✗ Program stops; jumps to EXCEPTION section
    │
EXCEPTION section
    │
    ├─ WHEN exception_name_1 THEN
    │      ├─ Is error = exception_name_1? YES → Execute recovery code
    │      └─ Catch successful; block completes
    │
    ├─ WHEN exception_name_2 THEN
    │      ├─ Is error = exception_name_2? NO → Skip
    │      └─ Check next exception
    │
    ├─ WHEN OTHERS THEN
    │      └─ Is error unknown? YES → Execute default recovery
    │
    ↓
Block completes (either successfully or with exception handled)
```

### Three Types of Exceptions in PL/SQL

#### 1. **Predefined Exceptions**
Oracle automatically raises these for common errors. You just catch them.

```sql
BEGIN
    SELECT salary INTO v_salary FROM employees WHERE employee_id = 99999;  -- No employee
EXCEPTION
    WHEN NO_DATA_FOUND THEN  -- Automatically raised by Oracle
        DBMS_OUTPUT.PUT_LINE('Employee not found');
END;
```

#### 2. **Non-Predefined Exceptions**
Oracle raises these, but they don't have built-in names. You assign names using PRAGMA EXCEPTION_INIT.

```sql
DECLARE
    e_resource_limit EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_resource_limit, -7445);  -- ORA-07445 (internal error)
BEGIN
    -- Some operation
EXCEPTION
    WHEN e_resource_limit THEN
        DBMS_OUTPUT.PUT_LINE('Resource limit exceeded');
END;
```

#### 3. **User-Defined Exceptions**
You create these for business rules.

```sql
DECLARE
    e_salary_too_high EXCEPTION;
BEGIN
    IF v_salary > 500000 THEN
        RAISE e_salary_too_high;
    END IF;
EXCEPTION
    WHEN e_salary_too_high THEN
        DBMS_OUTPUT.PUT_LINE('Salary exceeds maximum allowed');
END;
```

---

### Key Characteristics of Exception Handling

1. **Automatic Detection:** Oracle automatically detects database errors (NO_DATA_FOUND, ZERO_DIVIDE, etc.)
2. **Named Matching:** You match exceptions by name in the WHEN clause
3. **Local Scope:** Exceptions are caught at block level; unmatched exceptions propagate up
4. **Control Flow:** An exception immediately jumps to the EXCEPTION section (remaining statements skipped)
5. **Program Continuation:** After handling, the block either completes or propagates the exception to the caller

---

**➡ Transition:** Let's start with the most common exceptions: those predefined by Oracle.

---

## 3. Predefined Exceptions: Common Oracle Errors

Oracle has built-in exception names for the most common errors. You don't need to name them; just catch them.

### List of Common Predefined Exceptions

| Exception | Raised When | Error Code | Interview Notes |
| --- | --- | --- | --- |
| **NO_DATA_FOUND** | SELECT INTO finds no rows | ORA-01403 | Most common; affects row-level queries |
| **TOO_MANY_ROWS** | SELECT INTO finds 2+ rows | ORA-01422 | When result set expects exactly 1 row |
| **ZERO_DIVIDE** | Division by zero | ORA-01476 | Arithmetic error |
| **VALUE_ERROR** | String/number conversion fails | ORA-06502 | Type mismatch or overflow |
| **DUP_VAL_ON_INDEX** | INSERT/UPDATE violates unique key | ORA-00001 | Constraint violation |
| **INVALID_CURSOR** | Invalid cursor operation | ORA-01001 | Cursor not open, already closed, etc. |
| **STORAGE_ERROR** | Memory/storage limit exceeded | ORA-06500 | Out of memory |
| **PROGRAM_ERROR** | Internal PL/SQL error | ORA-06501 | Shouldn't happen; usually a bug |
| **CURSOR_ALREADY_OPEN** | OPEN on already-open cursor | ORA-06511 | Cursor management issue |
| **NOT_LOGGED_ON** | Database connection lost | ORA-01012 | Session terminated |

---

### NO_DATA_FOUND (Most Common)

**Raised:** When SELECT INTO finds 0 rows.

```sql
DECLARE
    v_salary NUMBER;
BEGIN
    SELECT salary INTO v_salary
    FROM employees
    WHERE employee_id = 99999;  -- Employee doesn't exist
    
    DBMS_OUTPUT.PUT_LINE('Salary: ' || v_salary);
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Employee not found');
END;
/
```

**Key Point:** NO_DATA_FOUND is specific to SELECT INTO. A SELECT query (not INTO) that returns 0 rows doesn't raise an exception; it just returns empty.

```sql
-- This does NOT raise NO_DATA_FOUND
SELECT * FROM employees WHERE employee_id = 99999;  -- No error; just no rows
```

---

### TOO_MANY_ROWS

**Raised:** When SELECT INTO finds 2+ rows (expects exactly 1).

```sql
DECLARE
    v_department_name VARCHAR2(50);
BEGIN
    SELECT department_name INTO v_department_name
    FROM departments
    WHERE location = 'New York';  -- 3 departments in NY!
    
    DBMS_OUTPUT.PUT_LINE('Department: ' || v_department_name);
    
EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Multiple departments found; expected exactly 1');
END;
/
```

**Solution:** Use ROWNUM or LIMIT, or fetch into a collection.

```sql
-- Better: Fetch only first row
DECLARE
    v_department_name VARCHAR2(50);
BEGIN
    SELECT department_name INTO v_department_name
    FROM departments
    WHERE location = 'New York'
    AND ROWNUM = 1;  -- Fetch only first row
    
    DBMS_OUTPUT.PUT_LINE('Department: ' || v_department_name);
END;
/
```

---

### ZERO_DIVIDE

**Raised:** Division by zero.

```sql
DECLARE
    v_result NUMBER;
    v_divisor NUMBER := 0;
BEGIN
    v_result := 100 / v_divisor;  -- BOOM
    
EXCEPTION
    WHEN ZERO_DIVIDE THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Division by zero not allowed');
        v_result := 0;  -- Default value
END;
/
```

---

### VALUE_ERROR

**Raised:** String/number conversion fails; field overflow.

```sql
DECLARE
    v_number NUMBER(3);  -- Max 3 digits: 999
BEGIN
    v_number := 1250;  -- Too many digits!
    
EXCEPTION
    WHEN VALUE_ERROR THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Value too large for field');
END;
/
```

```sql
-- Also raised by conversion errors
DECLARE
    v_number NUMBER;
BEGIN
    v_number := TO_NUMBER('HELLO');  -- Can't convert string to number
    
EXCEPTION
    WHEN VALUE_ERROR THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Cannot convert to number');
END;
/
```

---

### DUP_VAL_ON_INDEX

**Raised:** INSERT or UPDATE violates unique constraint or primary key.

```sql
DECLARE
    v_emp_id NUMBER := 101;
BEGIN
    INSERT INTO employees (employee_id, name)
    VALUES (v_emp_id, 'John Doe');  -- employee_id 101 already exists
    
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Employee ID ' || v_emp_id || ' already exists');
        -- Option 1: Skip insert
        -- Option 2: Update existing
        -- Option 3: Roll back and return error to caller
END;
/
```

---

**➡ Transition:** Now that we know predefined exceptions, let's learn how to catch them properly.

---

## 4. Catching Predefined Exceptions

### Basic Pattern: WHEN clause

```sql
BEGIN
    -- Code that might raise an exception
EXCEPTION
    WHEN exception_name THEN
        -- Recovery code
END;
```

### Example: Multiple WHEN Clauses

```sql
DECLARE
    v_employee_id NUMBER := 101;
    v_salary employees.salary%TYPE;
BEGIN
    -- Retrieve employee salary
    SELECT salary INTO v_salary
    FROM employees
    WHERE employee_id = v_employee_id;
    
    -- Calculate bonus
    IF v_salary < 0 THEN
        RAISE VALUE_ERROR;  -- Invalid data
    END IF;
    
    -- Update bonus (might fail)
    UPDATE employee_bonuses
    SET bonus = v_salary * 0.10
    WHERE employee_id = v_employee_id;
    
    DBMS_OUTPUT.PUT_LINE('Bonus calculated: ' || (v_salary * 0.10));
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Employee ID ' || v_employee_id || ' not found');
        
    WHEN VALUE_ERROR THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Invalid salary data');
        
    WHEN DUP_VAL_ON_INDEX THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Bonus record already exists for this employee');
        
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Unexpected error - ' || SQLERRM);
END;
/
```

### Order of WHEN Clauses

**Important:** Specific exceptions first, WHEN OTHERS last.

```sql
EXCEPTION
    WHEN NO_DATA_FOUND THEN      -- Specific (matched first)
        ...
    WHEN TOO_MANY_ROWS THEN       -- Specific
        ...
    WHEN OTHERS THEN               -- Catch-all (matched last)
        ...
END;
```

If you put WHEN OTHERS first, all exceptions match it; later clauses are never reached.

---

**➡ Transition:** Some Oracle errors don't have built-in names. We need to name them manually.

---

## 5. Non-Predefined Exceptions: Oracle Errors with No Built-In Names

### The Problem

Oracle raises hundreds of errors, but only ~20 have predefined exception names (NO_DATA_FOUND, TOO_MANY_ROWS, etc.). For others, you must create a name using **PRAGMA EXCEPTION_INIT**.

### Syntax

```sql
DECLARE
    e_custom_exception EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_custom_exception, -error_code);
BEGIN
    -- Code that raises the error
EXCEPTION
    WHEN e_custom_exception THEN
        -- Handle it
END;
```

---

### Example 1: Lock Timeout (ORA-30006)

**Scenario:** You want to catch "Resource Busy; Acquire with Wait Timeout Expired" error.

```sql
DECLARE
    e_lock_timeout EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_lock_timeout, -30006);
BEGIN
    UPDATE accounts
    SET balance = balance - 1000
    WHERE account_id = 101;  -- Might timeout if account is locked
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Update successful');
    
EXCEPTION
    WHEN e_lock_timeout THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Account is locked by another user; please retry');
        ROLLBACK;
    
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
        ROLLBACK;
END;
/
```

---

### Example 2: Child Record Exists (ORA-02292)

**Scenario:** You're deleting a department, but employees still belong to it.

```sql
DECLARE
    e_child_record_exists EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_child_record_exists, -2292);
    v_dept_id NUMBER := 10;
BEGIN
    DELETE FROM departments
    WHERE department_id = v_dept_id;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Department ' || v_dept_id || ' deleted');
    
EXCEPTION
    WHEN e_child_record_exists THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Cannot delete department; employees still assigned to it');
        ROLLBACK;
        
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
        ROLLBACK;
END;
/
```

---

### Common Oracle Error Codes for Non-Predefined Exceptions

| Error Code | Name | Meaning |
| --- | --- | --- |
| -1 | DUP_VAL_ON_INDEX | (Actually predefined, but shown for reference) |
| -2292 | Child Record Exists | Foreign key violation on delete |
| -20000 to -20999 | Application Errors | User-defined application errors (via RAISE_APPLICATION_ERROR) |
| -30006 | Lock Timeout | Resource busy; acquire with wait timeout expired |
| -7445 | INTERNAL_ERROR | Internal system error (catch for debugging) |
| -12899 | VALUE_TOO_LARGE | Value too large for field |

---

**➡ Transition:** User-defined exceptions are different—you create them and raise them explicitly.

---

## 6. User-Defined Exceptions: Custom Business Rules

### Definition

User-defined exceptions represent business logic errors (not Oracle database errors). You declare them, and you decide when to raise them.

### Pattern

```sql
DECLARE
    e_business_rule_violation EXCEPTION;
BEGIN
    -- Check business rule
    IF condition_violated THEN
        RAISE e_business_rule_violation;
    END IF;
    
EXCEPTION
    WHEN e_business_rule_violation THEN
        -- Handle business logic error
END;
```

---

### Example 1: Salary Validation

```sql
DECLARE
    e_salary_too_high EXCEPTION;
    e_salary_too_low EXCEPTION;
    v_employee_id NUMBER := 101;
    v_new_salary NUMBER := 600000;
    v_max_salary CONSTANT NUMBER := 500000;
    v_min_salary CONSTANT NUMBER := 20000;
BEGIN
    -- Validate salary
    IF v_new_salary > v_max_salary THEN
        RAISE e_salary_too_high;
    END IF;
    
    IF v_new_salary < v_min_salary THEN
        RAISE e_salary_too_low;
    END IF;
    
    -- If validation passes, update
    UPDATE employees
    SET salary = v_new_salary
    WHERE employee_id = v_employee_id;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Salary updated: $' || v_new_salary);
    
EXCEPTION
    WHEN e_salary_too_high THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: Salary $' || v_new_salary || ' exceeds maximum ($' || v_max_salary || ')');
        
    WHEN e_salary_too_low THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: Salary $' || v_new_salary || ' below minimum ($' || v_min_salary || ')');
        
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
END;
/
```

---

### Example 2: Duplicate Account Check

```sql
DECLARE
    e_duplicate_account EXCEPTION;
    v_account_number VARCHAR2(20) := 'ACC-20260816-001';
    v_count NUMBER;
BEGIN
    -- Check if account already exists
    SELECT COUNT(*) INTO v_count
    FROM accounts
    WHERE account_number = v_account_number;
    
    IF v_count > 0 THEN
        RAISE e_duplicate_account;
    END IF;
    
    -- Create account
    INSERT INTO accounts (account_number, created_date)
    VALUES (v_account_number, SYSDATE);
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Account ' || v_account_number || ' created');
    
EXCEPTION
    WHEN e_duplicate_account THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Account ' || v_account_number || ' already exists');
        
    WHEN DUP_VAL_ON_INDEX THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Account number is not unique (constraint violation)');
        
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
END;
/
```

---

### Example 3: Multi-Step Transaction with Custom Exceptions

```sql
DECLARE
    e_insufficient_balance EXCEPTION;
    e_invalid_account EXCEPTION;
    v_from_account_id NUMBER := 101;
    v_to_account_id NUMBER := 102;
    v_transfer_amount NUMBER := 1000;
    v_from_balance NUMBER;
    v_to_exists NUMBER;
BEGIN
    -- Step 1: Verify source account exists and has balance
    SELECT balance INTO v_from_balance
    FROM accounts
    WHERE account_id = v_from_account_id;
    
    IF v_from_balance < v_transfer_amount THEN
        RAISE e_insufficient_balance;
    END IF;
    
    -- Step 2: Verify destination account exists
    SELECT COUNT(*) INTO v_to_exists
    FROM accounts
    WHERE account_id = v_to_account_id;
    
    IF v_to_exists = 0 THEN
        RAISE e_invalid_account;
    END IF;
    
    -- Step 3: Perform transfer
    UPDATE accounts
    SET balance = balance - v_transfer_amount
    WHERE account_id = v_from_account_id;
    
    UPDATE accounts
    SET balance = balance + v_transfer_amount
    WHERE account_id = v_to_account_id;
    
    -- Step 4: Log transfer
    INSERT INTO transfer_log (from_account, to_account, amount, transfer_date)
    VALUES (v_from_account_id, v_to_account_id, v_transfer_amount, SYSDATE);
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Transfer successful: $' || v_transfer_amount);
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: Source account ' || v_from_account_id || ' not found');
        
    WHEN e_insufficient_balance THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: Insufficient balance in account ' || v_from_account_id);
        DBMS_OUTPUT.PUT_LINE('  Available: $' || v_from_balance || ', Requested: $' || v_transfer_amount);
        
    WHEN e_invalid_account THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: Destination account ' || v_to_account_id || ' does not exist');
        
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
END;
/
```

---

**➡ Transition:** Now let's learn the RAISE statement to throw exceptions.

---

## 7. Raising Exceptions: RAISE Statement

### Syntax

```sql
RAISE exception_name;
```

### Types of RAISE

#### 1. Raise Predefined Exception

```sql
BEGIN
    IF age < 18 THEN
        RAISE VALUE_ERROR;  -- Raise built-in exception
    END IF;
EXCEPTION
    WHEN VALUE_ERROR THEN
        DBMS_OUTPUT.PUT_LINE('Age must be >= 18');
END;
```

#### 2. Raise User-Defined Exception

```sql
DECLARE
    e_age_invalid EXCEPTION;
BEGIN
    IF age < 18 THEN
        RAISE e_age_invalid;
    END IF;
EXCEPTION
    WHEN e_age_invalid THEN
        DBMS_OUTPUT.PUT_LINE('Age must be >= 18');
END;
```

#### 3. Raise with RAISE_APPLICATION_ERROR (For Outer Callers)

```sql
DECLARE
    v_age NUMBER := 15;
BEGIN
    IF v_age < 18 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Age must be >= 18');
    END IF;
END;
/
-- ORA-20001: Age must be >= 18
```

**Key Difference:**
- `RAISE user_exception`: Caught in EXCEPTION block of same block
- `RAISE_APPLICATION_ERROR`: Propagates to caller (procedure, function, or SQL client); caught by caller

---

### Example: Re-raising an Exception

```sql
DECLARE
    e_error EXCEPTION;
BEGIN
    BEGIN
        -- Inner block: catch and handle
        SELECT * FROM nonexistent_table;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Inner block: Error caught, logging...');
            INSERT INTO error_log VALUES (SYSDATE, SQLERRM);
            RAISE;  -- Re-raise to outer block
    END;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Outer block: catches re-raised exception
        DBMS_OUTPUT.PUT_LINE('Outer block: Re-raised exception caught');
        ROLLBACK;
END;
/
```

---

**➡ Transition:** Exceptions in nested blocks behave differently. Let's understand propagation.

---

## 8. Exception Propagation: Scope and Nested Blocks

### Key Concept: Unhandled Exceptions Propagate Outward

If an exception is not caught in the current block, it propagates to the enclosing block.

### Example: Nested Blocks Without Handlers

```sql
BEGIN  -- Outer block
    BEGIN  -- Inner block
        SELECT salary INTO v_salary
        FROM employees
        WHERE employee_id = 99999;  -- NO_DATA_FOUND raised
        -- Inner block has NO EXCEPTION handler
    END;
    -- Exception propagates here
    
    DBMS_OUTPUT.PUT_LINE('This never executes');
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Outer block catches it: Employee not found');
END;
/
```

**Output:**
```
Outer block catches it: Employee not found
```

---

### Example: Caught in Inner Block

```sql
BEGIN  -- Outer block
    BEGIN  -- Inner block
        SELECT salary INTO v_salary
        FROM employees
        WHERE employee_id = 99999;  -- NO_DATA_FOUND raised
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Inner block handles it: Employee not found');
            v_salary := 0;  -- Default value
    END;
    
    DBMS_OUTPUT.PUT_LINE('Outer block continues: Salary is ' || v_salary);
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('This never executes');
END;
/
```

**Output:**
```
Inner block handles it: Employee not found
Outer block continues: Salary is 0
```

---

### Propagation Rules

```
Exception raised in inner block
    ↓
1. Is there a matching WHEN in inner block? 
   YES → Handle it (stop here)
   NO → Go to step 2
    ↓
2. Propagate to outer block
    ↓
3. Is there a matching WHEN in outer block?
   YES → Handle it
   NO → Propagate further (or terminate program)
```

---

### Interview Scenario: Batch Processing with Partial Rollback

```sql
DECLARE
    e_skip_record EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_skip_record, -20999);
BEGIN
    -- Outer: Process all records
    FOR record IN (SELECT * FROM import_data) LOOP
        BEGIN
            -- Inner: Process each record
            IF record.amount < 0 THEN
                RAISE_APPLICATION_ERROR(-20999, 'Negative amount not allowed');
            END IF;
            
            INSERT INTO transactions (account_id, amount, trans_date)
            VALUES (record.account_id, record.amount, SYSDATE);
            
        EXCEPTION
            WHEN e_skip_record THEN
                -- Log error and continue (don't stop entire batch)
                INSERT INTO import_errors (record_id, error_msg)
                VALUES (record.id, 'Negative amount');
                -- Continue to next record
                
            WHEN OTHERS THEN
                INSERT INTO import_errors (record_id, error_msg)
                VALUES (record.id, SQLERRM);
                -- Continue
        END;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Batch processing complete');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Batch failed: ' || SQLERRM);
END;
/
```

**Key Benefit:** Inner exception is caught; batch processing continues.

---

**➡ Transition:** Sometimes you need to know the error code and message. Oracle provides functions for that.

---

## 9. Exception Functions: SQLCODE and SQLERRM

### SQLCODE: Numeric Error Code

```sql
SQLCODE → Returns integer error code
  0 = No error (successful execution)
  < 0 = Oracle error (e.g., -1 for duplicate, -1403 for NO_DATA_FOUND)
  > 0 = Non-standard error (rarely used)
```

### SQLERRM: Error Message

```sql
SQLERRM → Returns varchar2 error message
  Example: 'ORA-01403: no data found'
```

---

### Example: Logging Errors with SQLCODE and SQLERRM

```sql
DECLARE
    v_employee_id NUMBER := 101;
BEGIN
    SELECT salary INTO v_salary
    FROM employees
    WHERE employee_id = v_employee_id;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Log error details
        INSERT INTO error_log (error_code, error_message, log_date)
        VALUES (SQLCODE, SQLERRM, SYSDATE);
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Error Code: ' || SQLCODE);
        DBMS_OUTPUT.PUT_LINE('Error Message: ' || SQLERRM);
END;
/
```

**Output (if employee not found):**
```
Error Code: -1403
Error Message: ORA-01403: no data found
```

---

### Example: Conditional Handling Based on Error Code

```sql
BEGIN
    UPDATE accounts
    SET balance = balance - 1000
    WHERE account_id = 101;
    
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -30006 THEN
            -- Lock timeout
            DBMS_OUTPUT.PUT_LINE('Account is locked; please retry');
        ELSIF SQLCODE = -1 THEN
            -- Duplicate value
            DBMS_OUTPUT.PUT_LINE('Duplicate entry');
        ELSE
            -- Unknown error
            DBMS_OUTPUT.PUT_LINE('Unknown error: ' || SQLERRM);
        END IF;
END;
/
```

---

**➡ Transition:** Let's see real production patterns for exception handling.

---

## 10. Common Exception Patterns in Production

### Pattern 1: Graceful Degradation (Fallback to Default)

```sql
DECLARE
    v_configuration VARCHAR2(1000);
BEGIN
    -- Try to get configuration from table
    SELECT config_value INTO v_configuration
    FROM system_config
    WHERE config_name = 'APP_MODE';
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Fallback to default
        v_configuration := 'PRODUCTION';
        DBMS_OUTPUT.PUT_LINE('Configuration not found; using default: ' || v_configuration);
END;
```

---

### Pattern 2: Retry Logic

```sql
DECLARE
    v_max_retries CONSTANT NUMBER := 3;
    v_retry_count NUMBER := 0;
    e_lock_timeout EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_lock_timeout, -30006);
BEGIN
    WHILE v_retry_count < v_max_retries LOOP
        BEGIN
            UPDATE accounts
            SET balance = balance - 1000
            WHERE account_id = 101;
            
            EXIT;  -- Success; exit loop
            
        EXCEPTION
            WHEN e_lock_timeout THEN
                v_retry_count := v_retry_count + 1;
                IF v_retry_count < v_max_retries THEN
                    DBMS_LOCK.SLEEP(1);  -- Wait 1 second, then retry
                    -- Loop continues
                ELSE
                    RAISE_APPLICATION_ERROR(-20001, 'Lock timeout after ' || v_max_retries || ' retries');
                END IF;
        END;
    END LOOP;
    
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
END;
/
```

---

### Pattern 3: Validation Before Operation (Prevent Exceptions)

```sql
-- GOOD: Check before inserting (prevents exception)
DECLARE
    v_duplicate_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_duplicate_count
    FROM accounts
    WHERE account_number = '12345';
    
    IF v_duplicate_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Account already exists');
    ELSE
        INSERT INTO accounts (account_number)
        VALUES ('12345');
    END IF;
END;
/

-- AVOID: Rely on exception (less efficient)
DECLARE
    e_dup EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_dup, -1);
BEGIN
    INSERT INTO accounts (account_number)
    VALUES ('12345');
EXCEPTION
    WHEN e_dup THEN
        DBMS_OUTPUT.PUT_LINE('Account already exists');
END;
/
```

**Why?** Throwing exceptions is expensive (CPU intensive). If you can validate beforehand, do it.

---

### Pattern 4: Comprehensive Error Logging

```sql
PROCEDURE safe_account_transfer (
    p_from_account_id IN NUMBER,
    p_to_account_id IN NUMBER,
    p_amount IN NUMBER
) AS
BEGIN
    UPDATE accounts
    SET balance = balance - p_amount
    WHERE account_id = p_from_account_id;
    
    UPDATE accounts
    SET balance = balance + p_amount
    WHERE account_id = p_to_account_id;
    
    INSERT INTO transfer_log (from_id, to_id, amount, status, log_date)
    VALUES (p_from_account_id, p_to_account_id, p_amount, 'SUCCESS', SYSDATE);
    
    COMMIT;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        INSERT INTO transfer_log (from_id, to_id, amount, status, error_message, log_date)
        VALUES (p_from_account_id, p_to_account_id, p_amount, 'FAILED', 'Account not found', SYSDATE);
        COMMIT;
        RAISE_APPLICATION_ERROR(-20001, 'One or both accounts do not exist');
        
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        INSERT INTO transfer_log (from_id, to_id, amount, status, error_message, log_date)
        VALUES (p_from_account_id, p_to_account_id, p_amount, 'FAILED', 'Duplicate transfer', SYSDATE);
        COMMIT;
        RAISE_APPLICATION_ERROR(-20002, 'Transfer already recorded');
        
    WHEN OTHERS THEN
        ROLLBACK;
        INSERT INTO transfer_log (from_id, to_id, amount, status, error_message, log_date)
        VALUES (p_from_account_id, p_to_account_id, p_amount, 'FAILED', SQLERRM, SYSDATE);
        COMMIT;
        RAISE_APPLICATION_ERROR(-20999, 'Transfer failed: ' || SQLERRM);
END safe_account_transfer;
/
```

---

**➡ Transition:** Now let's compare the three exception types.

---

## 11. Comparison: Predefined vs Non-Predefined vs User-Defined

| Aspect | Predefined | Non-Predefined | User-Defined |
| --- | --- | --- | --- |
| **Source** | Oracle (database errors) | Oracle (database errors) | You (business logic) |
| **Declaration** | Built-in; no code needed | Declare + PRAGMA EXCEPTION_INIT | DECLARE with exception name |
| **Examples** | NO_DATA_FOUND, TOO_MANY_ROWS | Lock timeout, child record exists | Invalid salary, duplicate account |
| **Raised By** | Oracle automatically | Oracle automatically | Your RAISE statement |
| **Error Code** | Negative (e.g., -1403) | Negative (e.g., -30006) | Custom (usually -20000 to -20999) |
| **Catching** | WHEN exception_name | WHEN exception_name | WHEN exception_name |
| **Propagation** | Yes (if not caught) | Yes (if not caught) | Yes (if not caught) |
| **Use Case** | Standard database errors | Specific Oracle errors (lock, FK) | Business validation |

---

## 12. Best Practices

### 1. Catch Specific Exceptions First

```sql
EXCEPTION
    WHEN NO_DATA_FOUND THEN        -- Specific
        ...
    WHEN TOO_MANY_ROWS THEN         -- Specific
        ...
    WHEN VALUE_ERROR THEN           -- Specific
        ...
    WHEN OTHERS THEN                -- Catch-all (last)
        ...
END;
```

If you put WHEN OTHERS first, all exceptions are caught; later clauses never execute.

---

### 2. Always Log Errors Before Handling

```sql
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        INSERT INTO error_log (error_code, error_msg, log_date)
        VALUES (SQLCODE, SQLERRM, SYSDATE);
        COMMIT;  -- Commit log even if transaction rolls back
        DBMS_OUTPUT.PUT_LINE('Employee not found');
END;
```

**Why?** You need an audit trail for debugging production issues.

---

### 3. Validate Data Before Operations (Prevent Exceptions)

```sql
-- ❌ AVOID: Rely on exception (expensive)
BEGIN
    INSERT INTO ...;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN ...
END;

-- ✅ GOOD: Check first
IF NOT EXISTS (SELECT 1 FROM ... WHERE ...) THEN
    INSERT INTO ...;
ELSE
    DBMS_OUTPUT.PUT_LINE('Already exists');
END IF;
```

Exceptions are expensive (CPU). Prevent them when possible.

---

### 4. Use Descriptive Exception Names

```sql
-- ❌ POOR: Unclear names
DECLARE
    e_error1 EXCEPTION;
    e_error2 EXCEPTION;

-- ✅ GOOD: Clear business meaning
DECLARE
    e_salary_exceeds_max EXCEPTION;
    e_employee_already_exists EXCEPTION;
    e_department_has_employees EXCEPTION;
```

---

### 5. Roll Back on Error (Maintain Consistency)

```sql
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;  -- Undo uncommitted changes
        DBMS_OUTPUT.PUT_LINE('Transaction rolled back');
        RAISE_APPLICATION_ERROR(-20999, 'Operation failed: ' || SQLERRM);
END;
```

**Why?** Partial transactions leave data inconsistent. Always rollback on unexpected errors.

---

### 6. Use RAISE_APPLICATION_ERROR for Outer Callers

```sql
-- Inside procedure/function
IF invalid_data THEN
    RAISE_APPLICATION_ERROR(-20001, 'Invalid employee salary: must be > 0');
END IF;

-- Caller receives ORA-20001: Invalid employee salary: must be > 0
```

This propagates the error to the calling program (SQL*Plus, application, etc.).

---

## 13. Common Mistakes

### Mistake 1: Catching OTHERS Silently

```sql
-- ❌ WRONG: Swallows errors
BEGIN
    SELECT salary INTO v_salary FROM employees WHERE employee_id = 99999;
EXCEPTION
    WHEN OTHERS THEN
        NULL;  -- Error is ignored; program continues
END;

-- v_salary is NULL; caller doesn't know there was an error!

-- ✅ CORRECT: Always log and propagate
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
        RAISE;  -- Re-raise so caller knows about the error
END;
```

---

### Mistake 2: Not Rolling Back on Error

```sql
-- ❌ WRONG: Partial transaction committed
BEGIN
    UPDATE accounts SET balance = balance - 1000 WHERE account_id = 101;
    UPDATE accounts SET balance = balance + 1000 WHERE account_id = 102;  -- Fails
    COMMIT;  -- What gets committed?
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
        -- No ROLLBACK; account 101 loses $1000!
END;

-- ✅ CORRECT
BEGIN
    ...
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;  -- Undo both UPDATEs
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
END;
```

---

### Mistake 3: Putting WHEN OTHERS First

```sql
-- ❌ WRONG: Generic handler matches first
BEGIN
    ...
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Generic error');
    WHEN NO_DATA_FOUND THEN  -- Never reaches here!
        DBMS_OUTPUT.PUT_LINE('Employee not found');
END;

-- ✅ CORRECT: Specific first, generic last
BEGIN
    ...
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Employee not found');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Generic error');
END;
```

---

### Mistake 4: Using Exception Instead of Validation

```sql
-- ❌ AVOID: Exception for expected condition
BEGIN
    INSERT INTO accounts (account_number) VALUES ('ACC-001');
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        DBMS_OUTPUT.PUT_LINE('Account exists; skipping');
END;

-- ✅ GOOD: Check first (cheaper)
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM accounts WHERE account_number = 'ACC-001';
    IF v_count = 0 THEN
        INSERT INTO accounts (account_number) VALUES ('ACC-001');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Account exists; skipping');
    END IF;
END;
```

Exceptions are expensive; validation is cheap.

---

### Mistake 5: Not Using Explicit Names for Non-Predefined Exceptions

```sql
-- ❌ WRONG: Catching by error code is fragile
BEGIN
    ...
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -30006 THEN
            DBMS_OUTPUT.PUT_LINE('Lock timeout');
        END IF;
END;

-- ✅ CORRECT: Use PRAGMA EXCEPTION_INIT
DECLARE
    e_lock_timeout EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_lock_timeout, -30006);
BEGIN
    ...
EXCEPTION
    WHEN e_lock_timeout THEN
        DBMS_OUTPUT.PUT_LINE('Lock timeout');
END;
```

Named exceptions are clearer and less error-prone.

---

## 14. Interview Q&A

### Q1: What's the difference between NO_DATA_FOUND and an empty result set?

**A:** 
- `NO_DATA_FOUND`: Raised by `SELECT INTO` when 0 rows found. Exception propagates.
- Empty result set: Returned by `SELECT` (not INTO) when 0 rows found. No exception.

```sql
-- Raises NO_DATA_FOUND
SELECT salary INTO v_salary FROM employees WHERE employee_id = 99999;

-- Returns empty result set (no exception)
SELECT * FROM employees WHERE employee_id = 99999;
```

---

### Q2: Why should you catch specific exceptions before WHEN OTHERS?

**A:** Order matters. PL/SQL evaluates WHEN clauses top-to-bottom. If you put `WHEN OTHERS` first, it matches all exceptions; subsequent WHEN clauses never execute.

```sql
EXCEPTION
    WHEN OTHERS THEN              -- Matches ALL exceptions
        ...
    WHEN NO_DATA_FOUND THEN        -- Never reaches here!
        ...
END;
```

---

### Q3: What's the difference between RAISE and RAISE_APPLICATION_ERROR?

**A:**
- `RAISE` (or `RAISE exception_name`): Throws exception; caught in EXCEPTION block of same/outer block.
- `RAISE_APPLICATION_ERROR`: Propagates to caller (SQL client, application); caller sees ORA-20xxx message.

Use RAISE_APPLICATION_ERROR for procedures/functions to communicate errors to callers.

---

### Q4: How do you handle a lock timeout in PL/SQL?

**A:**
```sql
DECLARE
    e_lock_timeout EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_lock_timeout, -30006);
BEGIN
    UPDATE accounts SET balance = balance - 1000 WHERE account_id = 101;
EXCEPTION
    WHEN e_lock_timeout THEN
        DBMS_OUTPUT.PUT_LINE('Lock timeout; please retry');
        -- Option: Retry logic, or propagate to caller
END;
```

Or retry multiple times:
```sql
FOR i IN 1..3 LOOP
    BEGIN
        UPDATE ...;
        EXIT;
    EXCEPTION
        WHEN e_lock_timeout THEN
            IF i < 3 THEN DBMS_LOCK.SLEEP(1); END IF;
    END;
END LOOP;
```

---

### Q5: Can you re-raise an exception?

**A:** Yes, using `RAISE` (without arguments) inside an EXCEPTION block.

```sql
BEGIN
    ...
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Logging error: ' || SQLERRM);
        RAISE;  -- Re-raise the same exception to outer block
END;
```

---

### Q6: What's the difference between user-defined and non-predefined exceptions?

**A:**
- **User-defined**: You create and raise them for business logic (e.g., INVALID_SALARY).
- **Non-predefined**: Oracle raises them (database errors), but they lack built-in names; you name them with PRAGMA EXCEPTION_INIT.

Example user-defined:
```sql
DECLARE
    e_invalid_salary EXCEPTION;
BEGIN
    IF salary < 0 THEN RAISE e_invalid_salary; END IF;
END;
```

Example non-predefined:
```sql
DECLARE
    e_lock_timeout EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_lock_timeout, -30006);
BEGIN
    -- Oracle raises -30006; you catch it with e_lock_timeout name
END;
```

---

### Q7: Should you always catch exceptions or let them propagate?

**A:** It depends:
- **Catch when** you can recover gracefully (retry, log, fallback).
- **Propagate when** the error is unrecoverable and must be handled by the caller.

```sql
-- Catch: You can handle it
BEGIN
    SELECT config INTO v_config FROM system_config;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        v_config := 'DEFAULT';  -- Fallback
END;

-- Propagate: Caller must handle
BEGIN
    UPDATE accounts SET balance = balance - 1000 WHERE account_id = 101;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'Transfer failed: ' || SQLERRM);
        -- Caller handles the error
END;
```

---

### Q8: What's the best way to log errors?

**A:** Create an error_log table and insert into it:

```sql
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO error_log (
            error_code, 
            error_message, 
            procedure_name,
            parameter_values,
            log_date
        ) VALUES (
            SQLCODE, 
            SQLERRM,
            'procedure_name',
            'p_account_id=' || p_account_id,
            SYSDATE
        );
        COMMIT;  -- Commit log separately (even if transaction rolls back)
        
        ROLLBACK;  -- Rollback main transaction
        RAISE_APPLICATION_ERROR(-20999, 'Operation failed');
END;
```

---

### Q9: Can you catch an exception in an outer block if it's already handled in an inner block?

**A:** No. Once caught in the inner block's EXCEPTION section, the exception doesn't propagate to the outer block.

```sql
BEGIN  -- Outer
    BEGIN  -- Inner
        SELECT salary INTO v_salary FROM employees WHERE employee_id = 99999;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Inner: Employee not found');  -- Handled here
            v_salary := 0;
    END;
    
    DBMS_OUTPUT.PUT_LINE('Outer: Salary=' || v_salary);  -- Continues normally
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Outer: This never executes');  -- Exception already handled
END;
```

---

### Q10: How do you handle multiple exceptions in batch processing without stopping the batch?

**A:**
```sql
FOR record IN (SELECT * FROM import_data) LOOP
    BEGIN
        -- Process each record
        IF record.amount < 0 THEN
            RAISE_APPLICATION_ERROR(-20999, 'Negative amount');
        END IF;
        
        INSERT INTO transactions VALUES (record.account_id, record.amount);
        
    EXCEPTION
        WHEN OTHERS THEN
            -- Log error for this record; continue to next
            INSERT INTO import_errors (record_id, error_msg)
            VALUES (record.id, SQLERRM);
            -- No RAISE; loop continues
    END;
END LOOP;

COMMIT;
```

---

## 15. Revision Summary

### Key Takeaways

1. **Exception handling prevents data inconsistency** — Always catch and roll back on error.
2. **Three exception types:** Predefined (NO_DATA_FOUND), Non-predefined (lock timeout), User-defined (INVALID_SALARY).
3. **Order matters:** Specific WHEN clauses first, WHEN OTHERS last.
4. **RAISE propagates exceptions** to outer blocks or callers; RAISE_APPLICATION_ERROR propagates to SQL clients.
5. **Log errors always** — Insert into error_log before handling or rolling back.
6. **Validate first, catch exceptions second** — Exceptions are expensive; prevention is cheaper.
7. **Roll back on error** — Uncommitted DML is automatically rolled back if exception propagates.
8. **Re-raise when needed** — Catch, log, then RAISE to propagate to caller.

### Quick Reference

| Need | Use |
| --- | --- |
| Catch database error? | WHEN exception_name THEN |
| Catch oracle error with no name? | PRAGMA EXCEPTION_INIT + WHEN |
| Catch business rule violation? | User-defined exception + RAISE |
| Propagate to caller? | RAISE_APPLICATION_ERROR(-20000 to -20999, message) |
| Know error code/message? | SQLCODE, SQLERRM |
| Re-raise? | RAISE (without arguments) |
| Catch multiple errors? | Multiple WHEN clauses + WHEN OTHERS |
| Prevent exceptions? | Validate before operations |
