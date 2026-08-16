# Oracle Data Types and Conversions Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **VARCHAR2** = Variable-length character data; 1–4000 bytes; most common for text columns.
- **CHAR** = Fixed-length character data; pads to declared size; use only for codes requiring fixed width.
- **NVARCHAR2** = Variable-length Unicode/national character data; stores characters in UTF-8/UTF-16.
- **CLOB** = Character Large Object; up to 4GB; external storage; used for unstructured text (documents, essays).
- **BLOB** = Binary Large Object; up to 4GB; external storage; used for binary data (images, PDFs, videos).
- **NUMBER** = Numeric data; precision and scale; range ±10^-130 to 10^126.
- **DATE** = Stores date and time to **seconds** precision; Oracle internal format.
- **TIMESTAMP** = Stores date and time with **fractional seconds** (microseconds); time-zone support available.
- **BOOLEAN** = TRUE, FALSE, or NULL; used only in PL/SQL blocks (not stored in tables).
- **Explicit conversion** = Use TO_DATE, TO_CHAR, TO_NUMBER, CAST; prevents NLS-dependent behavior.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do Data Types Matter?](#1-why-do-data-types-matter)
2. [What Are Oracle Data Types?](#2-what-are-oracle-data-types)
3. [Character Types: VARCHAR2, CHAR, NVARCHAR2](#3-character-types-varchar2-char-nvarchar2)
4. [Numeric Types: NUMBER and its Variants](#4-numeric-types-number-and-its-variants)
5. [Date and Time Types](#5-date-and-time-types)
6. [Large Object (LOB) Types: CLOB and BLOB](#6-large-object-lob-types-clob-and-blob)
7. [Boolean Type (PL/SQL Only)](#7-boolean-type-plsql-only)
8. [Explicit Type Conversion](#8-explicit-type-conversion)
9. [Comparison Matrix](#9-comparison-matrix)
10. [Best Practices](#10-best-practices)
11. [Common Mistakes](#11-common-mistakes)
12. [Interview Q&A](#12-interview-qa)
13. [Revision Summary](#13-revision-summary)

---

## 1. Why Do Data Types Matter?

### The Problem: Type Mismatches Cause Silent Failures and Performance Disasters

**Scenario:** You're building a financial application.

```sql
-- Problem 1: Storing dates as strings
CREATE TABLE transactions (
    transaction_id NUMBER,
    transaction_date VARCHAR2(10)  -- Stored as "2026-08-16"
);

-- Problem 2: Storing large documents as VARCHAR2
CREATE TABLE contracts (
    contract_id NUMBER,
    contract_text VARCHAR2(4000)  -- Truncates documents > 4000 bytes
);

-- Problem 3: Ambiguous numeric precision
CREATE TABLE accounts (
    account_id NUMBER,
    balance VARCHAR2(20)  -- "1250.50" sorted alphabetically, not numerically
);
```

**What goes wrong:**
- `SELECT * FROM transactions WHERE transaction_date > '2026-08-01'` → Incorrect sorting (string comparison)
- `contract_text` truncates silently; data loss without error
- `balance` calculations fail: `'1250.50' + '500.00'` → Error or wrong result
- NLS (National Language Settings) changes behavior: `TO_DATE('01/02/2026')` is ambiguous (Jan 2 or Feb 1?)

### The Solution: Choose Correct Types from the Start

A correct data type ensures:
- ✅ Automatic sorting and comparison semantics
- ✅ Proper validation (can't store letters in a NUMBER column)
- ✅ Efficient storage and indexing
- ✅ Predictable behavior across environments
- ✅ Meaningful constraints at schema level

### Real-World Scenarios

- **Financial Applications:** Balances must be NUMBER, not VARCHAR2 (calculations, precision, no rounding errors).
- **Document Management:** Large contracts/PDFs are CLOB/BLOB, not VARCHAR2 (no 4000-byte limit).
- **Global Applications:** Timestamps WITH TIME ZONE for international transactions (preserve original timezone).
- **Data Warehousing:** DATE for transaction dates (efficient indexing, range queries).
- **Compliance:** CLOB for audit logs and legal documents (full text, no truncation).

---

**➡ Transition:** Data types are the foundation of reliable databases. Let's understand what Oracle offers and how to choose them.

---

## 2. What Are Oracle Data Types?

### Simple Definition

A **data type** specifies what kind of values a column can hold, how Oracle stores them, and what operations are valid.

Think of data types as **contracts between you and Oracle**: You promise to store only valid values; Oracle promises efficient storage and correct behavior.

### The Type Categories

Oracle organizes data types into categories:

```
┌─────────────────────────────────────────────┐
│ Oracle Data Types                           │
├─────────────────────────────────────────────┤
│ 1. Character (VARCHAR2, CHAR, NVARCHAR2)   │
│ 2. Numeric (NUMBER, FLOAT, BINARY_FLOAT)   │
│ 3. Date/Time (DATE, TIMESTAMP variants)    │
│ 4. Large Objects (CLOB, BLOB, NCLOB)       │
│ 5. Other (ROWID, NROWID, RAW, INTERVAL)    │
│ 6. PL/SQL Only (BOOLEAN, REF, RECORD)      │
└─────────────────────────────────────────────┘
```

### Key Characteristics of All Data Types

1. **Storage:** How many bytes does it occupy?
2. **Range:** What values are valid?
3. **Precision:** How exact is the value? (e.g., DATE to seconds, TIMESTAMP to microseconds)
4. **Indexing:** Can it be indexed? Is it efficient?
5. **Conversion:** Can it convert to/from other types safely?
6. **NLS Sensitivity:** Do session settings affect it?

### Critical Interview Question

**Q: Why shouldn't I store everything as VARCHAR2?**

A: Because:
- No semantic meaning (DATE looks like any other string)
- No validation (can store "hello" in a date column)
- Wrong sorting (strings sort alphabetically, dates need date logic)
- Performance loss (can't use date indexes efficiently)
- Silent data corruption (implicit conversions fail unpredictably)

---

**➡ Transition:** Character types are the most common. Let's master VARCHAR2, CHAR, and when to use each.

---

## 3. Character Types: VARCHAR2, CHAR, NVARCHAR2

### VARCHAR2 (Variable Character)

#### Definition
Stores variable-length character data from 1 to 4000 **bytes** (not characters in multi-byte encodings).

#### Syntax
```sql
column_name VARCHAR2(size)
```

#### Example
```sql
CREATE TABLE employees (
    employee_id NUMBER,
    first_name VARCHAR2(50),      -- Up to 50 bytes
    email VARCHAR2(100),
    bio VARCHAR2(4000)            -- Maximum allowed
);
```

#### Key Points
- **Variable length:** Storage grows with actual data (only stores used bytes)
- **Size in bytes:** With UTF-8, one character = 1–4 bytes
- **Maximum:** 4000 bytes per column
- **Padding:** No padding (unlike CHAR)
- **Default:** If no size specified, defaults to column width (Oracle 23c+)

#### Why Use VARCHAR2?
```sql
-- Good: Variable text
product_name VARCHAR2(100)         -- Product names vary in length

-- Good: User input
user_comments VARCHAR2(4000)       -- Comments vary

-- AVOID: Fixed codes (use CHAR instead)
product_code VARCHAR2(5)           -- "A001" wasted space
```

---

### CHAR (Fixed Character)

#### Definition
Stores fixed-length character data; pads remaining space with spaces.

#### Syntax
```sql
column_name CHAR(size)
```

#### Example
```sql
CREATE TABLE departments (
    department_code CHAR(4),       -- Always 4 bytes (padded)
    department_name VARCHAR2(50)
);

-- If you store "ACCT" in CHAR(4), it actually stores "ACCT"
-- If you store "HR" in CHAR(4), it stores "HR  " (2 spaces padding)
```

#### Key Points
- **Fixed length:** Always uses declared size (pads with spaces)
- **Padding:** Trailing spaces are added automatically
- **Storage cost:** Wasted space for short values
- **Comparison:** Comparison may pad values (CHAR('HR  ') = CHAR('HR'))

#### When to Use CHAR
```sql
-- GOOD: Fixed-size codes where padding matters
bank_branch_code CHAR(5)           -- Always "00001", "00002", etc.
country_code CHAR(2)               -- "US", "IN", "UK" (always 2 chars)

-- AVOID: Variable text
customer_name CHAR(100)            -- Wastes space: "John       ..." (96 padding spaces)
```

#### CHAR vs VARCHAR2 Trade-off

| Aspect | CHAR | VARCHAR2 |
| --- | --- | --- |
| Storage | Fixed, pads with spaces | Variable, only stores actual data |
| Space Efficiency | Poor for short values | Excellent |
| Comparison | Considers padding | Ignores trailing spaces (usually) |
| Indexing | Works well; fixed size | Works well; more common |
| Use Case | Fixed-size codes | Names, descriptions, variable text |

---

### NVARCHAR2 (National Variable Character)

#### Definition
Variable-length Unicode (national language) character data; supports international characters natively.

#### Syntax
```sql
column_name NVARCHAR2(size)
```

#### Example
```sql
CREATE TABLE products (
    product_name VARCHAR2(100),        -- ASCII/Western characters
    product_description NVARCHAR2(500) -- Supports Chinese, Arabic, Emoji, etc.
);

-- Store:
INSERT INTO products VALUES ('Widget', N'产品描述');  -- N prefix for Unicode literals
```

#### When to Use NVARCHAR2
```sql
-- GOOD: International content
customer_name NVARCHAR2(100)       -- Names from multiple countries
product_description NVARCHAR2(2000)  -- Multilingual product info
feedback_text NVARCHAR2(4000)      -- Global user feedback

-- AVOID: English-only content
-- Wastes storage (each character = multiple bytes)
```

#### Size Consideration for NVARCHAR2
- Declared size is in **characters**, not bytes
- Actual storage: 1 character = 1–4 bytes (UTF-8) or 2 bytes (UTF-16)
- Total storage: Size × max character width
- Example: `NVARCHAR2(100)` can require up to 400 bytes with UTF-8

---

**➡ Transition:** Numeric values need a different approach. Let's understand NUMBER and precision.

---

## 4. Numeric Types: NUMBER and its Variants

### NUMBER (General-Purpose Numeric)

#### Definition
Stores numeric values with variable precision and scale.

#### Syntax
```sql
column_name NUMBER(precision, scale)
```

- **Precision:** Total number of digits (1–38)
- **Scale:** Number of digits after the decimal point (–84 to 127)

#### Examples

```sql
-- Example 1: Salary (2 decimal places)
salary NUMBER(10, 2)
-- Stores: 99,999,999.99 (10 digits total, 2 after decimal)
-- Maximum: 99,999,999.99
-- Minimum: –99,999,999.99

-- Example 2: Employee ID (no decimals)
employee_id NUMBER(10, 0)
-- Stores: 9,999,999,999 (10 digits total, 0 after decimal)

-- Example 3: Percentage (0-100 with 2 decimals)
commission_rate NUMBER(3, 2)
-- Stores: 99.99
-- Can't store 100.00 (would need 3 + 1 for the integer part)

-- Example 4: Scientific values (negative scale)
large_quantity NUMBER(10, -3)
-- Stores: 9,999,999,000 (rounds to nearest 1000)
-- 1,234,567 → 1,235,000
```

#### Storage
- Stores internally as variable-length binary
- 1–21 bytes per value
- More efficient than VARCHAR2 for calculations

#### Usage Guidelines

```sql
-- GOOD: Financial data
account_balance NUMBER(12, 2)    -- Supports up to 999,999,999.99
interest_rate NUMBER(5, 4)       -- 1.2345%

-- GOOD: Identifiers
customer_id NUMBER(10, 0)        -- No decimals needed

-- AVOID: Floating-point precision issues
price BINARY_FLOAT              -- Avoid: 0.1 + 0.2 ≠ 0.3

-- AVOID: Arbitrary precision
square_root NUMBER              -- No precision specified; less predictable
```

### NUMBER Subtypes

```sql
FLOAT                     -- Oracle FLOAT, converted to NUMBER internally
BINARY_FLOAT              -- 32-bit IEEE 754 (avoid for business logic)
BINARY_DOUBLE             -- 64-bit IEEE 754 (avoid for financial data)
DECIMAL(p, s)             -- Alias for NUMBER
INTEGER                   -- Alias for NUMBER(*, 0)
```

---

**➡ Transition:** Dates are special—they require their own types. TIME tracking across timezones adds complexity.

---

## 5. Date and Time Types

### DATE (Classic Oracle Date/Time)

#### Definition
Stores date and time down to **seconds** precision. Stored as 7-byte binary value.

#### Syntax
```sql
column_name DATE
```

#### Example
```sql
CREATE TABLE events (
    event_id NUMBER,
    event_date DATE              -- Stores both date and time
);

INSERT INTO events VALUES (1, TO_DATE('2026-08-16 14:30:45', 'YYYY-MM-DD HH24:MI:SS'));

-- Retrieve
SELECT event_date FROM events;   -- Output: 16-AUG-26 14:30:45
```

#### Characteristics
- **Precision:** Seconds only (no fractional seconds)
- **Range:** From 01-JAN-4712 BC to 31-DEC-9999 AD
- **Display:** Depends on NLS_DATE_FORMAT session parameter
- **Sorting:** Works correctly (date logic, not string logic)

#### When to Use
```sql
-- GOOD: Transaction dates, event times (second precision sufficient)
transaction_date DATE
order_date DATE
meeting_time DATE

-- AVOID: High-precision timestamps
created_at TIMESTAMP         -- Use TIMESTAMP instead for microseconds
```

---

### TIMESTAMP (Fractional Seconds and Timezone Support)

#### Definition
Stores date and time with **fractional seconds** (microseconds). Optional timezone information.

#### Variants

```sql
-- 1. TIMESTAMP (no timezone)
created_at TIMESTAMP(6)          -- 6 decimal places = microseconds
-- Example: 16-AUG-26 14:30:45.123456

-- 2. TIMESTAMP WITH TIME ZONE
order_date TIMESTAMP(6) WITH TIME ZONE
-- Example: 16-AUG-26 14:30:45.123456 +05:30

-- 3. TIMESTAMP WITH LOCAL TIME ZONE
log_date TIMESTAMP(6) WITH LOCAL TIME ZONE
-- Stored in UTC; converted to session timezone on retrieval
```

#### Example Usage

```sql
CREATE TABLE audit_log (
    log_id NUMBER,
    action_time TIMESTAMP(6),                    -- Microsecond precision
    user_timezone_time TIMESTAMP(6) WITH TIME ZONE,  -- Preserve user's timezone
    server_time TIMESTAMP(6) WITH LOCAL TIME ZONE    -- Always UTC + session timezone
);

INSERT INTO audit_log VALUES
(1, SYSTIMESTAMP, SYSTIMESTAMP, SYSTIMESTAMP);

SELECT * FROM audit_log;
-- log_id | action_time | user_timezone_time | server_time
-- 1 | 16-AUG-26 14:30:45.123456 | 16-AUG-26 14:30:45.123456 -07:00 | 16-AUG-26 14:30:45.123456
```

#### When to Use TIMESTAMP

```sql
-- GOOD: API response times (millisecond precision)
response_logged_at TIMESTAMP(3)          -- 3 decimal places = milliseconds

-- GOOD: Global applications (preserve original timezone)
user_registration_time TIMESTAMP(6) WITH TIME ZONE

-- GOOD: Event sourcing / audit logs (precise timing)
event_fired_at TIMESTAMP(6)

-- AVOID: Simple date storage (overkill, wastes storage)
hire_date TIMESTAMP(6)                   -- Use DATE instead
```

#### DATE vs TIMESTAMP Comparison

| Aspect | DATE | TIMESTAMP |
| --- | --- | --- |
| Precision | Seconds | Fractional seconds (microseconds) |
| Timezone Support | No | Yes (WITH TIME ZONE variants) |
| Storage | 7 bytes | 7–11 bytes |
| Example | 16-AUG-26 14:30:45 | 16-AUG-26 14:30:45.123456 |
| Use Case | General dates | High-precision timing, timezones |

---

**➡ Transition:** Large data requires different storage. CLOB and BLOB handle gigabytes, but with trade-offs.

---

## 6. Large Object (LOB) Types: CLOB and BLOB

### The LOB Problem and Solution

#### Problem: VARCHAR2 Size Limit
```sql
-- WRONG: Cannot store more than 4000 bytes
CREATE TABLE documents (
    document_id NUMBER,
    full_text VARCHAR2(4000)  -- ❌ Legal contract = 50KB, truncated!
);
```

#### Solution: Use CLOB
```sql
-- CORRECT: CLOB supports up to 4GB
CREATE TABLE documents (
    document_id NUMBER,
    full_text CLOB  -- ✅ Can store entire 50KB contract
);
```

---

### CLOB (Character Large Object)

#### Definition
Stores large amounts of character data (1 byte to 4 GB internally; 128 TB with SecureFile storage).

#### Syntax
```sql
column_name CLOB
```

#### Example
```sql
CREATE TABLE legal_documents (
    document_id NUMBER PRIMARY KEY,
    document_title VARCHAR2(200),
    document_content CLOB,           -- Can store entire contract
    created_date DATE
);

INSERT INTO legal_documents VALUES
(1, 'Service Agreement', EMPTY_CLOB(), SYSDATE);

-- Writing CLOB data via PL/SQL
DECLARE
    v_clob CLOB;
    v_amount NUMBER;
BEGIN
    SELECT document_content INTO v_clob
    FROM legal_documents
    WHERE document_id = 1
    FOR UPDATE;
    
    DBMS_LOB.WRITE(v_clob, 100, 1, 'This is a legal document...');
    DBMS_LOB.GETLENGTH(v_clob);  -- Returns current size
END;
/
```

#### Key Characteristics

| Aspect | Details |
| --- | --- |
| **Size Limit** | Up to 4GB (128TB with SecureFile) |
| **Storage** | External storage (in LOB segment, not inline) |
| **Access Pattern** | Sequential read/write (not random) |
| **Indexing** | Cannot index directly; use context indexes |
| **Precision** | Character data; encoding-aware (UTF-8, UTF-16) |
| **Performance** | Slower than VARCHAR2 (I/O operations); good for batch operations |

#### When to Use CLOB

```sql
-- GOOD: Long unstructured text
contract_terms CLOB              -- Legal documents (often 100KB+)
book_content CLOB                -- Full book text
user_essays CLOB                 -- Long-form user submissions
xml_document CLOB                -- XML data

-- GOOD: SQL stored procedures/code
stored_proc_source CLOB          -- Full source code of procedures

-- AVOID: Small text (< 4000 bytes)
description CLOB                 -- ❌ Use VARCHAR2(4000) instead

-- AVOID: When you need random access or frequent updates
logging_messages CLOB            -- ❌ Use VARCHAR2 for structured logs
```

#### CLOB vs VARCHAR2

| Aspect | VARCHAR2 | CLOB |
| --- | --- | --- |
| Max Size | 4000 bytes | 4GB |
| Storage | Inline (in row) | External (in LOB segment) |
| Access | Fast, random access | Sequential, slower I/O |
| Indexing | Full text indexing | Context indexing |
| Character Limit | Byte-count aware | Handles any encoding |
| Use Case | Names, codes, descriptions | Documents, essays, code |

---

### BLOB (Binary Large Object)

#### Definition
Stores large amounts of binary data (1 byte to 4 GB); no character encoding.

#### Syntax
```sql
column_name BLOB
```

#### Example
```sql
CREATE TABLE media_files (
    file_id NUMBER PRIMARY KEY,
    file_name VARCHAR2(200),
    file_type VARCHAR2(10),        -- 'PDF', 'PNG', 'MP4'
    file_data BLOB,                -- Binary content
    file_size NUMBER,              -- Size in bytes
    uploaded_date DATE
);

INSERT INTO media_files VALUES
(1, 'contract.pdf', 'PDF', EMPTY_BLOB(), NULL, SYSDATE);

-- Writing BLOB data
DECLARE
    v_blob BLOB;
    v_file_path VARCHAR2(200) := '/tmp/document.pdf';
BEGIN
    SELECT file_data INTO v_blob
    FROM media_files
    WHERE file_id = 1
    FOR UPDATE;
    
    -- Read file and write to BLOB (simplified)
    -- Usually done via external tools or Java/Python integration
    DBMS_LOB.WRITEAPPEND(v_blob, ...);
END;
/
```

#### Key Characteristics

| Aspect | Details |
| --- | --- |
| **Size Limit** | Up to 4GB (128TB with SecureFile) |
| **Storage** | External storage (binary data, no encoding) |
| **Access Pattern** | Sequential read/write |
| **Indexing** | Cannot index directly |
| **Content Type** | Binary (images, PDFs, video, compressed files) |
| **Performance** | I/O intensive; batch operations recommended |

#### When to Use BLOB

```sql
-- GOOD: Binary files
user_profile_photo BLOB          -- Profile pictures
product_pdf BLOB                 -- Product manuals (PDF)
document_scan BLOB               -- Scanned documents

-- GOOD: Compressed or encoded data
compressed_backup BLOB           -- ZIP or GZIP archives
encrypted_content BLOB           -- Encrypted data

-- AVOID: Text content
-- Use CLOB instead for text
contract_pdf CLOB                -- ❌ If it's readable text, use CLOB
```

---

### NCLOB (National CLOB)

#### Definition
Like CLOB, but optimized for national character sets (Unicode).

```sql
multilingual_document NCLOB      -- Chinese, Arabic, emoji support
```

---

**➡ Transition:** PL/SQL introduces a special type for conditions: BOOLEAN. It's unique to procedural code.

---

## 7. Boolean Type (PL/SQL Only)

### Definition
Stores TRUE, FALSE, or NULL; **only in PL/SQL blocks, not in tables**.

### Syntax (PL/SQL Only)
```sql
DECLARE
    is_active BOOLEAN;
    is_valid BOOLEAN := TRUE;
BEGIN
    IF is_active THEN
        DBMS_OUTPUT.PUT_LINE('Active');
    END IF;
END;
/
```

### Why Not in Tables?
```sql
-- ❌ INVALID: Cannot create table column as BOOLEAN
CREATE TABLE users (
    user_id NUMBER,
    is_active BOOLEAN  -- ERROR: BOOLEAN cannot be used in table
);

-- ✅ CORRECT: Use CHAR or NUMBER
CREATE TABLE users (
    user_id NUMBER,
    is_active CHAR(1)  -- 'Y' or 'N'
    -- OR
    -- is_active NUMBER(1)  -- 1 or 0
);
```

### Workaround in Tables
```sql
-- Option 1: CHAR(1)
is_active CHAR(1) CHECK (is_active IN ('Y', 'N'))

-- Option 2: NUMBER
is_active NUMBER(1) CHECK (is_active IN (0, 1))

-- Option 3: VARCHAR2 (modern)
is_active VARCHAR2(5) CHECK (is_active IN ('true', 'false'))

-- Option 4: BOOLEAN via trigger (stores as CHAR)
-- Table stores, trigger converts to BOOLEAN in app
```

---

**➡ Transition:** Type conversion is critical for reliable queries. Let's master explicit conversion to avoid NLS surprises.

---

## 8. Explicit Type Conversion

### Why Explicit Conversion Matters

#### Problem: Implicit Conversion is Unpredictable
```sql
-- Implicit conversion (DANGEROUS)
SELECT * FROM transactions
WHERE transaction_date = '2026-08-16';
-- ❌ Depends on NLS_DATE_FORMAT
-- ❌ May interpret '08-16' as MM-DD or DD-MM
-- ❌ Works in US, fails in Europe
```

#### Solution: Explicit Conversion (SAFE)
```sql
-- Explicit conversion (CORRECT)
SELECT * FROM transactions
WHERE transaction_date = TO_DATE('2026-08-16', 'YYYY-MM-DD');
-- ✅ Always interprets as YYYY-MM-DD
-- ✅ Independent of NLS settings
-- ✅ Works everywhere
```

---

### Character to Date Conversion

#### Function: TO_DATE
```sql
TO_DATE(char_value, format_mask)
```

#### Examples
```sql
-- Simple date
SELECT TO_DATE('2026-08-16', 'YYYY-MM-DD') FROM dual;
-- Result: 16-AUG-26

-- Date with time
SELECT TO_DATE('2026-08-16 14:30:45', 'YYYY-MM-DD HH24:MI:SS') FROM dual;
-- Result: 16-AUG-26 14:30:45

-- Various formats
SELECT TO_DATE('16-AUG-2026', 'DD-MON-YYYY') FROM dual;
SELECT TO_DATE('08/16/2026', 'MM/DD/YYYY') FROM dual;
SELECT TO_DATE('20260816', 'YYYYMMDD') FROM dual;
```

#### Common Format Masks
```
YYYY    = 4-digit year (2026)
MM      = 2-digit month (08)
DD      = 2-digit day (16)
MON     = 3-letter month (AUG)
MONTH   = Full month name (AUGUST)
HH24    = Hour 0-23 (14)
HH      = Hour 1-12 (02)
MI      = Minutes (30)
SS      = Seconds (45)
```

---

### Date to Character Conversion

#### Function: TO_CHAR
```sql
TO_CHAR(date_value, format_mask)
```

#### Examples
```sql
-- Standard format
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD') FROM dual;
-- Result: 2026-08-16

-- With time
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') FROM dual;
-- Result: 2026-08-16 14:30:45

-- Long format
SELECT TO_CHAR(SYSDATE, 'Day, Month DD, YYYY') FROM dual;
-- Result: Saturday, August 16, 2026

-- For reports (padded format)
SELECT TO_CHAR(SYSDATE, 'MM/DD/YYYY') FROM dual;
-- Result: 08/16/2026
```

---

### Number Conversion

#### Character to Number: TO_NUMBER
```sql
TO_NUMBER(char_value, format_mask)
```

#### Examples
```sql
-- Simple number
SELECT TO_NUMBER('1250') FROM dual;
-- Result: 1250

-- With decimals
SELECT TO_NUMBER('1250.50', '9999.99') FROM dual;
-- Result: 1250.50

-- Currency format
SELECT TO_NUMBER('$1,250.50', '$9,999.99') FROM dual;
-- Result: 1250.50

-- Negative numbers
SELECT TO_NUMBER('-500', '9999') FROM dual;
-- Result: -500
```

#### Number to Character: TO_CHAR (Numeric)
```sql
TO_CHAR(number_value, format_mask)
```

#### Examples
```sql
-- Simple formatting
SELECT TO_CHAR(1250, '9999') FROM dual;
-- Result: 1250

-- With decimals (zero-padded)
SELECT TO_CHAR(1250.5, '9999.99') FROM dual;
-- Result: 1250.50

-- With leading zeros
SELECT TO_CHAR(5, '0000') FROM dual;
-- Result: 0005

-- Currency formatting
SELECT TO_CHAR(1250.50, '$9,999.99') FROM dual;
-- Result: $1,250.50
```

---

### Universal Type Casting: CAST

#### Syntax
```sql
CAST(source_value AS target_type)
```

#### Examples
```sql
-- Character to date
SELECT CAST('2026-08-16' AS DATE) FROM dual;
-- ⚠️ Uses NLS format; not recommended
-- Use TO_DATE instead

-- Date to timestamp
SELECT CAST(SYSDATE AS TIMESTAMP) FROM dual;
-- Result: 16-AUG-26 14:30:45.000000

-- Number to character
SELECT CAST(1250 AS VARCHAR2(10)) FROM dual;
-- Result: '1250'

-- Character to number
SELECT CAST('1250' AS NUMBER) FROM dual;
-- Result: 1250
```

#### CAST vs TO_*
| Aspect | CAST | TO_* Functions |
| --- | --- | --- |
| SQL Standard | Yes (ANSI SQL) | Oracle-specific |
| Flexibility | Less (fixed conversion) | More (format masks) |
| Date Conversion | Uses NLS | Explicit masks (recommended) |
| Readability | Modern, standard | Explicit, but Oracle-specific |

---

**➡ Transition:** Now you know the types. Let's compare them in a matrix and see best practices.

---

## 9. Comparison Matrix

| Type | Max Size | Precision | Use Case | Interview Notes |
| --- | --- | --- | --- | --- |
| **VARCHAR2** | 4000 bytes | N/A | Variable text | Most common; efficient |
| **CHAR** | 4000 bytes | Fixed | Fixed-size codes | Pads with spaces; use sparingly |
| **NVARCHAR2** | 4000 chars | Unicode | International text | Multi-byte storage |
| **CLOB** | 4GB | N/A | Large documents | External storage; sequential access |
| **BLOB** | 4GB | N/A | Binary files | No character encoding |
| **NUMBER** | Variable | Precision/Scale | Calculations | Fixed-point; no rounding errors |
| **DATE** | 7 bytes | Seconds | Date/time | Stores both date and time |
| **TIMESTAMP** | 7–11 bytes | Microseconds | Precise timing | Fractional seconds; timezone support |
| **BOOLEAN** | N/A | TRUE/FALSE | PL/SQL only | Use CHAR(1) or NUMBER(1) in tables |

---

## 10. Best Practices

### 1. Choose Types Based on Semantics, Not Convenience

```sql
-- ❌ WRONG: Everything as VARCHAR2
CREATE TABLE employees (
    employee_id VARCHAR2(10),      -- Should be NUMBER
    hire_date VARCHAR2(10),         -- Should be DATE
    salary VARCHAR2(10),            -- Should be NUMBER
    department VARCHAR2(20)         -- Fine as VARCHAR2
);

-- ✅ CORRECT: Type matches meaning
CREATE TABLE employees (
    employee_id NUMBER PRIMARY KEY,
    hire_date DATE,
    salary NUMBER(10, 2),
    department VARCHAR2(20)
);
```

---

### 2. Use Explicit Conversion in Queries

```sql
-- ❌ Relies on NLS setting
SELECT * FROM orders
WHERE order_date = '2026-08-16';

-- ✅ Explicit, portable
SELECT * FROM orders
WHERE order_date = TO_DATE('2026-08-16', 'YYYY-MM-DD');
```

---

### 3. Use % Types for Flexibility

```sql
-- ❌ Hard-coded type; breaks if table changes
DECLARE
    v_salary NUMBER(10, 2);
BEGIN
    SELECT salary INTO v_salary FROM employees WHERE employee_id = 1;
END;
/

-- ✅ Anchored to table schema; updates automatically
DECLARE
    v_salary employees.salary%TYPE;
BEGIN
    SELECT salary INTO v_salary FROM employees WHERE employee_id = 1;
END;
/
```

---

### 4. CLOB/BLOB Patterns: Don't Load Entire LOB

```sql
-- ❌ WRONG: Loads entire 1GB CLOB into memory
DECLARE
    v_clob CLOB;
BEGIN
    SELECT document INTO v_clob FROM documents WHERE doc_id = 1;
    -- Now memory has 1GB
    DBMS_OUTPUT.PUT_LINE(v_clob);  -- Crash!
END;
/

-- ✅ CORRECT: Stream or read portions
DECLARE
    v_clob CLOB;
    v_buffer VARCHAR2(32767);
    v_offset NUMBER := 1;
    v_length NUMBER := 32767;
BEGIN
    SELECT document INTO v_clob FROM documents WHERE doc_id = 1;
    
    DBMS_LOB.READ(v_clob, v_length, v_offset, v_buffer);
    DBMS_OUTPUT.PUT_LINE(v_buffer);  -- Safe
END;
/
```

---

### 5. National Characters: Use NVARCHAR2 for Global Apps

```sql
-- Good for global applications
CREATE TABLE products (
    product_id NUMBER,
    product_name NVARCHAR2(100),     -- Supports Chinese, Arabic, emoji
    description NVARCHAR2(4000)
);

-- Storage: N'Chinese characters' or N'العربية'
```

---

### 6. Time Zones: Use TIMESTAMP WITH TIME ZONE for Global Systems

```sql
-- For international transactions
CREATE TABLE transactions (
    transaction_id NUMBER,
    transaction_date TIMESTAMP(6) WITH TIME ZONE  -- Preserves user's timezone
);

INSERT INTO transactions VALUES
(1, TIMESTAMP '2026-08-16 14:30:45.123456 +05:30');  -- India timezone

-- Retrieves in user's session timezone (or UTC + offset)
```

---

## 11. Common Mistakes

### Mistake 1: Storing Dates as VARCHAR2

```sql
-- ❌ WRONG
CREATE TABLE events (
    event_date VARCHAR2(10)  -- '2026-08-16' looks like a string
);

-- Problem
SELECT * FROM events WHERE event_date > '2026-08-01';  -- String comparison!
-- Result: '2026-08-16' > '2026-08-01' is TRUE (correct by accident)
-- But '2026-08-16' > '2026-08-25' is FALSE (wrong! because "08-16" < "08-25" lexically)

-- ✅ CORRECT
CREATE TABLE events (
    event_date DATE
);

SELECT * FROM events WHERE event_date > TO_DATE('2026-08-01', 'YYYY-MM-DD');  -- Date comparison
```

---

### Mistake 2: Relying on Implicit Conversion

```sql
-- ❌ Implicit (dangerous, NLS-dependent)
SELECT * FROM sales WHERE sale_date = '2026-08-16';
-- Fails if user's NLS_DATE_FORMAT = 'DD-MM-YYYY'

-- ✅ Explicit (safe, portable)
SELECT * FROM sales WHERE sale_date = TO_DATE('2026-08-16', 'YYYY-MM-DD');
```

---

### Mistake 3: Using VARCHAR2 for Large Documents

```sql
-- ❌ WRONG: Truncates silently
CREATE TABLE documents (
    content VARCHAR2(4000)  -- Loses data > 4000 bytes
);

-- ✅ CORRECT
CREATE TABLE documents (
    content CLOB  -- Full document preserved
);
```

---

### Mistake 4: Choosing CHAR for All Text

```sql
-- ❌ WRONG: Wastes space
CREATE TABLE customers (
    customer_name CHAR(100)  -- "John       ..." wasted space
);

-- ✅ CORRECT
CREATE TABLE customers (
    customer_name VARCHAR2(100)  -- Stores actual length
);

-- CHAR only for fixed-size codes:
country_code CHAR(2)  -- "US", "IN", "UK" always 2 characters
```

---

### Mistake 5: Not Using Timezone Types in Global Applications

```sql
-- ❌ WRONG: Loses timezone info
CREATE TABLE international_orders (
    order_date DATE  -- User's timezone lost
);

-- ✅ CORRECT: Preserve timezone
CREATE TABLE international_orders (
    order_date TIMESTAMP(6) WITH TIME ZONE  -- Preserves +05:30, -07:00, etc.
);
```

---

### Mistake 6: Loading Entire LOB into Memory

```sql
-- ❌ WRONG: 1GB CLOB crashes application
DECLARE
    v_clob CLOB;
BEGIN
    SELECT content INTO v_clob FROM documents WHERE id = 1;
    -- Now v_clob is 1GB in memory; OUT OF MEMORY ERROR
END;
/

-- ✅ CORRECT: Process in chunks
DECLARE
    v_clob CLOB;
    v_chunk VARCHAR2(32767);
    v_amt NUMBER := 32767;
    v_pos NUMBER := 1;
BEGIN
    SELECT content INTO v_clob FROM documents WHERE id = 1;
    
    WHILE v_pos <= DBMS_LOB.GETLENGTH(v_clob) LOOP
        DBMS_LOB.READ(v_clob, v_amt, v_pos, v_chunk);
        -- Process v_chunk (32KB chunk)
        v_pos := v_pos + v_amt;
    END LOOP;
END;
/
```

---

## 12. Interview Q&A

### Q1: What's the difference between VARCHAR2 and CHAR?

**A:** VARCHAR2 stores variable-length data and uses only the space needed, while CHAR stores fixed-length data and pads with spaces. VARCHAR2 is preferred for most text because it's space-efficient. Use CHAR only for fixed-size codes like country codes or product codes where fixed width matters.

**Example:**
- CHAR(4): 'US' is stored as 'US  ' (2 spaces padding)
- VARCHAR2(4): 'US' is stored as 'US' (no padding)

---

### Q2: Why shouldn't I store everything as VARCHAR2?

**A:** Because type conveys meaning. A DATE column tells Oracle to treat data as a date (sorting by date logic, not alphabetically), enables indexing, and enforces validation. A NUMBER column prevents storing 'hello' where you expect a price. Storing everything as VARCHAR2:
- Loses semantic meaning
- Prevents validation
- Breaks date and numeric sorting
- Defeats purpose of schemas

---

### Q3: What's the difference between DATE and TIMESTAMP?

**A:** DATE stores to **seconds** precision; TIMESTAMP stores to **microseconds**. TIMESTAMP also supports timezone information. Use DATE for general purposes; use TIMESTAMP when you need fractional seconds (logging, microsecond-level events) or timezone tracking (global applications).

---

### Q4: When should I use CLOB instead of VARCHAR2?

**A:** When data exceeds 4000 bytes or when you have unstructured large text (contracts, essays, documents). CLOB can store up to 4GB. VARCHAR2 is fast and inline (in the row); CLOB is external and slower but handles large data. Choose based on size: < 4KB use VARCHAR2; > 4KB use CLOB.

---

### Q5: What are the character and byte limits for VARCHAR2?

**A:** VARCHAR2 max size is **4000 bytes**. In a single-byte character set (ASCII), that's 4000 characters. In multi-byte (UTF-8), one character = 1–4 bytes, so 4000 bytes might store only 1000+ characters. Always verify: `MAX_STRING_SIZE` initialization parameter (legacy vs new settings).

---

### Q6: How do I convert a string to a date safely in SQL?

**A:** Use `TO_DATE` with an explicit format mask:
```sql
SELECT * FROM orders
WHERE order_date = TO_DATE('2026-08-16', 'YYYY-MM-DD');
```

Never rely on implicit conversion (NLS-dependent). CAST is ANSI-standard but uses NLS format for dates; stick with TO_DATE.

---

### Q7: What's the difference between NVARCHAR2 and VARCHAR2?

**A:** NVARCHAR2 supports Unicode (national characters); VARCHAR2 is encoding-dependent. NVARCHAR2 uses more storage (multi-byte per character). Use NVARCHAR2 for international content (Chinese, Arabic, emoji); use VARCHAR2 for ASCII/Western text.

---

### Q8: Can I store a BOOLEAN in a table?

**A:** No. BOOLEAN exists only in PL/SQL blocks. In tables, use:
- `CHAR(1)` with CHECK (value IN ('Y', 'N'))
- `NUMBER(1)` with CHECK (value IN (0, 1))
- `VARCHAR2(5)` with CHECK (value IN ('true', 'false'))

PL/SQL code can convert before/after:
```sql
DECLARE
    v_is_active BOOLEAN;  -- Only in PL/SQL
BEGIN
    SELECT CASE WHEN is_active = 'Y' THEN TRUE ELSE FALSE END
    INTO v_is_active
    FROM users WHERE user_id = 1;
END;
/
```

---

### Q9: What happens if I insert a value larger than the column size?

**A:** Oracle truncates or errors:
- VARCHAR2: Error (value too large) — doesn't truncate
- CHAR: Error (value too large)
- CLOB: Accepts (no size limit)
- NUMBER: Error if digits exceed precision

```sql
INSERT INTO test_table (name) VALUES ('This is a very long string that exceeds 50 bytes');
-- ORA-12899: value too large for column
```

---

### Q10: How do I handle NLS-dependent behavior in international applications?

**A:** Always use explicit format masks:
```sql
-- ❌ NLS-dependent
SELECT * FROM orders WHERE order_date = '2026-08-16';

-- ✅ Explicit (safe worldwide)
SELECT * FROM orders WHERE order_date = TO_DATE('2026-08-16', 'YYYY-MM-DD');
```

Or set session NLS parameters explicitly in applications.

---

## 13. Revision Summary

### Key Takeaways

1. **VARCHAR2** for variable text (names, descriptions); **CHAR** for fixed codes only
2. **DATE** for general date/time; **TIMESTAMP** for fractional seconds or timezones
3. **CLOB** for large documents (> 4KB text); **BLOB** for binary files
4. **NUMBER** for calculations (with precision/scale); **NVARCHAR2** for international text
5. **BOOLEAN** only in PL/SQL; use CHAR(1) or NUMBER(1) in tables
6. **Always use explicit conversion** (TO_DATE, TO_CHAR, TO_NUMBER, CAST) to avoid NLS surprises
7. **Type conveys meaning** — correct types enable validation, sorting, and indexing
8. **Process LOBs in chunks** — never load entire CLOBs into memory

### Comparison at a Glance

| Decision | Choose |
| --- | --- |
| Variable text? | VARCHAR2 |
| Fixed code? | CHAR |
| Date/time (seconds)? | DATE |
| High-precision time? | TIMESTAMP |
| Document (> 4KB)? | CLOB |
| Binary file? | BLOB |
| Calculation? | NUMBER(precision, scale) |
| International text? | NVARCHAR2 |
| Boolean in PL/SQL? | BOOLEAN |
| Boolean in table? | CHAR(1) or NUMBER(1) |

### Quick Reference for Interviews

- **Q: Difference between VARCHAR2 and CLOB?** A: Size (4KB vs 4GB) and storage (inline vs external)
- **Q: Why not store dates as text?** A: Loses sorting semantics; dependent on NLS
- **Q: How do you convert date safely?** A: TO_DATE(value, 'YYYY-MM-DD')
- **Q: What's wrong with CHAR(100)?** A: Wastes space if values are short (pads with spaces)
- **Q: Can you use BOOLEAN in tables?** A: No; use CHAR(1) or NUMBER(1) instead
