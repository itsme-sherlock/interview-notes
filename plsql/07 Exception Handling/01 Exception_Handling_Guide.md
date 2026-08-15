# Exception Handling in Oracle PL/SQL Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Exception** = Error/event that stops normal program flow (like "file not found" or "division by zero")
- **Predefined exceptions** = Oracle-defined errors (NO_DATA_FOUND, TOO_MANY_ROWS, ZERO_DIVIDE, DUP_VAL_ON_INDEX, etc.)
- **Non-predefined exceptions** = Oracle errors without PL/SQL names (must assign name with PRAGMA EXCEPTION_INIT)
- **User-defined exceptions** = Custom errors you create for business logic (invalid salary, duplicate account, etc.)
- **EXCEPTION block** = WHERE you catch and handle errors (WHEN exception_name THEN recovery_action)
- **RAISE statement** = Throw an exception manually (for user-defined or re-raising)
- **Exception scope** = Caught at block level; if not caught, propagates to outer block

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Exception Handling?](#1-why-do-we-need-exception-handling)
2. [What Is Exception Handling?](#2-what-is-exception-handling)
3. [Predefined Exceptions: Common Oracle Errors](#3-predefined-exceptions-common-oracle-errors)
4. [Catching Predefined Exceptions](#4-catching-predefined-exceptions)
5. [Non-Predefined Exceptions: Oracle Errors with No Names](#5-non-predefined-exceptions-oracle-errors-with-no-names)
6. [Assigning Names to Non-Predefined Exceptions](#6-assigning-names-to-non-predefined-exceptions)
7. [User-Defined Exceptions: Custom Business Rules](#7-user-defined-exceptions-custom-business-rules)
8. [Raising User-Defined Exceptions](#8-raising-user-defined-exceptions)
9. [Exception Scope and Propagation](#9-exception-scope-and-propagation)
10. [Comparison: Predefined vs Non-Predefined vs User-Defined](#10-comparison-predefined-vs-non-predefined-vs-user-defined)
11. [Best Practices](#11-best-practices)
12. [Common Mistakes](#12-common-mistakes)
13. [Interview Q&A](#13-interview-qa)
14. [Revision Summary](#14-revision-summary)

---

## 1. Why Do We Need Exception Handling?

### The Problem: Unhandled Errors Stop Programs Abruptly

**Scenario:** Your PL/SQL procedure updates employee salaries.

```sql
-- Without exception handling
DECLARE
  v_salary employees.salary%TYPE;
BEGIN
SELECT salary INTO v_salary FROM employees WHERE employee_id = 99999;  -- Employee doesn't exist!
  UPDATE employees SET salary = salary * 1.1
  WHERE department_id = 10;
  
  INSERT INTO salary_audit VALUES (...);  -- If this fails, UPDATE succeeded but audit failed!
  
  DELETE FROM temp_data WHERE created_date < SYSDATE - 30;  -- Never executes if INSERT fails
END;
/
```

**What happens:**
- UPDATE failed
- INSERT fails (constraint violation)
- DELETE never runs (program stopped at error)
- **Result:** Inconsistent state (salaries updated, audit missing, temp data not cleaned)

### The Solution: Exception Handling

```sql
DECLARE
  v_salary employees.salary%TYPE;
BEGIN
SELECT salary INTO v_salary FROM employees WHERE employee_id = 99999;  -- Employee doesn't exist!
  UPDATE employees SET salary = salary * 1.1
  WHERE department_id = 10;
  
  --INSERT INTO salary_audit VALUES (...);  -- If this fails, UPDATE succeeded but audit failed!
  
  --DELETE FROM temp_data WHERE created_date < SYSDATE - 30;  -- Never executes if INSERT fails
  EXCEPTION
  WHEN no_data_found THEN
    -- Handle no data found: log it, retry, or skip
    DBMS_OUTPUT.PUT_LINE('No data found for the given employee ID');
END;
/
```


### Real-World Scenarios

- **Data Load:** File parsing fails → Catch, log, skip bad record, continue loading
- **Batch Processing:** One customer's calculation fails → Skip, log, process next customer
- **API Calls:** External service timeout → Retry, fallback to cache, or notify user
- **Database Operations:** Lock timeout → Wait and retry, or proceed with alternative
- **Validation:** Invalid input from user → Show error message, ask for correction

---

**➡ Transition:** Now we understand why exceptions matter. Let's understand what an exception actually is.

---

## 2. What Is Exception Handling?

### Simple Definition

**Excption handling** is the process of detecting and responding to errors in a controlled way, allowing the program to continue or fail gracefully instead of crashing.

Think of a program without exception is like a car without brakes: it will crash when it hits an obstacle. Exception handling is the brake system that detects the crash and allows you to steer safely.

### The PL/SQL Exception Architecture

```
┌─────────────────────────────────┐
│ BEGIN                           │
│  [Executable statements]        │
│  [If error occurs here...]      │
└─────────────────────────────────┘
           ↓
    [Error detected]
           ↓
┌─────────────────────────────────┐
│ EXCEPTION                       │
│  WHEN exception_name THEN       │ ← Matching exception?
│    [Recovery code]              │
│  WHEN OTHERS THEN               │ ← Catch-all
│    [Default recovery]           │
└─────────────────────────────────┘
           ↓
    [Continue or RAISE]
```

### Three Types of Exceptions

1. **Predefined** = Named by Oracle (NO_DATA_FOUND, TOO_MANY_ROWS)
2. **Non-Predefined** = Oracle errors, no built-in name (need PRAGMA to name)
3. **User-Defined** = You create them for business logic (INVALID_SALARY, DUPLICATE_ACCOUNT)

### Key Characteristics

- **Automatic detection:** Oracle catches database errors automatically
- **Named matching:** WHEN clause matches exception by name
- **Local scope:** Caught at block level (if not caught, propagates up)
- **Control flow:** Exception jumps directly to EXCEPTION block (skips remaining statements)

---

**➡ Transition:** Let's start with the most common exceptions: those predefined by Oracle.

---

## 3. Predefined Exceptions: Common Oracle Errors

### What Are Predefined Exceptions?

**Predefined exceptions** = Oracle has already named common errors. You just catch them.

No PRAGMA needed—they're built-in.

### Most Common Predefined Exceptions

| Exception | Cause | Typical Scenario |
| --- | --- | --- |
| **NO_DATA_FOUND** | SELECT INTO returns 0 rows | Query employee, doesn't exist |
| **TOO_MANY_ROWS** | SELECT INTO returns 2+ rows | Expected 1 row, got 100 |
| **ZERO_DIVIDE** | Division by zero | `salary / months_worked` when months=0 |
| **DUP_VAL_ON_INDEX** | Unique key violation | Insert duplicate employee_id |
| **VALUE_ERROR** | Numeric/conversion error | `TO_NUMBER('ABC')` |
| **INVALID_CURSOR** | Cursor operation invalid | FETCH from closed cursor |
| **CURSOR_ALREADY_OPEN** | OPEN on already-open cursor | OPEN cursor twice without CLOSE |
| **ACCESS_INTO_NULL** | NULL collection/record | Reference field in NULL record |
| **COLLECTION_IS_NULL** | NULL nested table/VARRAY | Iterate over NULL collection |

### Examples by Scenario

**NO_DATA_FOUND — Most Common**

```sql
DECLARE
  v_salary employees.salary%TYPE;
BEGIN
  SELECT salary INTO v_salary
  FROM employees
  WHERE employee_id = 99999;  -- This employee doesn't exist
  
  DBMS_OUTPUT.PUT_LINE('Salary: ' || v_salary);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Employee not found');
    -- Could also: INSERT audit log, SET default value, RETURN, etc.
END;
/
-- Output: Employee not found
```

**TOO_MANY_ROWS — Multiple Results**

```sql
DECLARE
  v_name employees.first_name%TYPE;
BEGIN
  SELECT first_name INTO v_name
  FROM employees
  WHERE department_id = 10;  -- Multiple employees in dept 10!
  
  DBMS_OUTPUT.PUT_LINE('Name: ' || v_name);
EXCEPTION
  WHEN TOO_MANY_ROWS THEN
    DBMS_OUTPUT.PUT_LINE('Query returned multiple rows, using cursor instead');
END;
/
-- Output: Query returned multiple rows, using cursor instead
```

**ZERO_DIVIDE — Math Error**

```sql
DECLARE
  v_commission_rate NUMBER;
  v_years_employed NUMBER := 0;  -- Oops!
BEGIN
  v_commission_rate := 10000 / v_years_employed;  -- Division by zero!
EXCEPTION
  WHEN ZERO_DIVIDE THEN
    DBMS_OUTPUT.PUT_LINE('Error: Cannot divide by zero years');
    v_commission_rate := 0;  -- Default value
END;
/
-- Output: Error: Cannot divide by zero years
```

**DUP_VAL_ON_INDEX — Duplicate Key**

```sql
BEGIN
  INSERT INTO employees (employee_id, first_name, last_name)
  VALUES (100, 'John', 'Smith');  -- employee_id=100 already exists!
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
    DBMS_OUTPUT.PUT_LINE('Employee ID already exists');
    -- Could RETRY with different ID, UPDATE existing, or SKIP
END;
/
-- Output: Employee ID already exists
```

---

**➡ Transition:** Predefined exceptions cover common database errors. But what about Oracle errors that DON'T have predefined names?

---

## 4. Catching Predefined Exceptions

### Basic EXCEPTION Block Structure

```sql
BEGIN
  -- Executable statements
EXCEPTION
  WHEN exception_1 THEN
    -- Handle exception_1
  WHEN exception_2 THEN
    -- Handle exception_2
  WHEN OTHERS THEN
    -- Catch anything not matched above (fallback)
END;
/
```

### Catching Multiple Exceptions in One Handler

```sql
BEGIN
  -- Some operation
EXCEPTION
  WHEN NO_DATA_FOUND OR VALUE_ERROR THEN
    -- Same recovery for both
    DBMS_OUTPUT.PUT_LINE('Data validation failed');
  WHEN OTHERS THEN
    -- Unexpected error
    DBMS_OUTPUT.PUT_LINE('Unexpected error occurred');
END;
/
```

### Full Example: Robust Employee Query

```sql
DECLARE
  v_employee_id employees.employee_id%TYPE := 101;
  v_name employees.first_name%TYPE;
  v_salary employees.salary%TYPE;
BEGIN
  SELECT first_name, salary
  INTO v_name, v_salary
  FROM employees
  WHERE employee_id = v_employee_id;
  
  DBMS_OUTPUT.PUT_LINE('Employee: ' || v_name || ', Salary: ' || v_salary);

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Employee ' || v_employee_id || ' not found');
  WHEN TOO_MANY_ROWS THEN
    -- Shouldn't happen with PK, but possible with logic error
    DBMS_OUTPUT.PUT_LINE('ERROR: Multiple employees with same ID');
  WHEN VALUE_ERROR THEN
    DBMS_OUTPUT.PUT_LINE('Data type mismatch in SELECT INTO');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Unexpected error: ' || SQLCODE || ' - ' || SQLERRM);
END;
/
```

### Using SQLCODE and SQLERRM

Inside exception handler, get error details:

```sql
BEGIN
  -- Something fails
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error Code: ' || SQLCODE);      -- -20001, -1, etc.
    DBMS_OUTPUT.PUT_LINE('Error Message: ' || SQLERRM);   -- Full error text
    -- Log to table for debugging
    INSERT INTO error_log (error_code, error_msg, timestamp)
    VALUES (SQLCODE, SQLERRM, SYSDATE);
END;
/
```

---

**➡ Transition:** Predefined exceptions handle most common errors. But Oracle has hundreds of error codes without predefined names. Let's handle those.

---

## 5. Non-Predefined Exceptions: Oracle Errors with No Names

### The Problem: Errors Without Names

**Scenario:** You want to catch a specific Oracle error, but it has no predefined name.

Example: ORA-02291 (Foreign Key Constraint Violation)

```sql
BEGIN
  INSERT INTO employees (employee_id, department_id)
  VALUES (1, 9999);  -- department_id=9999 doesn't exist!
EXCEPTION
  WHEN ??? THEN  -- No predefined exception for this error!
    DBMS_OUTPUT.PUT_LINE('Invalid department');
END;
/
-- Error: unhandled exception ORA-02291
```

**Problem:** Can't catch it by name because Oracle never named it.

### The Solution: PRAGMA EXCEPTION_INIT
PRAGMA EXCEPTION_INIT allows you to assign a name to an Oracle error code, so you can catch it in your EXCEPTION block.

Give a name to the Oracle error using PRAGMA EXCEPTION_INIT:

```sql
DECLARE
  -- Step 1: Define your exception name
  e_invalid_department EXCEPTION;
  
  -- Step 2: Assign it to Oracle error code
  PRAGMA EXCEPTION_INIT(e_invalid_department, -1400);
BEGIN
  INSERT INTO employees (employee_id, department_id)
  VALUES (1, 9999);

  excEPTION
    WHEN e_invalid_department THEN
      DBMS_OUTPUT.PUT_LINE('Invalid department - does not exist');
  
END;
/
```

### How It Works

```
┌─────────────────────────────────┐
│ DECLARE                         │
│  e_invalid_dep EXCEPTION;       │ ← Step 1: Name it
│  PRAGMA EXCEPTION_INIT(...)     │ ← Step 2: Link to error code
└─────────────────────────────────┘
           ↓
┌─────────────────────────────────┐
│ BEGIN                           │
│  [Code that causes error]       │
└─────────────────────────────────┘
           ↓
    Oracle error -2291 occurs
           ↓
    PL/SQL sees: "Is this -2291?"
           ↓
    "Yes! It matches e_invalid_dep"
           ↓
┌─────────────────────────────────┐
│ EXCEPTION                       │
│  WHEN e_invalid_dep THEN        │ ← Caught by name!
│    [Recovery]                   │
└─────────────────────────────────┘
```

### Common Non-Predefined Exception Codes

| Error Code | Meaning | Handling |
| --- | --- | --- |
| **-2291** | Foreign key violated | "Invalid department/parent record" |
| **-2292** | Child record exists | "Cannot delete, has dependent records" |
| **-20000 to -20999** | Application errors (user-defined) | Business logic errors |
| **-6502** | Numeric value too large | Data overflow |
| **-6531** | Subscript outside bounds | Array/collection index out of range |
| **-4091** | DML restricted | Attempting DML in certain contexts |

### Full Example: Handling Multiple Non-Predefined Exceptions

```sql
DECLARE
  e_fk_constraint EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_fk_constraint, -2291);
  
  e_child_exists EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_child_exists, -2292);
BEGIN
  -- Try to delete department
  DELETE FROM departments WHERE department_id = 10;
  
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Department deleted successfully');

EXCEPTION
  WHEN e_child_exists THEN
    DBMS_OUTPUT.PUT_LINE('Cannot delete department - employees still assigned');
    ROLLBACK;
  WHEN e_fk_constraint THEN
    DBMS_OUTPUT.PUT_LINE('Invalid foreign key reference');
    ROLLBACK;
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Unexpected error: ' || SQLERRM);
    ROLLBACK;
END;
/
```

---

**➡ Transition:** Now you can handle both predefined and non-predefined Oracle errors. But what about custom business logic errors?

---

## 6. Assigning Names to Non-Predefined Exceptions

### Step-by-Step Process

**Step 1: Declare the exception**

```sql
DECLARE
  e_invalid_salary EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_invalid_salary, -20001);
```

**Step 2: Choose error code (-20000 to -20999 = Application errors)**

Best practice: Reserve ranges:
- -20001 to -20099 = Salary validations
- -20100 to -20199 = Department validations
- -20200 to -20299 = Employee status validations

**Step 3: Use in your code**

```sql
BEGIN
  IF salary < 0 THEN
    RAISE e_invalid_salary;  -- Manually trigger it
  END IF;
EXCEPTION
  WHEN e_invalid_salary THEN
    DBMS_OUTPUT.PUT_LINE('Salary cannot be negative');
END;
/
```



### Production Pattern: Procedure with Named Non-Predefined Exception

```sql
CREATE OR REPLACE PROCEDURE hire_employee(
  p_emp_id IN employees.employee_id%TYPE,
  p_dept_id IN employees.department_id%TYPE
) IS
  e_invalid_dept EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_invalid_dept, -2291);  -- FK violation
  
  e_duplicate_emp EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_duplicate_emp, -1);     -- Unique constraint
BEGIN
  INSERT INTO employees (employee_id, department_id)
  VALUES (p_emp_id, p_dept_id);
  
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Employee hired successfully');

EXCEPTION
  WHEN e_invalid_dept THEN
    DBMS_OUTPUT.PUT_LINE('Department does not exist');
    ROLLBACK;
  WHEN e_duplicate_emp THEN
    DBMS_OUTPUT.PUT_LINE('Employee ID already exists');
    ROLLBACK;
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
    ROLLBACK;
END hire_employee;
/
```

---

**➡ Transition:** Non-predefined exceptions handle Oracle's built-in errors. Now let's create custom exceptions for YOUR business rules.

---

## 7. User-Defined Exceptions: Custom Business Rules

### What Are User-Defined Exceptions?

**User-defined exceptions** = You create them for business logic that isn't enforced by database.

**Predefined:** "This salary is 'ABC' (not a number)" ← Database enforces
**User-defined:** "This salary is negative" ← Your business rule

### When to Use User-Defined Exceptions

✅ Business validations (salary range, age limit, status checks)
✅ Complex conditions (sum of values exceeds budget)
✅ Multi-step validations (A AND B AND C must all pass)
✅ Policy enforcement (duplicate accounts not allowed)

❌ Don't use for: Simple IF logic (use IF/ELSE instead)
❌ Don't use for: Data type errors (let Oracle raise them)

### Declaring User-Defined Exceptions

```sql
DECLARE
  -- Just declare—no error code needed
  e_invalid_salary EXCEPTION;
  e_duplicate_account EXCEPTION;
  e_insufficient_funds EXCEPTION;
BEGIN
  -- Use them later
END;
/
```

### Complete Example: Employee Salary Validation

```sql
DECLARE
  -- User-defined exceptions for business rules
  e_salary_too_low EXCEPTION;
  e_salary_too_high EXCEPTION;
  e_invalid_department EXCEPTION;
  
  -- Variables
  v_min_salary NUMBER := 1000;
  v_max_salary NUMBER := 500000;
  v_new_salary employees.salary%TYPE := 50000;
  v_department_id employees.department_id%TYPE := 10;
BEGIN
  -- Validation 1: Salary range
  IF v_new_salary < v_min_salary THEN
    RAISE e_salary_too_low;
  END IF;
  
  IF v_new_salary > v_max_salary THEN
    RAISE e_salary_too_high;
  END IF;
  
  -- Validation 2: Department exists
  IF NOT department_exists(v_department_id) THEN
    RAISE e_invalid_department;
  END IF;
  
  -- All validations passed—update salary
  UPDATE employees SET salary = v_new_salary
  WHERE employee_id = 101;
  
  DBMS_OUTPUT.PUT_LINE('Salary updated successfully');

EXCEPTION
  WHEN e_salary_too_low THEN
    DBMS_OUTPUT.PUT_LINE('ERROR: Salary ' || v_new_salary || ' is below minimum ' || v_min_salary);
  WHEN e_salary_too_high THEN
    DBMS_OUTPUT.PUT_LINE('ERROR: Salary ' || v_new_salary || ' exceeds maximum ' || v_max_salary);
  WHEN e_invalid_department THEN
    DBMS_OUTPUT.PUT_LINE('ERROR: Department ' || v_department_id || ' does not exist');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Unexpected error: ' || SQLERRM);
END;
/
```

---

**➡ Transition:** User-defined exceptions need to be triggered. Let's see how to raise them.

---

## 8. Raising User-Defined Exceptions

### The RAISE Statement

**Syntax:**
```sql
RAISE exception_name;  -- Throw an exception
RAISE exception_name WITH MESSAGE;  -- (Oracle 10g+, conditional)
```

### Three Ways to Raise

**Method 1: RAISE explicitly**

```sql
IF salary < 0 THEN
  RAISE e_invalid_salary;  -- Throw it
END IF;
```

**Method 2: RAISE in exception handler (re-raise)**

```sql
EXCEPTION
  WHEN e_invalid_salary THEN
    DBMS_OUTPUT.PUT_LINE('Invalid salary detected');
    RAISE;  -- Re-throw to outer block
END;
```

**Method 3: Raise with custom message (RAISE_APPLICATION_ERROR)**

```sql
IF salary < 0 THEN
  RAISE_APPLICATION_ERROR(-20001, 'Salary cannot be negative');
END IF;
```

### Full Example: Procedure That Raises User-Defined Exceptions

```sql
CREATE OR REPLACE PROCEDURE give_raise(
  p_emp_id IN employees.employee_id%TYPE,
  p_raise_percent IN NUMBER
) IS
  e_invalid_raise EXCEPTION;
  e_employee_not_found EXCEPTION;
  
  v_current_salary employees.salary%TYPE;
  v_new_salary employees.salary%TYPE;
  v_emp_count NUMBER;
BEGIN
  -- Validation 1: Raise percentage is positive
  IF p_raise_percent <= 0 OR p_raise_percent > 50 THEN
    RAISE e_invalid_raise;
  END IF;
  
  -- Validation 2: Employee exists
  SELECT COUNT(*) INTO v_emp_count
  FROM employees
  WHERE employee_id = p_emp_id;
  
  IF v_emp_count = 0 THEN
    RAISE e_employee_not_found;
  END IF;
  
  -- Get current salary
  SELECT salary INTO v_current_salary
  FROM employees
  WHERE employee_id = p_emp_id;
  
  -- Calculate new salary
  v_new_salary := v_current_salary * (1 + p_raise_percent / 100);
  
  -- Update
  UPDATE employees SET salary = v_new_salary
  WHERE employee_id = p_emp_id;
  
  DBMS_OUTPUT.PUT_LINE('Raise applied: ' || p_emp_id || ' from ' || v_current_salary || ' to ' || v_new_salary);

EXCEPTION
  WHEN e_invalid_raise THEN
    RAISE_APPLICATION_ERROR(-20001, 'Raise must be between 0 and 50 percent');
  WHEN e_employee_not_found THEN
    RAISE_APPLICATION_ERROR(-20002, 'Employee ' || p_emp_id || ' not found');
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20099, 'Unexpected error: ' || SQLERRM);
END give_raise;
/

-- Execute it
EXEC give_raise(101, 10);  -- OK: 10% raise
EXEC give_raise(101, 100); -- ERROR: Raise too high
EXEC give_raise(9999, 10); -- ERROR: Employee not found
```

### RAISE_APPLICATION_ERROR vs RAISE

| Aspect | RAISE | RAISE_APPLICATION_ERROR |
| --- | --- | --- |
| **Syntax** | `RAISE e_name;` | `RAISE_APPLICATION_ERROR(-20NNN, 'message');` |
| **Error Code** | None (custom exception) | -20001 to -20999 (app errors) |
| **Message** | From WHEN handler | Custom message embedded |
| **Use Case** | Internal to block | Propagate to caller with context |

---

**➡ Transition:** When you RAISE an exception, it doesn't stop at current block. It propagates up. Let's understand exception scope.

---

## 9. Exception Scope and Propagation

### How Exceptions Propagate

```
Outer Block
  ↓
Middle Block
  ↓
Inner Block ← Exception raised here
  ├─ Is it caught in Inner Block?
  │   YES → Handle it, continue
  │   NO  → Propagate up to Middle Block
  ↓
Middle Block
  ├─ Is it caught in Middle Block?
  │   YES → Handle it, continue
  │   NO  → Propagate up to Outer Block
  ↓
Outer Block
  ├─ Is it caught in Outer Block?
  │   YES → Handle it, continue
  │   NO  → Propagate to caller / crash
```

### Example: Nested Blocks with Propagation

```sql
DECLARE
  e_custom EXCEPTION;
BEGIN
  DBMS_OUTPUT.PUT_LINE('1. Outer block started');
  
  BEGIN  -- Middle block
    DBMS_OUTPUT.PUT_LINE('2. Middle block started');
    
    BEGIN  -- Inner block
      DBMS_OUTPUT.PUT_LINE('3. Inner block started');
      RAISE e_custom;  -- Exception raised here
      DBMS_OUTPUT.PUT_LINE('4. Never reaches here');
      
    EXCEPTION
      WHEN e_custom THEN
        DBMS_OUTPUT.PUT_LINE('5. Inner block caught it - STOP');
        -- Exception stops propagating
    END;  -- Inner block ends
    
    DBMS_OUTPUT.PUT_LINE('6. Middle block continues after inner');
    
  EXCEPTION
    WHEN e_custom THEN
      DBMS_OUTPUT.PUT_LINE('7. Middle block would catch here (but inner already caught it)');
  END;  -- Middle block ends
  
  DBMS_OUTPUT.PUT_LINE('8. Outer block continues');
  
EXCEPTION
  WHEN e_custom THEN
    DBMS_OUTPUT.PUT_LINE('9. Outer block would catch here');
END;
/

-- Output:
-- 1. Outer block started
-- 2. Middle block started
-- 3. Inner block started
-- 5. Inner block caught it - STOP
-- 6. Middle block continues after inner
-- 8. Outer block continues
```

### Re-Raising Exceptions (Propagate Upward)

Sometimes you want to handle an exception but let the caller know it happened:

```sql
DECLARE
  e_custom EXCEPTION;
BEGIN
  BEGIN
    RAISE e_custom;
  EXCEPTION
    WHEN e_custom THEN
      DBMS_OUTPUT.PUT_LINE('Inner: Logged the error');
      -- Log it, but pass it along
      RAISE;  -- Re-raise to outer block
  END;
EXCEPTION
  WHEN e_custom THEN
    DBMS_OUTPUT.PUT_LINE('Outer: Received re-raised exception');
END;
/

-- Output:
-- Inner: Logged the error
-- Outer: Received re-raised exception
```

### Scope Rule: Exception Available Only in Declaring Block

```sql
DECLARE
  e_inner_exception EXCEPTION;  -- Declared in outer scope
BEGIN
  BEGIN  -- Inner block
    RAISE e_inner_exception;  -- OK, declared in outer
  EXCEPTION
    WHEN e_inner_exception THEN
      DBMS_OUTPUT.PUT_LINE('Inner block caught it');
  END;
  
  BEGIN  -- Another inner block
    -- Can't declare e_other EXCEPTION here and use it in outer
    DECLARE
      e_local EXCEPTION;  -- Local to this block
    BEGIN
      RAISE e_local;
    EXCEPTION
      WHEN e_local THEN
        -- Can only catch locally
        DBMS_OUTPUT.PUT_LINE('Local exception caught');
    END;
  END;
END;
/
```

---

**➡ Transition:** Now you understand all three exception types. Let's compare them.

---

## 10. Comparison: Predefined vs Non-Predefined vs User-Defined

### Decision Matrix

| Aspect | Predefined | Non-Predefined | User-Defined |
| --- | --- | --- | --- |
| **How Triggered** | Automatically (database error) | Automatically (database error) | Manual (RAISE statement) |
| **Oracle Named It?** | Yes (built-in names) | No (you name with PRAGMA) | No (you create) |
| **Declaration** | No declaration | DECLARE + PRAGMA | DECLARE only |
| **Error Code** | Not assigned in code | -1, -20NNN, etc. (PRAGMA) | No error code (just thrown) |
| **Example** | NO_DATA_FOUND | FK violation (-2291) | Invalid salary |
| **When Catch** | WHEN NO_DATA_FOUND | WHEN e_fk_error | WHEN e_invalid_salary |
| **When Raise** | Never (auto) | Never (auto) | Manual: RAISE e_name |
| **Typical Scenario** | Database rejects operation | Specific DB constraint violated | Business rule violated |

### When to Use Each

**Predefined:**
```sql
-- Use when Oracle error has built-in name
WHEN NO_DATA_FOUND THEN        -- SELECT INTO found nothing
WHEN TOO_MANY_ROWS THEN        -- SELECT INTO found multiple
WHEN ZERO_DIVIDE THEN          -- Division by zero
WHEN DUP_VAL_ON_INDEX THEN     -- Unique constraint
```

**Non-Predefined:**
```sql
-- Use when Oracle error has no built-in name but you need to catch it specifically
DECLARE
  e_fk_violated EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_fk_violated, -2291);
BEGIN
  INSERT INTO employees (dept_id) VALUES (9999);  -- Invalid department
EXCEPTION
  WHEN e_fk_violated THEN ... -- Specific FK error
```

**User-Defined:**
```sql
-- Use for business logic validation
DECLARE
  e_salary_invalid EXCEPTION;
BEGIN
  IF salary < minimum_allowed THEN
    RAISE e_salary_invalid;
  END IF;
EXCEPTION
  WHEN e_salary_invalid THEN ...
```

### Real-World Complete Example: All Three Types

```sql
CREATE OR REPLACE PROCEDURE transfer_employee(
  p_emp_id IN employees.employee_id%TYPE,
  p_new_dept_id IN employees.department_id%TYPE
) IS
  -- Non-predefined exception (Oracle error without built-in name)
  e_fk_constraint EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_fk_constraint, -2291);
  
  -- User-defined exception (business rule)
  e_emp_not_found EXCEPTION;
  e_invalid_department EXCEPTION;
  
  v_emp_exists NUMBER;
  v_dept_exists NUMBER;
BEGIN
  -- Step 1: Validate employee exists (business rule)
  SELECT COUNT(*) INTO v_emp_exists
  FROM employees
  WHERE employee_id = p_emp_id;
  
  IF v_emp_exists = 0 THEN
    RAISE e_emp_not_found;
  END IF;
  
  -- Step 2: Validate department exists (business rule)
  SELECT COUNT(*) INTO v_dept_exists
  FROM departments
  WHERE department_id = p_new_dept_id;
  
  IF v_dept_exists = 0 THEN
    RAISE e_invalid_department;
  END IF;
  
  -- Step 3: Update (might trigger FK violation if not valid)
  UPDATE employees
  SET department_id = p_new_dept_id
  WHERE employee_id = p_emp_id;
  
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Employee transferred successfully');

EXCEPTION
  -- Predefined (automatic)
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Unexpected: data query failed');
  
  -- Non-predefined (specific DB constraint)
  WHEN e_fk_constraint THEN
    DBMS_OUTPUT.PUT_LINE('Department constraint violated');
    ROLLBACK;
  
  -- User-defined (business rule)
  WHEN e_emp_not_found THEN
    DBMS_OUTPUT.PUT_LINE('Employee ' || p_emp_id || ' not found');
  WHEN e_invalid_department THEN
    DBMS_OUTPUT.PUT_LINE('Department ' || p_new_dept_id || ' does not exist');
  
  -- Catch-all
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
    ROLLBACK;
END transfer_employee;
/
```

---

**➡ Transition:** Now that you understand all three types, let's explore production best practices.

---

## 11. Best Practices

### 1. Always Catch OTHERS

**Avoid:**
```sql
BEGIN
  UPDATE employees SET salary = 50000;
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
    DBMS_OUTPUT.PUT_LINE('Duplicate');
  -- What if other errors occur?
END;
```

**Prefer:**
```sql
BEGIN
  UPDATE employees SET salary = 50000;
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
    DBMS_OUTPUT.PUT_LINE('Duplicate key');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Unexpected error: ' || SQLERRM);
END;
```

**Why:** Catches unexpected errors instead of crashing silently.

---

### 2. Log Errors for Debugging

**Avoid:**
```sql
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error occurred');
END;
```

**Prefer:**
```sql
EXCEPTION
  WHEN OTHERS THEN
    INSERT INTO error_log (error_code, error_msg, created_date)
    VALUES (SQLCODE, SQLERRM, SYSDATE);
    DBMS_OUTPUT.PUT_LINE('Error logged: ' || SQLCODE);
END;
```

**Why:** Helps production debugging when errors occur unexpectedly.

---

### 3. Use ROLLBACK on Data Modification Errors

**Avoid:**
```sql
BEGIN
  INSERT INTO accounts VALUES (...);
  UPDATE balances SET amount = 100;  -- Might fail
  COMMIT;  -- Don't commit if anything failed
EXCEPTION
  WHEN OTHERS THEN
    NULL;  -- Silent failure
END;
```

**Prefer:**
```sql
BEGIN
  INSERT INTO accounts VALUES (...);
  UPDATE balances SET amount = 100;
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;  -- Undo everything on error
    RAISE;     -- Let caller know
END;
```

**Why:** Prevents partial/inconsistent data updates.

---

### 4. Be Specific in Exception Handling

**Avoid:**
```sql
EXCEPTION
  WHEN OTHERS THEN
    -- Same handling for everything
    DBMS_OUTPUT.PUT_LINE('Error');
END;
```

**Prefer:**
```sql
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Record not found');
  WHEN DUP_VAL_ON_INDEX THEN
    DBMS_OUTPUT.PUT_LINE('Duplicate record');
  WHEN ZERO_DIVIDE THEN
    DBMS_OUTPUT.PUT_LINE('Math error');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Unexpected: ' || SQLERRM);
END;
```

**Why:** Different errors need different recovery strategies.

---

### 5. Provide Context in Error Messages

**Avoid:**
```sql
EXCEPTION
  WHEN e_invalid_salary THEN
    RAISE_APPLICATION_ERROR(-20001, 'Invalid salary');
END;
```

**Prefer:**
```sql
EXCEPTION
  WHEN e_invalid_salary THEN
    RAISE_APPLICATION_ERROR(-20001, 
      'Invalid salary: ' || v_salary || 
      ' (min: ' || v_min || ', max: ' || v_max || ')');
END;
```

**Why:** Error messages with context help users understand what went wrong.

---

### 6. Use Named Exceptions for Complex Logic

**Avoid:**
```sql
BEGIN
  IF salary < 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Salary negative');
  END IF;
  IF salary > 1000000 THEN
    RAISE_APPLICATION_ERROR(-20002, 'Salary too high');
  END IF;
END;
```

**Prefer:**
```sql
DECLARE
  e_salary_negative EXCEPTION;
  e_salary_excessive EXCEPTION;
BEGIN
  IF salary < 0 THEN
    RAISE e_salary_negative;
  END IF;
  IF salary > 1000000 THEN
    RAISE e_salary_excessive;
  END IF;
EXCEPTION
  WHEN e_salary_negative THEN
    RAISE_APPLICATION_ERROR(-20001, 'Salary cannot be negative');
  WHEN e_salary_excessive THEN
    RAISE_APPLICATION_ERROR(-20002, 'Salary exceeds maximum allowed');
END;
```

**Why:** Named exceptions make code readable and maintainable.

---

## 12. Common Mistakes

### Mistake 1: Ignoring NULL Results

**Problem:**
```sql
DECLARE
  v_salary employees.salary%TYPE;
BEGIN
  SELECT salary INTO v_salary
  FROM employees
  WHERE employee_id = 101;
  -- What if employee doesn't exist?
END;
```

**Why it fails:** NO_DATA_FOUND crashes program.

**Solution:**
```sql
BEGIN
  SELECT salary INTO v_salary
  FROM employees
  WHERE employee_id = 101;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_salary := 0;  -- Default value
    DBMS_OUTPUT.PUT_LINE('Employee not found, using default salary');
END;
```

---

### Mistake 2: Not Rolling Back on Error

**Problem:**
```sql
BEGIN
  INSERT INTO orders VALUES (...);
  INSERT INTO order_items VALUES (...);  -- Fails
  COMMIT;  -- Commits partial data!
EXCEPTION
  WHEN OTHERS THEN
    NULL;  -- Ignore error
END;
```

**Why it fails:** Orders created without items.

**Solution:**
```sql
BEGIN
  INSERT INTO orders VALUES (...);
  INSERT INTO order_items VALUES (...);
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;  -- Undo all changes
    RAISE;
END;
```

---

### Mistake 3: Over-Catching with OTHERS

**Problem:**
```sql
EXCEPTION
  WHEN OTHERS THEN
    -- Catches everything, hides bugs
    DBMS_OUTPUT.PUT_LINE('Error');
END;
```

**Why it fails:** You miss real bugs because all errors look the same.

**Solution:**
```sql
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Not found');
  WHEN DUP_VAL_ON_INDEX THEN
    DBMS_OUTPUT.PUT_LINE('Duplicate');
  WHEN OTHERS THEN
    -- Only catch truly unexpected errors
    DBMS_OUTPUT.PUT_LINE('Unexpected: ' || SQLERRM);
END;
```

---

### Mistake 4: Using OTHERS Instead of Specific Exception

**Problem:**
```sql
DECLARE
  e_fk EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_fk, -2291);
BEGIN
  INSERT INTO employees (dept_id) VALUES (9999);
EXCEPTION
  WHEN OTHERS THEN  -- Vague
    IF SQLCODE = -2291 THEN
      DBMS_OUTPUT.PUT_LINE('FK violated');
    END IF;
END;
```

**Why it fails:** Code is harder to read.

**Solution:**
```sql
BEGIN
  INSERT INTO employees (dept_id) VALUES (9999);
EXCEPTION
  WHEN e_fk THEN  -- Specific, clear
    DBMS_OUTPUT.PUT_LINE('FK violated');
END;
```

---

### Mistake 5: Declaring Exception but Never Using It

**Problem:**
```sql
DECLARE
  e_invalid_salary EXCEPTION;  -- Declared
BEGIN
  IF salary < 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Salary negative');  -- Raised differently!
  END IF;
EXCEPTION
  WHEN e_invalid_salary THEN  -- Never caught
    DBMS_OUTPUT.PUT_LINE('Invalid');
END;
```

**Why it fails:** Exception raised but never caught by matching WHEN clause.

**Solution:**
```sql
DECLARE
  e_invalid_salary EXCEPTION;
BEGIN
  IF salary < 0 THEN
    RAISE e_invalid_salary;  -- Raise matching exception
  END IF;
EXCEPTION
  WHEN e_invalid_salary THEN  -- Now it's caught
    DBMS_OUTPUT.PUT_LINE('Invalid salary');
END;
```

---

### Mistake 6: Not Handling Data Modification Errors

**Problem:**
```sql
BEGIN
  FOR emp IN (SELECT * FROM employees)
  LOOP
    UPDATE salary_history SET salary = emp.salary;
    -- If one update fails, others continue without knowing
  END LOOP;
END;
```

**Solution:**
```sql
BEGIN
  FOR emp IN (SELECT * FROM employees)
  LOOP
    BEGIN
      UPDATE salary_history SET salary = emp.salary
      WHERE employee_id = emp.employee_id;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Failed for employee ' || emp.employee_id || ': ' || SQLERRM);
        -- Log and continue
    END;
  END LOOP;
END;
```

---

## 13. Interview Q&A

### Conceptual Questions

**Q: What's the difference between predefined and user-defined exceptions?**

A: **Predefined exceptions** are named by Oracle for common database errors (NO_DATA_FOUND, TOO_MANY_ROWS, ZERO_DIVIDE). **User-defined exceptions** are created by you for business logic validation (salary range checks, duplicate detection). Predefined are automatic; user-defined require manual RAISE.

---

**Q: When would you use PRAGMA EXCEPTION_INIT?**

A: When you need to catch a specific **non-predefined Oracle error** (one without a built-in name). PRAGMA EXCEPTION_INIT associates an error code (-2291 for FK, -1 for unique) with an exception name. Example: catching -2291 (foreign key violation) specifically instead of using OTHERS.

---

**Q: What happens if an exception is raised but not caught in the current block?**

A: The exception **propagates up** to the outer block's EXCEPTION section. If caught there, recovery happens. If not caught anywhere, program terminates with error. This is called **exception propagation**.

---

### Comparison Questions

**Q: NO_DATA_FOUND vs a user-defined exception for "employee not found"?**

A: 

| Aspect | NO_DATA_FOUND | User-Defined |
| --- | --- | --- |
| **Triggered** | Automatically (SELECT returns 0 rows) | Manual (RAISE statement) |
| **Usage** | When SELECT INTO fails | When business logic checks fail |
| **Example** | `SELECT salary INTO v_sal FROM employees WHERE id=1;` (1 doesn't exist) | Check COUNT(*) = 0, then RAISE |
| **Best for** | Database layer errors | Validation before operation |

Use **NO_DATA_FOUND** for actual SELECT failures. Use **user-defined** for pre-checks that might have business logic.

---

**Q: RAISE vs RAISE_APPLICATION_ERROR?**

A: 

| RAISE | RAISE_APPLICATION_ERROR |
| --- | --- |
| Re-raises current exception or throws declared exception | Throws error with code (-20NNN) and message |
| `RAISE e_name;` | `RAISE_APPLICATION_ERROR(-20001, 'msg');` |
| Local to block | Propagates with error code to caller |
| For internal flow | For API/external communication |

Use **RAISE** to throw user-defined exceptions in internal logic. Use **RAISE_APPLICATION_ERROR** to report errors to stored procedure callers.

---

### Scenario Questions

**Q: Employee hire procedure must validate salary range, check department exists, and avoid duplicate IDs. How would you structure exception handling?**

A:
```sql
DECLARE
  e_salary_low EXCEPTION;       -- User-defined
  e_salary_high EXCEPTION;      -- User-defined
  e_invalid_dept EXCEPTION;     -- User-defined
  e_duplicate_id EXCEPTION;     -- User-defined
  PRAGMA EXCEPTION_INIT(e_duplicate_id, -1);  -- For unique constraint
BEGIN
  -- Validation 1: Salary range
  IF p_salary < 10000 THEN RAISE e_salary_low; END IF;
  IF p_salary > 500000 THEN RAISE e_salary_high; END IF;
  
  -- Validation 2: Department exists
  IF NOT dept_exists(p_dept_id) THEN
    RAISE e_invalid_dept;
  END IF;
  
  -- Insert (might fail with duplicate ID)
  INSERT INTO employees VALUES (p_emp_id, p_name, p_salary, p_dept_id);
  COMMIT;
  
EXCEPTION
  WHEN e_salary_low THEN
    RAISE_APPLICATION_ERROR(-20010, 'Salary below minimum: ' || p_salary);
  WHEN e_salary_high THEN
    RAISE_APPLICATION_ERROR(-20011, 'Salary exceeds maximum: ' || p_salary);
  WHEN e_invalid_dept THEN
    RAISE_APPLICATION_ERROR(-20012, 'Invalid department: ' || p_dept_id);
  WHEN e_duplicate_id THEN
    RAISE_APPLICATION_ERROR(-20013, 'Employee ID already exists: ' || p_emp_id);
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20099, 'Hire failed: ' || SQLERRM);
END;
```

---

## 14. Revision Summary

### 1-Minute Recap

**Exception handling** = Detect errors (EXCEPTION block), catch them (WHEN clause), recover (handler code)

Three types:
1. **Predefined** → Oracle named it (NO_DATA_FOUND, ZERO_DIVIDE)
2. **Non-Predefined** → Oracle error, you name it (PRAGMA EXCEPTION_INIT)
3. **User-Defined** → You create it for business rules

Pattern:
```
BEGIN
  [code that might fail]
EXCEPTION
  WHEN specific_error THEN recovery
  WHEN OTHERS THEN catch-all
END;
```

---

### Interview Keywords

- **NO_DATA_FOUND** → SELECT INTO returns 0 rows
- **TOO_MANY_ROWS** → SELECT INTO returns 2+ rows
- **ZERO_DIVIDE** → Division by zero
- **DUP_VAL_ON_INDEX** → Unique key violation
- **PRAGMA EXCEPTION_INIT** → Link error code to exception name
- **RAISE** → Throw exception manually
- **RAISE_APPLICATION_ERROR** → Report error to caller (-20NNN)
- **Exception propagation** → Unhandled exception moves to outer block
- **OTHERS** → Catch-all for unexpected errors
- **ROLLBACK** → Undo changes on error
- **SQLCODE, SQLERRM** → Get error code and message

---

### Important Syntax & Patterns

```sql
-- PREDEFINED EXCEPTION
BEGIN
  SELECT salary INTO v_sal FROM employees WHERE id = 1;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_sal := 0;
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- NON-PREDEFINED EXCEPTION
DECLARE
  e_fk_error EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_fk_error, -2291);
BEGIN
  INSERT INTO employees (dept_id) VALUES (9999);
EXCEPTION
  WHEN e_fk_error THEN
    DBMS_OUTPUT.PUT_LINE('Invalid department');
END;
/

-- USER-DEFINED EXCEPTION
DECLARE
  e_invalid_salary EXCEPTION;
BEGIN
  IF p_salary < 0 THEN
    RAISE e_invalid_salary;
  END IF;
EXCEPTION
  WHEN e_invalid_salary THEN
    RAISE_APPLICATION_ERROR(-20001, 'Salary cannot be negative');
END;
/

-- PROPAGATION & RE-RAISE
BEGIN
  BEGIN
    RAISE e_custom;
  EXCEPTION
    WHEN e_custom THEN
      DBMS_OUTPUT.PUT_LINE('Logged');
      RAISE;  -- Re-raise to outer block
  END;
EXCEPTION
  WHEN e_custom THEN
    DBMS_OUTPUT.PUT_LINE('Outer handler');
END;
/
```

---

**✅ You now understand all three exception types and how to use them in production code!**
