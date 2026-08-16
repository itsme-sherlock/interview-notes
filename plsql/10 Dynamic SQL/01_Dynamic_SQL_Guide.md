# PL/SQL Dynamic SQL: Comprehensive Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Dynamic SQL** = SQL statement whose text or structure is determined at runtime (not compile time).
- **`EXECUTE IMMEDIATE`** = Primary method for dynamic SQL and DDL (single statement, simple syntax).
- **Bind variables** = Runtime values supplied separately from SQL text (USING clause); safe and efficient.
- **SQL injection** = Security vulnerability: concatenating untrusted values into SQL text (WHERE user_input = 'abc' OR '1'='1').
- **Parameterized queries** = Best practice: bind all values; EXECUTE IMMEDIATE ... USING param1, param2.
- **OPEN FOR** = Dynamic queries with result sets; return REF CURSOR to caller (often used in procedures).
- **DBMS_SQL** = Lower-level dynamic SQL API (legacy; avoid in new code; useful for highly variable statements).
- **DDL (CREATE, ALTER, DROP)** = Cannot use bind variables; validate table/column names against allow-list or use DBMS_ASSERT.
- **Security rule** = Never concatenate untrusted input directly into SQL text; use binds or validation; log suspicious attempts.
- **Common pitfall** = Assuming EXECUTE IMMEDIATE is slow (it's not; parse cost is minimal); using string concatenation instead of binds (security risk).

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Dynamic SQL?](#1-why-do-we-need-dynamic-sql)
2. [What Is Dynamic SQL?](#2-what-is-dynamic-sql)
3. [EXECUTE IMMEDIATE: Basic Syntax](#3-execute-immediate-basic-syntax)
4. [EXECUTE IMMEDIATE Variations](#4-execute-immediate-variations)
5. [Bind Variables: Security and Performance](#5-bind-variables-security-and-performance)
6. [SQL Injection: Risks and Prevention](#6-sql-injection-risks-and-prevention)
7. [OPEN FOR: Dynamic Cursors and REF CURSORS](#7-open-for-dynamic-cursors-and-ref-cursors)
8. [Dynamic DDL (CREATE, ALTER, DROP)](#8-dynamic-ddl-create-alter-drop)
9. [DBMS_SQL: Legacy Approach (Avoid)](#9-dbms_sql-legacy-approach-avoid)
10. [Dynamic SQL in Procedures](#10-dynamic-sql-in-procedures)
11. [Real-World Production Scenarios](#11-real-world-production-scenarios)
12. [Comparison: Static vs Dynamic SQL](#12-comparison-static-vs-dynamic-sql)
13. [Best Practices](#13-best-practices)
14. [Common Mistakes](#14-common-mistakes)
15. [Interview Q&A](#15-interview-qa)
16. [Revision Summary](#16-revision-summary)

---

## 1. Why Do We Need Dynamic SQL?

### The Problem: Fixed SQL Statements

Static SQL requires object names, column names, and statement structure to be known at compile time.

```sql
-- STATIC SQL (compile-time known structure)
DECLARE
    v_salary employees.salary%TYPE;
BEGIN
    SELECT salary INTO v_salary FROM employees WHERE employee_id = 101;
    -- Table name, column names, WHERE condition all known at compile time
END;
```

### When Static SQL Isn't Enough

| Scenario | Limitation |
| --- | --- |
| **Generic Utilities** | "Show me any table's data" → table name unknown |
| **Administrative Tools** | "Create user ABC" → username from user input |
| **Configuration-Driven** | "Query the table named in config" → table name from config |
| **Optional Filters** | "WHERE department = 10 OR WHERE salary > 50000" → condition varies |
| **Metadata-Driven ETL** | "Load columns A, B, C or A, B, D?" → columns vary per run |
| **Migration Tools** | "Compare old schema vs new" → schemas unknown in advance |

### The Solution: Dynamic SQL

```sql
-- DYNAMIC SQL (runtime-determined structure)
DECLARE
    v_table_name VARCHAR2(30) := 'EMPLOYEES';
    v_column_name VARCHAR2(30) := 'EMPLOYEE_ID';
    v_value NUMBER := 101;
    v_result VARCHAR2(4000);
    v_sql VARCHAR2(4000);
BEGIN
    -- SQL text built at runtime
    v_sql := 'SELECT ' || v_column_name || ' FROM ' || v_table_name || ' WHERE employee_id = :1';
    EXECUTE IMMEDIATE v_sql INTO v_result USING v_value;
    -- Runs query for any table, column, value combination
END;
```

---

**➡ Transition:** Let's understand what makes SQL "dynamic" vs "static".

---

## 2. What Is Dynamic SQL?

### Definition

**Dynamic SQL** = SQL statement whose text or object identifiers are constructed or selected while the program runs (not known at compile time).

### Static vs Dynamic Comparison

#### Static SQL (Compile Time)
```sql
SELECT salary INTO v_salary FROM employees WHERE employee_id = 101;
-- All parts known when code is written/compiled
```

#### Dynamic SQL (Runtime)
```sql
v_sql := 'SELECT salary FROM ' || v_table_name || ' WHERE employee_id = ' || v_id;
EXECUTE IMMEDIATE v_sql INTO v_salary;
-- v_table_name and v_id determined while program runs
```

### Key Characteristics

1. **Text Built at Runtime:** SQL statement is a string, not hard-coded
2. **Flexibility:** Same code works for different tables, columns, conditions
3. **Trade-off:** More flexible but harder to validate, parse-overhead, SQL injection risk
4. **Use Sparingly:** Only when structure can't be known at compile time

---

**➡ Transition:** Let's start with EXECUTE IMMEDIATE, the primary dynamic SQL method.

---

## 3. EXECUTE IMMEDIATE: Basic Syntax

### Syntax

```sql
EXECUTE IMMEDIATE sql_string
    [INTO variable1, variable2, ...]
    [USING [IN|OUT|IN OUT] parameter1, ...]
    [RETURNING INTO variable];
```

### Example 1: Simple DDL (No Result)

```sql
DECLARE
    v_table_name VARCHAR2(30) := 'new_employees';
BEGIN
    EXECUTE IMMEDIATE 
        'CREATE TABLE ' || v_table_name || ' AS SELECT * FROM employees WHERE 1=0';
    -- Creates new table (empty structure only)
    DBMS_OUTPUT.PUT_LINE('Table ' || v_table_name || ' created');
END;
/
```

---

### Example 2: Query with INTO (Scalar Result)

```sql
DECLARE
    v_salary NUMBER;
    v_employee_id NUMBER := 101;
    v_sql VARCHAR2(500);
BEGIN
    v_sql := 'SELECT salary FROM employees WHERE employee_id = :emp_id';
    EXECUTE IMMEDIATE v_sql INTO v_salary USING v_employee_id;
    DBMS_OUTPUT.PUT_LINE('Salary: ' || v_salary);
END;
/
```

---

### Example 3: DML with RETURNING

```sql
DECLARE
    v_employee_id NUMBER := 101;
    v_new_salary NUMBER := 75000;
    v_old_salary NUMBER;
    v_sql VARCHAR2(500);
BEGIN
    v_sql := 'UPDATE employees SET salary = :new_sal WHERE employee_id = :emp_id RETURNING salary INTO :old_sal';
    
    -- ❌ WRONG: RETURNING INTO in EXECUTE IMMEDIATE doesn't work this way
    -- ✅ CORRECT: Use nested RETURNING clause with RETURNING INTO
    
    EXECUTE IMMEDIATE 
        'UPDATE employees SET salary = :1 WHERE employee_id = :2 RETURNING salary INTO :3'
        RETURNING INTO v_old_salary
        USING v_new_salary, v_employee_id;
    
    DBMS_OUTPUT.PUT_LINE('Old salary was: ' || v_old_salary);
END;
/
```

---

### Example 4: DML with RETURNING (Simpler Syntax)

```sql
DECLARE
    v_salary NUMBER;
    v_emp_id NUMBER := 101;
BEGIN
    EXECUTE IMMEDIATE 
        'UPDATE employees SET salary = salary * 1.10 WHERE employee_id = :1 RETURNING salary INTO :2'
        RETURNING INTO v_salary
        USING v_emp_id;
    
    DBMS_OUTPUT.PUT_LINE('New salary: ' || v_salary);
END;
/
```

---

**➡ Transition:** Let's explore different variations of EXECUTE IMMEDIATE.

---

## 4. EXECUTE IMMEDIATE Variations

### Variation 1: SELECT with INTO (Scalar)

```sql
DECLARE
    v_count NUMBER;
BEGIN
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM employees WHERE salary > :1'
        INTO v_count
        USING 50000;
    
    DBMS_OUTPUT.PUT_LINE('Employees earning > $50K: ' || v_count);
END;
/
```

---

### Variation 2: SELECT into Collection

```sql
DECLARE
    TYPE emp_id_table IS TABLE OF employees.employee_id%TYPE;
    v_emp_ids emp_id_table;
    v_dept_id NUMBER := 10;
BEGIN
    EXECUTE IMMEDIATE 
        'SELECT employee_id FROM employees WHERE department_id = :1 BULK COLLECT INTO :2'
        BULK COLLECT INTO v_emp_ids
        USING v_dept_id;
    
    FOR i IN 1 .. v_emp_ids.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('ID: ' || v_emp_ids(i));
    END LOOP;
END;
/
```

---

### Variation 3: INSERT (No Result)

```sql
DECLARE
    v_emp_id NUMBER := 999;
    v_name VARCHAR2(50) := 'John Doe';
    v_salary NUMBER := 60000;
BEGIN
    EXECUTE IMMEDIATE 
        'INSERT INTO employees (employee_id, name, salary) VALUES (:1, :2, :3)'
        USING v_emp_id, v_name, v_salary;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Employee ' || v_emp_id || ' inserted');
END;
/
```

---

### Variation 4: DELETE with RETURNING

```sql
DECLARE
    TYPE emp_table IS TABLE OF employees%ROWTYPE;
    v_deleted_emps emp_table;
    v_dept_id NUMBER := 10;
BEGIN
    EXECUTE IMMEDIATE 
        'DELETE FROM employees WHERE department_id = :1 RETURNING * BULK COLLECT INTO :2'
        BULK COLLECT INTO v_deleted_emps
        USING v_dept_id;
    
    -- v_deleted_emps contains all deleted rows
    DBMS_OUTPUT.PUT_LINE('Deleted ' || v_deleted_emps.COUNT || ' employees');
    
    -- Log deletions
    FOR i IN 1 .. v_deleted_emps.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('Deleted: ' || v_deleted_emps(i).name);
    END LOOP;
    
    ROLLBACK;  -- Undo for demo
END;
/
```

---

**➡ Transition:** Now let's discuss the critical importance of bind variables.

---

## 5. Bind Variables: Security and Performance

### What Are Bind Variables?

Bind variables (`:1`, `:2`, or `:name`) are placeholders in SQL text where values are supplied separately via USING clause.

### Example: Bind vs Concatenation

```sql
DECLARE
    v_employee_id NUMBER := 101;
    v_salary NUMBER;
BEGIN
    -- ❌ BAD: String concatenation (SQL injection risk)
    EXECUTE IMMEDIATE 
        'SELECT salary FROM employees WHERE employee_id = ' || v_employee_id
        INTO v_salary;
    
    -- ✅ GOOD: Bind variable (safe, efficient, cacheable)
    EXECUTE IMMEDIATE 
        'SELECT salary FROM employees WHERE employee_id = :1'
        INTO v_salary
        USING v_employee_id;
END;
/
```

### Why Bind Variables Matter

#### 1. **Security: SQL Injection Prevention**

```sql
-- ❌ VULNERABLE: String concatenation with untrusted input
DECLARE
    v_user_input VARCHAR2(100) := 'abc'' OR ''1''=''1';  -- Malicious input
    v_result VARCHAR2(100);
BEGIN
    EXECUTE IMMEDIATE 
        'SELECT name FROM users WHERE username = ''' || v_user_input || ''''
        INTO v_result;
    -- SQL becomes: "... WHERE username = 'abc' OR '1'='1'"
    -- Returns ALL rows! SQL injection successful.
END;

-- ✅ SAFE: Bind variables with USING
DECLARE
    v_user_input VARCHAR2(100) := 'abc'' OR ''1''=''1';
    v_result VARCHAR2(100);
BEGIN
    EXECUTE IMMEDIATE 
        'SELECT name FROM users WHERE username = :1'
        INTO v_result
        USING v_user_input;
    -- :1 is replaced with literal value 'abc'' OR ''1''=''1'
    -- Treated as single string value; no SQL injection
END;
```

#### 2. **Performance: Query Plan Caching**

Without binds, every variation creates a new query plan:
```sql
-- ❌ NO BIND: Each is a new query
EXECUTE IMMEDIATE 'SELECT ... WHERE employee_id = 101';   -- Query plan 1
EXECUTE IMMEDIATE 'SELECT ... WHERE employee_id = 102';   -- Query plan 2
EXECUTE IMMEDIATE 'SELECT ... WHERE employee_id = 103';   -- Query plan 3
-- 3 different query plans cached

-- ✅ BIND: Same query plan reused
EXECUTE IMMEDIATE 'SELECT ... WHERE employee_id = :1' USING 101;  -- Query plan 1
EXECUTE IMMEDIATE 'SELECT ... WHERE employee_id = :1' USING 102;  -- Reuses plan 1
EXECUTE IMMEDIATE 'SELECT ... WHERE employee_id = :1' USING 103;  -- Reuses plan 1
-- 1 query plan cached, reused 3 times
```

---

### Named Bind Variables

```sql
DECLARE
    v_emp_id NUMBER := 101;
    v_dept_id NUMBER := 10;
    v_salary NUMBER;
BEGIN
    EXECUTE IMMEDIATE 
        'SELECT salary FROM employees WHERE employee_id = :emp_id AND department_id = :dept_id'
        INTO v_salary
        USING emp_id => v_emp_id, dept_id => v_dept_id;
    
    DBMS_OUTPUT.PUT_LINE('Salary: ' || v_salary);
END;
/
```

---

**➡ Transition:** Let's discuss SQL injection in detail—the most critical security issue.

---

## 6. SQL Injection: Risks and Prevention

### What Is SQL Injection?

**SQL injection** = An attacker modifies SQL logic by injecting SQL code through user input fields, changing query behavior without permission.

### Attack Example 1: Authentication Bypass

```sql
-- Vulnerable login procedure
PROCEDURE check_login (p_username IN VARCHAR2, p_password IN VARCHAR2) AS
    v_count NUMBER;
BEGIN
    -- ❌ VULNERABLE: String concatenation
    EXECUTE IMMEDIATE 
        'SELECT COUNT(*) FROM users WHERE username = ''' || p_username || 
        ''' AND password = ''' || p_password || ''''
        INTO v_count;
    
    IF v_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Login successful');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Login failed');
    END IF;
END;

-- Attacker provides:
-- Username: admin' --
-- Password: anything
-- Resulting SQL: "... WHERE username = 'admin' --' AND password = ...'"
-- The comment (--) ignores password check! Attacker logged in without password!
```

---

### Attack Example 2: Data Theft

```sql
-- Vulnerable search
DECLARE
    v_user_input VARCHAR2(100) := 'Smith'' UNION SELECT password FROM users WHERE ''1''=''1';
    v_result VARCHAR2(4000);
BEGIN
    -- ❌ VULNERABLE
    EXECUTE IMMEDIATE 
        'SELECT name FROM employees WHERE name LIKE ''%' || v_user_input || '%'''
        INTO v_result;
    -- Resulting SQL unions employee names with passwords!
END;
```

---

### Prevention Strategy 1: Always Use Bind Variables

```sql
-- ✅ SAFE: Bind variables prevent SQL injection
PROCEDURE check_login (p_username IN VARCHAR2, p_password IN VARCHAR2) AS
    v_count NUMBER;
BEGIN
    EXECUTE IMMEDIATE 
        'SELECT COUNT(*) FROM users WHERE username = :1 AND password = :2'
        INTO v_count
        USING p_username, p_password;
    
    -- No matter what attacker provides in p_username/p_password,
    -- it's treated as a literal value, not SQL code
    
    IF v_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Login successful');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Login failed');
    END IF;
END;
```

---

### Prevention Strategy 2: Validate/Sanitize Non-Bindable Input

For DDL (table names, column names), values cannot be bound. Validate against allow-list:

```sql
-- ❌ VULNERABLE: Table name from user input
DECLARE
    v_table_name VARCHAR2(30) := p_table_name;  -- User input
    v_sql VARCHAR2(1000);
BEGIN
    v_sql := 'SELECT COUNT(*) FROM ' || v_table_name;
    EXECUTE IMMEDIATE v_sql INTO v_count;
    -- Attacker provides: "employees; DROP TABLE employees; --"
    -- Multiple statements executed! Disaster!
END;

-- ✅ SAFE: Validate against allow-list
DECLARE
    v_table_name VARCHAR2(30) := UPPER(p_table_name);
    v_sql VARCHAR2(1000);
BEGIN
    -- Verify table exists in database (only allow real tables)
    DECLARE
        v_exists NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_exists
        FROM user_tables
        WHERE table_name = v_table_name;
        
        IF v_exists = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Table does not exist: ' || v_table_name);
        END IF;
    END;
    
    v_sql := 'SELECT COUNT(*) FROM ' || v_table_name;
    EXECUTE IMMEDIATE v_sql INTO v_count;
END;
```

---

### Prevention Strategy 3: Use DBMS_ASSERT (Oracle's Security Package)

```sql
-- ✅ SAFE: DBMS_ASSERT validates identifiers
DECLARE
    v_table_name VARCHAR2(30);
    v_sql VARCHAR2(1000);
BEGIN
    -- DBMS_ASSERT.SQL_OBJECT_NAME raises error if invalid identifier
    v_table_name := DBMS_ASSERT.SQL_OBJECT_NAME(p_table_name);
    
    v_sql := 'SELECT COUNT(*) FROM ' || v_table_name;
    EXECUTE IMMEDIATE v_sql INTO v_count;
END;

-- DBMS_ASSERT functions:
DBMS_ASSERT.ENQUOTE_LITERAL(p_str)    -- Validates quoted string
DBMS_ASSERT.SQL_OBJECT_NAME(p_str)    -- Validates table/column name
DBMS_ASSERT.SCHEMA_NAME(p_str)        -- Validates schema name
DBMS_ASSERT.SIMPLE_SQL_NAME(p_str)    -- Validates simple name (no dots)
```

---

### Prevention Checklist

| Risk | Mitigation |
| --- | --- |
| **User input in WHERE clause** | Use bind variables (USING) |
| **User input for table name** | Validate against user_tables; use DBMS_ASSERT.SQL_OBJECT_NAME |
| **User input for column name** | Validate against user_tab_columns; use DBMS_ASSERT.SQL_OBJECT_NAME |
| **User input in DDL** | Validate all identifiers; use DBMS_ASSERT |
| **Dynamic WHERE conditions** | Build condition logic, bind values separately |
| **Logging suspicious input** | Insert attempts into audit table; alert admin |

---

**➡ Transition:** Let's explore OPEN FOR for dynamic cursor results.

---

## 7. OPEN FOR: Dynamic Cursors and REF CURSORS

### When to Use OPEN FOR

When you need to return a dynamic result set to a caller (procedure, function, SQL client), use OPEN FOR with REF CURSOR.

### Basic Syntax

```sql
TYPE ref_cursor_type IS REF CURSOR;
v_cursor ref_cursor_type;

OPEN v_cursor FOR 'SELECT ... WHERE column = :1' USING value;
-- Return v_cursor to caller
```

---

### Example 1: Simple Dynamic Cursor

```sql
DECLARE
    TYPE emp_ref_cursor IS REF CURSOR;
    v_cursor emp_ref_cursor;
    v_row employees%ROWTYPE;
    v_dept_id NUMBER := 10;
BEGIN
    -- Open dynamic cursor
    OPEN v_cursor FOR 
        'SELECT * FROM employees WHERE department_id = :1'
        USING v_dept_id;
    
    -- Fetch from cursor
    LOOP
        FETCH v_cursor INTO v_row;
        EXIT WHEN v_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Employee: ' || v_row.name);
    END LOOP;
    
    CLOSE v_cursor;
END;
/
```

---

### Example 2: Procedure Returning REF CURSOR

```sql
CREATE OR REPLACE PROCEDURE get_employees_by_dept (
    p_dept_id IN NUMBER,
    p_result_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_result_cursor FOR
        'SELECT employee_id, name, salary FROM employees WHERE department_id = :1'
        USING p_dept_id;
END get_employees_by_dept;
/

-- Caller usage (in SQL*Plus or application)
DECLARE
    v_cursor SYS_REFCURSOR;
    v_emp_id NUMBER;
    v_name VARCHAR2(50);
    v_salary NUMBER;
BEGIN
    get_employees_by_dept(10, v_cursor);
    
    LOOP
        FETCH v_cursor INTO v_emp_id, v_name, v_salary;
        EXIT WHEN v_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(v_emp_id || ' - ' || v_name || ' - $' || v_salary);
    END LOOP;
    
    CLOSE v_cursor;
END;
/
```

---

### Example 3: Dynamic Column Selection

```sql
PROCEDURE get_employee_column (
    p_column_name IN VARCHAR2,
    p_dept_id IN NUMBER,
    p_result_cursor OUT SYS_REFCURSOR
) AS
    v_valid_columns VARCHAR2(100) := 'EMPLOYEE_ID,NAME,SALARY,HIRE_DATE';
BEGIN
    -- Validate column name (prevent SQL injection)
    IF INSTR(v_valid_columns, UPPER(p_column_name)) = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Invalid column: ' || p_column_name);
    END IF;
    
    -- Open dynamic cursor with dynamic column
    OPEN p_result_cursor FOR
        'SELECT ' || p_column_name || ' FROM employees WHERE department_id = :1'
        USING p_dept_id;
END get_employee_column;
/
```

---

**➡ Transition:** Let's discuss dynamic DDL (CREATE, ALTER, DROP).

---

## 8. Dynamic DDL (CREATE, ALTER, DROP)

### Why DDL Must Be Dynamic

DDL (CREATE TABLE, ALTER TABLE, DROP TABLE, CREATE INDEX) doesn't support bind variables. Object names must be dynamically constructed.

### Example 1: CREATE TABLE

```sql
DECLARE
    v_table_name VARCHAR2(30) := 'TEMP_DATA_' || TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS');
BEGIN
    EXECUTE IMMEDIATE 
        'CREATE TABLE ' || v_table_name || ' (
            id NUMBER PRIMARY KEY,
            name VARCHAR2(50),
            created_date DATE
        )';
    
    DBMS_OUTPUT.PUT_LINE('Table ' || v_table_name || ' created');
    
    -- Later: drop the table
    EXECUTE IMMEDIATE 'DROP TABLE ' || v_table_name;
    DBMS_OUTPUT.PUT_LINE('Table ' || v_table_name || ' dropped');
END;
/
```

---

### Example 2: CREATE INDEX

```sql
DECLARE
    v_table_name VARCHAR2(30) := 'EMPLOYEES';
    v_column_name VARCHAR2(30) := 'SALARY';
    v_index_name VARCHAR2(30) := 'IDX_' || v_table_name || '_' || v_column_name;
BEGIN
    EXECUTE IMMEDIATE 
        'CREATE INDEX ' || v_index_name || ' ON ' || v_table_name || '(' || v_column_name || ')';
    
    DBMS_OUTPUT.PUT_LINE('Index ' || v_index_name || ' created');
END;
/
```

---

### Example 3: ALTER TABLE with Validation

```sql
PROCEDURE add_column_safe (
    p_table_name IN VARCHAR2,
    p_column_name IN VARCHAR2,
    p_data_type IN VARCHAR2
) AS
    v_col_exists NUMBER;
BEGIN
    -- Validate that column doesn't already exist
    SELECT COUNT(*) INTO v_col_exists
    FROM user_tab_columns
    WHERE table_name = UPPER(p_table_name)
    AND column_name = UPPER(p_column_name);
    
    IF v_col_exists > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Column ' || p_column_name || ' already exists');
    END IF;
    
    -- Validate data type
    IF p_data_type NOT IN ('VARCHAR2(50)', 'NUMBER', 'DATE', 'NUMBER(10,2)') THEN
        RAISE_APPLICATION_ERROR(-20002, 'Invalid data type: ' || p_data_type);
    END IF;
    
    -- Add column
    EXECUTE IMMEDIATE 
        'ALTER TABLE ' || UPPER(p_table_name) || ' ADD ' || 
        UPPER(p_column_name) || ' ' || p_data_type;
    
    DBMS_OUTPUT.PUT_LINE('Column ' || p_column_name || ' added to ' || p_table_name);
END add_column_safe;
/
```

---

### Example 4: Metadata-Driven View Creation

```sql
PROCEDURE create_reporting_view (
    p_base_table IN VARCHAR2,
    p_view_name IN VARCHAR2
) AS
    v_sql VARCHAR2(4000);
BEGIN
    -- Build column list from metadata
    v_sql := 'CREATE OR REPLACE VIEW ' || p_view_name || ' AS SELECT ';
    
    -- Dynamically add columns from user_tab_columns
    FOR col IN (
        SELECT column_name
        FROM user_tab_columns
        WHERE table_name = UPPER(p_base_table)
        ORDER BY column_id
    ) LOOP
        v_sql := v_sql || col.column_name || ', ';
    END LOOP;
    
    -- Remove trailing comma
    v_sql := RTRIM(v_sql, ', ');
    v_sql := v_sql || ' FROM ' || UPPER(p_base_table);
    
    EXECUTE IMMEDIATE v_sql;
    DBMS_OUTPUT.PUT_LINE('View ' || p_view_name || ' created');
END create_reporting_view;
/
```

---

**➡ Transition:** Let's discuss DBMS_SQL (legacy but useful for very dynamic scenarios).

---

## 9. DBMS_SQL: Legacy Approach (Avoid)

### When to Use DBMS_SQL

DBMS_SQL is a lower-level API, rarely needed with modern EXECUTE IMMEDIATE. Use only when:
- Parsing statements with unknown column count/types
- Need more control over bind variables
- Migrating legacy code

### DBMS_SQL Workflow

```sql
DECLARE
    v_cursor INTEGER;
    v_execute_result INTEGER;
    v_column_value VARCHAR2(4000);
BEGIN
    -- Step 1: Parse statement
    v_cursor := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(v_cursor, 'SELECT * FROM employees', DBMS_SQL.NATIVE);
    
    -- Step 2: Define columns (if SELECT)
    DBMS_SQL.DEFINE_COLUMN(v_cursor, 1, v_column_value, 4000);
    
    -- Step 3: Execute
    v_execute_result := DBMS_SQL.EXECUTE(v_cursor);
    
    -- Step 4: Fetch rows
    LOOP
        IF DBMS_SQL.FETCH_ROWS(v_cursor) > 0 THEN
            DBMS_SQL.COLUMN_VALUE(v_cursor, 1, v_column_value);
            DBMS_OUTPUT.PUT_LINE(v_column_value);
        ELSE
            EXIT;
        END IF;
    END LOOP;
    
    -- Step 5: Close
    DBMS_SQL.CLOSE_CURSOR(v_cursor);
END;
/
```

### Why AVOID DBMS_SQL

- **Verbose:** More code than EXECUTE IMMEDIATE for same result
- **Error-prone:** Easy to forget DEFINE_COLUMN calls
- **Outdated:** EXECUTE IMMEDIATE handles 99% of use cases
- **Slower:** Additional parsing overhead

### DBMS_SQL vs EXECUTE IMMEDIATE

| Task | DBMS_SQL | EXECUTE IMMEDIATE |
| --- | --- | --- |
| **Simple SELECT** | 20 lines | 5 lines |
| **Dynamic columns** | Complex | Not possible (use OPEN FOR) |
| **Readability** | Poor | Good |
| **Performance** | Slower | Faster |
| **Recommendation** | Avoid | Use |

---

**➡ Transition:** Let's see dynamic SQL used in real procedures.

---

## 10. Dynamic SQL in Procedures

### Procedure 1: Generic SELECT for Any Table

```sql
CREATE OR REPLACE PROCEDURE select_from_table (
    p_table_name IN VARCHAR2,
    p_where_clause IN VARCHAR2,
    p_result_cursor OUT SYS_REFCURSOR
) AS
    v_sql VARCHAR2(4000);
BEGIN
    -- Validate table exists
    DECLARE
        v_table_exists NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_table_exists
        FROM user_tables
        WHERE table_name = UPPER(p_table_name);
        
        IF v_table_exists = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Table does not exist: ' || p_table_name);
        END IF;
    END;
    
    -- Build query
    v_sql := 'SELECT * FROM ' || UPPER(p_table_name);
    
    IF p_where_clause IS NOT NULL THEN
        v_sql := v_sql || ' WHERE ' || p_where_clause;
    END IF;
    
    -- Open cursor
    OPEN p_result_cursor FOR v_sql;
    
END select_from_table;
/
```

---

### Procedure 2: Dynamic Bulk Insert (ETL)

```sql
CREATE OR REPLACE PROCEDURE bulk_insert (
    p_source_table IN VARCHAR2,
    p_target_table IN VARCHAR2,
    p_where_clause IN VARCHAR2 := NULL,
    p_rows_inserted OUT NUMBER
) AS
    v_sql VARCHAR2(4000);
BEGIN
    -- Build INSERT ... SELECT statement
    v_sql := 'INSERT INTO ' || UPPER(p_target_table) || ' SELECT * FROM ' || UPPER(p_source_table);
    
    IF p_where_clause IS NOT NULL THEN
        v_sql := v_sql || ' WHERE ' || p_where_clause;
    END IF;
    
    -- Execute
    EXECUTE IMMEDIATE v_sql;
    p_rows_inserted := SQL%ROWCOUNT;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Inserted ' || p_rows_inserted || ' rows into ' || p_target_table);
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999, 'Insert failed: ' || SQLERRM);
END bulk_insert;
/
```

---

### Procedure 3: Dynamic Execution with Validation

```sql
CREATE OR REPLACE PROCEDURE execute_user_query (
    p_query IN VARCHAR2,
    p_result_cursor OUT SYS_REFCURSOR
) AS
    v_query_upper VARCHAR2(4000) := UPPER(p_query);
BEGIN
    -- Security: Reject dangerous statements
    IF INSTR(v_query_upper, 'DROP') > 0 OR
       INSTR(v_query_upper, 'TRUNCATE') > 0 OR
       INSTR(v_query_upper, 'DELETE') > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'SELECT queries only; no DML or DDL');
    END IF;
    
    -- Ensure it's a SELECT
    IF SUBSTR(TRIM(v_query_upper), 1, 6) != 'SELECT' THEN
        RAISE_APPLICATION_ERROR(-20002, 'Only SELECT queries allowed');
    END IF;
    
    -- Log query (audit)
    INSERT INTO query_audit_log (query, executed_by, executed_date)
    VALUES (p_query, USER, SYSDATE);
    COMMIT;
    
    -- Execute safe SELECT
    OPEN p_result_cursor FOR p_query;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Query execution failed: ' || SQLERRM);
        RAISE;
END execute_user_query;
/
```

---

**➡ Transition:** Let's see real-world production scenarios.

---

## 11. Real-World Production Scenarios

### Scenario 1: Multi-Tenant SaaS (Dynamic Table by Tenant)

```sql
CREATE OR REPLACE FUNCTION get_tenant_data (
    p_tenant_id IN NUMBER,
    p_column_name IN VARCHAR2
) RETURN SYS_REFCURSOR AS
    v_cursor SYS_REFCURSOR;
    v_table_name VARCHAR2(30) := 'TENANT_' || p_tenant_id || '_DATA';
BEGIN
    -- Verify table exists for this tenant
    DECLARE
        v_exists NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_exists
        FROM user_tables
        WHERE table_name = v_table_name;
        
        IF v_exists = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Tenant ' || p_tenant_id || ' not found');
        END IF;
    END;
    
    -- Return cursor with dynamic column selection
    OPEN v_cursor FOR
        'SELECT ' || p_column_name || ' FROM ' || v_table_name
        USING p_tenant_id;
    
    RETURN v_cursor;
END get_tenant_data;
/
```

---

### Scenario 2: Dynamic Report Generation

```sql
PROCEDURE generate_report (
    p_table_name IN VARCHAR2,
    p_output_filename IN VARCHAR2
) AS
    v_cursor SYS_REFCURSOR;
    v_row_count NUMBER := 0;
BEGIN
    -- Open cursor for any table
    OPEN v_cursor FOR
        'SELECT * FROM ' || UPPER(p_table_name);
    
    -- Write to file
    -- (In real code, use UTL_FILE to write to file_system)
    
    LOOP
        FETCH v_cursor INTO ...
        EXIT WHEN v_cursor%NOTFOUND;
        v_row_count := v_row_count + 1;
        -- Write row to file
    END LOOP;
    
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE('Report generated: ' || v_row_count || ' rows');
END generate_report;
/
```

---

### Scenario 3: Configuration-Driven Data Load

```sql
PROCEDURE load_data_from_config (
    p_config_id IN NUMBER
) AS
    v_source_table VARCHAR2(30);
    v_target_table VARCHAR2(30);
    v_where_clause VARCHAR2(500);
    v_rows_loaded NUMBER;
BEGIN
    -- Read configuration
    SELECT source_table, target_table, where_clause
    INTO v_source_table, v_target_table, v_where_clause
    FROM load_config
    WHERE config_id = p_config_id;
    
    -- Execute bulk insert based on config
    EXECUTE IMMEDIATE
        'INSERT INTO ' || v_target_table || ' SELECT * FROM ' || v_source_table ||
        ' WHERE ' || v_where_clause;
    
    v_rows_loaded := SQL%ROWCOUNT;
    
    -- Update config log
    INSERT INTO load_config_log (config_id, rows_loaded, loaded_date)
    VALUES (p_config_id, v_rows_loaded, SYSDATE);
    
    COMMIT;
END load_data_from_config;
/
```

---

## 12. Comparison: Static vs Dynamic SQL

| Aspect | Static SQL | Dynamic SQL |
| --- | --- | --- |
| **Syntax** | Hard-coded in source | Built as string at runtime |
| **Compilation** | Compile-time checking | No compile-time checking |
| **Flexibility** | Fixed to one table/condition | Works with any table/condition |
| **Security** | Inherently safe | SQL injection risk (use binds!) |
| **Performance** | Slightly faster (no parse) | Minimal overhead (query plan cached) |
| **Query Plan** | Checked at compile time | Checked at runtime |
| **Use Case** | Most database access | Admin tools, generic utilities |
| **Example** | SELECT salary FROM employees | SELECT col FROM table WHERE cond |

---

## 13. Best Practices

### 1. Always Use Bind Variables for Values

```sql
-- ❌ AVOID
EXECUTE IMMEDIATE 'SELECT * FROM employees WHERE id = ' || v_id;

-- ✅ GOOD
EXECUTE IMMEDIATE 'SELECT * FROM employees WHERE id = :1' USING v_id;
```

---

### 2. Validate Object Names (Tables, Columns, Schemas)

```sql
-- ❌ RISKY
EXECUTE IMMEDIATE 'SELECT * FROM ' || p_table_name;

-- ✅ SAFE: Validate first
SELECT COUNT(*) INTO v_count FROM user_tables WHERE table_name = UPPER(p_table_name);
IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Table not found');
END IF;
EXECUTE IMMEDIATE 'SELECT * FROM ' || UPPER(p_table_name);
```

---

### 3. Use DBMS_ASSERT for Identifier Validation

```sql
v_table := DBMS_ASSERT.SQL_OBJECT_NAME(p_table);
v_column := DBMS_ASSERT.SQL_OBJECT_NAME(p_column);
EXECUTE IMMEDIATE 'SELECT ' || v_column || ' FROM ' || v_table;
```

---

### 4. Log All Dynamic SQL Execution (Audit)

```sql
INSERT INTO sql_execution_audit (sql_text, executed_by, executed_date)
VALUES (p_sql, USER, SYSDATE);
EXECUTE IMMEDIATE p_sql;
```

---

### 5. Use Procedures for Reusable Dynamic SQL

```sql
-- Don't repeat dynamic SQL in multiple places
-- Create a procedure and call it

CREATE OR REPLACE PROCEDURE safe_select (
    p_table IN VARCHAR2,
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    -- Validation and execution in one place
    OPEN p_cursor FOR
        'SELECT * FROM ' || DBMS_ASSERT.SQL_OBJECT_NAME(p_table);
END;
```

---

## 14. Common Mistakes

### Mistake 1: String Concatenation Instead of Binds

```sql
-- ❌ VULNERABLE
EXECUTE IMMEDIATE 
    'SELECT salary FROM employees WHERE id = ' || p_id;  -- SQL injection risk

-- ✅ CORRECT
EXECUTE IMMEDIATE 
    'SELECT salary FROM employees WHERE id = :1' USING p_id;
```

---

### Mistake 2: Not Validating Object Names

```sql
-- ❌ RISKY: Any string allowed
EXECUTE IMMEDIATE 'DROP TABLE ' || p_table_name;

-- ✅ SAFE
v_table := DBMS_ASSERT.SQL_OBJECT_NAME(p_table_name);
EXECUTE IMMEDIATE 'DROP TABLE ' || v_table;
```

---

### Mistake 3: Assuming Dynamic SQL is Always Slow

```sql
-- FALSE: Dynamic SQL has minimal parse overhead
-- Query plans ARE cached; subsequent calls are FAST

EXECUTE IMMEDIATE 'SELECT ... WHERE id = :1' USING 101;  -- Parse + execute
EXECUTE IMMEDIATE 'SELECT ... WHERE id = :1' USING 102;  -- Reuses plan, fast!
```

---

### Mistake 4: Not Handling SQL Exceptions

```sql
-- ❌ POOR: Exception not handled
EXECUTE IMMEDIATE 'SELECT salary FROM employees WHERE id = :1' INTO v_sal USING p_id;

-- ✅ GOOD
BEGIN
    EXECUTE IMMEDIATE 'SELECT salary FROM employees WHERE id = :1' INTO v_sal USING p_id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Employee not found');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
END;
```

---

### Mistake 5: Forgetting COMMIT

```sql
-- ❌ UNCOMMITTED
EXECUTE IMMEDIATE 'INSERT INTO employees VALUES (:1, :2)' USING p_id, p_name;

-- ✅ COMMITTED
EXECUTE IMMEDIATE 'INSERT INTO employees VALUES (:1, :2)' USING p_id, p_name;
COMMIT;
```

---

## 15. Interview Q&A

### Q1: What's the main advantage of dynamic SQL?

**A:** Flexibility—same code works for different tables, columns, or conditions determined at runtime (not compile time). Used in generic utilities, admin tools, configuration-driven ETL.

---

### Q2: Why use bind variables instead of string concatenation?

**A:** 
1. **Security:** Prevents SQL injection (user input can't modify SQL logic)
2. **Performance:** Query plan cached after first parse; reused for different values
3. **Clarity:** Separates SQL text from data

---

### Q3: Can you bind table names and column names?

**A:** No. Only values (WHERE clause predicates) can be bound. For table/column names, validate against data dictionary or use DBMS_ASSERT.

```sql
-- ✅ Can bind values
EXECUTE IMMEDIATE 'SELECT * FROM employees WHERE id = :1' USING v_id;

-- ❌ Cannot bind identifiers
-- EXECUTE IMMEDIATE 'SELECT * FROM :table_name' -- WRONG

-- ✅ Validate and concatenate identifiers
EXECUTE IMMEDIATE 'SELECT * FROM ' || DBMS_ASSERT.SQL_OBJECT_NAME(p_table);
```

---

### Q4: What's the difference between EXECUTE IMMEDIATE and OPEN FOR?

**A:**
- **EXECUTE IMMEDIATE:** Single statement (SELECT, INSERT, UPDATE, DELETE, DDL); result into variable or none
- **OPEN FOR:** Dynamic cursor; result set returned to caller as REF CURSOR

```sql
-- EXECUTE IMMEDIATE: Result to variable
EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM employees' INTO v_count;

-- OPEN FOR: Result as cursor for caller
OPEN p_cursor FOR 'SELECT * FROM employees WHERE id = :1' USING p_id;
```

---

### Q5: How do you prevent SQL injection?

**A:**
1. Use bind variables for all values (USING clause)
2. Validate/sanitize non-bindable input (table, column names) against data dictionary
3. Use DBMS_ASSERT for identifier validation
4. Log all dynamic SQL execution (audit)
5. Restrict statement types (e.g., SELECT only in user-facing tools)

---

### Q6: Can you execute multiple statements in one EXECUTE IMMEDIATE?

**A:** No. EXECUTE IMMEDIATE executes one statement at a time.

```sql
-- ❌ WRONG: Multiple statements
EXECUTE IMMEDIATE 'INSERT INTO t1 VALUES (1); INSERT INTO t2 VALUES (2)';

-- ✅ CORRECT: One statement at a time
EXECUTE IMMEDIATE 'INSERT INTO t1 VALUES (1)';
EXECUTE IMMEDIATE 'INSERT INTO t2 VALUES (2)';
```

---

### Q7: What does RETURNING INTO do in EXECUTE IMMEDIATE?

**A:** Captures the values affected by DML (INSERT, UPDATE, DELETE) to use back in PL/SQL.

```sql
EXECUTE IMMEDIATE
    'UPDATE employees SET salary = :1 WHERE id = :2 RETURNING salary INTO :3'
    RETURNING INTO v_new_salary
    USING v_new_sal, v_emp_id;
```

---

### Q8: When should you use DBMS_SQL instead of EXECUTE IMMEDIATE?

**A:** Rarely. DBMS_SQL is verbose and outdated. Use EXECUTE IMMEDIATE for ~99% of cases. Use DBMS_SQL only for highly dynamic scenarios (unknown column count, complex metadata operations).

---

### Q9: How do you handle no rows found in dynamic SQL?

**A:**
```sql
BEGIN
    EXECUTE IMMEDIATE 'SELECT salary FROM employees WHERE id = :1'
        INTO v_salary
        USING p_emp_id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Employee not found');
        v_salary := 0;  -- Default
END;
```

---

### Q10: What's the performance impact of dynamic SQL vs static SQL?

**A:** Minimal (< 1% difference). Dynamic SQL has small parse overhead on first call, but query plan is cached. Subsequent calls with same SQL structure execute just as fast. The difference is negligible in real applications.

---

## 16. Revision Summary

### Key Takeaways

1. **Dynamic SQL is for runtime-determined structure** (table, column, condition determined while program runs).
2. **Always use bind variables** for values (USING clause); prevents SQL injection and improves performance.
3. **Cannot bind identifiers** (table, column names); validate them against data dictionary instead.
4. **EXECUTE IMMEDIATE for single statements** (SELECT, DML, DDL); OPEN FOR for dynamic cursors.
5. **Validate/sanitize all non-bindable input** (table names, column names, schema names).
6. **DBMS_ASSERT** helps validate identifiers safely.
7. **SQL injection is the main risk**; bind variables + validation prevent it.
8. **Performance is NOT a concern** with dynamic SQL; query plans are cached.
9. **Log all dynamic SQL execution** for audit and debugging.
10. **Use procedures** for reusable dynamic SQL; don't repeat validation logic.

### Quick Reference: Dynamic SQL Patterns

| Need | Pattern |
| --- | --- |
| Query with dynamic WHERE | `EXECUTE IMMEDIATE 'SELECT ... WHERE col = :1' USING value` |
| Query with dynamic table | Validate table name, then `'SELECT * FROM ' \|\| v_table` |
| Query returning cursor | `OPEN v_cursor FOR 'SELECT ... WHERE col = :1' USING value` |
| DML with audit | Log SQL to audit table, then execute |
| DDL (CREATE, DROP) | Validate identifiers, then `EXECUTE IMMEDIATE v_ddl_statement` |
| Prevent SQL injection | Use binds (USING) + validate identifiers (DBMS_ASSERT) |
| Error handling | EXCEPTION WHEN NO_DATA_FOUND, OTHERS |

| Aspect | Static SQL | `EXECUTE IMMEDIATE` | `DBMS_SQL` |
| --- | --- | --- | --- |
| Compile-time checking | Strong | Limited | Limited |
| Flexibility | Low | Medium/high | Highest |
| Ease of use | Easiest | Simple | Complex |
| Dynamic result shape | Limited | Limited | Strong |
| Injection risk | Low | Must manage | Must manage |

---

## 7. Best Practices

1. Prefer static SQL whenever the structure is known.
2. Bind every runtime value.
3. Allow-list identifiers and use `DBMS_ASSERT` as a defense-in-depth check.
4. Keep dynamic statements small and log normalized text.
5. Test privilege and injection boundaries.

---

## 8. Common Mistakes

- Concatenating a username or filter value into SQL text.
- Trying to bind a table name with `:table_name`.
- Forgetting `INTO` for a dynamic single-row query.
- Assuming dynamic DDL can be rolled back like ordinary DML.
- Using `DBMS_SQL` when `EXECUTE IMMEDIATE` is sufficient.

---

## 9. Interview Q&A

**Q: Why use dynamic SQL?**

A: When statement structure or object identifiers are not known until runtime, such as generic administration utilities.

**Q: Can a bind variable represent a table name?**

A: No. Bind variables represent values, not SQL identifiers. Validate identifiers separately.

**Q: When would you choose `DBMS_SQL`?**

A: When column count, metadata, or result types are not known at compile time and the lower-level API is necessary.

**Q: How do you prevent injection?**

A: Bind values, allow-list identifiers, validate input, restrict privileges, and avoid concatenating untrusted text.

---

## 10. Revision Summary

- **Dynamic SQL** -> runtime statement structure
- **`EXECUTE IMMEDIATE`** -> simple dynamic SQL API
- **Bind variable** -> safe runtime value
- **`DBMS_ASSERT`** -> identifier validation aid
- **`DBMS_SQL`** -> metadata-driven dynamic SQL

```sql
EXECUTE IMMEDIATE
  'UPDATE employees SET salary = :1 WHERE employee_id = :2'
  USING p_salary, p_employee_id;
```
