# Oracle Regular Expressions, JSON, and XML Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Regular expression** = Pattern used to search or transform text.
- **REGEXP_LIKE** = Filters text using a pattern.
- **REGEXP_SUBSTR** = Extracts matching text.
- **JSON** = Structured key-value and array data commonly used in APIs.
- **XML** = Structured tag-based data used in integration and legacy systems.
- **Interview keyword** = Validate and transform semi-structured data without losing relational query power.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Advanced Text and Document SQL?](#1-why-do-we-need-advanced-text-and-document-sql)
2. [Regular Expressions](#2-regular-expressions)
3. [REGEXP_LIKE and REGEXP_SUBSTR](#3-regexp_like-and-regexp_substr)
4. [JSON Data](#4-json-data)
5. [XML Data](#5-xml-data)
6. [Comparison Matrix](#6-comparison-matrix)
7. [Best Practices](#7-best-practices)
8. [Common Mistakes](#8-common-mistakes)
9. [Interview Q&A](#9-interview-qa)
10. [Revision Summary](#10-revision-summary)

---

## 1. Why Do We Need Advanced Text and Document SQL?

### The Problem: Modern Data Is Not Always Fully Relational

Applications often store emails, phone numbers, API payloads, and integration documents that need validation or extraction.

### The Solution

Oracle provides regular-expression functions and JSON/XML features for semi-structured data.

### Real-World Scenarios

- Validate email or identifier patterns
- Extract values from API payloads
- Query integration documents

---

**➡ Transition:** Regular expressions handle structured text patterns. 

---

## 2. Regular Expressions

### Simple Definition

A **regular expression** is a pattern that describes text to find, validate, or replace.

### Common Functions

| Function | Purpose |
| --- | --- |
| REGEXP_LIKE | Test whether text matches |
| REGEXP_SUBSTR | Extract matching text |
| REGEXP_REPLACE | Replace matching text |
| REGEXP_INSTR | Find match position |

### Example

```sql
SELECT email
FROM customers
WHERE REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+$');
```

---

**➡ Transition:** Filtering and extraction are the most common regular-expression tasks. 

---

## 3. REGEXP_LIKE and REGEXP_SUBSTR

### Filtering

```sql
SELECT phone_number
FROM customers
WHERE REGEXP_LIKE(phone_number, '^[0-9]{10}$');
```

### Extraction

```sql
SELECT REGEXP_SUBSTR('Order: 45821', '[0-9]+') AS order_number
FROM dual;
```

### Replacement

```sql
SELECT REGEXP_REPLACE(phone_number, '[^0-9]', '') AS clean_phone
FROM customers;
```

### Caution

Regular expressions can be CPU-intensive on large data sets. Use them for appropriate workloads and validate performance.

---

**➡ Transition:** JSON is common when relational systems exchange API payloads. 

---

## 4. JSON Data

### JSON Example

```json
{"employee_id":101,"name":"Alice","skills":["SQL","PLSQL"]}
```

### JSON_VALUE

```sql
SELECT JSON_VALUE(payload, '$.name') AS employee_name
FROM api_events;
```

### JSON_EXISTS

```sql
SELECT *
FROM api_events
WHERE JSON_EXISTS(payload, '$.skills[*]?(@ == "SQL")');
```

### JSON_TABLE

```sql
SELECT jt.employee_id, jt.employee_name
FROM api_events e,
     JSON_TABLE(e.payload, '$'
       COLUMNS (
           employee_id NUMBER PATH '$.employee_id',
           employee_name VARCHAR2(100) PATH '$.name'
       )) jt;
```

### Why It Matters

JSON functions let relational SQL query document fields without treating the entire payload as opaque text.

---

**➡ Transition:** XML remains important in enterprise integrations and older systems. 

---

## 5. XML Data

### XML Example

```xml
<employee><id>101</id><name>Alice</name></employee>
```

### XMLTABLE Pattern

```sql
SELECT x.employee_id, x.employee_name
FROM employee_xml e,
     XMLTABLE('/employee'
       PASSING e.document
       COLUMNS
           employee_id NUMBER PATH 'id',
           employee_name VARCHAR2(100) PATH 'name') x;
```

### Use Cases

- Enterprise integration
- Legacy application interfaces
- Structured document exchange

---

## 6. Comparison Matrix

| Feature | Regular Expression | JSON | XML |
| --- | --- | --- | --- |
| Data type | Text pattern | Key-value document | Tag-based document |
| Main use | Validate/extract text | API payloads | Enterprise integration |
| Common tools | REGEXP_LIKE, REGEXP_SUBSTR | JSON_VALUE, JSON_TABLE | XMLTABLE |
| Main risk | CPU-heavy patterns | Schema drift | Complex document paths |

---

## 7. Best Practices

### 1. Validate document structure before extraction

**Why:** Missing or changed paths can produce null or invalid results.

### 2. Keep regular expressions simple and tested

**Why:** Complex patterns are difficult to maintain and can be slow.

### 3. Use JSON_TABLE or XMLTABLE for repeated extraction

**Why:** Relational projection is clearer than repeatedly calling scalar functions.

---

## 8. Common Mistakes

### Mistake 1: Using regex for every string operation

**Solution:** Use ordinary string functions when they are sufficient.

### Mistake 2: Assuming every JSON key exists

**Solution:** Handle missing paths and validate documents.

### Mistake 3: Treating XML or JSON storage as a substitute for relational design

**Solution:** Keep frequently queried fields relational or index the document paths appropriately.

---

## 9. Interview Q&A

**Q: What does REGEXP_LIKE do?**
A: It filters rows whose text matches a regular-expression pattern.

**Q: What is JSON_TABLE used for?**
A: It projects JSON fields and arrays into relational rows and columns.

**Q: Why use XMLTABLE?**
A: It extracts XML nodes into relational columns for SQL processing.

---

## 10. Revision Summary

- **REGEXP_LIKE** → pattern filtering
- **REGEXP_SUBSTR** → pattern extraction
- **REGEXP_REPLACE** → pattern replacement
- **JSON_VALUE** → one JSON value
- **JSON_TABLE** → JSON to relational columns
- **XMLTABLE** → XML to relational columns

### Important Syntax

```sql
SELECT JSON_VALUE(payload, '$.name')
FROM api_events;

SELECT REGEXP_SUBSTR('Order: 45821', '[0-9]+')
FROM dual;
```

---

**Done!** These features extend SQL into text validation and semi-structured document processing.
