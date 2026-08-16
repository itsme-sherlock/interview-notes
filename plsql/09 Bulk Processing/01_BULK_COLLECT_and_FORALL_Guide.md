# PL/SQL Bulk Processing: BULK COLLECT and FORALL Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Context switch** = PL/SQL engine calls SQL engine (expensive cost: ~0.1ms per call). Thousands of switches in loops add up quickly.
- **Bulk processing** = Batch rows between engines; reduce context switches from thousands to dozens (10-20x performance gain).
- **`BULK COLLECT`** = Fetches multiple rows INTO a collection in a single call (SELECT ... BULK COLLECT INTO collection).
- **`FORALL`** = Executes one DML statement against collection elements (FORALL index IN start..end statement).
- **`LIMIT`** = Controls fetch batch size (FETCH ... BULK COLLECT INTO col LIMIT 500); balances memory vs context switches.
- **`SAVE EXCEPTIONS`** = Continues FORALL even if some rows fail; errors stored in SQL%BULK_EXCEPTIONS array.
- **Memory trade-off** = Large LIMIT = fewer context switches but more memory; small LIMIT = less memory but more switches.
- **Best practice** = Use BULK COLLECT + FORALL together for maximum performance; LIMIT typically 500-2000 rows per batch; always SAVE EXCEPTIONS for robustness.
- **Common pitfall** = Using BULK COLLECT without LIMIT on huge result sets (memory explosion); FORALL without SAVE EXCEPTIONS (first error stops entire batch).
- **Interview focus** = Context switches, LIMIT tuning, SAVE EXCEPTIONS error handling, ETL performance patterns, comparison to row-by-row loops.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Bulk Processing?](#1-why-do-we-need-bulk-processing)
2. [What Is Bulk Processing?](#2-what-is-bulk-processing)
3. [Context Switches: The Hidden Cost](#3-context-switches-the-hidden-cost)
4. [BULK COLLECT: Fetching Multiple Rows](#4-bulk-collect-fetching-multiple-rows)
5. [BULK COLLECT Syntax and Variations](#5-bulk-collect-syntax-and-variations)
6. [FORALL: Batch DML Operations](#6-forall-batch-dml-operations)
7. [SAVE EXCEPTIONS: Handling Errors in Bulk DML](#7-save-exceptions-handling-errors-in-bulk-dml)
8. [LIMIT Clause: Memory vs Performance Trade-off](#8-limit-clause-memory-vs-performance-trade-off)
9. [Real-World Production Scenarios](#9-real-world-production-scenarios)
10. [Performance Benchmarks](#10-performance-benchmarks)
11. [Comparison: Row-by-Row vs Bulk Processing](#11-comparison-row-by-row-vs-bulk-processing)
12. [Best Practices](#12-best-practices)
13. [Common Mistakes](#13-common-mistakes)
14. [Interview Q&A](#14-interview-qa)
15. [Revision Summary](#15-revision-summary)

---

## 1. Why Do We Need Bulk Processing?

### The Problem: Context Switches in Loops

When you loop over SQL statements in PL/SQL, each statement crosses the PL/SQL/SQL engine boundary.

```sql
-- ❌ ROW-BY-ROW LOOP (SLOW)
DECLARE
    v_employee_id NUMBER;
    v_salary employees.salary%TYPE;
BEGIN
    -- Loop 10,000 times
    FOR emp IN (SELECT employee_id FROM employees WHERE department_id = 10) LOOP
        -- Context switch #1: PL/SQL → SQL
        SELECT salary INTO v_salary
        FROM employees
        WHERE employee_id = emp.employee_id;
        
        -- Context switch #2: SQL → PL/SQL
        v_salary := v_salary * 1.10;
        
        -- Context switch #3: PL/SQL → SQL
        UPDATE employees
        SET salary = v_salary
        WHERE employee_id = emp.employee_id;
        
        -- Context switch #4: SQL → PL/SQL
        -- Back to top of loop
    END LOOP;
    -- TOTAL CONTEXT SWITCHES: 10,000 rows × 4 switches = 40,000 context switches!
END;
/
```

**Performance Cost:**
- Each context switch: ~0.1 milliseconds
- 10,000 rows × 4 switches × 0.1ms = **4 seconds (overhead alone!)**
- Actual SQL work: ~0.5 seconds
- **Total time: 4.5 seconds** ❌

---

### The Solution: Bulk Processing

```sql
-- ✅ BULK PROCESSING (FAST)
DECLARE
    TYPE emp_table IS TABLE OF employees%ROWTYPE;
    v_employees emp_table;
BEGIN
    -- Context switch #1: Fetch all rows in one call
    SELECT * BULK COLLECT INTO v_employees
    FROM employees
    WHERE department_id = 10;
    
    -- Process in PL/SQL (no context switches here)
    FOR i IN 1 .. v_employees.COUNT LOOP
        v_employees(i).salary := v_employees(i).salary * 1.10;
    END LOOP;
    
    -- Context switch #2: Update all rows in one call
    FORALL i IN 1 .. v_employees.COUNT
        UPDATE employees
        SET salary = v_employees(i).salary
        WHERE employee_id = v_employees(i).employee_id;
    
    -- TOTAL CONTEXT SWITCHES: 2 (massive reduction!)
END;
/
```

**Performance:**
- Fetch: 1 context switch
- Processing: 0 context switches (in PL/SQL memory)
- Update: 1 context switch
- **Total time: 0.5 seconds** ✅ (9x faster!)

---

**➡ Transition:** Let's understand the mechanics of bulk processing.

---

## 2. What Is Bulk Processing?

### Definition

**Bulk processing** = Bundling multiple rows into collections and operating on them in batches, reducing context switches between PL/SQL and SQL engines.

### The Context Switch Diagram

```
ROW-BY-ROW:                          BULK:
─────────────────────────            ──────────────────────
PL/SQL Engine │                       PL/SQL Engine │
              │                                       │
              │ FETCH one row                        │ FETCH 1000 rows
              ↓                                       ↓
SQL Engine ──→ Return row             SQL Engine ──→ Return 1000 rows
              ↑                                       ↑
              │ FETCH one row                        │ FETCH 1000 rows
              │                                       │
              (Repeat 1000s times)                   (Repeat 10s times)
```

### Three Components of Bulk Processing

1. **BULK COLLECT** = Fetch many rows into a collection with one SQL call
2. **FORALL** = Execute one DML statement against many collection elements with one SQL call
3. **LIMIT** = Control fetch batch size (memory vs context switch trade-off)

---

**➡ Transition:** Let's dive into context switches, the hidden cost of loops.

---

## 3. Context Switches: The Hidden Cost

### What Happens During a Context Switch?

When PL/SQL calls SQL (or vice versa):

1. **Save execution state** (registers, variables, call stack)
2. **Load new engine's state** (SQL engine initialization)
3. **Execute SQL statement**
4. **Switch back** (restore PL/SQL state)

This happens **for every SQL statement in a loop**.

### The Cost in Real Numbers

Example: Load 10,000 employee records

**Row-by-Row Approach:**
```
Loop iterations: 10,000
Context switches per iteration: 4 (SELECT + UPDATE + 2 returns)
Total context switches: 40,000
Cost per switch: ~0.1ms
Total overhead: 40,000 × 0.1ms = 4,000ms (4 seconds!)
Actual SQL work: ~0.5 seconds
Total time: 4.5 seconds
```

**Bulk Approach:**
```
Batches: 10 (10,000 ÷ 1000 per batch)
Context switches per batch: 4 (FETCH + processing + UPDATE + return)
Total context switches: 40
Cost per switch: ~0.1ms
Total overhead: 40 × 0.1ms = 4ms
Actual SQL work: ~0.5 seconds
Total time: 0.5 seconds
```

**Performance Gain: 9x faster** (same SQL work, fewer context switches)

---

**➡ Transition:** Now let's learn BULK COLLECT to fetch rows efficiently.

---

## 4. BULK COLLECT: Fetching Multiple Rows

### Syntax

```sql
SELECT ...
BULK COLLECT INTO collection
FROM table
WHERE ...;
```

Or with cursor:

```sql
FETCH cursor_name
BULK COLLECT INTO collection
[LIMIT batch_size];
```

### Simple Example: Fetch All Rows

```sql
DECLARE
    -- Define collection type
    TYPE emp_id_table IS TABLE OF employees.employee_id%TYPE;
    v_emp_ids emp_id_table;
BEGIN
    -- Fetch all employee IDs in ONE call
    SELECT employee_id
    BULK COLLECT INTO v_emp_ids
    FROM employees
    WHERE department_id = 10;
    
    -- v_emp_ids now contains all rows
    DBMS_OUTPUT.PUT_LINE('Fetched ' || v_emp_ids.COUNT || ' employees');
    
    -- Process collection
    FOR i IN 1 .. v_emp_ids.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('Employee: ' || v_emp_ids(i));
    END LOOP;
END;
/
```

---

### Fetching into Records

```sql
DECLARE
    -- Collection of records (entire rows)
    TYPE emp_table IS TABLE OF employees%ROWTYPE;
    v_employees emp_table;
BEGIN
    -- Fetch entire rows
    SELECT *
    BULK COLLECT INTO v_employees
    FROM employees
    WHERE salary > 50000;
    
    -- Process each record
    FOR i IN 1 .. v_employees.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(
            'ID=' || v_employees(i).employee_id || 
            ', Name=' || v_employees(i).name ||
            ', Salary=' || v_employees(i).salary
        );
    END LOOP;
END;
/
```

---

### Fetching into Multiple Collections

```sql
DECLARE
    TYPE id_table IS TABLE OF employees.employee_id%TYPE;
    TYPE name_table IS TABLE OF employees.name%TYPE;
    TYPE salary_table IS TABLE OF employees.salary%TYPE;
    
    v_ids id_table;
    v_names name_table;
    v_salaries salary_table;
BEGIN
    -- Fetch into separate collections
    SELECT employee_id, name, salary
    BULK COLLECT INTO v_ids, v_names, v_salaries
    FROM employees
    WHERE department_id = 10;
    
    -- Process
    FOR i IN 1 .. v_ids.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(v_ids(i) || ' - ' || v_names(i) || ' - $' || v_salaries(i));
    END LOOP;
END;
/
```

---

## 5. BULK COLLECT Syntax and Variations

### Variation 1: Fetch with LIMIT (Batch Processing)

```sql
DECLARE
    CURSOR c_emp IS
        SELECT employee_id, name, salary
        FROM employees;
    
    TYPE emp_table IS TABLE OF c_emp%ROWTYPE;
    v_emp_batch emp_table;
    v_batch_size CONSTANT NUMBER := 1000;
    v_total_rows NUMBER := 0;
BEGIN
    OPEN c_emp;
    LOOP
        -- Fetch up to 1000 rows per iteration
        FETCH c_emp
        BULK COLLECT INTO v_emp_batch
        LIMIT v_batch_size;
        
        -- v_emp_batch now contains <= 1000 rows
        DBMS_OUTPUT.PUT_LINE('Batch size: ' || v_emp_batch.COUNT);
        v_total_rows := v_total_rows + v_emp_batch.COUNT;
        
        -- Process batch
        FORALL i IN 1 .. v_emp_batch.COUNT
            INSERT INTO employee_archive
            VALUES v_emp_batch(i);
        
        COMMIT;  -- Commit after each batch
        
        -- Exit when no more rows
        EXIT WHEN v_emp_batch.COUNT < v_batch_size;
    END LOOP;
    CLOSE c_emp;
    
    DBMS_OUTPUT.PUT_LINE('Total rows processed: ' || v_total_rows);
END;
/
```

**Key Point:** LIMIT prevents memory explosion on huge result sets.

---

### Variation 2: Bulk Collect with DELETE INTO (Getting Deleted Rows)

```sql
DECLARE
    TYPE emp_table IS TABLE OF employees%ROWTYPE;
    v_deleted_employees emp_table;
BEGIN
    -- Delete and capture deleted rows
    DELETE FROM employees
    WHERE salary < 30000
    RETURNING * BULK COLLECT INTO v_deleted_employees;
    
    -- Log deleted employees
    FOR i IN 1 .. v_deleted_employees.COUNT LOOP
        INSERT INTO employee_audit_log (action, employee_id, employee_data)
        VALUES ('DELETED', v_deleted_employees(i).employee_id, v_deleted_employees(i).name);
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Deleted ' || v_deleted_employees.COUNT || ' employees');
END;
/
```

---

### Variation 3: Checking Fetch Results

```sql
DECLARE
    TYPE emp_id_table IS TABLE OF employees.employee_id%TYPE;
    v_emp_ids emp_id_table;
    CURSOR c_emp IS SELECT employee_id FROM employees WHERE department_id = 10;
BEGIN
    OPEN c_emp;
    FETCH c_emp BULK COLLECT INTO v_emp_ids LIMIT 500;
    
    -- Check if we fetched any rows
    IF v_emp_ids.COUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No employees found');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Fetched ' || v_emp_ids.COUNT || ' employees');
    END IF;
    
    CLOSE c_emp;
END;
/
```

---

**➡ Transition:** Now let's learn FORALL for batch DML operations.

---

## 6. FORALL: Batch DML Operations

### Syntax

```sql
FORALL index IN [REVERSE] start .. end [SAVE EXCEPTIONS]
    DML_statement;
```

### Simple Example: Batch Update

```sql
DECLARE
    TYPE emp_id_table IS TABLE OF employees.employee_id%TYPE;
    TYPE emp_table IS TABLE OF employees%ROWTYPE;
    v_employees emp_table;
    v_raise_percent CONSTANT NUMBER := 0.10;  -- 10% raise
BEGIN
    -- Step 1: Fetch employees
    SELECT *
    BULK COLLECT INTO v_employees
    FROM employees
    WHERE department_id = 10;
    
    -- Step 2: Update salaries in batch
    FORALL i IN 1 .. v_employees.COUNT
        UPDATE employees
        SET salary = salary * (1 + v_raise_percent)
        WHERE employee_id = v_employees(i).employee_id;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Updated ' || SQL%ROWCOUNT || ' employees');
END;
/
```

**Key Point:** FORALL sends all UPDATEs to SQL in one batch (instead of one at a time).

---

### Batch Insert

```sql
DECLARE
    TYPE emp_table IS TABLE OF employees%ROWTYPE;
    v_new_employees emp_table;
BEGIN
    -- Simulate loading new employees from external source
    v_new_employees := emp_table(
        employees(null, 'John Smith', 50000, 10),
        employees(null, 'Jane Doe', 55000, 10),
        employees(null, 'Bob Johnson', 48000, 10)
    );
    
    -- Insert all rows in one batch
    FORALL i IN 1 .. v_new_employees.COUNT
        INSERT INTO employees
        VALUES (emp_id_seq.NEXTVAL, 
                v_new_employees(i).name,
                v_new_employees(i).salary,
                v_new_employees(i).department_id);
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Inserted ' || v_new_employees.COUNT || ' employees');
END;
/
```

---

### Batch Delete

```sql
DECLARE
    TYPE emp_id_table IS TABLE OF employees.employee_id%TYPE;
    v_ids_to_delete emp_id_table := emp_id_table(101, 102, 103, 104, 105);
BEGIN
    -- Delete multiple employees
    FORALL i IN 1 .. v_ids_to_delete.COUNT
        DELETE FROM employees
        WHERE employee_id = v_ids_to_delete(i);
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Deleted ' || SQL%ROWCOUNT || ' employees');
END;
/
```

---

### FORALL with REVERSE

```sql
DECLARE
    TYPE id_table IS TABLE OF NUMBER;
    v_ids id_table := id_table(1, 2, 3, 4, 5);
BEGIN
    -- Process in reverse order
    FORALL i IN REVERSE 1 .. v_ids.COUNT
        UPDATE employees SET salary = salary * 1.05 WHERE employee_id = v_ids(i);
    
    COMMIT;
END;
/
```

---

**➡ Transition:** What happens when a FORALL operation encounters an error? Let's handle it with SAVE EXCEPTIONS.

---

## 7. SAVE EXCEPTIONS: Handling Errors in Bulk DML

### The Problem: Stop-on-First-Error

By default, FORALL stops when the first error occurs:

```sql
-- ❌ PROBLEMATIC: First error stops entire batch
DECLARE
    TYPE emp_table IS TABLE OF employees%ROWTYPE;
    v_employees emp_table;
BEGIN
    SELECT * BULK COLLECT INTO v_employees FROM import_data;
    
    FORALL i IN 1 .. v_employees.COUNT
        INSERT INTO employees VALUES v_employees(i);
    -- If row 50 of 1000 violates constraint, rows 51-1000 are never inserted!
    
    COMMIT;
END;
/
```

---

### The Solution: SAVE EXCEPTIONS

```sql
-- ✅ SAVE EXCEPTIONS: Continue despite errors
DECLARE
    TYPE emp_table IS TABLE OF employees%ROWTYPE;
    v_employees emp_table;
    v_error_count NUMBER := 0;
    v_success_count NUMBER := 0;
BEGIN
    SELECT * BULK COLLECT INTO v_employees FROM import_data;
    
    FORALL i IN 1 .. v_employees.COUNT SAVE EXCEPTIONS
        INSERT INTO employees VALUES v_employees(i);
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Successful inserts: ' || (v_employees.COUNT - SQL%BULK_EXCEPTIONS.COUNT));
    DBMS_OUTPUT.PUT_LINE('Failed inserts: ' || SQL%BULK_EXCEPTIONS.COUNT);
    
EXCEPTION
    WHEN OTHERS THEN
        NULL;  -- SAVE EXCEPTIONS catches errors; no exception here
END;
/
```

---

### Capturing Error Details

```sql
DECLARE
    TYPE emp_table IS TABLE OF employees%ROWTYPE;
    v_employees emp_table;
BEGIN
    SELECT * BULK COLLECT INTO v_employees FROM import_data;
    
    FORALL i IN 1 .. v_employees.COUNT SAVE EXCEPTIONS
        INSERT INTO employees VALUES v_employees(i);
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Total rows: ' || v_employees.COUNT);
    DBMS_OUTPUT.PUT_LINE('Failed rows: ' || SQL%BULK_EXCEPTIONS.COUNT);
    
    -- Log each failure
    FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Row ' || SQL%BULK_EXCEPTIONS(i).ERROR_INDEX ||
            ' failed with error ' || SQL%BULK_EXCEPTIONS(i).ERROR_CODE ||
            ': ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE)
        );
    END LOOP;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('FORALL encountered error: ' || SQLERRM);
END;
/
```

### SQL%BULK_EXCEPTIONS Structure

| Field | Type | Meaning |
| --- | --- | --- |
| ERROR_INDEX | PLS_INTEGER | Index in collection that failed |
| ERROR_CODE | PLS_INTEGER | Oracle error code (negative) |

---

### Production Example: Import with Error Handling

```sql
DECLARE
    TYPE emp_table IS TABLE OF employees%ROWTYPE;
    v_employees emp_table;
    v_failed_count NUMBER := 0;
BEGIN
    -- Fetch import data
    SELECT * BULK COLLECT INTO v_employees
    FROM import_staging
    WHERE import_date = TRUNC(SYSDATE);
    
    DBMS_OUTPUT.PUT_LINE('Processing ' || v_employees.COUNT || ' records');
    
    -- Insert all, capturing errors
    FORALL i IN 1 .. v_employees.COUNT SAVE EXCEPTIONS
        INSERT INTO employees (employee_id, name, salary, department_id)
        VALUES (emp_seq.NEXTVAL, v_employees(i).name, v_employees(i).salary, v_employees(i).department_id);
    
    -- Log results
    v_failed_count := SQL%BULK_EXCEPTIONS.COUNT;
    
    INSERT INTO import_results (import_date, total_records, success_count, failure_count, processed_date)
    VALUES (TRUNC(SYSDATE), v_employees.COUNT, v_employees.COUNT - v_failed_count, v_failed_count, SYSDATE);
    
    -- Log individual failures
    FOR i IN 1 .. v_failed_count LOOP
        INSERT INTO import_errors (import_date, row_index, error_code, error_message, processed_date)
        VALUES (
            TRUNC(SYSDATE),
            SQL%BULK_EXCEPTIONS(i).ERROR_INDEX,
            SQL%BULK_EXCEPTIONS(i).ERROR_CODE,
            SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE),
            SYSDATE
        );
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Import complete. Successful: ' || (v_employees.COUNT - v_failed_count) || ', Failed: ' || v_failed_count);
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
END;
/
```

---

**➡ Transition:** The LIMIT clause is crucial for memory management. Let's explore it.

---

## 8. LIMIT Clause: Memory vs Performance Trade-off

### The Trade-off

- **Large LIMIT (e.g., 5000):** Fewer context switches, more memory
- **Small LIMIT (e.g., 100):** More memory efficient, more context switches
- **Optimal LIMIT (500-2000):** Balance between memory and performance

### Memory Calculation

```
Memory per row (approximate) = column_size_sum
For employees table:
  - employee_id (NUMBER): ~4 bytes
  - name (VARCHAR2(100)): ~100 bytes
  - salary (NUMBER): ~4 bytes
  - department_id (NUMBER): ~4 bytes
  Total per row: ~112 bytes

LIMIT 1000: 1000 rows × 112 bytes = 112 KB (safe)
LIMIT 10000: 10000 rows × 112 bytes = 1.12 MB (acceptable)
LIMIT 100000: 100000 rows × 112 bytes = 11.2 MB (risky for large objects)
```

---

### Example: Determining Optimal LIMIT

```sql
DECLARE
    TYPE emp_table IS TABLE OF employees%ROWTYPE;
    v_emp_batch emp_table;
    CURSOR c_emp IS SELECT * FROM employees;
    v_batch_size CONSTANT NUMBER := 1000;  -- Start with this
    v_total_processed NUMBER := 0;
BEGIN
    OPEN c_emp;
    
    LOOP
        FETCH c_emp
        BULK COLLECT INTO v_emp_batch
        LIMIT v_batch_size;
        
        EXIT WHEN v_emp_batch.COUNT = 0;
        
        -- Process batch
        FORALL i IN 1 .. v_emp_batch.COUNT SAVE EXCEPTIONS
            INSERT INTO employee_archive VALUES v_emp_batch(i);
        
        v_total_processed := v_total_processed + v_emp_batch.COUNT;
        
        -- Commit after each batch to free memory
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Processed ' || v_total_processed || ' rows');
    END LOOP;
    
    CLOSE c_emp;
END;
/
```

---

### When to Use Different LIMIT Values

| LIMIT | Data Type | Use Case |
| --- | --- | --- |
| **100-500** | VARCHAR2(4000), CLOB | Large text fields; memory-constrained |
| **500-2000** | VARCHAR2(100), NUMBER, DATE | Most common; good balance |
| **2000-5000** | Small types (NUMBER, INTEGER) | Small columns; better performance |
| **10000+** | NUMBER, DATE | Tiny types; large available memory |

---

**➡ Transition:** Let's see real-world production scenarios using bulk processing.

---

## 9. Real-World Production Scenarios

### Scenario 1: ETL Data Load (CSV to Database)

```sql
PROCEDURE load_employee_data_from_csv (p_file_path IN VARCHAR2) AS
    TYPE emp_table IS TABLE OF employees%ROWTYPE;
    v_employees emp_table;
    v_batch_size CONSTANT NUMBER := 1000;
    v_total_loaded NUMBER := 0;
    v_load_errors NUMBER := 0;
BEGIN
    -- Simulate reading CSV (in real code, use UTL_FILE or external table)
    SELECT *
    BULK COLLECT INTO v_employees
    FROM external_csv_table
    WHERE file_path = p_file_path;
    
    DBMS_OUTPUT.PUT_LINE('Loaded ' || v_employees.COUNT || ' records from CSV');
    
    -- Process in batches
    FOR batch_start IN 1 .. v_employees.COUNT BY v_batch_size LOOP
        DECLARE
            v_batch_end NUMBER := LEAST(batch_start + v_batch_size - 1, v_employees.COUNT);
        BEGIN
            -- Insert batch
            FORALL i IN batch_start .. v_batch_end SAVE EXCEPTIONS
                INSERT INTO employees (employee_id, name, salary, department_id, hire_date)
                VALUES (emp_id_seq.NEXTVAL, v_employees(i).name, v_employees(i).salary, v_employees(i).department_id, SYSDATE);
            
            v_total_loaded := v_total_loaded + (v_batch_end - batch_start + 1);
            
            -- Log any errors
            v_load_errors := SQL%BULK_EXCEPTIONS.COUNT;
            FOR j IN 1 .. v_load_errors LOOP
                INSERT INTO load_error_log (source, row_index, error_code, error_message)
                VALUES (p_file_path, SQL%BULK_EXCEPTIONS(j).ERROR_INDEX, SQL%BULK_EXCEPTIONS(j).ERROR_CODE, SQLERRM(-SQL%BULK_EXCEPTIONS(j).ERROR_CODE));
            END LOOP;
            
            COMMIT;
            DBMS_OUTPUT.PUT_LINE('Batch ' || (batch_start / v_batch_size) || ' complete. Rows loaded: ' || v_total_loaded);
            
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('ERROR in batch: ' || SQLERRM);
        END;
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('Load complete. Total: ' || v_total_loaded || ', Errors: ' || v_load_errors);
    
END load_employee_data_from_csv;
/
```

---

### Scenario 2: Batch Salary Update (No Exceptions)

```sql
PROCEDURE grant_annual_raises (p_raise_percent IN NUMBER) AS
    TYPE emp_table IS TABLE OF employees%ROWTYPE;
    v_employees emp_table;
BEGIN
    -- Fetch all employees (no filtering; we update all)
    SELECT * BULK COLLECT INTO v_employees
    FROM employees;
    
    DBMS_OUTPUT.PUT_LINE('Granting ' || p_raise_percent || '% raise to ' || v_employees.COUNT || ' employees');
    
    -- Apply raise to all employees (no errors expected)
    FORALL i IN 1 .. v_employees.COUNT
        UPDATE employees
        SET salary = ROUND(salary * (1 + p_raise_percent / 100), 2)
        WHERE employee_id = v_employees(i).employee_id;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Raises applied: ' || SQL%ROWCOUNT || ' employees');
    
END grant_annual_raises;
/
```

---

### Scenario 3: Archive Old Records (Bulk Delete + Capture)

```sql
PROCEDURE archive_old_employees (p_years_inactive IN NUMBER) AS
    TYPE emp_table IS TABLE OF employees%ROWTYPE;
    v_archived_employees emp_table;
    v_archive_count NUMBER;
BEGIN
    -- Delete and capture archived rows
    DELETE FROM employees
    WHERE last_promotion_date < ADD_MONTHS(SYSDATE, -p_years_inactive * 12)
    RETURNING * BULK COLLECT INTO v_archived_employees;
    
    v_archive_count := v_archived_employees.COUNT;
    DBMS_OUTPUT.PUT_LINE('Archived ' || v_archive_count || ' inactive employees');
    
    -- Insert into archive table (batch)
    IF v_archive_count > 0 THEN
        FORALL i IN 1 .. v_archived_employees.COUNT
            INSERT INTO employee_archive (employee_id, name, salary, archived_date)
            VALUES (v_archived_employees(i).employee_id, v_archived_employees(i).name, v_archived_employees(i).salary, SYSDATE);
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Inserted ' || SQL%ROWCOUNT || ' records into archive');
    END IF;
    
END archive_old_employees;
/
```

---

**➡ Transition:** Let's see performance benchmarks comparing approaches.

---

## 10. Performance Benchmarks

### Test Scenario: Load 10,000 Employee Records

#### Approach 1: Row-by-Row Loop (Baseline)

```sql
DECLARE
    v_count NUMBER := 0;
BEGIN
    FOR emp IN (SELECT * FROM import_staging ROWNUM <= 10000) LOOP
        INSERT INTO employees (employee_id, name, salary)
        VALUES (emp_seq.NEXTVAL, emp.name, emp.salary);
        v_count := v_count + 1;
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Row-by-row: ' || v_count || ' rows inserted');
END;
/ -- Time: ~4.5 seconds
```

---

#### Approach 2: BULK COLLECT + FORALL (No LIMIT)

```sql
DECLARE
    TYPE emp_table IS TABLE OF import_staging%ROWTYPE;
    v_employees emp_table;
BEGIN
    SELECT * BULK COLLECT INTO v_employees FROM import_staging WHERE ROWNUM <= 10000;
    
    FORALL i IN 1 .. v_employees.COUNT
        INSERT INTO employees (employee_id, name, salary)
        VALUES (emp_seq.NEXTVAL, v_employees(i).name, v_employees(i).salary);
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Bulk (no LIMIT): ' || v_employees.COUNT || ' rows inserted');
END;
/ -- Time: ~0.5 seconds (9x faster!)
```

---

#### Approach 3: BULK COLLECT + FORALL (With LIMIT 1000)

```sql
DECLARE
    TYPE emp_table IS TABLE OF import_staging%ROWTYPE;
    v_employees emp_table;
    CURSOR c_emp IS SELECT * FROM import_staging WHERE ROWNUM <= 10000;
    v_batch_size CONSTANT NUMBER := 1000;
BEGIN
    OPEN c_emp;
    LOOP
        FETCH c_emp BULK COLLECT INTO v_employees LIMIT v_batch_size;
        EXIT WHEN v_employees.COUNT = 0;
        
        FORALL i IN 1 .. v_employees.COUNT
            INSERT INTO employees (employee_id, name, salary)
            VALUES (emp_seq.NEXTVAL, v_employees(i).name, v_employees(i).salary);
        
        COMMIT;
    END LOOP;
    CLOSE c_emp;
    DBMS_OUTPUT.PUT_LINE('Bulk (LIMIT 1000): 10,000 rows inserted');
END;
/ -- Time: ~0.7 seconds (6x faster than row-by-row, slightly more overhead than full load due to commits)
```

---

### Results Summary

| Approach | Time | Speed | Memory | Notes |
| --- | --- | --- | --- | --- |
| **Row-by-Row** | 4.5 sec | 1x (baseline) | Low | ~40,000 context switches |
| **Bulk (No LIMIT)** | 0.5 sec | **9x** | High (~1.1 MB) | 2 context switches; risk of memory issues |
| **Bulk (LIMIT 1000)** | 0.7 sec | **6-7x** | Low (~112 KB) | Balanced; safe for all scenarios |

**Recommendation:** Use BULK COLLECT + FORALL with LIMIT 1000 for production code (safety + performance).

---

## 11. Comparison: Row-by-Row vs Bulk Processing

| Aspect | Row-by-Row Loop | BULK COLLECT + FORALL |
| --- | --- | --- |
| **Context Switches** | Thousands (row × 4) | Dozens (batch × 4) |
| **Performance** | 4-5 seconds / 10K | 0.5-0.7 seconds / 10K |
| **Memory Usage** | Low (1 row at a time) | Medium (batch in memory) |
| **Code Readability** | Simple loops | Requires collection understanding |
| **Error Handling** | Per-statement; easy to stop | SAVE EXCEPTIONS for batch errors |
| **LIMIT Support** | N/A | LIMIT for memory control |
| **Commit Strategy** | After each row (slow) | After each batch (faster) |
| **Use Case** | Small datasets; simple logic | Large datasets; performance-critical |

---

## 12. Best Practices

### 1. Always Use BULK COLLECT + FORALL Together

```sql
-- ❌ AVOID: Only BULK COLLECT (no batch DML benefit)
DECLARE
    TYPE emp_table IS TABLE OF employees%ROWTYPE;
    v_employees emp_table;
BEGIN
    SELECT * BULK COLLECT INTO v_employees FROM employees;
    
    FOR i IN 1 .. v_employees.COUNT LOOP
        INSERT INTO archive VALUES v_employees(i);  -- Row-by-row insert!
    END LOOP;
END;

-- ✅ GOOD: Both BULK COLLECT and FORALL
DECLARE
    TYPE emp_table IS TABLE OF employees%ROWTYPE;
    v_employees emp_table;
BEGIN
    SELECT * BULK COLLECT INTO v_employees FROM employees;
    
    FORALL i IN 1 .. v_employees.COUNT
        INSERT INTO archive VALUES v_employees(i);  -- Batch insert
END;
```

---

### 2. Use LIMIT for Large Result Sets

```sql
-- ❌ RISKY: Large result set in memory
DECLARE
    TYPE emp_table IS TABLE OF employees%ROWTYPE;
    v_employees emp_table;
BEGIN
    SELECT * BULK COLLECT INTO v_employees
    FROM employees;  -- What if 1 million rows?
END;

-- ✅ SAFE: LIMIT batches
DECLARE
    TYPE emp_table IS TABLE OF employees%ROWTYPE;
    v_employees emp_table;
    CURSOR c_emp IS SELECT * FROM employees;
BEGIN
    OPEN c_emp;
    LOOP
        FETCH c_emp BULK COLLECT INTO v_employees LIMIT 1000;
        EXIT WHEN v_employees.COUNT = 0;
        -- Process batch
    END LOOP;
    CLOSE c_emp;
END;
```

---

### 3. Always Use SAVE EXCEPTIONS for Robustness

```sql
-- ❌ AVOID: First error stops batch
FORALL i IN 1 .. v_employees.COUNT
    INSERT INTO employees VALUES v_employees(i);

-- ✅ GOOD: Continue despite errors
FORALL i IN 1 .. v_employees.COUNT SAVE EXCEPTIONS
    INSERT INTO employees VALUES v_employees(i);
```

---

### 4. Commit After Each Batch

```sql
LOOP
    FETCH c_emp BULK COLLECT INTO v_emp_batch LIMIT 1000;
    EXIT WHEN v_emp_batch.COUNT = 0;
    
    FORALL i IN 1 .. v_emp_batch.COUNT
        INSERT INTO employees VALUES v_emp_batch(i);
    
    COMMIT;  -- Commit after batch; free locks and memory
END LOOP;
```

---

### 5. Log Bulk Exceptions

```sql
FORALL i IN 1 .. v_employees.COUNT SAVE EXCEPTIONS
    INSERT INTO employees VALUES v_employees(i);

-- Log errors
FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
    INSERT INTO error_log (row_index, error_code)
    VALUES (SQL%BULK_EXCEPTIONS(i).ERROR_INDEX, SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
END LOOP;
```

---

## 13. Common Mistakes

### Mistake 1: Forgetting LIMIT on Large Cursors

```sql
-- ❌ RISKY: 1 million rows in memory at once
DECLARE
    TYPE emp_table IS TABLE OF employees%ROWTYPE;
    v_employees emp_table;
BEGIN
    SELECT * BULK COLLECT INTO v_employees
    FROM large_table;  -- No LIMIT; could crash
END;

-- ✅ SAFE
DECLARE
    TYPE emp_table IS TABLE OF employees%ROWTYPE;
    v_employees emp_table;
    CURSOR c_emp IS SELECT * FROM large_table;
BEGIN
    OPEN c_emp;
    LOOP
        FETCH c_emp BULK COLLECT INTO v_employees LIMIT 1000;
        EXIT WHEN v_employees.COUNT = 0;
        -- Process
    END LOOP;
    CLOSE c_emp;
END;
```

---

### Mistake 2: Not Using SAVE EXCEPTIONS

```sql
-- ❌ PROBLEM: 1 bad row stops 999 good rows
FORALL i IN 1 .. 1000
    INSERT INTO employees VALUES v_emp(i);  -- Row 50 fails; rows 51-1000 never insert

-- ✅ SOLUTION: SAVE EXCEPTIONS
FORALL i IN 1 .. 1000 SAVE EXCEPTIONS
    INSERT INTO employees VALUES v_emp(i);  -- Row 50 fails; rows 51-1000 still insert
```

---

### Mistake 3: Using BULK COLLECT Without Batch DML

```sql
-- ❌ INEFFICIENT: Fetch in bulk, process row-by-row
DECLARE
    TYPE emp_table IS TABLE OF employees%ROWTYPE;
    v_employees emp_table;
BEGIN
    SELECT * BULK COLLECT INTO v_employees FROM employees;  -- Saves context switches
    
    FOR i IN 1 .. v_employees.COUNT LOOP
        UPDATE archive SET data = v_employees(i) WHERE id = v_employees(i).id;  -- Row-by-row updates!
    END LOOP;
END;

-- ✅ EFFICIENT: Batch both fetch and DML
DECLARE
    TYPE emp_table IS TABLE OF employees%ROWTYPE;
    v_employees emp_table;
BEGIN
    SELECT * BULK COLLECT INTO v_employees FROM employees;
    
    FORALL i IN 1 .. v_employees.COUNT
        UPDATE archive SET data = v_employees(i) WHERE id = v_employees(i).id;  -- Batch update
END;
```

---

### Mistake 4: Not Clearing Collection Between Fetches

```sql
-- ❌ PROBLEM: Collection grows; memory leaks
DECLARE
    TYPE emp_table IS TABLE OF employees%ROWTYPE;
    v_employees emp_table;
    CURSOR c_emp IS SELECT * FROM employees;
BEGIN
    OPEN c_emp;
    LOOP
        FETCH c_emp BULK COLLECT INTO v_employees LIMIT 1000;
        -- v_employees still contains previous batch rows + new rows!
        -- Memory grows unbounded
        EXIT WHEN v_employees.COUNT < 1000;
    END LOOP;
END;

-- ✅ CORRECT: Collection is cleared by FETCH
DECLARE
    TYPE emp_table IS TABLE OF employees%ROWTYPE;
    v_employees emp_table;
    CURSOR c_emp IS SELECT * FROM employees;
BEGIN
    OPEN c_emp;
    LOOP
        FETCH c_emp BULK COLLECT INTO v_employees LIMIT 1000;
        -- FETCH automatically clears v_employees before populating
        EXIT WHEN v_employees.COUNT = 0;
    END LOOP;
END;
```

---

## 14. Interview Q&A

### Q1: What's the main benefit of BULK COLLECT and FORALL?

**A:** Reducing context switches between PL/SQL and SQL engines.
- Row-by-row loop: 1000 rows × 4 switches each = 4,000 context switches
- Bulk: 10 batches × 4 switches = 40 context switches
- Result: 10x faster (for 10K rows, ~4.5 sec → 0.5 sec)

---

### Q2: When should you use LIMIT in BULK COLLECT?

**A:** Always use LIMIT for potentially large result sets to prevent memory explosion.
- No LIMIT: All rows fetched into memory at once (risky if 1M rows)
- LIMIT 1000: Batches of 1000 rows fetched iteratively (safe, predictable memory)

```sql
FETCH c_emp BULK COLLECT INTO v_employees LIMIT 1000;  -- Safe batch fetching
```

---

### Q3: What's the difference between BULK COLLECT and a regular SELECT loop?

**A:**
- Regular SELECT loop: Implicit cursor; one row per iteration; multiple context switches
- BULK COLLECT: Explicit batch fetch; many rows in one context switch

```sql
-- Regular loop (implicit cursor)
FOR emp IN (SELECT * FROM employees) LOOP  -- One row per iteration
    -- Process emp
END LOOP;

-- BULK COLLECT (explicit batch)
FETCH cursor_name BULK COLLECT INTO v_employees LIMIT 1000;  -- Many rows at once
FOR i IN 1 .. v_employees.COUNT LOOP
    -- Process v_employees(i)
END LOOP;
```

---

### Q4: What does SAVE EXCEPTIONS do in FORALL?

**A:** Continues FORALL execution even if some rows fail; captures errors in SQL%BULK_EXCEPTIONS array.

```sql
FORALL i IN 1 .. 1000 SAVE EXCEPTIONS
    INSERT INTO employees VALUES v_emp(i);  -- If row 50 fails, rows 51-1000 still insert

-- Check errors
DBMS_OUTPUT.PUT_LINE('Failed rows: ' || SQL%BULK_EXCEPTIONS.COUNT);
FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
    DBMS_OUTPUT.PUT_LINE('Row ' || SQL%BULK_EXCEPTIONS(i).ERROR_INDEX || ' failed');
END LOOP;
```

---

### Q5: How do you handle errors in a BULK COLLECT/FORALL ETL load?

**A:**
```sql
DECLARE
    TYPE emp_table IS TABLE OF import_staging%ROWTYPE;
    v_employees emp_table;
BEGIN
    SELECT * BULK COLLECT INTO v_employees FROM import_staging;
    
    FORALL i IN 1 .. v_employees.COUNT SAVE EXCEPTIONS
        INSERT INTO employees VALUES v_employees(i);
    
    COMMIT;
    
    -- Log errors
    FOR j IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
        INSERT INTO import_error_log (row_num, error_code, error_msg)
        VALUES (SQL%BULK_EXCEPTIONS(j).ERROR_INDEX, SQL%BULK_EXCEPTIONS(j).ERROR_CODE, SQLERRM(-SQL%BULK_EXCEPTIONS(j).ERROR_CODE));
    END LOOP;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Loaded: ' || (v_employees.COUNT - SQL%BULK_EXCEPTIONS.COUNT) || ', Errors: ' || SQL%BULK_EXCEPTIONS.COUNT);
END;
```

---

### Q6: Can you use FORALL without BULK COLLECT?

**A:** Yes, but you lose batch fetch optimization. You still benefit from batch DML:

```sql
-- FORALL with manually-built collection
DECLARE
    TYPE id_table IS TABLE OF NUMBER;
    v_ids id_table := id_table(101, 102, 103);  -- Manually created
BEGIN
    FORALL i IN 1 .. v_ids.COUNT
        UPDATE employees SET salary = salary * 1.10 WHERE employee_id = v_ids(i);  -- Batch DML
END;
```

But for fetching from database, BULK COLLECT saves context switches.

---

### Q7: What's the optimal LIMIT value?

**A:** Typically 500-2000 rows per batch. Balance between:
- **Memory usage:** Larger LIMIT uses more memory
- **Context switches:** Smaller LIMIT increases switches
- **Practical choice:** Start with LIMIT 1000; adjust based on row size and available memory

```sql
-- Typical safe choice
FETCH c_emp BULK COLLECT INTO v_emp_batch LIMIT 1000;
```

---

### Q8: Does BULK COLLECT guarantee no context switches?

**A:** No, but it reduces them dramatically:
- BULK COLLECT: 1 context switch (fetch all)
- Processing in PL/SQL: 0 context switches
- FORALL: 1 context switch (execute batch DML)
- Total: 2-3 context switches vs. thousands in row-by-row

---

### Q9: What happens if you use FORALL without SAVE EXCEPTIONS and an error occurs?

**A:** The entire FORALL statement stops; remaining rows in the collection are never processed.

```sql
-- ❌ PROBLEM: Row 50 of 1000 fails; rows 51-1000 never insert
FORALL i IN 1 .. 1000
    INSERT INTO employees VALUES v_emp(i);  -- Stops at row 50's error

-- ✅ SOLUTION: Use SAVE EXCEPTIONS
FORALL i IN 1 .. 1000 SAVE EXCEPTIONS
    INSERT INTO employees VALUES v_emp(i);  -- Continues despite errors
```

---

### Q10: How do you commit periodically during a large BULK COLLECT/FORALL operation?

**A:**
```sql
DECLARE
    TYPE emp_table IS TABLE OF employees%ROWTYPE;
    v_emp_batch emp_table;
    CURSOR c_emp IS SELECT * FROM employees;
    v_batch_size CONSTANT NUMBER := 1000;
BEGIN
    OPEN c_emp;
    LOOP
        FETCH c_emp BULK COLLECT INTO v_emp_batch LIMIT v_batch_size;
        EXIT WHEN v_emp_batch.COUNT = 0;
        
        FORALL i IN 1 .. v_emp_batch.COUNT SAVE EXCEPTIONS
            INSERT INTO employee_archive VALUES v_emp_batch(i);
        
        COMMIT;  -- Commit after each batch (releases locks, frees memory)
    END LOOP;
    CLOSE c_emp;
    
    DBMS_OUTPUT.PUT_LINE('Batch load complete');
END;
```

---

## 15. Revision Summary

### Key Takeaways

1. **Context switches are expensive:** Row-by-row loops incur thousands; bulk processing reduces to dozens.
2. **BULK COLLECT + FORALL = 10x faster** for large datasets (thousands of rows).
3. **Always use LIMIT** for batching cursors to prevent memory issues on large result sets.
4. **SAVE EXCEPTIONS** captures errors without stopping the batch; use for ETL robustness.
5. **Optimal LIMIT:** 500-2000 rows depending on row size and memory availability.
6. **Commit after each batch** to release locks and free memory.
7. **FORALL without LIMIT** risks memory explosion; pair BULK COLLECT + LIMIT with FORALL.
8. **Not a replacement for set-based SQL:** Use BULK COLLECT + FORALL only when set-based operation isn't possible.

### Quick Reference: Bulk Processing Steps

| Step | Code | Purpose |
| --- | --- | --- |
| 1. Declare collection type | TYPE emp_table IS TABLE OF employees%ROWTYPE | Define structure |
| 2. Open cursor | OPEN c_emp | Ready to fetch |
| 3. Fetch batch | FETCH c_emp BULK COLLECT INTO v_emp LIMIT 1000 | Get 1000 rows at once |
| 4. Check count | EXIT WHEN v_emp.COUNT = 0 | Stop when no more rows |
| 5. Process batch | FORALL i IN 1 .. v_emp.COUNT ... | Execute DML in batch |
| 6. Commit | COMMIT | Save changes, release locks |
| 7. Loop | Go to step 3 | Process next batch |
    SET salary = salary * 1.05
    WHERE employee_id = v_ids(i);
END;
/
```

Use `SAVE EXCEPTIONS` when valid rows should continue after an individual failure.

```sql
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE = -24381 THEN
      FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(
          SQL%BULK_EXCEPTIONS(i).ERROR_INDEX || ': ' ||
          SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
      END LOOP;
    ELSE
      RAISE;
    END IF;
```

---

## 5. Batch Size and Performance

A larger batch reduces context switches but consumes more PGA memory. Measure realistic batch sizes such as 100, 500, or 1000. Use SQL directly when a single `UPDATE`, `INSERT INTO SELECT`, or `MERGE` expresses the operation.

---

## 6. Comparison Matrix

| Approach | Context switches | Memory | Best use |
| --- | --- | --- | --- |
| Set-based SQL | Lowest | Database-managed | Uniform transformation |
| Row-by-row loop | Highest | Low | Complex per-row logic |
| Bulk processing | Low | Moderate/high | Per-row logic at scale |

---

## 7. Best Practices

1. Prefer one set-based SQL statement first.
2. Use `LIMIT` for potentially large fetches.
3. Choose batch size from measurement, not guesswork.
4. Handle `NO_DATA_FOUND` and empty collections correctly.
5. Use `SAVE EXCEPTIONS` only when partial success is acceptable.
6. Log failed indexes with enough business context to replay them.

---

## 8. Common Mistakes

- Using `FORALL` for a statement that could be one set-based update.
- Fetching millions of rows without `LIMIT`.
- Assuming `SQL%BULK_EXCEPTIONS` contains the business key automatically.
- Looping from `1 .. collection.COUNT` over a sparse collection.
- Swallowing bulk errors with `WHEN OTHERS THEN NULL`.

---

## 9. Interview Q&A

**Q: What is the difference between `BULK COLLECT` and `FORALL`?**

A: `BULK COLLECT` moves query results into collections; `FORALL` sends collection-driven DML efficiently to SQL.

**Q: Why is set-based SQL usually preferred?**

A: It avoids procedural loops and minimizes engine crossings while allowing Oracle to optimize the whole operation.

**Q: What does `SAVE EXCEPTIONS` do?**

A: It allows other iterations to continue, then raises an aggregate error whose details are available through `SQL%BULK_EXCEPTIONS`.

---

## 10. Revision Summary

- **Context switch** -> PL/SQL/SQL handoff cost
- **`BULK COLLECT`** -> query to collection
- **`FORALL`** -> collection to bulk DML
- **`LIMIT`** -> bounded fetch batch
- **`SAVE EXCEPTIONS`** -> collect row failures

```sql
FETCH c BULK COLLECT INTO v_rows LIMIT 500;
FORALL i IN 1 .. v_rows.COUNT
  UPDATE target SET processed = 'Y' WHERE id = v_rows(i).id;
```
