# Oracle Data Types and Conversions Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **VARCHAR2** = Variable-length character data.
- **CHAR** = Fixed-length character data.
- **NUMBER** = Numeric values with optional precision and scale.
- **DATE** = Date and time to second precision.
- **TIMESTAMP** = Date and time with fractional seconds.
- **CLOB/BLOB** = Large character/binary objects.
- **Explicit conversion** = Use functions such as `TO_DATE`, `TO_CHAR`, `TO_NUMBER`, and `CAST`.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do Data Types Matter?](#1-why-do-data-types-matter)
2. [What Are Oracle Data Types?](#2-what-are-oracle-data-types)
3. [Character Types](#3-character-types)
4. [Numeric Types](#4-numeric-types)
5. [DATE and TIMESTAMP](#5-date-and-timestamp)
6. [LOB Types](#6-lob-types)
7. [Explicit Conversion](#7-explicit-conversion)
8. [Comparison Matrix](#8-comparison-matrix)
9. [Best Practices](#9-best-practices)
10. [Common Mistakes](#10-common-mistakes)
11. [Interview Q&A](#11-interview-qa)
12. [Revision Summary](#12-revision-summary)

---

## 1. Why Do Data Types Matter?

### The Problem: Incorrect Types Cause Errors and Poor Storage

A date stored as text cannot be reliably sorted as a date, and a number stored as text can cause conversion errors.

**Problems:**
- Incorrect comparisons
- NLS-dependent behavior
- Wasted storage
- Invalid data

### The Solution: Choose Types That Match the Meaning

A correct data type improves integrity, performance, and query clarity.

---

**➡ Transition:** Oracle provides specialized types for text, numbers, dates, and large objects. 

---

## 2. What Are Oracle Data Types?

### Simple Definition

A **data type** defines what values a column can store and how Oracle stores and processes them.

### Key Characteristics

- Controls valid values
- Influences storage and comparison
- Supports conversion rules
- Helps constraints express business meaning

---

**➡ Transition:** Character columns are commonly defined with CHAR or VARCHAR2. 

---

## 3. Character Types

### CHAR vs VARCHAR2

```sql
fixed_code CHAR(5);
name VARCHAR2(100);
```

- `CHAR` always uses fixed length and pads values.
- `VARCHAR2` stores variable-length text and is usually preferred for names and descriptions.

### Example

```sql
CREATE TABLE departments (
    department_code CHAR(4),
    department_name VARCHAR2(100)
);
```

### Rule of Thumb

Use `CHAR` for truly fixed-size codes and `VARCHAR2` for variable text.

---

**➡ Transition:** Numeric values require attention to precision and scale. 

---

## 4. Numeric Types

### Syntax

```sql
salary NUMBER(10, 2)
```

- Precision: total number of digits
- Scale: digits to the right of the decimal point

### Example

```sql
amount NUMBER(12, 2)
```

This supports up to 12 total digits, including 2 decimal places.

### Common Mistake

Do not use character columns for values that must be calculated.

---

**➡ Transition:** Oracle has multiple date and time types for different precision requirements. 

---

## 5. DATE and TIMESTAMP

### DATE

```sql
hire_date DATE
```

Stores date and time down to seconds.

### TIMESTAMP

```sql
created_at TIMESTAMP
```

Stores fractional seconds.

### Time Zone Types

```sql
created_at TIMESTAMP WITH TIME ZONE
```

Use time-zone-aware types when values come from multiple regions.

### Example

```sql
SELECT SYSTIMESTAMP,
       CAST(SYSDATE AS TIMESTAMP)
FROM dual;
```

---

**➡ Transition:** Large values use LOB data types. 

---

## 6. LOB Types

| Type | Purpose |
| --- | --- |
| CLOB | Large character data |
| BLOB | Large binary data |
| NCLOB | Large national character data |

### Example

```sql
CREATE TABLE documents (
    document_id NUMBER PRIMARY KEY,
    document_text CLOB,
    document_file BLOB
);
```

### Design Note

LOB storage and access patterns should be reviewed separately for high-volume systems.

---

**➡ Transition:** Explicit conversions make SQL predictable across environments. 

---

## 7. Explicit Conversion

### Character to Date

```sql
SELECT TO_DATE('2026-08-16', 'YYYY-MM-DD')
FROM dual;
```

### Date to Character

```sql
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS')
FROM dual;
```

### Number Conversion

```sql
SELECT TO_NUMBER('1250.50', '9999D99')
FROM dual;
```

### CAST

```sql
SELECT CAST(SYSDATE AS TIMESTAMP)
FROM dual;
```

### Why Explicit Conversion Matters

It avoids dependence on session NLS settings and prevents implicit-conversion surprises.

---

## 8. Comparison Matrix

| Type | Best For | Key Detail |
| --- | --- | --- |
| CHAR | Fixed codes | Padded to fixed length |
| VARCHAR2 | Variable text | Stores variable length |
| NUMBER | Calculations | Precision and scale |
| DATE | Date and seconds | Oracle date/time type |
| TIMESTAMP | Fractional seconds | Higher precision |
| CLOB/BLOB | Large values | Character/binary storage |

---

## 9. Best Practices

### 1. Store values according to meaning

Use dates for dates, numbers for amounts, and character types for labels.

### 2. Use explicit conversion masks

```sql
TO_DATE(:date_text, 'YYYY-MM-DD')
```

**Why:** It is independent of session format settings.

### 3. Choose time-zone types for global systems

**Why:** A plain DATE may not preserve the original regional context.

---

## 10. Common Mistakes

### Mistake 1: Comparing dates as strings

**Solution:** Convert text explicitly to DATE or TIMESTAMP.

### Mistake 2: Relying on implicit conversion

**Solution:** Use `TO_DATE`, `TO_CHAR`, `TO_NUMBER`, or `CAST`.

### Mistake 3: Using CHAR for all text

**Solution:** Use VARCHAR2 unless fixed-length padding is intentional.

---

## 11. Interview Q&A

**Q: What is the difference between CHAR and VARCHAR2?**
A: CHAR is fixed length; VARCHAR2 is variable length and usually better for ordinary text.

**Q: What is the difference between DATE and TIMESTAMP?**
A: DATE stores time to seconds, while TIMESTAMP supports fractional seconds and related time-zone variants.

**Q: Why use explicit conversion?**
A: It makes formats predictable and avoids NLS-dependent behavior.

---

## 12. Revision Summary

- **CHAR** → fixed-length text
- **VARCHAR2** → variable-length text
- **NUMBER** → numeric values
- **DATE** → date and seconds
- **TIMESTAMP** → fractional seconds
- **CLOB/BLOB** → large objects
- **TO_DATE / TO_CHAR / TO_NUMBER / CAST** → explicit conversion

### Important Syntax

```sql
CREATE TABLE events (
    event_id NUMBER,
    event_time TIMESTAMP WITH TIME ZONE,
    description VARCHAR2(200),
    payload CLOB
);
```

---

**Done!** Correct Oracle data types prevent conversion errors and make the database model match the real business data.
