# PL/SQL Collections and Records: Comprehensive Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Record** = Composite structure grouping related fields (like a single row); useful for passing multiple values or storing complex data.
- **Collection** = In-memory array or table holding multiple elements; three types: associative array (key-value, PL/SQL only), nested table (unbounded, SQL-usable), VARRAY (bounded, fixed size).
- **Associative array** = KEY-VALUE store (INDEX BY clause); fastest lookup; PL/SQL-only (cannot store in tables); sparse indexing allowed.
- **Nested table** = Unbounded collection (no size limit); can be stored in table columns; usable in SQL; allows DELETE (becomes sparse).
- **VARRAY** = Fixed-size ordered collection (declare maximum); dense ordering preserved; usable in SQL columns; fast access; cannot shrink below declared max.
- **Collection methods** = COUNT (size), FIRST/LAST (boundaries), NEXT/PRIOR (iteration), EXISTS (check index), DELETE (remove), EXTEND (grow), TRIM (shrink).
- **Sparse vs Dense** = Dense: all indexes exist (1 to N); Sparse: gaps exist after DELETE (1, 3, 5); use EXISTS before access.
- **%ROWTYPE** = Auto-generated record matching table structure; changes automatically when table changes; preferred for table-shaped data.
- **Custom records** = Define specific fields; more flexible than %ROWTYPE; useful for API boundaries, temporary structures, computed values.
- **Best practice** = Use associative array for caching/lookup; nested table for bulk SQL operations; VARRAY for fixed-size lists; validate indexes before access.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Collections and Records?](#1-why-do-we-need-collections-and-records)
2. [What Are Records and Collections?](#2-what-are-records-and-collections)
3. [Records: Single Composite Values](#3-records-single-composite-values)
4. [Associative Arrays: Key-Value Lookup](#4-associative-arrays-key-value-lookup)
5. [Nested Tables: Unbounded Collections](#5-nested-tables-unbounded-collections)
6. [VARRAYs: Fixed-Size Ordered Collections](#6-varrays-fixed-size-ordered-collections)
7. [Collection Methods: Manipulation and Iteration](#7-collection-methods-manipulation-and-iteration)
8. [Sparse vs Dense Collections](#8-sparse-vs-dense-collections)
9. [Passing Collections as Parameters](#9-passing-collections-as-parameters)
10. [Real-World Production Scenarios](#10-real-world-production-scenarios)
11. [Performance Characteristics](#11-performance-characteristics)
12. [Comparison Matrix](#12-comparison-matrix)
13. [Best Practices](#13-best-practices)
14. [Common Mistakes](#14-common-mistakes)
15. [Interview Q&A](#15-interview-qa)
16. [Revision Summary](#16-revision-summary)

---

## 1. Why Do We Need Collections and Records?

### The Problem: Limited Scalar Variables

A scalar variable holds ONE value (one employee ID, one salary, one date).

```sql
-- Scalar approach (limited)
DECLARE
    v_emp_id_1 NUMBER := 101;
    v_emp_id_2 NUMBER := 102;
    v_emp_id_3 NUMBER := 103;
    -- What if we have 10,000 IDs? We can't declare 10,000 variables!
BEGIN
    NULL;
END;
```

### The Solution: Collections and Records

Collections (arrays, tables) and records (composite structures) let you:
- **Store multiple values** in ONE variable
- **Pass many rows** to procedures/functions
- **Cache lookup tables** in memory (fast)
- **Batch process** rows from database (BULK COLLECT)
- **Return complex results** from functions

### Real-World Use Cases

| Scenario | Solution |
| --- | --- |
| **Caching lookup data** | Associative array (employee names by ID) |
| **Processing 10K rows** | Nested table with BULK COLLECT |
| **Fixed list of statuses** | VARRAY (ACTIVE, INACTIVE, SUSPENDED) |
| **One employee row** | Record or %ROWTYPE |
| **Multiple rows + columns** | Collection of records |
| **ID-based fast lookup** | Associative array INDEX BY employee_id |

---

**➡ Transition:** Let's understand records first (simplest composite structure).

---

## 2. What Are Records and Collections?

### Records vs Collections

A **record** = one composite value (like one database row)  
A **collection** = many elements in a single variable (like an array or table)

```sql
-- One record (one row of data)
DECLARE
    v_employee employees%ROWTYPE;  -- One employee
BEGIN
    SELECT * INTO v_employee FROM employees WHERE employee_id = 101;
    DBMS_OUTPUT.PUT_LINE(v_employee.name);
END;

-- Collection (many rows or values)
DECLARE
    TYPE emp_table IS TABLE OF employees%ROWTYPE;
    v_employees emp_table;  -- Many employees
BEGIN
    SELECT * BULK COLLECT INTO v_employees FROM employees WHERE department_id = 10;
    FOR i IN 1 .. v_employees.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(v_employees(i).name);
    END LOOP;
END;
```

---

## 3. Records: Single Composite Values

### Using %ROWTYPE (Recommended)

```sql
DECLARE
    v_employee employees%ROWTYPE;
BEGIN
    -- Fetch entire row
    SELECT * INTO v_employee FROM employees WHERE employee_id = 101;
    
    -- Access fields
    DBMS_OUTPUT.PUT_LINE('Name: ' || v_employee.first_name || ' ' || v_employee.last_name);
    DBMS_OUTPUT.PUT_LINE('Salary: $' || v_employee.salary);
    
    -- Update fields
    v_employee.salary := v_employee.salary * 1.10;
    DBMS_OUTPUT.PUT_LINE('New salary: $' || v_employee.salary);
END;
/
```

**Advantages of %ROWTYPE:**
- ✅ Automatically includes all table columns
- ✅ Adapts if table structure changes
- ✅ No manual field declaration
- ✅ Clear intent (one row of data)

### Custom Record Types

When you need specific fields (not all table columns):

```sql
DECLARE
    TYPE employee_summary IS RECORD (
        employee_id NUMBER,
        name VARCHAR2(100),
        salary NUMBER,
        hire_date DATE,
        years_employed NUMBER
    );
    
    v_summary employee_summary;
BEGIN
    SELECT 
        e.employee_id, 
        e.first_name || ' ' || e.last_name, 
        e.salary,
        e.hire_date,
        TRUNC((SYSDATE - e.hire_date) / 365.25) years_employed
    INTO v_summary
    FROM employees e
    WHERE e.employee_id = 101;
    
    DBMS_OUTPUT.PUT_LINE('Employee: ' || v_summary.name);
    DBMS_OUTPUT.PUT_LINE('Years employed: ' || v_summary.years_employed);
END;
/
```

### Record with Default Values

```sql
DECLARE
    TYPE config_record IS RECORD (
        app_mode VARCHAR2(20) := 'PRODUCTION',
        log_level NUMBER := 3,
        debug_enabled BOOLEAN := FALSE
    );
    
    v_config config_record;
BEGIN
    DBMS_OUTPUT.PUT_LINE('App mode: ' || v_config.app_mode);  -- Prints: PRODUCTION
END;
/
```

---

**➡ Transition:** Now let's explore collections, starting with associative arrays (key-value stores).

---

## 4. Associative Arrays: Key-Value Lookup

### What is an Associative Array?

Associative array = In-memory key-value map. INDEX BY specifies the key type.

```sql
DECLARE
    -- INDEX BY PLS_INTEGER: integer keys (like array indexes)
    TYPE salary_by_emp IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    v_salaries salary_by_emp;
    
    -- INDEX BY VARCHAR2: string keys (like hash map)
    TYPE phone_directory IS TABLE OF VARCHAR2(20) INDEX BY VARCHAR2(50);
    v_phones phone_directory;
BEGIN
    -- Store salary by employee ID
    v_salaries(101) := 75000;
    v_salaries(102) := 80000;
    v_salaries(105) := 95000;
    
    -- Store phone by name
    v_phones('Alice') := '555-1234';
    v_phones('Bob') := '555-5678';
    
    -- Retrieve
    DBMS_OUTPUT.PUT_LINE('Alice phone: ' || v_phones('Alice'));
    DBMS_OUTPUT.PUT_LINE('Employee 101 salary: $' || v_salaries(101));
END;
/
```

### Sparse Indexing (Gaps Allowed)

```sql
DECLARE
    TYPE num_list IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    v_values num_list;
    v_index PLS_INTEGER;
BEGIN
    v_values(1) := 100;
    v_values(5) := 500;      -- Gap: no indexes 2, 3, 4
    v_values(10) := 1000;    -- Gap: no indexes 6-9
    
    -- Iterate from first to last (skip gaps automatically)
    v_index := v_values.FIRST;
    WHILE v_index IS NOT NULL LOOP
        DBMS_OUTPUT.PUT_LINE('Index ' || v_index || ': ' || v_values(v_index));
        v_index := v_values.NEXT(v_index);
    END LOOP;
    
    -- Output:
    -- Index 1: 100
    -- Index 5: 500
    -- Index 10: 1000
END;
/
```

### Cache Use Case: Employee Lookup

```sql
PROCEDURE process_departments (p_dept_ids IN TABLE OF NUMBER) AS
    TYPE emp_cache IS TABLE OF employees%ROWTYPE INDEX BY PLS_INTEGER;
    v_emp_cache emp_cache;
    v_employee employees%ROWTYPE;
BEGIN
    -- Load all employees into cache (once)
    FOR emp IN (SELECT * FROM employees) LOOP
        v_emp_cache(emp.employee_id) := emp;
    END LOOP;
    
    -- Process each department
    FOR i IN 1 .. p_dept_ids.COUNT LOOP
        -- Fast lookup (no database call)
        IF v_emp_cache.EXISTS(p_dept_ids(i)) THEN
            v_employee := v_emp_cache(p_dept_ids(i));
            DBMS_OUTPUT.PUT_LINE('Found: ' || v_employee.name);
        ELSE
            DBMS_OUTPUT.PUT_LINE('Employee not found');
        END IF;
    END LOOP;
END process_departments;
/
```

**Performance:** Associative array lookup is **O(1)** (instant), vs database query which is **O(log n)** (slower).

---

## 5. Nested Tables: Unbounded Collections

### What is a Nested Table?

Nested table = Unbounded collection (no size limit); can be stored in database tables; usable in SQL.

```sql
-- Declare schema-level nested table type
CREATE OR REPLACE TYPE emp_id_list IS TABLE OF NUMBER;
/

-- Use in procedure
DECLARE
    v_ids emp_id_list;
BEGIN
    v_ids := emp_id_list(101, 102, 103, 104, 105);
    
    FOR i IN 1 .. v_ids.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('ID: ' || v_ids(i));
    END LOOP;
END;
/
```

### BULK COLLECT into Nested Table

```sql
DECLARE
    TYPE emp_table IS TABLE OF employees%ROWTYPE;
    v_employees emp_table;
BEGIN
    -- Fetch all rows in ONE call
    SELECT * BULK COLLECT INTO v_employees
    FROM employees
    WHERE department_id = 10;
    
    DBMS_OUTPUT.PUT_LINE('Fetched ' || v_employees.COUNT || ' employees');
    
    -- Process
    FOR i IN 1 .. v_employees.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(i || ': ' || v_employees(i).name);
    END LOOP;
END;
/
```

### Nested Table with DELETE (Sparse Collection)

```sql
DECLARE
    TYPE num_list IS TABLE OF NUMBER;
    v_values num_list := num_list(10, 20, 30, 40, 50);
    v_index PLS_INTEGER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Before DELETE:');
    FOR i IN 1 .. v_values.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(v_values(i));
    END LOOP;
    
    -- Delete index 2 (removes value 20)
    v_values.DELETE(2);
    
    DBMS_OUTPUT.PUT_LINE('After DELETE(2):');
    DBMS_OUTPUT.PUT_LINE('COUNT: ' || v_values.COUNT);  -- Still 5!
    
    -- Iterate (skip deleted)
    v_index := v_values.FIRST;
    WHILE v_index IS NOT NULL LOOP
        DBMS_OUTPUT.PUT_LINE('Index ' || v_index || ': ' || v_values(v_index));
        v_index := v_values.NEXT(v_index);
    END LOOP;
    
    -- Output shows gap at index 2
END;
/
```

**Key Point:** After DELETE, the collection is SPARSE (has gaps). You must use EXISTS or FIRST/NEXT to safely iterate.

---

## 6. VARRAYs: Fixed-Size Ordered Collections

### What is a VARRAY?

VARRAY = Fixed-size collection; maximum size declared at creation; dense ordering preserved.

```sql
-- Declare VARRAY type (maximum 5 elements)
DECLARE
    TYPE skill_list IS VARRAY(5) OF VARCHAR2(50);
    v_skills skill_list := skill_list('SQL', 'PL/SQL', 'Python');
BEGIN
    DBMS_OUTPUT.PUT_LINE('Skills count: ' || v_skills.COUNT);  -- 3
    DBMS_OUTPUT.PUT_LINE('Max size: 5');
    
    FOR i IN 1 .. v_skills.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(i || ': ' || v_skills(i));
    END LOOP;
    
    -- Add 4th skill
    v_skills.EXTEND;
    v_skills(4) := 'Java';
    
    -- Try to add 6th skill (ERROR: collection is full)
    -- v_skills.EXTEND;  -- Would raise error
END;
/
```

### VARRAY Use Cases

```sql
-- Status codes (only 3 values allowed)
DECLARE
    TYPE status_list IS VARRAY(3) OF VARCHAR2(20);
    v_statuses status_list := status_list('ACTIVE', 'INACTIVE', 'SUSPENDED');
BEGIN
    FOR i IN 1 .. v_statuses.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(v_statuses(i));
    END LOOP;
END;

-- Weekly schedule (always 7 days)
DECLARE
    TYPE work_schedule IS VARRAY(7) OF VARCHAR2(10);
    v_schedule work_schedule := work_schedule(
        'Morning', 'Morning', 'Afternoon', 'Afternoon', 'Night', 'OFF', 'OFF'
    );
BEGIN
    FOR i IN 1 .. v_schedule.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('Day ' || i || ': ' || v_schedule(i));
    END LOOP;
END;
/
```

### VARRAY vs Nested Table

| Aspect | VARRAY | Nested Table |
| --- | --- | --- |
| **Size** | Fixed max size | Unbounded |
| **Ordering** | Dense (preserved) | Can be sparse |
| **DELETE** | Leaves gaps if deleted | Leaves gaps if deleted |
| **SQL columns** | Yes | Yes |
| **Best for** | Fixed-size lists | Bulk operations, variable size |

---

## 7. Collection Methods: Manipulation and Iteration

### COUNT: Collection Size

```sql
DECLARE
    TYPE num_list IS TABLE OF NUMBER;
    v_values num_list := num_list(10, 20, 30, 40, 50);
BEGIN
    DBMS_OUTPUT.PUT_LINE('Count: ' || v_values.COUNT);  -- 5
    
    v_values.DELETE(2);
    v_values.DELETE(4);
    
    DBMS_OUTPUT.PUT_LINE('Count after DELETEs: ' || v_values.COUNT);  -- Still 5 (deletion doesn't change COUNT)
END;
/
```

### FIRST and LAST: Boundaries

```sql
DECLARE
    TYPE num_list IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    v_values num_list;
    v_first PLS_INTEGER;
    v_last PLS_INTEGER;
BEGIN
    v_values(1) := 100;
    v_values(5) := 500;
    v_values(10) := 1000;
    
    v_first := v_values.FIRST;  -- 1
    v_last := v_values.LAST;    -- 10
    
    DBMS_OUTPUT.PUT_LINE('First index: ' || v_first);
    DBMS_OUTPUT.PUT_LINE('Last index: ' || v_last);
END;
/
```

### NEXT and PRIOR: Iteration

```sql
DECLARE
    TYPE num_list IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    v_values num_list;
    v_index PLS_INTEGER;
BEGIN
    v_values(1) := 100;
    v_values(5) := 500;
    v_values(10) := 1000;
    
    -- Forward iteration
    DBMS_OUTPUT.PUT_LINE('Forward:');
    v_index := v_values.FIRST;
    WHILE v_index IS NOT NULL LOOP
        DBMS_OUTPUT.PUT_LINE(v_index || ': ' || v_values(v_index));
        v_index := v_values.NEXT(v_index);
    END LOOP;
    
    -- Backward iteration
    DBMS_OUTPUT.PUT_LINE('Backward:');
    v_index := v_values.LAST;
    WHILE v_index IS NOT NULL LOOP
        DBMS_OUTPUT.PUT_LINE(v_index || ': ' || v_values(v_index));
        v_index := v_values.PRIOR(v_index);
    END LOOP;
END;
/
```

### EXISTS: Safe Index Check

```sql
DECLARE
    TYPE num_list IS TABLE OF NUMBER;
    v_values num_list := num_list(10, 20, 30);
BEGIN
    -- ❌ WRONG: May raise SUBSCRIPT_OUTSIDE_LIMIT
    -- DBMS_OUTPUT.PUT_LINE(v_values(10));
    
    -- ✅ CORRECT: Check first
    IF v_values.EXISTS(10) THEN
        DBMS_OUTPUT.PUT_LINE('Index 10: ' || v_values(10));
    ELSE
        DBMS_OUTPUT.PUT_LINE('Index 10 does not exist');
    END IF;
END;
/
```

### EXTEND and TRIM: Grow and Shrink

```sql
DECLARE
    TYPE num_list IS TABLE OF NUMBER;
    v_values num_list := num_list(10, 20, 30);
BEGIN
    DBMS_OUTPUT.PUT_LINE('Initial count: ' || v_values.COUNT);  -- 3
    
    -- Extend by 1 (add empty element at end)
    v_values.EXTEND;
    v_values(4) := 40;
    DBMS_OUTPUT.PUT_LINE('After EXTEND: ' || v_values.COUNT);  -- 4
    
    -- Extend by 2
    v_values.EXTEND(2);
    v_values(5) := 50;
    v_values(6) := 60;
    DBMS_OUTPUT.PUT_LINE('After EXTEND(2): ' || v_values.COUNT);  -- 6
    
    -- Trim 1 (remove from end)
    v_values.TRIM;
    DBMS_OUTPUT.PUT_LINE('After TRIM: ' || v_values.COUNT);  -- 5
END;
/
```

### DELETE: Remove Elements

```sql
DECLARE
    TYPE num_list IS TABLE OF NUMBER;
    v_values num_list := num_list(10, 20, 30, 40, 50);
    v_index PLS_INTEGER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Initial: ' || v_values.COUNT);  -- 5
    
    -- Delete one index
    v_values.DELETE(2);  -- Removes value 20
    DBMS_OUTPUT.PUT_LINE('After DELETE(2): ' || v_values.COUNT);  -- Still 5
    
    -- Delete range
    v_values.DELETE(3, 4);  -- Removes indexes 3-4
    DBMS_OUTPUT.PUT_LINE('After DELETE(3,4): ' || v_values.COUNT);  -- Still 5
    
    -- Delete all
    v_values.DELETE;
    DBMS_OUTPUT.PUT_LINE('After DELETE (all): ' || v_values.COUNT);  -- 0
END;
/
```

---

## 8. Sparse vs Dense Collections

### Dense Collection (Continuous Indexes)

```sql
DECLARE
    TYPE num_list IS TABLE OF NUMBER;
    v_values num_list := num_list(10, 20, 30, 40, 50);
    v_index PLS_INTEGER;
BEGIN
    -- Dense: indexes 1, 2, 3, 4, 5
    -- No gaps
    
    DBMS_OUTPUT.PUT_LINE('Dense collection (no gaps):');
    FOR i IN 1 .. v_values.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(i || ': ' || v_values(i));
    END LOOP;
END;
/
```

### Sparse Collection (Gaps After DELETE)

```sql
DECLARE
    TYPE num_list IS TABLE OF NUMBER;
    v_values num_list := num_list(10, 20, 30, 40, 50);
    v_index PLS_INTEGER;
BEGIN
    v_values.DELETE(2);  -- Remove index 2
    v_values.DELETE(4);  -- Remove index 4
    
    -- Sparse: indexes 1, 3, 5 (gaps at 2, 4)
    
    DBMS_OUTPUT.PUT_LINE('Sparse collection (has gaps):');
    
    -- ❌ WRONG: FOR loop with COUNT assumes dense
    -- FOR i IN 1 .. v_values.COUNT LOOP
    --     DBMS_OUTPUT.PUT_LINE(v_values(i));  -- Error at gap!
    -- END LOOP;
    
    -- ✅ CORRECT: Use FIRST/NEXT for sparse
    v_index := v_values.FIRST;
    WHILE v_index IS NOT NULL LOOP
        DBMS_OUTPUT.PUT_LINE('Index ' || v_index || ': ' || v_values(v_index));
        v_index := v_values.NEXT(v_index);
    END LOOP;
END;
/
```

---

## 9. Passing Collections as Parameters

### Collection Type Definition (Reusable)

```sql
-- Define type at schema level
CREATE OR REPLACE TYPE emp_id_list IS TABLE OF NUMBER;
/

-- Use in multiple procedures
PROCEDURE process_employees (p_emp_ids IN emp_id_list) AS
BEGIN
    FOR i IN 1 .. p_emp_ids.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('Processing employee ' || p_emp_ids(i));
    END LOOP;
END process_employees;
/

-- Call with collection
BEGIN
    process_employees(emp_id_list(101, 102, 103));
END;
/
```

### IN Parameter (Read-Only)

```sql
PROCEDURE display_values (p_values IN TABLE OF NUMBER) AS
BEGIN
    FOR i IN 1 .. p_values.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(p_values(i));
    END LOOP;
    -- p_values.EXTEND;  -- ERROR: Can't modify IN parameter
END display_values;
/
```

### OUT Parameter (Returned by Procedure)

```sql
PROCEDURE fetch_employee_ids (
    p_dept_id IN NUMBER,
    p_ids OUT TABLE OF NUMBER
) AS
BEGIN
    SELECT employee_id BULK COLLECT INTO p_ids
    FROM employees
    WHERE department_id = p_dept_id;
END fetch_employee_ids;
/

DECLARE
    v_ids TABLE OF NUMBER;
BEGIN
    fetch_employee_ids(10, v_ids);
    FOR i IN 1 .. v_ids.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('ID: ' || v_ids(i));
    END LOOP;
END;
/
```

### IN OUT Parameter (Modified by Procedure)

```sql
PROCEDURE apply_raise (p_salaries IN OUT TABLE OF NUMBER) AS
BEGIN
    -- Modify all salaries
    FOR i IN 1 .. p_salaries.COUNT LOOP
        p_salaries(i) := ROUND(p_salaries(i) * 1.10, 2);
    END LOOP;
END apply_raise;
/

DECLARE
    v_salaries TABLE OF NUMBER := TABLE OF NUMBER(50000, 60000, 70000);
BEGIN
    DBMS_OUTPUT.PUT_LINE('Before: ' || v_salaries(1));
    apply_raise(v_salaries);
    DBMS_OUTPUT.PUT_LINE('After: ' || v_salaries(1));
END;
/
```

---

## 10. Real-World Production Scenarios

### Scenario 1: ETL with Bulk Load and Error Handling

```sql
PROCEDURE load_employee_data (p_source_table IN VARCHAR2) AS
    TYPE emp_table IS TABLE OF employees%ROWTYPE;
    TYPE error_table IS TABLE OF VARCHAR2(1000);
    
    v_employees emp_table;
    v_errors error_table := error_table();
    v_error_count NUMBER := 0;
BEGIN
    -- Fetch all records to load
    SELECT * BULK COLLECT INTO v_employees
    FROM import_staging
    WHERE import_date = TRUNC(SYSDATE);
    
    -- Process each record
    FOR i IN 1 .. v_employees.COUNT LOOP
        BEGIN
            -- Validate before insert
            IF v_employees(i).salary < 0 THEN
                v_errors.EXTEND;
                v_errors(v_errors.COUNT) := 'Record ' || i || ': Negative salary not allowed';
                v_error_count := v_error_count + 1;
                CONTINUE;
            END IF;
            
            -- Insert into employees
            INSERT INTO employees
            VALUES (emp_id_seq.NEXTVAL, v_employees(i).name, v_employees(i).salary, v_employees(i).department_id);
            
        EXCEPTION
            WHEN OTHERS THEN
                v_errors.EXTEND;
                v_errors(v_errors.COUNT) := 'Record ' || i || ': ' || SQLERRM;
                v_error_count := v_error_count + 1;
        END;
    END LOOP;
    
    COMMIT;
    
    -- Log results
    DBMS_OUTPUT.PUT_LINE('Loaded: ' || (v_employees.COUNT - v_error_count));
    DBMS_OUTPUT.PUT_LINE('Errors: ' || v_error_count);
    
    FOR i IN 1 .. v_errors.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('  ' || v_errors(i));
    END LOOP;
END load_employee_data;
/
```

### Scenario 2: Caching Lookup Table

```sql
PACKAGE lookup_cache AS
    PROCEDURE initialize_cache;
    FUNCTION get_department_name (p_dept_id IN NUMBER) RETURN VARCHAR2;
END lookup_cache;
/

CREATE OR REPLACE PACKAGE BODY lookup_cache AS
    TYPE dept_cache IS TABLE OF departments%ROWTYPE INDEX BY PLS_INTEGER;
    v_departments dept_cache;
    v_initialized BOOLEAN := FALSE;
    
    PROCEDURE initialize_cache AS
    BEGIN
        FOR dept IN (SELECT * FROM departments) LOOP
            v_departments(dept.department_id) := dept;
        END LOOP;
        v_initialized := TRUE;
        DBMS_OUTPUT.PUT_LINE('Cache initialized with ' || v_departments.COUNT || ' departments');
    END initialize_cache;
    
    FUNCTION get_department_name (p_dept_id IN NUMBER) RETURN VARCHAR2 AS
    BEGIN
        IF NOT v_initialized THEN
            initialize_cache;
        END IF;
        
        IF v_departments.EXISTS(p_dept_id) THEN
            RETURN v_departments(p_dept_id).department_name;
        ELSE
            RETURN NULL;
        END IF;
    END get_department_name;
    
BEGIN
    NULL;
END lookup_cache;
/
```

---

## 11. Performance Characteristics

### Time Complexity

| Operation | Associative Array | Nested Table | VARRAY |
| --- | --- | --- | --- |
| **Insert/Update** | O(1) | O(1) | O(1) |
| **Access by index** | O(1) | O(1) | O(1) |
| **Lookup by key** | O(1) | O(n) | O(n) |
| **Iteration** | O(n) | O(n) | O(n) |
| **Sparse iteration** | Efficient | Must skip gaps | N/A (dense) |

### Memory Usage

```sql
DECLARE
    TYPE emp_table IS TABLE OF employees%ROWTYPE;
    v_employees emp_table;
BEGIN
    -- Estimate memory per row: ~200 bytes
    -- 10,000 rows = 2 MB (safe)
    -- 100,000 rows = 20 MB (risky)
    -- 1,000,000 rows = 200 MB (use LIMIT batching)
    
    SELECT * BULK COLLECT INTO v_employees FROM employees;  -- All at once
    -- vs
    SELECT * BULK COLLECT INTO v_employees FROM employees LIMIT 1000;  -- Batches
END;
/
```

---

## 12. Comparison Matrix

| Feature | Associative Array | Nested Table | VARRAY | Record |
| --- | --- | --- | --- | --- |
| **Indexes** | Integer or string | Integer only | Integer only | Named fields |
| **Size** | Unbounded | Unbounded | Fixed max | Fixed |
| **Sparse** | Yes | Yes (after DELETE) | No (dense) | N/A |
| **SQL columns** | No | Yes | Yes | No |
| **Lookup** | O(1) by key | O(n) | O(n) | Direct access |
| **Best use** | Cache, lookup | Bulk SQL | Fixed lists | Row data |
| **PL/SQL only** | Yes | No | No | No |

---

## 13. Best Practices

### 1. Use %ROWTYPE for Table Rows

```sql
-- ✅ GOOD
DECLARE
    v_employee employees%ROWTYPE;
    TYPE emp_table IS TABLE OF employees%ROWTYPE;
    v_employees emp_table;

-- ❌ AVOID: Manual field listing
DECLARE
    TYPE emp_table IS TABLE OF RECORD (
        employee_id NUMBER,
        name VARCHAR2(50),
        ...many more fields
    );
```

---

### 2. Check EXISTS Before Accessing Sparse Collections

```sql
-- ✅ GOOD
IF v_values.EXISTS(v_index) THEN
    DBMS_OUTPUT.PUT_LINE(v_values(v_index));
END IF;

-- ❌ AVOID: May raise error on gap
DBMS_OUTPUT.PUT_LINE(v_values(v_index));
```

---

### 3. Use FIRST/NEXT for Sparse Iteration

```sql
-- ✅ GOOD: Handles sparse collections
v_index := v_values.FIRST;
WHILE v_index IS NOT NULL LOOP
    DBMS_OUTPUT.PUT_LINE(v_values(v_index));
    v_index := v_values.NEXT(v_index);
END LOOP;

-- ❌ AVOID: Fails on gaps (assumes dense)
FOR i IN 1 .. v_values.COUNT LOOP
    DBMS_OUTPUT.PUT_LINE(v_values(i));
END LOOP;
```

---

### 4. Use LIMIT with Bulk Collect on Large Tables

```sql
-- ✅ GOOD: Batch processing
LOOP
    FETCH cursor_name BULK COLLECT INTO v_batch LIMIT 1000;
    EXIT WHEN v_batch.COUNT = 0;
    -- Process batch
    COMMIT;
END LOOP;

-- ❌ RISKY: Loads entire table into memory
SELECT * BULK COLLECT INTO v_all_rows FROM large_table;
```

---

### 5. Choose Right Collection Type

```sql
-- Use ASSOCIATIVE ARRAY for caching
TYPE emp_cache IS TABLE OF employees%ROWTYPE INDEX BY PLS_INTEGER;

-- Use NESTED TABLE for bulk SQL operations
TYPE emp_table IS TABLE OF employees%ROWTYPE;

-- Use VARRAY for fixed-size lists
TYPE status_list IS VARRAY(10) OF VARCHAR2(50);
```

---

## 14. Common Mistakes

### Mistake 1: Accessing Sparse Collection Without EXISTS

```sql
-- ❌ WRONG: Raises SUBSCRIPT_OUTSIDE_LIMIT
DECLARE
    TYPE num_list IS TABLE OF NUMBER;
    v_values num_list := num_list(10, 20, 30);
BEGIN
    v_values.DELETE(2);
    DBMS_OUTPUT.PUT_LINE(v_values(2));  -- ERROR!
END;

-- ✅ CORRECT
DECLARE
    TYPE num_list IS TABLE OF NUMBER;
    v_values num_list := num_list(10, 20, 30);
BEGIN
    v_values.DELETE(2);
    IF v_values.EXISTS(2) THEN
        DBMS_OUTPUT.PUT_LINE(v_values(2));
    END IF;
END;
```

---

### Mistake 2: Using FOR Loop on Sparse Collection

```sql
-- ❌ WRONG: FOR assumes dense; fails at gaps
DECLARE
    TYPE num_list IS TABLE OF NUMBER;
    v_values num_list := num_list(10, 20, 30, 40);
BEGIN
    v_values.DELETE(2);
    FOR i IN 1 .. v_values.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(v_values(i));  -- ERROR at index 2 (gap)
    END LOOP;
END;

-- ✅ CORRECT: Use FIRST/NEXT
DECLARE
    TYPE num_list IS TABLE OF NUMBER;
    v_values num_list := num_list(10, 20, 30, 40);
    v_index PLS_INTEGER;
BEGIN
    v_values.DELETE(2);
    v_index := v_values.FIRST;
    WHILE v_index IS NOT NULL LOOP
        DBMS_OUTPUT.PUT_LINE(v_values(v_index));
        v_index := v_values.NEXT(v_index);
    END LOOP;
END;
```

---

### Mistake 3: Uninitialized Collection

```sql
-- ❌ WRONG: Collection is null
DECLARE
    TYPE num_list IS TABLE OF NUMBER;
    v_values num_list;
BEGIN
    v_values.EXTEND;  -- ERROR: Collection is null
END;

-- ✅ CORRECT: Initialize first
DECLARE
    TYPE num_list IS TABLE OF NUMBER;
    v_values num_list := num_list();
BEGIN
    v_values.EXTEND;
    v_values(1) := 100;
END;
```

---

### Mistake 4: Overfilling Memory with BULK COLLECT

```sql
-- ❌ RISKY: Loads 1M rows into memory
DECLARE
    TYPE emp_table IS TABLE OF employees%ROWTYPE;
    v_employees emp_table;
BEGIN
    SELECT * BULK COLLECT INTO v_employees FROM large_table;  -- 200+ MB
END;

-- ✅ SAFE: Batch in chunks
DECLARE
    TYPE emp_table IS TABLE OF employees%ROWTYPE;
    v_employees emp_table;
    CURSOR c_emp IS SELECT * FROM large_table;
BEGIN
    OPEN c_emp;
    LOOP
        FETCH c_emp BULK COLLECT INTO v_employees LIMIT 1000;
        EXIT WHEN v_employees.COUNT = 0;
        -- Process batch
        COMMIT;
    END LOOP;
    CLOSE c_emp;
END;
```

---

### Mistake 5: Wrong Collection Type for Use Case

```sql
-- ❌ WRONG: Using VARRAY for unbounded list
DECLARE
    TYPE emp_list IS VARRAY(999999) OF employees%ROWTYPE;  -- Defeats purpose
    v_employees emp_list;
BEGIN
    SELECT * BULK COLLECT INTO v_employees FROM employees;
END;

-- ✅ CORRECT: Use NESTED TABLE for bulk operations
DECLARE
    TYPE emp_list IS TABLE OF employees%ROWTYPE;
    v_employees emp_list;
BEGIN
    SELECT * BULK COLLECT INTO v_employees FROM employees;
END;
```

---

## 15. Interview Q&A

### Q1: What's the difference between a record and a collection?

**A:** A record is ONE composite value (one row with multiple fields). A collection is MANY elements (array or table). Use records for single logical units, collections for batches of data.

---

### Q2: When should you use each collection type?

**A:**
- **Associative array:** Fast lookup/caching (by ID, by name)
- **Nested table:** Bulk SQL operations, BULK COLLECT, unbounded size
- **VARRAY:** Fixed-size lists (statuses, weekdays, short lists)

---

### Q3: What's the difference between a sparse and dense collection?

**A:** Dense has continuous indexes (1,2,3,4,5). Sparse has gaps after DELETE (1,3,5). Use FIRST/NEXT for sparse, FOR loop for dense.

---

### Q4: How do you safely iterate a collection that might be sparse?

**A:**
```sql
v_index := v_collection.FIRST;
WHILE v_index IS NOT NULL LOOP
    DBMS_OUTPUT.PUT_LINE(v_collection(v_index));
    v_index := v_collection.NEXT(v_index);
END LOOP;
```

---

### Q5: What's the performance advantage of an associative array for caching?

**A:** Lookup is O(1) (instant) by key, vs database query O(log n). For 10K lookups, cache is ~100x faster. Trade-off: uses memory.

---

### Q6: Why should you use LIMIT with BULK COLLECT on large tables?

**A:** Without LIMIT, all rows load into memory at once (risky: 1M rows = 200+ MB). LIMIT batches fetch (LIMIT 1000 = 2MB per batch), safer for production.

---

### Q7: Can you store an associative array in a database table?

**A:** No. Associative arrays are PL/SQL-only. Nested tables and VARRAYs can be stored (must be schema-level types).

---

### Q8: What happens if you try to access an index that doesn't exist in a sparse collection?

**A:** Raises SUBSCRIPT_OUTSIDE_LIMIT error. Use EXISTS to check first.

---

### Q9: Can you use %ROWTYPE with a cursor?

**A:** Yes. `CURSOR cur IS ...; TYPE rec_type IS RECORD LIKE cur%ROWTYPE;` But %ROWTYPE on the table is simpler.

---

### Q10: What's the difference between DELETE(index) and TRIM?

**A:** DELETE(index) removes specific element (sparse). TRIM removes from end (maintains order). DELETE makes collection sparse, TRIM just shrinks count.

---

## 16. Revision Summary

### Key Takeaways

1. **Records** = One row of data (composite structure); use %ROWTYPE for tables
2. **Associative arrays** = Key-value map; PL/SQL only; O(1) lookup; perfect for caching
3. **Nested tables** = Unbounded; usable in SQL; can be sparse after DELETE
4. **VARRAYs** = Fixed size; dense ordering; best for small fixed lists
5. **Sparse vs Dense** = Dense = continuous indexes; Sparse = gaps after DELETE
6. **Collection methods** = COUNT, FIRST/LAST, NEXT/PRIOR, EXISTS, DELETE, EXTEND, TRIM
7. **Safe iteration** = Use FIRST/NEXT for sparse; FOR loop for dense
8. **BULK COLLECT** = Load rows efficiently; use LIMIT for large tables
9. **EXISTS check** = Always verify index exists before accessing sparse collection
10. **Performance** = Associative array O(1) lookup; nested table O(n); VARRAY O(1)

### Quick Reference: Choosing Collection Type

```
Need fast key-value lookup?        → Associative array (INDEX BY)
Need to store in SQL column?       → Nested table or VARRAY
Have fixed max size?               → VARRAY
Need unbounded variable size?      → Nested table
Need single row of data?           → Record or %ROWTYPE
Bulk loading from database?        → Nested table + BULK COLLECT + LIMIT

