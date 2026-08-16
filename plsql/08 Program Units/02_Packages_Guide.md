# PL/SQL Packages: Comprehensive Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Package** = Container grouping related procedures, functions, types, and variables (like a library or module); has SPECIFICATION (public API) + BODY (implementation + private members).
- **Specification (Package Spec)** = Declares public members (procedures, functions, types, constants); acts as contract; callers see only this.
- **Package Body** = Implements procedures/functions from spec; contains PRIVATE members (helpers, variables, cursors) invisible to callers.
- **Public members** = Declared in specification; callable from outside package; part of stable contract.
- **Private members** = Declared in body ONLY; hidden from callers; can change without breaking external code.
- **Package state** = Package variables persist for SESSION DURATION (not database-wide); each session has own copy; useful for caching.
- **Initialization section** = Code in package body that runs ONCE per session when package is first referenced; resets package state.
- **Forward declaration** = Declare procedure name in spec before defining in body; allows mutual recursion between procedures.
- **Overloading in packages** = Multiple public procedures/functions with same name but DIFFERENT signatures; compile-time signature matching.
- **Best practice** = Keep spec small (public API); hide complexity in body (private helpers); document state; recompile atomically (spec + body).

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Packages?](#1-why-do-we-need-packages)
2. [What Is a Package?](#2-what-is-a-package)
3. [Package Specification: The Public Contract](#3-package-specification-the-public-contract)
4. [Package Body: Implementation and Private Members](#4-package-body-implementation-and-private-members)
5. [Public vs Private Members](#5-public-vs-private-members)
6. [Package State and Session Persistence](#6-package-state-and-session-persistence)
7. [Package Initialization Section](#7-package-initialization-section)
8. [Overloading in Packages](#8-overloading-in-packages)
9. [Package Dependencies and Recompilation](#9-package-dependencies-and-recompilation)
10. [Real-World Production Scenarios](#10-real-world-production-scenarios)
11. [Package Best Practices](#11-package-best-practices)
12. [Common Mistakes](#12-common-mistakes)
13. [Interview Q&A](#13-interview-qa)
14. [Comparison Matrix](#14-comparison-matrix)
15. [Revision Summary](#15-revision-summary)

---

## 1. Why Do We Need Packages?

### The Problem: Scattered Related Code

Without packages, related procedures are scattered across the database:

```sql
-- Without packages: Callers need to know MANY different procedures
EXEC hire_employee(100, 'John', 'Doe', 10);
EXEC validate_salary(75000);
EXEC calculate_bonus(75000, 5);
EXEC get_employee_count(10);

-- Hard to discover all related operations
-- Hard to group related logic
-- Difficult to manage dependencies
```

### The Solution: Packages

```sql
-- With packages: Callers know ONE entry point (employee_api)
employee_api.hire_employee(100, 'John', 'Doe', 10);
employee_api.validate_salary(75000);
employee_api.calculate_bonus(75000, 5);
employee_api.get_employee_count(10);

-- Easy to discover (all employee operations are in one package)
-- Logical grouping (all employee logic together)
-- Easy dependency management (one package = one unit of code)
```

### Benefits of Packages

| Benefit | How it Helps |
| --- | --- |
| **Organization** | All related procedures in one place |
| **API clarity** | Specification is the contract; callers know what's available |
| **Encapsulation** | Hide implementation in body; only expose public API |
| **Maintainability** | Change private helpers without affecting callers |
| **Reusability** | Share types, constants, functions across procedures |
| **Session state** | Package variables for caching, configuration |
| **Overloading** | Same name, multiple versions (by parameter signature) |

---

**➡ Transition:** Let's understand the structure of packages (specification vs body).

---

## 2. What Is a Package?

### Definition

A **package** = Two-part stored object:
1. **Specification** = Public API (what's available to callers)
2. **Body** = Implementation (how it works, private helpers)

**Metaphor:** A restaurant
- **Spec** = Menu (what customers see; the contract)
- **Body** = Kitchen (how food is prepared; hidden from customers)

### Package Structure

```
PACKAGE employee_api
├── SPECIFICATION (public)
│   ├── PROCEDURE hire_employee
│   ├── FUNCTION is_valid_salary
│   └── TYPE emp_record (type definition)
│
└── BODY (implementation + private)
    ├── PROCEDURE hire_employee (implementation)
    ├── FUNCTION is_valid_salary (implementation)
    ├── PROCEDURE validate_hire (PRIVATE helper)
    ├── FUNCTION get_max_salary (PRIVATE helper)
    └── INITIALIZATION SECTION
```

---

## 3. Package Specification: The Public Contract

### Basic Syntax

```sql
CREATE OR REPLACE PACKAGE employee_api AS
    -- Declare public procedures
    PROCEDURE hire_employee (
        p_emp_id IN NUMBER,
        p_name IN VARCHAR2,
        p_dept_id IN NUMBER
    );
    
    -- Declare public functions
    FUNCTION is_valid_salary (p_salary IN NUMBER) RETURN BOOLEAN;
    FUNCTION get_bonus (p_salary IN NUMBER) RETURN NUMBER;
    
    -- Declare public types
    TYPE emp_record IS RECORD (
        emp_id NUMBER,
        name VARCHAR2(100),
        salary NUMBER
    );
    
    -- Declare public constants
    MAX_SALARY CONSTANT NUMBER := 500000;
    MIN_SALARY CONSTANT NUMBER := 10000;
    
END employee_api;
/
```

### What Goes in Specification?

```sql
CREATE OR REPLACE PACKAGE public_api AS
    -- Public procedures and functions
    PROCEDURE process_data (p_id IN NUMBER);
    FUNCTION calculate_value (p_input IN NUMBER) RETURN NUMBER;
    
    -- Public types (shared with callers)
    TYPE result_rec IS RECORD (
        id NUMBER,
        value NUMBER,
        status VARCHAR2(20)
    );
    
    -- Public constants (shared configuration)
    DEFAULT_TIMEOUT CONSTANT NUMBER := 300;
    BATCH_SIZE CONSTANT NUMBER := 1000;
    
    -- Public variables (rare; state sharing)
    g_debug_mode BOOLEAN;
    
END public_api;
/
```

**Rules for specification:**
- ✅ Declare: Public procedures, functions, types, constants
- ❌ Don't declare: Private helpers, implementation details
- ✅ Can reference: Database objects, built-in types
- ✅ Should be: Stable, documented, minimal

---

## 4. Package Body: Implementation and Private Members

### Basic Syntax

```sql
CREATE OR REPLACE PACKAGE BODY employee_api AS
    
    -- Private helper function (NOT in spec; callers can't see it)
    FUNCTION get_max_salary_for_dept (p_dept_id IN NUMBER) RETURN NUMBER AS
        v_max NUMBER;
    BEGIN
        SELECT MAX(salary) INTO v_max FROM employees WHERE department_id = p_dept_id;
        RETURN NVL(v_max, MAX_SALARY);
    END get_max_salary_for_dept;
    
    -- Implementation of public procedure
    PROCEDURE hire_employee (
        p_emp_id IN NUMBER,
        p_name IN VARCHAR2,
        p_dept_id IN NUMBER
    ) AS
    BEGIN
        -- Validation
        IF NOT is_valid_salary(50000) THEN
            RAISE_APPLICATION_ERROR(-20001, 'Invalid salary for new employee');
        END IF;
        
        -- Call private helper
        IF is_valid_salary(get_max_salary_for_dept(p_dept_id)) THEN
            INSERT INTO employees VALUES (p_emp_id, p_name, 50000, p_dept_id);
            COMMIT;
        END IF;
    END hire_employee;
    
    -- Implementation of public function
    FUNCTION is_valid_salary (p_salary IN NUMBER) RETURN BOOLEAN AS
    BEGIN
        RETURN p_salary BETWEEN MIN_SALARY AND MAX_SALARY;
    END is_valid_salary;
    
    FUNCTION get_bonus (p_salary IN NUMBER) RETURN NUMBER AS
    BEGIN
        RETURN ROUND(p_salary * 0.10, 2);
    END get_bonus;
    
    -- INITIALIZATION SECTION (runs once per session)
BEGIN
    DBMS_OUTPUT.PUT_LINE('employee_api package loaded');
END employee_api;
/
```

### What Goes in Body?

```sql
CREATE OR REPLACE PACKAGE BODY implementation_details AS
    
    -- Private variables (session-persistent)
    v_cache_loaded BOOLEAN := FALSE;
    v_cache_data TABLE OF number;
    
    -- Private procedures (NOT in spec)
    PROCEDURE initialize_cache AS
    BEGIN
        SELECT * BULK COLLECT INTO v_cache_data FROM lookup_table;
        v_cache_loaded := TRUE;
    END initialize_cache;
    
    PROCEDURE log_operation (p_operation VARCHAR2) AS
    BEGIN
        INSERT INTO audit_log VALUES (p_operation, USER, SYSDATE);
    END log_operation;
    
    -- Implement public procedures/functions
    -- ...
    
    -- INITIALIZATION BLOCK (runs once per session)
BEGIN
    IF NOT v_cache_loaded THEN
        initialize_cache;
    END IF;
    log_operation('PACKAGE_LOAD');
END implementation_details;
/
```

**Rules for body:**
- ✅ Declare: Private procedures, functions, variables
- ✅ Implement: All public procedures/functions from spec
- ✅ Can have: Multiple helpers per public routine
- ✅ Use INITIALIZATION for one-time setup per session
- ❌ Don't change: Public signatures (breaks callers)

---

## 5. Public vs Private Members

### Visibility Comparison

```sql
-- SPECIFICATION (Public)
CREATE OR REPLACE PACKAGE library AS
    -- PUBLIC: Callers see this in spec
    PROCEDURE borrow_book (p_book_id IN NUMBER);
    FUNCTION is_book_available (p_book_id IN NUMBER) RETURN BOOLEAN;
    TYPE book_rec IS RECORD (id NUMBER, title VARCHAR2(100));
END library;
/

-- BODY (Private)
CREATE OR REPLACE PACKAGE BODY library AS
    
    -- PRIVATE: Not in spec; callers can't call this
    PROCEDURE audit_borrow (p_book_id IN NUMBER, p_borrower_id IN NUMBER) AS
    BEGIN
        INSERT INTO borrow_log VALUES (p_book_id, p_borrower_id, SYSDATE);
    END audit_borrow;
    
    -- PRIVATE: Helper function (not in spec)
    FUNCTION get_borrower_limit (p_borrower_id IN NUMBER) RETURN NUMBER AS
        v_limit NUMBER;
    BEGIN
        SELECT borrow_limit INTO v_limit FROM borrowers WHERE borrower_id = p_borrower_id;
        RETURN v_limit;
    END get_borrower_limit;
    
    -- PUBLIC: Implement the spec
    PROCEDURE borrow_book (p_book_id IN NUMBER) AS
        v_borrower_id NUMBER := SYS_CONTEXT('userenv', 'client_identifier');
        v_limit NUMBER;
    BEGIN
        v_limit := get_borrower_limit(v_borrower_id);  -- Call private helper
        
        IF is_book_available(p_book_id) THEN
            UPDATE books SET borrower_id = v_borrower_id WHERE book_id = p_book_id;
            audit_borrow(p_book_id, v_borrower_id);  -- Call private helper
            COMMIT;
        ELSE
            RAISE_APPLICATION_ERROR(-20001, 'Book not available');
        END IF;
    END borrow_book;
    
    FUNCTION is_book_available (p_book_id IN NUMBER) RETURN BOOLEAN AS
        v_status VARCHAR2(20);
    BEGIN
        SELECT status INTO v_status FROM books WHERE book_id = p_book_id;
        RETURN v_status = 'AVAILABLE';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END is_book_available;
    
END library;
/
```

### Calling from Outside

```sql
-- Callers can call PUBLIC procedures
EXEC library.borrow_book(123);

-- Callers CAN'T call PRIVATE procedures (compile error)
-- EXEC library.audit_borrow(123, 456);  -- ERROR!

-- Use public type in local variable
DECLARE
    v_book library.book_rec;
BEGIN
    v_book.id := 123;
    v_book.title := 'PL/SQL Guide';
END;
```

---

## 6. Package State and Session Persistence

### Package Variables Are Session-Specific

```sql
CREATE OR REPLACE PACKAGE user_session AS
    g_user_id NUMBER;
    g_login_time DATE;
    g_request_count NUMBER := 0;
    
    PROCEDURE login (p_user_id IN NUMBER);
    FUNCTION get_session_info RETURN VARCHAR2;
END user_session;
/

CREATE OR REPLACE PACKAGE BODY user_session AS
    
    PROCEDURE login (p_user_id IN NUMBER) AS
    BEGIN
        g_user_id := p_user_id;
        g_login_time := SYSDATE;
        g_request_count := 0;
        DBMS_OUTPUT.PUT_LINE('User ' || p_user_id || ' logged in');
    END login;
    
    FUNCTION get_session_info RETURN VARCHAR2 AS
    BEGIN
        RETURN 'User: ' || g_user_id || ', Logged: ' || g_login_time || ', Requests: ' || g_request_count;
    END get_session_info;
    
BEGIN
    g_user_id := NULL;
    g_login_time := NULL;
    g_request_count := 0;
END user_session;
/

-- Session 1 (Connection A)
EXEC user_session.login(101);
SELECT user_session.get_session_info() FROM dual;  -- User 101 logged in

-- Session 2 (Connection B, different session)
SELECT user_session.get_session_info() FROM dual;  -- User NULL (different session state)

-- ✅ Each session has its own copy of package variables
-- ❌ NOT shared across sessions
```

### Using Package State for Caching

```sql
CREATE OR REPLACE PACKAGE dept_cache AS
    PROCEDURE load_departments;
    FUNCTION get_department_name (p_dept_id IN NUMBER) RETURN VARCHAR2;
END dept_cache;
/

CREATE OR REPLACE PACKAGE BODY dept_cache AS
    
    TYPE dept_table IS TABLE OF departments%ROWTYPE INDEX BY PLS_INTEGER;
    v_depts dept_table;
    v_loaded BOOLEAN := FALSE;
    
    PROCEDURE load_departments AS
    BEGIN
        FOR dept IN (SELECT * FROM departments) LOOP
            v_depts(dept.department_id) := dept;
        END LOOP;
        v_loaded := TRUE;
        DBMS_OUTPUT.PUT_LINE('Cache loaded: ' || v_depts.COUNT || ' departments');
    END load_departments;
    
    FUNCTION get_department_name (p_dept_id IN NUMBER) RETURN VARCHAR2 AS
    BEGIN
        IF NOT v_loaded THEN
            load_departments;
        END IF;
        
        IF v_depts.EXISTS(p_dept_id) THEN
            RETURN v_depts(p_dept_id).department_name;
        ELSE
            RETURN NULL;
        END IF;
    END get_department_name;
    
BEGIN
    NULL;  -- Initialized empty; loaded on first use
END dept_cache;
/

-- Usage: Fast lookup with automatic lazy load
BEGIN
    DBMS_OUTPUT.PUT_LINE(dept_cache.get_department_name(10));  -- First call: loads cache
    DBMS_OUTPUT.PUT_LINE(dept_cache.get_department_name(20));  -- Second call: uses cache (fast!)
END;
/
```

---

## 7. Package Initialization Section

### What is Initialization?

```sql
CREATE OR REPLACE PACKAGE BODY my_package AS
    
    PROCEDURE my_proc AS
    BEGIN
        NULL;
    END my_proc;
    
    -- INITIALIZATION SECTION: Runs once per session
BEGIN
    DBMS_OUTPUT.PUT_LINE('Package loaded for user: ' || USER);
    -- Set up session-specific variables
    -- Initialize caches
    -- Register session in audit table
END my_package;
/
```

### Real Example: Session Initialization

```sql
CREATE OR REPLACE PACKAGE session_init AS
    FUNCTION get_session_id RETURN VARCHAR2;
    FUNCTION get_login_user RETURN VARCHAR2;
END session_init;
/

CREATE OR REPLACE PACKAGE BODY session_init AS
    
    v_session_id VARCHAR2(30);
    v_login_user VARCHAR2(30);
    v_session_start DATE;
    
    FUNCTION get_session_id RETURN VARCHAR2 AS
    BEGIN
        RETURN v_session_id;
    END get_session_id;
    
    FUNCTION get_login_user RETURN VARCHAR2 AS
    BEGIN
        RETURN v_login_user;
    END get_login_user;
    
    -- INITIALIZATION: Runs when package is first referenced
BEGIN
    v_session_id := DBMS_SESSION.UNIQUE_SESSION_ID;
    v_login_user := USER;
    v_session_start := SYSDATE;
    
    -- Log session start
    INSERT INTO session_log (session_id, user_name, login_time)
    VALUES (v_session_id, v_login_user, v_session_start);
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Session ' || v_session_id || ' initialized for user ' || v_login_user);
    
END session_init;
/
```

### Important: Initialization Only Runs Once Per Session

```sql
-- Session 1
BEGIN
    -- First call to session_init package
    DBMS_OUTPUT.PUT_LINE(session_init.get_login_user());
    -- Output: "Session XXX initialized for user SCOTT"
    --         "SCOTT"
    
    -- Second call
    DBMS_OUTPUT.PUT_LINE(session_init.get_login_user());
    -- Output: "SCOTT" (initialization does NOT run again)
END;
```

---

## 8. Overloading in Packages

### Multiple Versions of Same Procedure

```sql
CREATE OR REPLACE PACKAGE calc_utils AS
    -- Overload 1: Add two numbers
    FUNCTION add (p1 IN NUMBER, p2 IN NUMBER) RETURN NUMBER;
    
    -- Overload 2: Concatenate two strings
    FUNCTION add (p1 IN VARCHAR2, p2 IN VARCHAR2) RETURN VARCHAR2;
    
    -- Overload 3: Add days to date
    FUNCTION add (p_date IN DATE, p_days IN NUMBER) RETURN DATE;
END calc_utils;
/

CREATE OR REPLACE PACKAGE BODY calc_utils AS
    
    FUNCTION add (p1 IN NUMBER, p2 IN NUMBER) RETURN NUMBER AS
    BEGIN
        RETURN p1 + p2;
    END add;
    
    FUNCTION add (p1 IN VARCHAR2, p2 IN VARCHAR2) RETURN VARCHAR2 AS
    BEGIN
        RETURN p1 || ' ' || p2;
    END add;
    
    FUNCTION add (p_date IN DATE, p_days IN NUMBER) RETURN DATE AS
    BEGIN
        RETURN p_date + p_days;
    END add;
    
END calc_utils;
/

-- Usage: Same name, different signatures
BEGIN
    DBMS_OUTPUT.PUT_LINE(calc_utils.add(5, 10));  -- 15 (number + number)
    DBMS_OUTPUT.PUT_LINE(calc_utils.add('Hello', 'World'));  -- Hello World (string + string)
    DBMS_OUTPUT.PUT_LINE(calc_utils.add(SYSDATE, 30));  -- Date + 30 days (date + number)
END;
/
```

---

## 9. Package Dependencies and Recompilation

### Spec Changes Break Callers

```sql
-- Original spec
CREATE OR REPLACE PACKAGE emp_pkg AS
    PROCEDURE hire (p_id NUMBER, p_name VARCHAR2);
END emp_pkg;

-- Callers compile successfully
-- Then spec changes:
CREATE OR REPLACE PACKAGE emp_pkg AS
    PROCEDURE hire (p_id NUMBER, p_name VARCHAR2, p_dept NUMBER);  -- Added parameter!
END emp_pkg;

-- Now all callers are INVALID (must recompile)
```

### Body Changes Usually DON'T Break Callers

```sql
-- Spec (stable)
CREATE OR REPLACE PACKAGE emp_pkg AS
    PROCEDURE process_employee (p_id NUMBER);
END emp_pkg;

-- Body implementation change (internal only)
CREATE OR REPLACE PACKAGE BODY emp_pkg AS
    -- Change from simple to complex implementation
    -- Doesn't affect spec or callers
    PROCEDURE process_employee (p_id NUMBER) AS
    BEGIN
        -- NEW: More complex logic
        -- But signature and behavior are the same
        UPDATE employees SET last_updated = SYSDATE WHERE employee_id = p_id;
        INSERT INTO audit_log VALUES (p_id, SYSDATE);
        COMMIT;
    END process_employee;
END emp_pkg;

-- Callers still work without recompiling
```

### Recompilation Best Practice

```sql
-- Deploy as atomic unit: spec + body
CREATE OR REPLACE PACKAGE stable_api AS
    PROCEDURE public_operation;
END stable_api;
/

CREATE OR REPLACE PACKAGE BODY stable_api AS
    PROCEDURE public_operation AS
    BEGIN
        NULL;
    END public_operation;
END stable_api;
/

-- Never change just the spec in production
-- Always recompile both together if needed
```

---

## 10. Real-World Production Scenarios

### Scenario 1: Employee Management API

```sql
CREATE OR REPLACE PACKAGE employee_api AS
    TYPE emp_rec IS RECORD (
        emp_id NUMBER,
        name VARCHAR2(100),
        salary NUMBER,
        dept_id NUMBER
    );
    
    PROCEDURE hire_employee (p_emp emp_rec);
    FUNCTION calculate_bonus (p_salary IN NUMBER, p_tenure IN NUMBER) RETURN NUMBER;
    FUNCTION get_employee (p_emp_id IN NUMBER) RETURN emp_rec;
    PROCEDURE update_salary (p_emp_id IN NUMBER, p_new_salary IN NUMBER);
END employee_api;
/

CREATE OR REPLACE PACKAGE BODY employee_api AS
    
    -- Private: Validation helper
    FUNCTION is_valid_salary (p_salary IN NUMBER) RETURN BOOLEAN AS
    BEGIN
        RETURN p_salary BETWEEN 10000 AND 500000;
    END is_valid_salary;
    
    -- Private: Department check
    FUNCTION dept_exists (p_dept_id IN NUMBER) RETURN BOOLEAN AS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM departments WHERE department_id = p_dept_id;
        RETURN v_count > 0;
    END dept_exists;
    
    -- Public: Hire
    PROCEDURE hire_employee (p_emp emp_rec) AS
    BEGIN
        IF NOT is_valid_salary(p_emp.salary) THEN
            RAISE_APPLICATION_ERROR(-20001, 'Invalid salary');
        END IF;
        IF NOT dept_exists(p_emp.dept_id) THEN
            RAISE_APPLICATION_ERROR(-20002, 'Invalid department');
        END IF;
        
        INSERT INTO employees VALUES (p_emp.emp_id, p_emp.name, p_emp.salary, p_emp.dept_id);
        COMMIT;
    END hire_employee;
    
    -- Public: Bonus calculation
    FUNCTION calculate_bonus (p_salary IN NUMBER, p_tenure IN NUMBER) RETURN NUMBER AS
        v_rate NUMBER;
    BEGIN
        IF p_tenure >= 10 THEN
            v_rate := 0.20;
        ELSIF p_tenure >= 5 THEN
            v_rate := 0.15;
        ELSE
            v_rate := 0.05;
        END IF;
        RETURN ROUND(p_salary * v_rate, 2);
    END calculate_bonus;
    
    -- Public: Get employee
    FUNCTION get_employee (p_emp_id IN NUMBER) RETURN emp_rec AS
        v_emp emp_rec;
    BEGIN
        SELECT employee_id, name, salary, department_id
        INTO v_emp.emp_id, v_emp.name, v_emp.salary, v_emp.dept_id
        FROM employees
        WHERE employee_id = p_emp_id;
        RETURN v_emp;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20003, 'Employee not found');
    END get_employee;
    
    -- Public: Update salary
    PROCEDURE update_salary (p_emp_id IN NUMBER, p_new_salary IN NUMBER) AS
    BEGIN
        IF NOT is_valid_salary(p_new_salary) THEN
            RAISE_APPLICATION_ERROR(-20001, 'Invalid salary');
        END IF;
        
        UPDATE employees SET salary = p_new_salary WHERE employee_id = p_emp_id;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Employee not found');
        END IF;
        COMMIT;
    END update_salary;
    
END employee_api;
/
```

---

## 11. Package Best Practices

### 1. Keep Specification Small

```sql
-- ✅ GOOD: Only public API in spec
CREATE OR REPLACE PACKAGE payroll_api AS
    PROCEDURE calculate_paycheck (p_emp_id IN NUMBER);
    FUNCTION get_gross_pay (p_emp_id IN NUMBER) RETURN NUMBER;
END payroll_api;

-- ❌ AVOID: Too many public members; cluttered spec
CREATE OR REPLACE PACKAGE payroll_api AS
    PROCEDURE calculate_paycheck (p_emp_id IN NUMBER);
    PROCEDURE calculate_taxes (p_emp_id IN NUMBER);
    PROCEDURE calculate_deductions (p_emp_id IN NUMBER);
    PROCEDURE apply_benefits (p_emp_id IN NUMBER);
    -- ... 50 more procedures
END payroll_api;
```

### 2. Hide Implementation Details

```sql
-- ✅ GOOD: Helpers in body only
CREATE OR REPLACE PACKAGE BODY impl AS
    FUNCTION get_tax_rate (p_income NUMBER) RETURN NUMBER AS
    BEGIN
        IF p_income > 100000 THEN
            RETURN 0.30;
        ELSE
            RETURN 0.20;
        END IF;
    END get_tax_rate;
    
    PROCEDURE process_payroll AS
    BEGIN
        -- Call private helper
        -- ... use get_tax_rate internally
    END process_payroll;
END impl;
```

### 3. Document Package State

```sql
-- ✅ GOOD: Clear documentation
CREATE OR REPLACE PACKAGE session_mgr AS
    -- Session state: persists for connection duration
    -- WARNING: Do not rely on state in connection pools
    -- Call reset_session() when connection is reused
    
    PROCEDURE reset_session;
    FUNCTION get_current_user RETURN VARCHAR2;
END session_mgr;
```

### 4. Test Private Helpers

```sql
-- Test private helpers by calling through public API
CREATE OR REPLACE PACKAGE body_test AS
    -- Create a test package that calls internal helpers
    -- OR: Create a separate test procedure in the body
END body_test;
```

---

## 12. Common Mistakes

### Mistake 1: Too Many Public Members

```sql
-- ❌ WRONG: Spec is huge; hard to understand API
CREATE OR REPLACE PACKAGE huge_pkg AS
    PROCEDURE p1; PROCEDURE p2; PROCEDURE p3;
    -- ... 100 more procedures
END huge_pkg;

-- ✅ CORRECT: Logical grouping
CREATE OR REPLACE PACKAGE employee_api AS
    PROCEDURE hire; FUNCTION get_salary RETURN NUMBER;
END employee_api;

CREATE OR REPLACE PACKAGE payroll_api AS
    PROCEDURE calculate; FUNCTION get_deductions RETURN NUMBER;
END payroll_api;
```

### Mistake 2: Assuming Package Variables Are Shared Across Sessions

```sql
-- ❌ WRONG: Package variables are session-specific
DECLARE
    g_counter NUMBER := 0;  -- Session 1
BEGIN
    g_counter := 1;  -- Session 1: increments to 1
    -- Session 2 still sees g_counter = 0 (different session)
END;

-- ✅ CORRECT: For true shared state, use table
CREATE TABLE session_counter (
    user_name VARCHAR2(30),
    counter NUMBER
);
```

### Mistake 3: Changing Spec Without Recompiling Callers

```sql
-- ❌ PROBLEM: Existing procedures that call this package are now invalid
CREATE OR REPLACE PACKAGE old_api AS
    PROCEDURE operation (p_id IN NUMBER);
END old_api;

-- Later, someone changes the spec:
CREATE OR REPLACE PACKAGE old_api AS
    PROCEDURE operation (p_id IN NUMBER, p_dept IN NUMBER);  -- Added parameter!
END old_api;

-- All dependent objects are now INVALID (must recompile)

-- ✅ SOLUTION: Keep stable API; add new procedure version with different name
CREATE OR REPLACE PACKAGE api AS
    PROCEDURE operation (p_id IN NUMBER);
    PROCEDURE operation_v2 (p_id IN NUMBER, p_dept IN NUMBER);  -- Different name
END api;
```

### Mistake 4: COMMIT/ROLLBACK Inside Package

```sql
-- ❌ PROBLEM: Package unilaterally commits
CREATE OR REPLACE PACKAGE BODY bad_pkg AS
    PROCEDURE modify_data (p_id IN NUMBER, p_value NUMBER) AS
    BEGIN
        UPDATE table1 SET value = p_value WHERE id = p_id;
        COMMIT;  -- Commits immediately; caller can't control
    END modify_data;
END bad_pkg;

-- ✅ CORRECT: Let caller control transaction
CREATE OR REPLACE PACKAGE BODY good_pkg AS
    PROCEDURE modify_data (p_id IN NUMBER, p_value NUMBER) AS
    BEGIN
        UPDATE table1 SET value = p_value WHERE id = p_id;
        -- No COMMIT; let caller decide
    END modify_data;
END good_pkg;
```

---

## 13. Interview Q&A

### Q1: What's the difference between package specification and body?

**A:** Specification declares the PUBLIC API (procedures, functions, types, constants). Body contains the IMPLEMENTATION and PRIVATE helpers. Spec is the contract; body is how it works.

---

### Q2: Are package variables shared across sessions?

**A:** No. Package variables are SESSION-SPECIFIC (one copy per session). Each user/connection has its own package state.

---

### Q3: When does package initialization run?

**A:** Once per session, the FIRST time the package is referenced. The initialization block in the package body runs automatically.

---

### Q4: Can you change the package body without affecting callers?

**A:** Yes, usually. Body implementation changes don't affect the spec, so callers don't recompile. NEVER change the spec signature without recompiling dependent objects.

---

### Q5: Why use packages instead of standalone procedures?

**A:** Packages group related code, hide implementation, support overloading, enable session state, and provide a stable API. Better organization and maintainability.

---

### Q6: Can you overload procedures in a package?

**A:** Yes. Multiple procedures with the SAME NAME but DIFFERENT parameter lists (count, type, order). Compiler chooses based on signature.

---

### Q7: What's in the initialization section?

**A:** Code that runs ONCE per session when the package is first used. Good for setting up variables, loading caches, logging session start, etc.

---

### Q8: What happens if two procedures have the same name (overloading) but are ambiguous?

**A:** Compile error. Make sure signature is clearly distinct (different number of params, different types).

---

### Q9: Can you call private procedures from outside the package?

**A:** No. Private procedures (declared in body only) are invisible to callers. Attempting to call raises a compilation error.

---

### Q10: How do you reset package state between calls in a connection pool?

**A:** Provide a public reset procedure in the package that reinitializes session variables. Call it at the start of each pooled connection reuse.

---

## 14. Comparison Matrix

| Aspect | Package Specification | Package Body | Standalone Procedure |
| --- | --- | --- | --- |
| **Visibility** | Public API | Private + Public implementation | Public object |
| **Main role** | Contract for callers | Implementation and helpers | One standalone operation |
| **When to change** | Rarely (breaks callers) | Often (no impact on callers) | Each change affects callers |
| **State** | Declared here | Implemented here | No state |
| **Best for** | Stable API | Implementation details | Simple isolated operations |
| **Overloading** | Yes | Yes | Not in same package |

---

## 15. Revision Summary

### Key Takeaways

1. **Packages = Specification + Body** (contract + implementation)
2. **Specification** = Public API (procedures, functions, types, constants)
3. **Body** = Implementation + Private helpers (invisible to callers)
4. **Public vs Private** = Declared in spec = public; declared in body only = private
5. **Package state** = Session-specific (one copy per session), useful for caching
6. **Initialization** = Runs once per session; good for setup
7. **Overloading** = Same name, different parameter signatures
8. **Body changes** = Safe; don't require caller recompilation
9. **Spec changes** = Risky; break dependent objects
10. **Best practice** = Keep spec small, hide complexity in body, document state

### Quick Reference: Package Structure

```sql
PACKAGE my_api
├── SPEC (Public)
│   ├── PROCEDURE public_op (...)
│   ├── FUNCTION public_func (...) RETURN ...
│   ├── TYPE public_type IS RECORD ...
│   └── PUBLIC_CONSTANT CONSTANT NUMBER := ...
│
└── BODY (Implementation + Private)
    ├── v_private_var NUMBER  (private variable)
    ├── FUNCTION private_helper (...)  (private)
    ├── PROCEDURE public_op (...)  (implementation)
    ├── FUNCTION public_func (...) RETURN ...  (implementation)
    └── BEGIN (Initialization section)

