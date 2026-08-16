# PL/SQL Procedures and Functions: Comprehensive Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Procedure** = Named PL/SQL program that PERFORMS AN ACTION; can return values via OUT/IN OUT parameters; does not have RETURN datatype.
- **Function** = Named PL/SQL program that RETURNS ONE VALUE; must have RETURN datatype; callable from SQL queries in SELECT, WHERE, ORDER BY.
- **Parameter modes:** IN (caller sends, read-only), OUT (procedure returns, write-only), IN OUT (caller sends + procedure modifies + returns).
- **%TYPE** = Anchored parameter type to table column; auto-updates if column type changes; preferred for maintainability.
- **Validation at boundary** = Check inputs (NOT NULL, valid range, foreign keys) BEFORE modifying data; raise RAISE_APPLICATION_ERROR.
- **Transaction ownership** = Caller usually controls COMMIT/ROLLBACK; procedures avoid COMMIT unless they own complete business transaction.
- **Nested subprogram** = Procedure or function declared inside another block; visible only to enclosing unit; private helper logic.
- **Overloading** = Same procedure/function name with DIFFERENT parameter lists (count, type, order); compile-time signature matching.
- **RETURN clause** = Required in functions; must return on every successful path; missing RETURN raises error.
- **Best practice** = Keep public contract small; validate at boundary; use %TYPE; avoid premature COMMIT; let caller own transactions.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Procedures and Functions?](#1-why-do-we-need-procedures-and-functions)
2. [What Are Procedures and Functions?](#2-what-are-procedures-and-functions)
3. [Procedures: Performing Actions](#3-procedures-performing-actions)
4. [Functions: Returning Values](#4-functions-returning-values)
5. [Parameter Modes: IN, OUT, IN OUT](#5-parameter-modes-in-out-in-out)
6. [Anchored Parameter Types (%TYPE)](#6-anchored-parameter-types-type)
7. [Validation and Error Handling](#7-validation-and-error-handling)
8. [Nested Subprograms (Local Procedures/Functions)](#8-nested-subprograms-local-proceduresfunctions)
9. [Overloading: Same Name, Different Signatures](#9-overloading-same-name-different-signatures)
10. [Transaction Ownership and Control](#10-transaction-ownership-and-control)
11. [Functions in SQL vs PL/SQL](#11-functions-in-sql-vs-plsql)
12. [Real-World Production Scenarios](#12-real-world-production-scenarios)
13. [Comparison Matrix](#13-comparison-matrix)
14. [Best Practices](#14-best-practices)
15. [Common Mistakes](#15-common-mistakes)
16. [Interview Q&A](#16-interview-qa)
17. [Revision Summary](#17-revision-summary)

---

## 1. Why Do We Need Procedures and Functions?

### The Problem: Repeated Business Logic

Copying the same code into multiple places causes:
- **Inconsistent rules** (same rule implemented differently in 3 places)
- **Maintenance nightmare** (fix one place, miss the others)
- **No reusability** (different teams write same code independently)
- **Hard to test** (logic scattered across many scripts)

```sql
-- The same salary validation rule copied into multiple scripts
IF p_salary < 10000 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Salary must be at least $10,000');
END IF;

UPDATE employees SET salary = p_salary WHERE employee_id = p_emp_id;
```

**Repeated 5 places = 5 places to maintain!**

### The Solution: Named Program Units

Store logic once in a procedure or function, call it from anywhere:
- **Consistent behavior** (one code path, all callers follow it)
- **Easy maintenance** (fix once, everywhere benefits)
- **Reusable** (SQL, PL/SQL, jobs, applications all call it)
- **Testable** (validate one routine, not 5 copies)

### Real-World Scenarios

| Scenario | Solution |
| --- | --- |
| **Employee onboarding** | Procedure: hire_employee (validates, inserts, sends email) |
| **Monthly bonus calculation** | Function: calculate_bonus (formula reused in payroll) |
| **Data validation** | Function: is_valid_salary (checks constraints before insert) |
| **Batch reporting** | Procedure: generate_monthly_report (aggregates data) |
| **Cleanup tasks** | Procedure: archive_old_records (deletes + logs) |

---

**➡ Transition:** Let's understand the fundamental difference between procedures and functions.

---

## 2. What Are Procedures and Functions?

### Simple Definition

- **Procedure** = Does something (INSERT, UPDATE, DELETE, business logic)
- **Function** = Calculates and returns a value

**Metaphor:**
- Procedure = "Please process this order" (action, no result expected beyond completion)
- Function = "What's the order total?" (question, expect an answer)

### Stored Objects vs Anonymous Blocks

```sql
-- ANONYMOUS BLOCK (not stored)
DECLARE
    v_salary NUMBER := 50000;
BEGIN
    v_salary := v_salary * 1.10;
    DBMS_OUTPUT.PUT_LINE('New salary: ' || v_salary);
END;

-- STORED PROCEDURE (saved in database)
CREATE OR REPLACE PROCEDURE apply_raise (
    p_employee_id IN NUMBER,
    p_percent IN NUMBER
) AS
    v_salary NUMBER;
BEGIN
    SELECT salary INTO v_salary FROM employees WHERE employee_id = p_employee_id;
    v_salary := v_salary * (1 + p_percent / 100);
    UPDATE employees SET salary = v_salary WHERE employee_id = p_employee_id;
END apply_raise;

-- Call from SQL client, job scheduler, application
EXEC apply_raise(101, 10);
```

**Advantages of stored procedures:**
- ✅ Stored once in database
- ✅ Called from anywhere (SQL, jobs, applications)
- ✅ No need to recompile
- ✅ Better security (data validation at database level)
- ✅ Easier to version and audit

---

## 3. Procedures: Performing Actions

### Basic Syntax

```sql
CREATE OR REPLACE PROCEDURE procedure_name (
    parameter1 IN type1,
    parameter2 OUT type2,
    parameter3 IN OUT type3
) AS
BEGIN
    -- Logic here
    NULL;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
        RAISE;
END procedure_name;
/
```

### Example 1: Simple Procedure (No Parameters)

```sql
CREATE OR REPLACE PROCEDURE display_employee_count AS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM employees;
    DBMS_OUTPUT.PUT_LINE('Total employees: ' || v_count);
END display_employee_count;
/

-- Call
EXEC display_employee_count;
-- Output: Total employees: 100
```

### Example 2: Procedure with IN Parameters

```sql
CREATE OR REPLACE PROCEDURE apply_raise (
    p_employee_id IN NUMBER,
    p_percent IN NUMBER
) AS
    v_current_salary NUMBER;
    v_new_salary NUMBER;
BEGIN
    -- Validate inputs
    IF p_percent <= 0 OR p_percent > 50 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Raise percent must be between 0 and 50');
    END IF;
    
    -- Get current salary
    SELECT salary INTO v_current_salary
    FROM employees
    WHERE employee_id = p_employee_id;
    
    -- Calculate new salary
    v_new_salary := v_current_salary * (1 + p_percent / 100);
    
    -- Update
    UPDATE employees
    SET salary = v_new_salary
    WHERE employee_id = p_employee_id;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Salary updated: $' || v_current_salary || ' → $' || v_new_salary);
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Employee ' || p_employee_id || ' not found');
        RAISE_APPLICATION_ERROR(-20002, 'Invalid employee ID');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999, 'Update failed: ' || SQLERRM);
END apply_raise;
/

-- Call
EXEC apply_raise(101, 10);  -- 10% raise to employee 101
```

### Example 3: Procedure with OUT Parameters

```sql
CREATE OR REPLACE PROCEDURE get_employee_details (
    p_employee_id IN NUMBER,
    p_name OUT VARCHAR2,
    p_salary OUT NUMBER,
    p_department OUT VARCHAR2
) AS
BEGIN
    SELECT e.first_name || ' ' || e.last_name, e.salary, d.department_name
    INTO p_name, p_salary, p_department
    FROM employees e
    JOIN departments d ON e.department_id = d.department_id
    WHERE e.employee_id = p_employee_id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Employee not found');
END get_employee_details;
/

-- Call
DECLARE
    v_name VARCHAR2(100);
    v_salary NUMBER;
    v_dept VARCHAR2(50);
BEGIN
    get_employee_details(101, v_name, v_salary, v_dept);
    DBMS_OUTPUT.PUT_LINE('Name: ' || v_name || ', Salary: $' || v_salary || ', Dept: ' || v_dept);
END;
/
```

### Example 4: Procedure with IN OUT Parameters

```sql
CREATE OR REPLACE PROCEDURE adjust_salary_in_place (
    p_employee_id IN NUMBER,
    p_salary IN OUT NUMBER
) AS
    v_adjustment NUMBER;
BEGIN
    -- p_salary comes in with OLD salary
    -- We modify it, caller receives NEW salary
    
    SELECT salary INTO v_adjustment
    FROM employees
    WHERE employee_id = p_employee_id;
    
    -- Modify the parameter (caller's variable)
    p_salary := v_adjustment * 1.15;
    
    -- Update database
    UPDATE employees
    SET salary = p_salary
    WHERE employee_id = p_employee_id;
    
    COMMIT;
END adjust_salary_in_place;
/

-- Call
DECLARE
    v_new_salary NUMBER := 0;  -- Caller sends initial (unused) value
BEGIN
    adjust_salary_in_place(101, v_new_salary);
    DBMS_OUTPUT.PUT_LINE('New salary after 15% increase: $' || v_new_salary);
END;
/
```

---

## 4. Functions: Returning Values

### Basic Syntax

```sql
CREATE OR REPLACE FUNCTION function_name (
    parameter1 IN type1,
    parameter2 IN type2
) RETURN return_type AS
BEGIN
    -- Logic here
    RETURN computed_value;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20999, 'ERROR: ' || SQLERRM);
END function_name;
/
```

**Key difference from procedures:**
- Functions MUST have a RETURN datatype
- Functions MUST return on every success path
- Functions CAN be called from SQL queries

### Example 1: Simple Function (Calculation)

```sql
CREATE OR REPLACE FUNCTION annual_salary (
    p_monthly_salary IN NUMBER
) RETURN NUMBER AS
BEGIN
    IF p_monthly_salary IS NULL THEN
        RETURN NULL;
    END IF;
    RETURN p_monthly_salary * 12;
END annual_salary;
/

-- Call from PL/SQL
BEGIN
    DBMS_OUTPUT.PUT_LINE('Annual: $' || annual_salary(5000));
END;
/

-- Call from SQL (this is the power of functions!)
SELECT employee_id, salary, annual_salary(salary) AS annual
FROM employees
WHERE department_id = 10;
```

### Example 2: Function with Conditional Logic

```sql
CREATE OR REPLACE FUNCTION calculate_bonus (
    p_salary IN NUMBER,
    p_tenure_years IN NUMBER
) RETURN NUMBER AS
    v_bonus_percent NUMBER;
BEGIN
    IF p_tenure_years >= 10 THEN
        v_bonus_percent := 0.20;
    ELSIF p_tenure_years >= 5 THEN
        v_bonus_percent := 0.15;
    ELSIF p_tenure_years >= 1 THEN
        v_bonus_percent := 0.10;
    ELSE
        v_bonus_percent := 0.05;
    END IF;
    
    RETURN ROUND(p_salary * v_bonus_percent, 2);
END calculate_bonus;
/

-- Use in SQL
SELECT 
    employee_id,
    salary,
    calculate_bonus(salary, TRUNC((SYSDATE - hire_date) / 365.25)) AS bonus
FROM employees;
```

### Example 3: Function with Database Query

```sql
CREATE OR REPLACE FUNCTION get_department_name (
    p_dept_id IN NUMBER
) RETURN VARCHAR2 AS
    v_dept_name departments.department_name%TYPE;
BEGIN
    SELECT department_name INTO v_dept_name
    FROM departments
    WHERE department_id = p_dept_id;
    RETURN v_dept_name;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'UNKNOWN';
END get_department_name;
/

-- Use in SQL
SELECT 
    employee_id,
    get_department_name(department_id) AS department
FROM employees;
```

### Example 4: Function Returns a Collection

```sql
CREATE OR REPLACE FUNCTION get_employee_ids (p_dept_id IN NUMBER)
RETURN TABLE OF NUMBER AS
    v_ids TABLE OF NUMBER;
BEGIN
    SELECT employee_id BULK COLLECT INTO v_ids
    FROM employees
    WHERE department_id = p_dept_id;
    RETURN v_ids;
END get_employee_ids;
/

-- Call
DECLARE
    v_emp_ids TABLE OF NUMBER;
BEGIN
    v_emp_ids := get_employee_ids(10);
    FOR i IN 1 .. v_emp_ids.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('ID: ' || v_emp_ids(i));
    END LOOP;
END;
/
```

---

## 5. Parameter Modes: IN, OUT, IN OUT

### IN: Input Parameter (Read-Only)

```sql
CREATE OR REPLACE PROCEDURE log_message (
    p_severity IN VARCHAR2,
    p_message IN VARCHAR2
) AS
BEGIN
    INSERT INTO message_log (severity, message, logged_date)
    VALUES (p_severity, p_message, SYSDATE);
    COMMIT;
    
    -- p_severity and p_message are READ-ONLY
    -- p_severity := 'ERROR';  -- ERROR: Cannot assign to IN parameter
END log_message;
/

-- Call
EXEC log_message('ERROR', 'Database connection failed');
```

### OUT: Output Parameter (Write-Only)

```sql
CREATE OR REPLACE PROCEDURE get_employee_name (
    p_employee_id IN NUMBER,
    p_first_name OUT VARCHAR2,
    p_last_name OUT VARCHAR2
) AS
BEGIN
    SELECT first_name, last_name INTO p_first_name, p_last_name
    FROM employees
    WHERE employee_id = p_employee_id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_first_name := NULL;
        p_last_name := NULL;
END get_employee_name;
/

-- Call
DECLARE
    v_first VARCHAR2(50);
    v_last VARCHAR2(50);
BEGIN
    get_employee_name(101, v_first, v_last);
    DBMS_OUTPUT.PUT_LINE('Name: ' || v_first || ' ' || v_last);
END;
/
```

### IN OUT: Input and Output

```sql
CREATE OR REPLACE PROCEDURE double_value (
    p_value IN OUT NUMBER
) AS
BEGIN
    -- p_value comes in with original value
    -- We modify it
    -- Caller receives the modified value
    p_value := p_value * 2;
END double_value;
/

-- Call
DECLARE
    v_amount NUMBER := 100;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Before: ' || v_amount);
    double_value(v_amount);
    DBMS_OUTPUT.PUT_LINE('After: ' || v_amount);  -- Prints 200
END;
/
```

### Comparison: Parameter Modes

| Mode | Caller Sends | Procedure Reads | Procedure Modifies | Caller Receives |
| --- | --- | --- | --- | --- |
| **IN** | ✅ Value | ✅ Yes | ❌ No | Original value |
| **OUT** | ❌ No | ❌ No | ✅ Yes | New value |
| **IN OUT** | ✅ Value | ✅ Yes | ✅ Yes | Modified value |

---

## 6. Anchored Parameter Types (%TYPE)

### Why Use %TYPE?

`%TYPE` parameter types automatically match column definitions. If the column type changes, parameters adapt automatically.

```sql
-- ❌ BRITTLE: Hard-coded types
CREATE OR REPLACE PROCEDURE hire_employee (
    p_employee_id IN NUMBER,
    p_name IN VARCHAR2
) AS
BEGIN
    -- If employees.employee_id becomes VARCHAR2, this breaks!
    INSERT INTO employees (employee_id, first_name) VALUES (p_employee_id, p_name);
END;

-- ✅ FLEXIBLE: Uses %TYPE
CREATE OR REPLACE PROCEDURE hire_employee (
    p_employee_id IN employees.employee_id%TYPE,
    p_name IN employees.first_name%TYPE
) AS
BEGIN
    -- Automatically matches column type; changes adapt automatically
    INSERT INTO employees (employee_id, first_name) VALUES (p_employee_id, p_name);
END;
```

### Complex Types with %TYPE

```sql
CREATE OR REPLACE PROCEDURE update_employee_record (
    p_employee employees%ROWTYPE
) AS
BEGIN
    UPDATE employees
    SET first_name = p_employee.first_name,
        last_name = p_employee.last_name,
        salary = p_employee.salary
    WHERE employee_id = p_employee.employee_id;
    COMMIT;
END update_employee_record;
/

-- Call
DECLARE
    v_emp employees%ROWTYPE;
BEGIN
    v_emp.employee_id := 101;
    v_emp.first_name := 'John';
    v_emp.last_name := 'Doe';
    v_emp.salary := 75000;
    update_employee_record(v_emp);
END;
/
```

---

## 7. Validation and Error Handling

### Validate Inputs at the Boundary

```sql
CREATE OR REPLACE PROCEDURE update_employee_salary (
    p_employee_id IN employees.employee_id%TYPE,
    p_new_salary IN employees.salary%TYPE
) AS
    v_min_salary CONSTANT NUMBER := 10000;
    v_max_salary CONSTANT NUMBER := 500000;
BEGIN
    -- Validate inputs
    IF p_employee_id IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Employee ID is required');
    END IF;
    
    IF p_new_salary IS NULL THEN
        RAISE_APPLICATION_ERROR(-20002, 'Salary is required');
    END IF;
    
    IF p_new_salary < v_min_salary THEN
        RAISE_APPLICATION_ERROR(-20003, 'Salary must be at least $' || v_min_salary);
    END IF;
    
    IF p_new_salary > v_max_salary THEN
        RAISE_APPLICATION_ERROR(-20004, 'Salary cannot exceed $' || v_max_salary);
    END IF;
    
    -- Perform update
    UPDATE employees
    SET salary = p_new_salary
    WHERE employee_id = p_employee_id;
    
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'Employee ' || p_employee_id || ' not found');
    END IF;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Salary updated successfully');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999, 'Update failed: ' || SQLERRM);
END update_employee_salary;
/
```

### Error Handling Best Practices

```sql
CREATE OR REPLACE PROCEDURE safe_hire_employee (
    p_emp_id IN employees.employee_id%TYPE,
    p_name IN employees.first_name%TYPE,
    p_dept_id IN employees.department_id%TYPE,
    p_success OUT BOOLEAN,
    p_message OUT VARCHAR2
) AS
BEGIN
    p_success := FALSE;
    
    -- Validate department exists
    DECLARE
        v_dept_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_dept_count
        FROM departments
        WHERE department_id = p_dept_id;
        
        IF v_dept_count = 0 THEN
            p_message := 'Department ' || p_dept_id || ' does not exist';
            RETURN;
        END IF;
    END;
    
    -- Insert employee
    INSERT INTO employees (employee_id, first_name, department_id)
    VALUES (p_emp_id, p_name, p_dept_id);
    
    COMMIT;
    p_success := TRUE;
    p_message := 'Employee hired successfully';
    
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        p_message := 'Employee ID ' || p_emp_id || ' already exists';
    WHEN OTHERS THEN
        ROLLBACK;
        p_message := 'Hire failed: ' || SQLERRM;
END safe_hire_employee;
/
```

---

## 8. Nested Subprograms (Local Procedures/Functions)

### Definition

Nested subprograms are declared inside a block and visible only to that block. Use them for private helper logic.

```sql
DECLARE
    -- Private function (visible only in this block)
    FUNCTION is_valid_salary (p_salary IN NUMBER) RETURN BOOLEAN IS
    BEGIN
        RETURN p_salary BETWEEN 10000 AND 500000;
    END is_valid_salary;
    
    -- Private procedure (visible only in this block)
    PROCEDURE log_action (p_action VARCHAR2) IS
    BEGIN
        INSERT INTO audit_log (action, logged_date) VALUES (p_action, SYSDATE);
    END log_action;
    
BEGIN
    -- Main logic can call the nested subprograms
    IF is_valid_salary(75000) THEN
        log_action('ACCEPTED');
    ELSE
        log_action('REJECTED');
    END IF;
END;
/
```

### Real-World Nested Procedure Example

```sql
CREATE OR REPLACE PROCEDURE process_department_payroll (p_dept_id IN NUMBER) AS
    -- Private procedure (only visible in this procedure)
    PROCEDURE pay_employee (p_emp_id IN NUMBER, p_amount IN NUMBER) IS
    BEGIN
        INSERT INTO payroll (employee_id, amount, payment_date)
        VALUES (p_emp_id, p_amount, SYSDATE);
    END pay_employee;
    
    -- Main logic
    v_total_cost NUMBER := 0;
BEGIN
    FOR emp IN (SELECT employee_id, salary FROM employees WHERE department_id = p_dept_id) LOOP
        pay_employee(emp.employee_id, emp.salary);
        v_total_cost := v_total_cost + emp.salary;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Payroll processed. Total: $' || v_total_cost);
END process_department_payroll;
/
```

---

## 9. Overloading: Same Name, Different Signatures

### Definition

Overloading allows the same procedure/function name with DIFFERENT parameter lists.

```sql
-- First version: takes employee ID
CREATE OR REPLACE PROCEDURE get_salary (
    p_employee_id IN NUMBER,
    p_salary OUT NUMBER
) AS
BEGIN
    SELECT salary INTO p_salary FROM employees WHERE employee_id = p_employee_id;
END get_salary;
/

-- Second version: takes employee name
CREATE OR REPLACE PROCEDURE get_salary (
    p_first_name IN VARCHAR2,
    p_last_name IN VARCHAR2,
    p_salary OUT NUMBER
) AS
BEGIN
    SELECT salary INTO p_salary FROM employees 
    WHERE first_name = p_first_name AND last_name = p_last_name;
END get_salary;
/

-- Compiler picks the right one based on parameters
BEGIN
    DECLARE v_sal NUMBER;
    BEGIN
        get_salary(101, v_sal);  -- Calls first version (by ID)
    END;
    
    BEGIN
        get_salary('John', 'Doe', v_sal);  -- Calls second version (by name)
    END;
END;
/
```

### Function Overloading Example

```sql
CREATE OR REPLACE PACKAGE math_utils AS
    FUNCTION add (p1 IN NUMBER, p2 IN NUMBER) RETURN NUMBER;
    FUNCTION add (p1 IN VARCHAR2, p2 IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION add (p1 IN DATE, p2 IN NUMBER) RETURN DATE;
END math_utils;
/

CREATE OR REPLACE PACKAGE BODY math_utils AS
    FUNCTION add (p1 IN NUMBER, p2 IN NUMBER) RETURN NUMBER IS
    BEGIN
        RETURN p1 + p2;
    END add;
    
    FUNCTION add (p1 IN VARCHAR2, p2 IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN p1 || p2;
    END add;
    
    FUNCTION add (p1 IN DATE, p2 IN NUMBER) RETURN DATE IS
    BEGIN
        RETURN p1 + p2;  -- Add days to date
    END add;
END math_utils;
/

-- Usage
BEGIN
    DBMS_OUTPUT.PUT_LINE(math_utils.add(5, 10));  -- 15
    DBMS_OUTPUT.PUT_LINE(math_utils.add('Hello', ' World'));  -- Hello World
    DBMS_OUTPUT.PUT_LINE(math_utils.add(SYSDATE, 30));  -- Date + 30 days
END;
/
```

---

## 10. Transaction Ownership and Control

### Design Rule: Caller Usually Controls Transactions

```sql
-- ❌ WRONG: Procedure commits unilaterally
CREATE OR REPLACE PROCEDURE hire_and_assign (
    p_emp_id IN NUMBER,
    p_dept_id IN NUMBER
) AS
BEGIN
    INSERT INTO employees (employee_id, department_id) VALUES (p_emp_id, p_dept_id);
    COMMIT;  -- Commits immediately; caller can't control transaction
    
    INSERT INTO salary_history (employee_id, salary) VALUES (p_emp_id, 50000);
    COMMIT;  -- If this fails, first insert already committed!
END;

-- ✅ CORRECT: Let caller control transaction
CREATE OR REPLACE PROCEDURE hire_and_assign (
    p_emp_id IN NUMBER,
    p_dept_id IN NUMBER
) AS
BEGIN
    INSERT INTO employees (employee_id, department_id) VALUES (p_emp_id, p_dept_id);
    
    INSERT INTO salary_history (employee_id, salary) VALUES (p_emp_id, 50000);
    
    -- Caller decides whether to COMMIT or ROLLBACK
    -- Both operations succeed or both fail atomically
END;

-- Caller controls transaction
BEGIN
    hire_and_assign(100, 10);
    hire_and_assign(101, 10);
    hire_and_assign(102, 10);
    
    COMMIT;  -- All three succeed together
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;  -- All three roll back together
        RAISE;
END;
```

### Exception: Complete Business Transaction

When a procedure represents a COMPLETE business operation, it may own the transaction:

```sql
CREATE OR REPLACE PROCEDURE complete_month_end_close AS
BEGIN
    -- Step 1: Calculate month-end adjustments
    INSERT INTO gl_adjustments SELECT ... ;
    
    -- Step 2: Close all transactions
    UPDATE transactions SET status = 'CLOSED' WHERE close_date IS NULL;
    
    -- Step 3: Lock the month
    UPDATE accounting_periods SET locked_date = SYSDATE WHERE period_id = current_month;
    
    -- Step 4: Log completion
    INSERT INTO audit_log VALUES ('MONTH_CLOSE', SYSDATE);
    
    -- This is ONE complete business transaction; commit together
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;  -- All or nothing
        RAISE_APPLICATION_ERROR(-20999, 'Month-end close failed: ' || SQLERRM);
END complete_month_end_close;
```

---

## 11. Functions in SQL vs PL/SQL

### Functions Callable from SQL

```sql
-- Function must be "pure" or "deterministic" for SQL use
CREATE OR REPLACE FUNCTION get_employee_age (p_employee_id IN NUMBER)
RETURN NUMBER AS
    v_hire_date DATE;
BEGIN
    SELECT hire_date INTO v_hire_date FROM employees WHERE employee_id = p_employee_id;
    RETURN TRUNC((SYSDATE - v_hire_date) / 365.25);
END get_employee_age;
/

-- Use in SELECT query
SELECT employee_id, name, get_employee_age(employee_id) AS tenure_years
FROM employees
WHERE get_employee_age(employee_id) >= 5;
```

### Functions NOT Suitable for SQL

```sql
-- ❌ NOT SAFE for SQL: Modifies data (side effect)
CREATE OR REPLACE FUNCTION unsafe_increment_call_count (p_emp_id IN NUMBER)
RETURN NUMBER AS
BEGIN
    UPDATE employee_stats SET call_count = call_count + 1 WHERE employee_id = p_emp_id;
    RETURN 1;
END unsafe_increment_call_count;
/

-- ✅ BETTER: Separate procedure for side effects
CREATE OR REPLACE PROCEDURE increment_call_count (p_emp_id IN NUMBER) AS
BEGIN
    UPDATE employee_stats SET call_count = call_count + 1 WHERE employee_id = p_emp_id;
END increment_call_count;

CREATE OR REPLACE FUNCTION get_call_count (p_emp_id IN NUMBER)
RETURN NUMBER AS
    v_count NUMBER;
BEGIN
    SELECT call_count INTO v_count FROM employee_stats WHERE employee_id = p_emp_id;
    RETURN v_count;
END get_call_count;
```

---

## 12. Real-World Production Scenarios

### Scenario 1: Employee Onboarding Workflow

```sql
CREATE OR REPLACE PROCEDURE onboard_new_employee (
    p_emp_id IN employees.employee_id%TYPE,
    p_first_name IN employees.first_name%TYPE,
    p_last_name IN employees.last_name%TYPE,
    p_dept_id IN employees.department_id%TYPE,
    p_salary IN employees.salary%TYPE
) AS
    e_invalid_dept EXCEPTION;
    v_dept_count NUMBER;
BEGIN
    -- Validate department
    SELECT COUNT(*) INTO v_dept_count FROM departments WHERE department_id = p_dept_id;
    IF v_dept_count = 0 THEN
        RAISE e_invalid_dept;
    END IF;
    
    -- Create employee record
    INSERT INTO employees (employee_id, first_name, last_name, department_id, salary, hire_date)
    VALUES (p_emp_id, p_first_name, p_last_name, p_dept_id, p_salary, SYSDATE);
    
    -- Create HR record
    INSERT INTO employee_hr (employee_id, start_date, status) VALUES (p_emp_id, SYSDATE, 'ACTIVE');
    
    -- Create salary history
    INSERT INTO salary_history (employee_id, salary, effective_date) VALUES (p_emp_id, p_salary, SYSDATE);
    
    -- Log action
    INSERT INTO audit_log (action, employee_id, logged_date) VALUES ('ONBOARD', p_emp_id, SYSDATE);
    
    DBMS_OUTPUT.PUT_LINE('Employee ' || p_emp_id || ' onboarded successfully');
    
EXCEPTION
    WHEN e_invalid_dept THEN
        RAISE_APPLICATION_ERROR(-20001, 'Department ' || p_dept_id || ' does not exist');
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20002, 'Employee ID ' || p_emp_id || ' already exists');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20999, 'Onboarding failed: ' || SQLERRM);
END onboard_new_employee;
/
```

### Scenario 2: Batch Reporting Function

```sql
CREATE OR REPLACE FUNCTION calculate_department_summary (p_dept_id IN NUMBER)
RETURN VARCHAR2 AS
    v_emp_count NUMBER;
    v_avg_salary NUMBER;
    v_total_salary NUMBER;
    v_result VARCHAR2(500);
BEGIN
    SELECT COUNT(*), AVG(salary), SUM(salary)
    INTO v_emp_count, v_avg_salary, v_total_salary
    FROM employees
    WHERE department_id = p_dept_id;
    
    v_result := 'Dept ' || p_dept_id || ': ' ||
                v_emp_count || ' employees, ' ||
                'Avg Salary: $' || ROUND(v_avg_salary, 2) || ', ' ||
                'Total Salary: $' || v_total_salary;
    
    RETURN v_result;
END calculate_department_summary;
/

-- Use in query
SELECT department_id, calculate_department_summary(department_id)
FROM departments;
```

---

## 13. Comparison Matrix

| Aspect | Procedure | Function |
| --- | --- | --- |
| **Purpose** | Perform action | Return value |
| **RETURN clause** | Not required | Required |
| **Parameters** | IN, OUT, IN OUT | Usually IN only |
| **SQL callable** | Not directly | Yes (with restrictions) |
| **Transaction control** | Flexible | Should avoid |
| **Best for** | Commands, workflows | Calculations, lookups |

---

## 14. Best Practices

### 1. Use %TYPE for Parameter Types

```sql
-- ✅ GOOD: Schema-aligned
p_employee_id IN employees.employee_id%TYPE

-- ❌ AVOID: Hard-coded
p_employee_id IN NUMBER
```

### 2. Validate at Boundary

```sql
-- ✅ GOOD: Check inputs first
IF p_salary < 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Salary cannot be negative');
END IF;

-- ❌ AVOID: Let bad data propagate
UPDATE employees SET salary = p_salary WHERE ...;
```

### 3. Let Caller Control Transactions

```sql
-- ✅ GOOD: Procedure doesn't commit
UPDATE employees SET salary = p_salary WHERE employee_id = p_emp_id;
-- Caller decides: COMMIT or ROLLBACK

-- ❌ AVOID: Commit inside procedure
UPDATE employees SET salary = p_salary WHERE employee_id = p_emp_id;
COMMIT;
```

### 4. Use Meaningful Error Codes and Messages

```sql
-- ✅ GOOD
RAISE_APPLICATION_ERROR(-20001, 'Salary $' || p_salary || ' exceeds maximum $500000');

-- ❌ AVOID
RAISE_APPLICATION_ERROR(-20001, 'Invalid input');
```

### 5. Document Parameter Modes Clearly

```sql
CREATE OR REPLACE PROCEDURE calculate_bonus (
    p_employee_id IN NUMBER,      -- IN: Employee to calculate for
    p_bonus_amount OUT NUMBER      -- OUT: Calculated bonus returned here
) AS
BEGIN
    -- Clear documentation helps callers understand the contract
END;
```

---

## 15. Common Mistakes

### Mistake 1: Missing RETURN in Function

```sql
-- ❌ ERROR: Not all paths return
CREATE OR REPLACE FUNCTION get_status (p_id IN NUMBER) RETURN VARCHAR2 AS
BEGIN
    IF p_id > 100 THEN
        RETURN 'ACTIVE';
    END IF;
    -- Path missing RETURN!
END;

-- ✅ CORRECT: All paths return
CREATE OR REPLACE FUNCTION get_status (p_id IN NUMBER) RETURN VARCHAR2 AS
BEGIN
    IF p_id > 100 THEN
        RETURN 'ACTIVE';
    ELSE
        RETURN 'INACTIVE';
    END IF;
END;
```

### Mistake 2: Modifying IN Parameters

```sql
-- ❌ ERROR: Cannot modify IN
CREATE OR REPLACE PROCEDURE bad_proc (p_value IN NUMBER) AS
BEGIN
    p_value := p_value * 2;  -- ERROR!
END;

-- ✅ CORRECT: Use local variable or IN OUT
CREATE OR REPLACE PROCEDURE good_proc (p_value IN NUMBER) AS
    v_result NUMBER;
BEGIN
    v_result := p_value * 2;
END;
```

### Mistake 3: Premature COMMIT

```sql
-- ❌ PROBLEM: Each procedure commits independently
PROCEDURE step1 AS
BEGIN
    INSERT INTO table1 VALUES (...);
    COMMIT;  -- Commits immediately
END;

PROCEDURE step2 AS
BEGIN
    INSERT INTO table2 VALUES (...);  -- Fails!
    COMMIT;  -- Step1 already committed; can't rollback
END;

-- ✅ SOLUTION: Let caller control
PROCEDURE step1 AS
BEGIN
    INSERT INTO table1 VALUES (...);
    -- No COMMIT; let caller decide
END;

PROCEDURE step2 AS
BEGIN
    INSERT INTO table2 VALUES (...);
    -- No COMMIT
END;

-- Caller controls atomicity
BEGIN
    step1;
    step2;
    COMMIT;  -- Both succeed or both fail
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
END;
```

### Mistake 4: Wrong Parameter Mode

```sql
-- ❌ WRONG: Using OUT when IN OUT is needed
PROCEDURE modify_value (p_value OUT NUMBER) AS
BEGIN
    p_value := p_value * 2;  -- ERROR: p_value is uninitialized (OUT only)
END;

-- ✅ CORRECT: Use IN OUT
PROCEDURE modify_value (p_value IN OUT NUMBER) AS
BEGIN
    p_value := p_value * 2;  -- OK: p_value has original value
END;
```

---

## 16. Interview Q&A

### Q1: What's the difference between a procedure and a function?

**A:** A procedure PERFORMS AN ACTION; a function RETURNS A VALUE. Functions can be called from SQL queries; procedures cannot (directly). Functions are used for calculations; procedures for operations.

---

### Q2: Can a procedure return multiple values?

**A:** Yes, using OUT or IN OUT parameters. Functions can return only one value.

```sql
PROCEDURE get_values (
    p_id IN NUMBER,
    p_name OUT VARCHAR2,
    p_salary OUT NUMBER
) AS
BEGIN
    SELECT name, salary INTO p_name, p_salary FROM employees WHERE employee_id = p_id;
END;
```

---

### Q3: Should a procedure commit?

**A:** Usually NO. Let the caller control transactions so multiple procedure calls can be part of one atomic transaction. Exception: if the procedure represents a complete business transaction (e.g., month-end close).

---

### Q4: What does %TYPE do?

**A:** %TYPE anchors a parameter to a table column's type. If the column type changes, the parameter automatically adapts. Preferred over hard-coded types.

---

### Q5: Can you call a procedure from SQL?

**A:** Not directly in a SELECT. Procedures must be called from PL/SQL (EXEC or BEGIN...END). Functions CAN be called from SQL queries.

---

### Q6: What's overloading?

**A:** Allowing the same procedure/function name with DIFFERENT parameter lists (different count, type, or order). Compiler picks the matching signature at compile time.

---

### Q7: Why validate at the boundary?

**A:** Check inputs BEFORE modifying data. Catches errors early, prevents partial updates, and provides clear error messages to the caller.

---

### Q8: What's the difference between IN and IN OUT?

**A:** IN: Parameter is read-only; caller sends value. IN OUT: Caller sends value AND receives modified value back.

---

### Q9: Can functions have side effects?

**A:** Technically yes, but NOT RECOMMENDED. Functions should be "pure" (no side effects). Use procedures for operations that modify data.

---

### Q10: How do you handle errors in procedures?

**A:** Use EXCEPTION blocks. Catch specific errors (NO_DATA_FOUND, DUP_VAL_ON_INDEX) with WHEN clauses. Use RAISE_APPLICATION_ERROR for business rule violations.

---

## 17. Revision Summary

### Key Takeaways

1. **Procedures** = Actions (INSERT, UPDATE, DELETE, workflows)
2. **Functions** = Values (calculations, lookups, usable in SQL)
3. **Parameter modes** = IN (input), OUT (output), IN OUT (both)
4. **%TYPE** = Auto-align parameters to column types
5. **Validation** = Check inputs at boundary; use RAISE_APPLICATION_ERROR
6. **Transactions** = Caller usually owns COMMIT/ROLLBACK
7. **Nested subprograms** = Private helper logic
8. **Overloading** = Same name, different signatures
9. **Error handling** = Catch specific exceptions, provide clear messages
10. **SQL-callable functions** = Must be "pure" (no side effects)

### Quick Reference: When to Use What

```
Need to perform an action?        → Procedure
Need to return a calculated value? → Function
Need to call from SQL SELECT?      → Function
Need to modify multiple values?    → Procedure with OUT params
Need private helper?               → Nested subprogram
Need multiple versions?            → Overloading
Need same name, SQL + PL/SQL?      → Function + Procedure wrapper

