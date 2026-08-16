# Oracle Temporary and External Tables Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Global temporary table** = Table definition is permanent, but rows are temporary.
- **ON COMMIT DELETE ROWS** = Clears rows after commit.
- **ON COMMIT PRESERVE ROWS** = Keeps rows until the session ends.
- **Private temporary table** = Temporary definition and data with limited session scope.
- **External table** = Queries data stored outside the database, such as a file.
- **Staging table** = Temporary landing area for imports and transformations.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Temporary and External Tables?](#1-why-do-we-need-temporary-and-external-tables)
2. [Global Temporary Tables](#2-global-temporary-tables)
3. [Transaction and Session Scope](#3-transaction-and-session-scope)
4. [Private Temporary Tables](#4-private-temporary-tables)
5. [External Tables](#5-external-tables)
6. [Comparison Matrix](#6-comparison-matrix)
7. [Best Practices](#7-best-practices)
8. [Common Mistakes](#8-common-mistakes)
9. [Interview Q&A](#9-interview-qa)
10. [Revision Summary](#10-revision-summary)

---

## 1. Why Do We Need Temporary and External Tables?

### The Problem: Intermediate Data Does Not Belong in Permanent Tables

Reports and imports often need a workspace for intermediate rows.

**Problems with permanent staging tables:**
- Old rows remain after a job
- Multiple sessions may interfere
- Cleanup becomes manual

### The Solution

Temporary tables isolate intermediate data, while external tables let SQL query files without loading them first.

---

**➡ Transition:** Global temporary tables keep their structure but isolate their rows. 

---

## 2. Global Temporary Tables

### Simple Definition

A **global temporary table** has a permanent definition, but each session sees only its own temporary rows.

### Syntax/Usage

```sql
CREATE GLOBAL TEMPORARY TABLE session_sales (
    product_id NUMBER,
    amount NUMBER
) ON COMMIT DELETE ROWS;
```

### Preserve Rows Example

```sql
CREATE GLOBAL TEMPORARY TABLE report_data (
    employee_id NUMBER,
    score NUMBER
) ON COMMIT PRESERVE ROWS;
```

### Important Point

“Global” refers to the table definition, not shared row data. Rows remain private to the session.

---

**➡ Transition:** The ON COMMIT option decides how long temporary rows survive. 

---

## 3. Transaction and Session Scope

| Option | Rows disappear |
| --- | --- |
| ON COMMIT DELETE ROWS | At commit or rollback |
| ON COMMIT PRESERVE ROWS | At session end |

### Example

```sql
INSERT INTO session_sales VALUES (10, 500);
COMMIT;
```

With `DELETE ROWS`, the inserted row is removed after commit.

---

**➡ Transition:** Newer Oracle versions also support private temporary tables. 

---

## 4. Private Temporary Tables

### Simple Definition

A **private temporary table** has a temporary definition and is available only within its creating session or transaction scope.

### Example

```sql
CREATE PRIVATE TEMPORARY TABLE ora$ptt_sales (
    product_id NUMBER,
    amount NUMBER
) ON COMMIT DROP DEFINITION;
```

### Use Case

Short-lived scripts that need an isolated intermediate structure without leaving a permanent table definition.

---

**➡ Transition:** External tables solve a different problem: querying files as table-like data. 

---

## 5. External Tables

### Simple Definition

An **external table** describes data stored outside the database, commonly in files accessed through an Oracle directory object.

### Example Pattern

```sql
CREATE TABLE sales_file (
    product_id NUMBER,
    amount NUMBER
)
ORGANIZATION EXTERNAL (
    TYPE ORACLE_LOADER
    DEFAULT DIRECTORY data_dir
    ACCESS PARAMETERS (
        RECORDS DELIMITED BY NEWLINE
        FIELDS TERMINATED BY ','
    )
    LOCATION ('sales.csv')
)
REJECT LIMIT UNLIMITED;
```

### Benefits

- Query files with SQL
- Useful for ETL landing areas
- Avoids a separate initial load step

### Limitation

External tables are generally read-oriented; data management and file permissions must be handled carefully.

---

## 6. Comparison Matrix

| Aspect | Global Temporary | Private Temporary | External Table |
| --- | --- | --- | --- |
| Definition | Permanent | Temporary | Permanent metadata |
| Rows | Session-private | Session-private | External source |
| Typical use | Staging and reports | Short scripts | File ingestion |
| Persistence | Rows temporary | Definition temporary | File remains external |

---

## 7. Best Practices

### 1. Choose row scope deliberately

Use `DELETE ROWS` for transaction-level work and `PRESERVE ROWS` for session-level reporting.

### 2. Isolate staging jobs by session

Temporary-table rows should not be used as a cross-session communication mechanism.

### 3. Secure directory objects for external tables

File access is a database and operating-system security concern.

---

## 8. Common Mistakes

### Mistake 1: Expecting temporary rows to be visible to another session

**Solution:** Use a permanent staging table for cross-session workflows.

### Mistake 2: Choosing DELETE ROWS when the report needs multiple commits

**Solution:** Use PRESERVE ROWS when session lifetime is required.

### Mistake 3: Treating an external table like a normal writable table

**Solution:** Confirm the external-table access driver and supported operations.

---

## 9. Interview Q&A

**Q: What is a global temporary table?**
A: It has a permanent definition but session-private temporary rows.

**Q: What is the difference between DELETE ROWS and PRESERVE ROWS?**
A: DELETE ROWS clears data at commit; PRESERVE ROWS keeps it until session end.

**Q: What is an external table?**
A: A table definition that lets SQL query data stored outside the database.

---

## 10. Revision Summary

- **GTT** → permanent structure, temporary session rows
- **DELETE ROWS** → clear at commit
- **PRESERVE ROWS** → clear at session end
- **Private temporary** → temporary definition and data
- **External table** → SQL access to external files

### Important Syntax

```sql
CREATE GLOBAL TEMPORARY TABLE stage_data (
    id NUMBER,
    value VARCHAR2(100)
) ON COMMIT PRESERVE ROWS;
```

---

**Done!** Temporary and external tables give Oracle controlled workspaces for reports, batch processing, and file-based ingestion.
