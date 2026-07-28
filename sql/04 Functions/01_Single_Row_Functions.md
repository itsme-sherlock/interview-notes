# Single Row Functions Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Single-row function** = Processes one row, returns one result (unlike aggregate functions that group rows).
- **Character functions:** UPPER/LOWER/INITCAP (case), SUBSTR/INSTR (extraction), REPLACE/TRANSLATE (replacement), TRIM/LTRIM/RTRIM (whitespace), LPAD/RPAD (padding), LENGTH, REVERSE.
- **Numeric functions:** ROUND (decimal places), TRUNC (remove decimals), MOD (remainder), CEIL (up), FLOOR (down), ABS (absolute), SIGN (-, 0, +), POWER (exponent).
- **Date functions:** SYSDATE (server date), CURRENT_DATE (session date), ADD_MONTHS (add months), MONTHS_BETWEEN (difference), NEXT_DAY (next weekday), LAST_DAY (end of month), EXTRACT (year/month/day).
- **General functions:** GREATEST/LEAST (min/max from list), CONCAT (combine strings), CASE/DECODE (conditional).
- **Null functions:** NVL (replace NULL), NVL2 (conditional NULL), COALESCE (first non-NULL), NULLIF (NULL if equal), IS NULL/IS NOT NULL.
- **Conversion:** TO_CHAR (date/number → string), TO_DATE (string → date), TO_NUMBER (string → number), CAST (any type → any type).

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Single-Row Functions?](#1-why-do-we-need-single-row-functions)
2. [What is a Single-Row Function?](#2-what-is-a-single-row-function)
3. [Single-Row vs Aggregate Functions](#3-single-row-vs-aggregate-functions)
4. [Character Case Functions](#4-character-case-functions)
5. [Character Extraction Functions](#5-character-extraction-functions)
6. [Character Manipulation Functions](#6-character-manipulation-functions)
7. [Character Padding Functions](#7-character-padding-functions)
8. [Numeric Functions](#8-numeric-functions)
9. [Rounding Functions Comparison](#9-rounding-functions-comparison)
10. [Date Functions](#10-date-functions)
11. [Date Arithmetic](#11-date-arithmetic)
12. [General Functions](#12-general-functions)
13. [Conditional Functions: CASE vs DECODE](#13-conditional-functions-case-vs-decode)
14. [NULL Handling Functions](#14-null-handling-functions)
15. [Conversion Functions](#15-conversion-functions)
16. [Best Practices](#16-best-practices)
17. [Common Mistakes](#17-common-mistakes)
18. [Interview Q&A](#18-interview-qa)
19. [Revision Summary](#19-revision-summary)

---

## 1. Why Do We Need Single-Row Functions?

### The Problem: Raw Data Isn't Always Ready for Use

**Scenario:** Your EMPLOYEES table has raw data:

```sql
SELECT * FROM employees WHERE employee_id = 101;
-- Result:
-- emp_id | first_name | last_name | hire_date | salary
-- 101    | john       | smith     | 1999-08-26 | 50000.456
```

**Raw data problems:**
- Name in lowercase (marketing wants "John Smith")
- Date format ugly (need "26-AUG-1999")
- Salary has extra decimals (need "50000.46")
- Missing values (commission is NULL, need "0")

### The Solution: Single-Row Functions

Functions **transform data within SQL** (no post-processing needed):

```sql
SELECT employee_id,
       INITCAP(first_name) || ' ' || INITCAP(last_name) AS proper_name,
       TO_CHAR(hire_date, 'DD-MON-YYYY') AS formatted_date,
       ROUND(salary, 2) AS rounded_salary,
       NVL(commission, 0) AS commission_pct
FROM employees
WHERE employee_id = 101;
-- Result:
-- emp_id | proper_name  | formatted_date | rounded_salary | commission_pct
-- 101    | John Smith   | 26-AUG-1999    | 50000.46       | 0
```

### Real-World Scenarios

- **Reporting:** Format dates, numbers for readability
- **Data validation:** Check string length, NULL values
- **Calculations:** Math operations on salary/bonus
- **Data transformation:** Convert data types before INSERT/UPDATE
- **Conditional logic:** Apply different rules based on column values

---

**➡ Transition:** Single-row functions are everywhere in SQL. Let's understand what makes them different from aggregate functions.

---

## 2. What is a Single-Row Function?

### Simple Definition

A **single-row function** operates on **one row at a time** and returns **one result per row**.

It processes each row independently and doesn't combine data across rows.

### Function Categories

Oracle provides functions for:
1. **Character data:** Case, extraction, manipulation, padding
2. **Numeric data:** Rounding, math operations
3. **Date data:** Calculations, formatting
4. **NULL handling:** Replacing, checking
5. **Data conversion:** Type casting

### Syntax Patterns

```sql
SELECT function_name(column_or_value) AS result
FROM table_name;
```

### Example: Applying to Each Row

```sql
SELECT employee_id,
       first_name,
       UPPER(first_name) AS upper_first_name,
       LENGTH(first_name) AS name_length,
       SUBSTR(first_name, 1, 3) AS first_3_chars
FROM employees;
```

**Result (one row per employee):**
```
emp_id | first_name | upper_first_name | name_length | first_3_chars
101    | john       | JOHN             | 4           | joh
102    | alice      | ALICE            | 5           | ali
103    | bob        | BOB              | 3           | bob
```

---

**➡ Transition:** Single-row functions work on individual rows. Aggregate functions (like SUM, COUNT) work on groups of rows. Let's see the difference.

---

## 3. Single-Row vs Aggregate Functions

### Comparison

| Aspect | Single-Row | Aggregate |
| --- | --- | --- |
| **Rows processed** | One row at a time | Multiple rows together |
| **Rows in output** | One result per input row | One result per group |
| **Examples** | UPPER, ROUND, NVL | SUM, COUNT, AVG, MAX |
| **Use with GROUP BY** | No (not required) | Yes (often required) |
| **Query structure** | SELECT, WHERE, ORDER BY | SELECT, GROUP BY, HAVING |

### Example: Single-Row

```sql
SELECT first_name,
       UPPER(first_name) AS upper_name  -- Single-row function
FROM employees;
```

**Result (5 rows in, 5 rows out):**
```
first_name | upper_name
john       | JOHN
alice      | ALICE
bob        | BOB
charlie    | CHARLIE
diana      | DIANA
```

### Example: Aggregate

```sql
SELECT COUNT(*) AS total_employees  -- Aggregate function
FROM employees;
```

**Result (5 rows in, 1 row out):**
```
total_employees
5
```

### Combining Both: Single-Row Inside Aggregate

```sql
SELECT COUNT(*),
       AVG(LENGTH(first_name)) AS avg_name_length  -- Single-row in aggregate context
FROM employees;
```

---

**➡ Transition:** Now let's explore function categories. We'll start with character functions for text transformation.

---

## 4. Character Case Functions

### UPPER: Convert to Uppercase

```sql
SELECT first_name,
       UPPER(first_name) AS upper_name
FROM employees;
-- john → JOHN, alice → ALICE
```

### LOWER: Convert to Lowercase

```sql
SELECT first_name,
       LOWER(first_name) AS lower_name
FROM employees;
-- JOHN → john, ALICE → alice
```

### INITCAP: Capitalize First Letter of Each Word

```sql
SELECT first_name,
       INITCAP(first_name) AS initcap_name
FROM employees;
-- john → John, ALICE → Alice, john paul → John Paul
```

### Use Cases

```sql
-- Case-insensitive search
SELECT * FROM employees 
WHERE UPPER(first_name) = 'JOHN';

-- Format names for display
SELECT INITCAP(first_name) || ' ' || INITCAP(last_name) AS full_name
FROM employees;

-- Find duplicates ignoring case
SELECT UPPER(email), COUNT(*)
FROM users
GROUP BY UPPER(email)
HAVING COUNT(*) > 1;
```

---

## 5. Character Extraction Functions

### LENGTH: String Length

```sql
SELECT first_name,
       LENGTH(first_name) AS name_length
FROM employees;
-- john → 4, alice → 5

-- NULL handling
SELECT LENGTH(NULL) FROM dual;  -- NULL (not 0!)
```

### SUBSTR: Extract Substring

**Syntax:** `SUBSTR(string, start_position, length)`

```sql
SELECT first_name,
       SUBSTR(first_name, 1, 3) AS first_3_chars,
       SUBSTR(first_name, 2, 2) AS chars_2_to_3
FROM employees;
-- john: first_3_chars=joh, chars_2_to_3=oh

-- Negative index (from end)
SELECT SUBSTR('SOWPARNIKA', -4, 4) AS last_4_chars
FROM dual;
-- Result: NIKA
```

### INSTR: Find Position of Substring

**Syntax:** `INSTR(string, substring, start_position, occurrence)`

```sql
SELECT first_name,
       INSTR(first_name, 'a') AS pos_of_a
FROM employees;
-- john → 0 (not found), alice → 3 (position of 'a')

-- Multiple occurrences
SELECT INSTR('BANANA', 'A', 1, 2) AS pos_2nd_a
FROM dual;
-- Result: 4 (second occurrence of 'A' in BANANA)

-- Combined with SUBSTR
SELECT SUBSTR('ORACLE SQL', INSTR('ORACLE SQL', 'SQL')) AS extracted
FROM dual;
-- Result: SQL
```

---

**➡ Transition:** Extraction is great for finding data. But often you need to **replace** or **transform** characters.

---

## 6. Character Manipulation Functions

### REPLACE: Replace Substring

**Syntax:** `REPLACE(string, old_substring, new_substring)`

```sql
SELECT first_name,
       REPLACE(first_name, 'a', 'A') AS replace_a
FROM employees;
-- alice → AlicE, david → dAvid

-- Remove characters (replace with nothing)
SELECT REPLACE('ORACLE SQL', ' ', '') AS no_space
FROM dual;
-- Result: ORACLESQL
```

### TRANSLATE: Character-by-Character Replacement

**Syntax:** `TRANSLATE(string, from_chars, to_chars)`

```sql
SELECT first_name,
       TRANSLATE(first_name, 'aeiou', '12345') AS vowels_to_nums
FROM employees;
-- john → j3hn, alice → 1l1c2, david → d1v1d

-- Multiple characters
SELECT TRANSLATE('SOWPARNIKA', 'SA', '12') AS translate_sa
FROM dual;
-- S→1, A→2: Result: 1OWP2RNIK2
```

### REPLACE vs TRANSLATE

| Function | Replaces | Example |
| --- | --- | --- |
| **REPLACE** | Specific substring | Replace "cat" with "dog" |
| **TRANSLATE** | Individual characters | Replace vowels with numbers |

```sql
-- REPLACE: Replace whole substring
REPLACE('I have a cat', 'cat', 'dog')  -- I have a dog

-- TRANSLATE: Character by character
TRANSLATE('ABC', 'ABC', '123')  -- 123
```

### REVERSE: Reverse String

```sql
SELECT first_name,
       REVERSE(first_name) AS reversed
FROM employees;
-- john → nhoj, alice → ecila
```

---

## 7. Character Padding Functions

### TRIM: Remove Leading/Trailing Spaces

```sql
SELECT TRIM('   SOWPARNIKA   ') AS trimmed
FROM dual;
-- Result: SOWPARNIKA (spaces removed)

-- LTRIM (left trim)
SELECT LTRIM('   SOWPARNIKA   ') AS ltrimmed
FROM dual;
-- Result: SOWPARNIKA   (left spaces removed)

-- RTRIM (right trim)
SELECT RTRIM('   SOWPARNIKA   ') AS rtrimmed
FROM dual;
-- Result:    SOWPARNIKA (right spaces removed)
```

### LPAD: Pad Left Side

**Syntax:** `LPAD(string, length, pad_char)`

```sql
SELECT first_name,
       LPAD(first_name, 10, '*') AS padded
FROM employees;
-- john (4 chars) → ****john (total 10)
-- alice (5 chars) → *****alice (total 10)

-- Use cases
LPAD(employee_id, 5, '0')  -- 1 → 00001 (ID formatting)
LPAD(amount, 10, ' ')      -- 500 → '       500' (right-aligned)
```

### RPAD: Pad Right Side

**Syntax:** `RPAD(string, length, pad_char)`

```sql
SELECT first_name,
       RPAD(first_name, 10, '*') AS padded
FROM employees;
-- john (4 chars) → john**** (total 10)

-- Use cases
RPAD(description, 50, ' ')  -- Pad to fixed width (formatting)
RPAD(code, 5, '0')          -- AB → AB000
```

---

**➡ Transition:** Character functions handle text. Numeric functions handle math and rounding operations.

---

## 8. Numeric Functions

### ROUND: Round to Decimal Places

**Syntax:** `ROUND(number, decimal_places)`

```sql
SELECT ROUND(123.4567, 2) AS rounded_2
       ROUND(123.4567) AS rounded_0
FROM dual;
-- 123.4567 → 123.46 (2 decimals)
-- 123.4567 → 123 (0 decimals)

-- Negative decimal places (round whole number)
SELECT ROUND(1234.5678, -1) AS round_tens
FROM dual;
-- 1234.5678 → 1230 (nearest 10)
```

### TRUNC: Truncate (Remove) Decimals

**Syntax:** `TRUNC(number, decimal_places)`

```sql
SELECT TRUNC(123.9876, 2) AS trunc_2,
       TRUNC(123.9876, 0) AS trunc_0,
       TRUNC(123.9876, -1) AS trunc_minus_1
FROM dual;
-- 123.9876 → 123.98 (keep 2 decimals, don't round)
-- 123.9876 → 123 (remove all decimals)
-- 123.9876 → 120 (remove last digit)
```

### MOD: Remainder (Modulus)

**Syntax:** `MOD(dividend, divisor)`

```sql
SELECT MOD(10, 3) AS remainder  -- 10 ÷ 3 = 3 remainder 1
FROM dual;
-- Result: 1

-- Use cases
SELECT * FROM employees WHERE MOD(employee_id, 2) = 0;  -- Even IDs only
```

### CEIL: Round Up

```sql
SELECT CEIL(123.45) AS ceiling
FROM dual;
-- Result: 124 (smallest integer ≥ 123.45)

-- Always goes up (or stays same if already integer)
CEIL(123.00)  -- 123 (already integer)
CEIL(123.01)  -- 124 (always up)
```

### FLOOR: Round Down

```sql
SELECT FLOOR(123.99) AS floor_val
FROM dual;
-- Result: 123 (largest integer ≤ 123.99)

-- Always goes down
FLOOR(123.99)  -- 123
FLOOR(123.01)  -- 123
FLOOR(123.00)  -- 123
```

### ABS: Absolute Value

```sql
SELECT ABS(-123.45) AS absolute
FROM dual;
-- Result: 123.45 (removes negative sign)

SELECT ABS(salary - 50000) AS salary_difference
FROM employees;
```

### SIGN: Sign of Number

```sql
SELECT SIGN(-123) AS sign_neg,
       SIGN(0) AS sign_zero,
       SIGN(123) AS sign_pos
FROM dual;
-- Results: -1, 0, 1
```

### POWER: Exponentiation

**Syntax:** `POWER(base, exponent)`

```sql
SELECT POWER(2, 3) AS power_val
FROM dual;
-- 2^3 = 8

SELECT POWER(10, 2) FROM dual;  -- 100
SELECT POWER(2, 10) FROM dual;  -- 1024
```

---

## 9. Rounding Functions Comparison

**Test value: 123.456**

| Function | Result | Logic |
| --- | --- | --- |
| ROUND(123.456, 2) | 123.46 | Round using 0.5 rule |
| TRUNC(123.456, 2) | 123.45 | Cut off (truncate) |
| CEIL(123.456) | 124 | Always up |
| FLOOR(123.456) | 123 | Always down |

**Choose function based on need:**
- **ROUND:** Mathematical rounding (default)
- **TRUNC:** Financial precision (don't round up money)
- **CEIL:** Always round up (estimate jobs needed)
- **FLOOR:** Always round down (inventory count)

---

**➡ Transition:** Numeric functions handle numbers. Date functions handle time-based calculations.

---

## 10. Date Functions

### SYSDATE: Current Server Date/Time

```sql
SELECT SYSDATE FROM dual;
-- Returns: 28-JUL-2026 14:32:45
```

### CURRENT_DATE: Current Session Date

```sql
SELECT SYSDATE,
       CURRENT_DATE
FROM dual;
-- SYSDATE: Server's date/time
-- CURRENT_DATE: Session's date (in session timezone)
```

### EXTRACT: Get Date Component

**Syntax:** `EXTRACT(component FROM date)`

```sql
SELECT EXTRACT(YEAR FROM SYSDATE) AS current_year,
       EXTRACT(MONTH FROM SYSDATE) AS current_month,
       EXTRACT(DAY FROM SYSDATE) AS current_day,
       EXTRACT(HOUR FROM SYSDATE) AS current_hour
FROM dual;
-- Results: 2026, 7, 28, 14
```

---

## 11. Date Arithmetic

### ADD_MONTHS: Add Months to Date

**Syntax:** `ADD_MONTHS(date, num_months)`

```sql
SELECT SYSDATE AS today,
       ADD_MONTHS(SYSDATE, 3) AS in_3_months,
       ADD_MONTHS(SYSDATE, -3) AS 3_months_ago
FROM dual;
-- Automatically handles year boundaries
-- 2026-10-28 + 3 months = 2027-01-28
```

### MONTHS_BETWEEN: Months Between Two Dates

**Syntax:** `MONTHS_BETWEEN(date1, date2)`

```sql
SELECT MONTHS_BETWEEN(SYSDATE, ADD_MONTHS(SYSDATE, 3)) AS months_diff
FROM dual;
-- Result: -3 (3 months in the future)

SELECT MONTHS_BETWEEN(DATE '2026-08-26', DATE '2026-02-07') AS months_diff
FROM dual;
-- Result: 6.61 (6 months and some days)
```

### NEXT_DAY: Next Occurrence of Weekday

**Syntax:** `NEXT_DAY(date, weekday)`

```sql
SELECT NEXT_DAY(SYSDATE, 'MONDAY') AS next_monday,
       NEXT_DAY(SYSDATE, 'FRIDAY') AS next_friday
FROM dual;
-- Returns date of next occurrence of that weekday
```

### LAST_DAY: Last Day of Month

**Syntax:** `LAST_DAY(date)`

```sql
SELECT LAST_DAY(SYSDATE) AS end_of_month,
       LAST_DAY(ADD_MONTHS(SYSDATE, 1)) AS end_next_month
FROM dual;
-- 2026-07-31 (last day of July)
```

---

**➡ Transition:** Generic functions provide common utilities like conditionals and comparisons.

---

## 12. General Functions

### GREATEST: Find Maximum Value

**Syntax:** `GREATEST(value1, value2, value3, ...)`

```sql
SELECT GREATEST(10, 20, 30, 5) AS greatest_val
FROM dual;
-- Result: 30

SELECT first_name, salary, commission_pct,
       GREATEST(salary, NVL(commission_pct, 0)) AS higher_val
FROM employees;
```

### LEAST: Find Minimum Value

**Syntax:** `LEAST(value1, value2, value3, ...)`

```sql
SELECT LEAST(10, 20, 30, 5) AS least_val
FROM dual;
-- Result: 5

-- ⚠️ Important: If ANY value is NULL, result is NULL
SELECT LEAST(10, 2, NULL, 8) FROM dual;  -- NULL (not 2!)
```

### CONCAT: Combine Strings

**Syntax:** `CONCAT(string1, string2)` (only 2 arguments)

```sql
SELECT CONCAT(first_name, last_name) AS full_name
FROM employees;
-- john + smith = johnsmith

-- For multiple strings, use ||
SELECT first_name || ' ' || last_name AS full_name
FROM employees;
-- john + ' ' + smith = john smith
```

---

## 13. Conditional Functions: CASE vs DECODE

### CASE: Standard SQL Conditional

```sql
SELECT first_name,
       salary,
       CASE
         WHEN salary < 5000 THEN 'Low'
         WHEN salary BETWEEN 5000 AND 10000 THEN 'Medium'
         WHEN salary > 10000 THEN 'High'
         ELSE 'Unknown'
       END AS salary_category
FROM employees;
```

**Advantages:**
- Standard SQL (works in most databases)
- Clear logic flow
- Complex conditions possible

### DECODE: Oracle Conditional (Legacy)

**Syntax:** `DECODE(expression, search1, result1, search2, result2, ..., default)`

```sql
SELECT first_name,
       salary,
       DECODE(salary,
         5000, 'Low',
         10000, 'Medium',
         'High') AS salary_category
FROM employees;
```

**Advantages:**
- Simpler syntax for simple cases
- Oracle-specific

### Comparison

| Feature | CASE | DECODE |
| --- | --- | --- |
| **Standard SQL** | Yes | No (Oracle-specific) |
| **Complex logic** | Easy | Hard |
| **Readability** | Better | Compact |
| **Nested conditions** | Yes | Limited |

**Use CASE** (modern preference) in almost all cases.

---

**➡ Transition:** One common challenge: handling NULL values. Let's explore NULL handling functions.

---

## 14. NULL Handling Functions

### NVL: Replace NULL with Value

**Syntax:** `NVL(expression, replacement)`

```sql
SELECT first_name,
       commission_pct,
       NVL(commission_pct, 0) AS commission
FROM employees;
-- NULL commission → 0

SELECT NVL(NULL, 'No Value') AS result FROM dual;
-- Result: No Value
```

**Use case:** Provide default values for calculations

```sql
SELECT first_name,
       salary,
       NVL(commission_pct, 0) AS comm,
       salary + (salary * NVL(commission_pct, 0)) AS total_comp
FROM employees;
```

### NVL2: Conditional NULL Check

**Syntax:** `NVL2(expression, value_if_not_null, value_if_null)`

```sql
SELECT first_name,
       commission_pct,
       NVL2(commission_pct, 'Has Commission', 'No Commission') AS status
FROM employees;
-- commission_pct is NULL → No Commission
-- commission_pct has value → Has Commission
```

### COALESCE: First Non-NULL Value

**Syntax:** `COALESCE(expr1, expr2, expr3, ...)`

```sql
SELECT COALESCE(NULL, '1', '2', '3') AS first_non_null
FROM dual;
-- Result: 1 (first non-NULL value)

-- Use case: Multiple fallback options
SELECT employee_id,
       COALESCE(phone, mobile, email, 'No Contact') AS contact_info
FROM employees;
```

### NULLIF: Return NULL if Equal

**Syntax:** `NULLIF(expr1, expr2)`

```sql
SELECT employee_id,
       salary,
       NULLIF(salary, 2600) AS salary_check
FROM employees;
-- If salary = 2600, result is NULL
-- Otherwise, result is salary

-- Use case: Identify anomalies
SELECT employee_id,
       NULLIF(actual_salary, expected_salary) AS salary_anomaly
FROM salary_audit;
-- Shows only rows where salary doesn't match expectation
```

### Comparison: NVL vs NVL2 vs COALESCE vs NULLIF

| Function | Purpose | Syntax | Result |
| --- | --- | --- | --- |
| **NVL** | Replace NULL | NVL(value, default) | default if NULL |
| **NVL2** | Branch on NULL | NVL2(value, if_not_null, if_null) | One or other |
| **COALESCE** | First non-NULL | COALESCE(v1, v2, v3) | First non-NULL |
| **NULLIF** | Return NULL if equal | NULLIF(v1, v2) | NULL if equal |

---

**➡ Transition:** Sometimes you need to convert data to different types before using functions.

---

## 15. Conversion Functions

### TO_CHAR: Convert to String

**Syntax:** `TO_CHAR(value, format)`

```sql
-- Date to string
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD') AS date_string,
       TO_CHAR(SYSDATE, 'DD-MON-YYYY') AS date_format,
       TO_CHAR(SYSDATE, 'HH24:MI:SS') AS time_string
FROM dual;

-- Number to string with formatting
SELECT TO_CHAR(12345.6789, '99,999.99') AS formatted_number
FROM dual;
-- Result: 12,345.68

-- Date components
SELECT TO_CHAR(SYSDATE, 'DAY') AS day_name,
       TO_CHAR(SYSDATE, 'MONTH') AS month_name,
       TO_CHAR(SYSDATE, 'DY') AS day_abbreviation
FROM dual;
```

### TO_DATE: Convert to Date

**Syntax:** `TO_DATE(string, format)`

```sql
SELECT TO_DATE('26-08-2026', 'DD-MM-YYYY') AS converted_date,
       TO_DATE('26-AUG-2026 10:30:00', 'DD-MON-YYYY HH24:MI:SS') AS datetime
FROM dual;
```

### TO_NUMBER: Convert to Number

**Syntax:** `TO_NUMBER(string, format)`

```sql
SELECT TO_NUMBER('12345.6789') AS num1,
       TO_NUMBER('12,345.67', '99,999.99') AS num2
FROM dual;
```

### CAST: Universal Conversion

**Syntax:** `CAST(value AS target_type)`

```sql
SELECT CAST('12345' AS NUMBER) AS to_number,
       CAST(12345 AS VARCHAR2(10)) AS to_string,
       CAST(SYSDATE AS TIMESTAMP) AS to_timestamp
FROM dual;
```

---

## 16. Best Practices

### 1. Use Appropriate Function for Task

**Avoid:**
```sql
-- Manual string manipulation
SELECT SUBSTR(name, 1, 1) || LOWER(SUBSTR(name, 2)) AS proper_name
FROM users;
```

**Prefer:**
```sql
-- Built-in function designed for it
SELECT INITCAP(name) AS proper_name
FROM users;
```

---

### 2. Handle NULL Explicitly

**Avoid:**
```sql
-- Assumes commission_pct is never NULL
SELECT salary + commission_pct AS total_comp
FROM employees;
-- Returns NULL for employees without commission!
```

**Prefer:**
```sql
-- Explicitly handle NULL
SELECT salary + NVL(commission_pct, 0) AS total_comp
FROM employees;
```

---

### 3. Use CASE for Complex Logic

**Avoid:**
```sql
-- Nested DECODE (hard to read)
SELECT DECODE(status, 'A', DECODE(level, 1, 'High', 2, 'Med', 'Low'), 'Inactive')
FROM users;
```

**Prefer:**
```sql
-- CASE is clearer
SELECT CASE
         WHEN status = 'A' AND level = 1 THEN 'High'
         WHEN status = 'A' AND level = 2 THEN 'Medium'
         WHEN status = 'A' THEN 'Low'
         ELSE 'Inactive'
       END AS user_status
FROM users;
```

---

### 4. Apply Functions Consistently

**Avoid:**
```sql
-- Inconsistent case handling
SELECT * FROM employees WHERE first_name = 'John';  -- Exact case
SELECT * FROM employees WHERE UPPER(first_name) = 'JOHN';  -- Case-insensitive
```

**Prefer:**
```sql
-- Consistent case-insensitive search
SELECT * FROM employees WHERE UPPER(first_name) = 'JOHN';
```

---

## 17. Common Mistakes

### Mistake 1: GREATEST/LEAST with NULL

```sql
-- ❌ WRONG: Returns NULL!
SELECT GREATEST(10, 2, NULL, 8) FROM dual;
-- Result: NULL (not 10!)

-- ✅ CORRECT: Use NVL to handle NULL
SELECT GREATEST(10, 2, NVL(NULL, 0), 8) FROM dual;
-- Result: 10
```

---

### Mistake 2: String Concatenation with NULL

```sql
-- ❌ WRONG: Returns NULL
SELECT first_name || ' ' || last_name AS full_name FROM employees;
-- If either is NULL, result is NULL

-- ✅ CORRECT: Use NVL
SELECT NVL(first_name, '') || ' ' || NVL(last_name, '') AS full_name
FROM employees;
```

---

### Mistake 3: Function on Indexed Column

```sql
-- ❌ WRONG: Index not used, full table scan
SELECT * FROM employees WHERE UPPER(first_name) = 'JOHN';

-- ✅ CORRECT: Create function-based index
CREATE INDEX idx_upper_first ON employees (UPPER(first_name));

-- Now the query uses index
SELECT * FROM employees WHERE UPPER(first_name) = 'JOHN';
```

---

### Mistake 4: Comparing Different Types

```sql
-- ❌ WRONG: Implicit conversion, unpredictable
SELECT * FROM employees WHERE salary = '50000';

-- ✅ CORRECT: Explicit conversion
SELECT * FROM employees WHERE salary = TO_NUMBER('50000');
```

---

### Mistake 5: Complex Logic Without CASE

```sql
-- ❌ WRONG: Nested IFs are error-prone
SELECT employee_id,
       DECODE(1, DECODE(status, 'A', 1, 0), DECODE(...), ...)
FROM employees;

-- ✅ CORRECT: Use CASE
SELECT employee_id,
       CASE WHEN condition1 THEN result1
            WHEN condition2 THEN result2
            ELSE result3
       END AS status
FROM employees;
```

---

## 18. Interview Q&A

### Conceptual

**Q: What's the difference between single-row and aggregate functions?**

A: Single-row functions operate on one row at a time (UPPER, ROUND, NVL) and return one result per row. Aggregate functions combine multiple rows (SUM, COUNT, AVG) and return one result per group.

---

**Q: Why would LENGTH(NULL) return NULL and not 0?**

A: NULL represents unknown value. Oracle can't determine length of unknown, so returns NULL. This follows SQL's three-valued logic (TRUE, FALSE, NULL).

---

**Q: When would you use COALESCE over NVL?**

A: COALESCE accepts multiple arguments (first non-NULL wins), while NVL only takes 2. Use COALESCE when multiple fallback options needed.

---

### Comparison

**Q: NVL vs NVL2 vs COALESCE?**

A: NVL (2 args, replace NULL). NVL2 (3 args, IF-THEN-ELSE on NULL). COALESCE (many args, first non-NULL).

---

**Q: ROUND vs TRUNC?**

A: ROUND uses rounding rules (0.5 up). TRUNC just cuts off decimals. For financial data, TRUNC is safer (never rounds up money).

---

### Scenario

**Q: Query needs salary + commission, but commission is NULL for many. How to handle?**

A: Use NVL(commission, 0): `salary + NVL(commission_pct, 0)`. Returns salary unchanged if commission is NULL.

---

**Q: Want to search case-insensitively for employee names. Approach?**

A: Use UPPER() on both sides: `WHERE UPPER(first_name) = UPPER('John')`. Or standardize all to uppercase on INSERT: `INSERT INTO employees VALUES (..., UPPER(first_name), ...)`.

---

## 19. Revision Summary

### 1-Minute Revision

**Single-row functions = Process one row, transform data (text, numbers, dates, NULL handling).**

1. **Character case:** UPPER, LOWER, INITCAP
2. **Character extraction:** LENGTH, SUBSTR, INSTR
3. **Character manipulation:** REPLACE, TRANSLATE, REVERSE, TRIM, LTRIM, RTRIM, LPAD, RPAD
4. **Numeric:** ROUND, TRUNC, MOD, CEIL, FLOOR, ABS, SIGN, POWER
5. **Date:** SYSDATE, CURRENT_DATE, EXTRACT, ADD_MONTHS, MONTHS_BETWEEN, NEXT_DAY, LAST_DAY
6. **General:** GREATEST, LEAST, CONCAT, CASE, DECODE
7. **NULL:** NVL (replace NULL), NVL2 (conditional), COALESCE (first non-NULL), NULLIF (NULL if equal)
8. **Conversion:** TO_CHAR (→ string), TO_DATE (→ date), TO_NUMBER (→ number), CAST (any → any)

### Interview Keywords

- Single-row vs aggregate functions
- Character functions: UPPER, LOWER, INITCAP, SUBSTR, INSTR, REPLACE, TRANSLATE, TRIM, LPAD, RPAD, REVERSE
- Numeric functions: ROUND, TRUNC, MOD, CEIL, FLOOR, ABS, SIGN, POWER
- Date functions: SYSDATE, CURRENT_DATE, ADD_MONTHS, MONTHS_BETWEEN, NEXT_DAY, LAST_DAY, EXTRACT
- NULL handling: NVL, NVL2, COALESCE, NULLIF, IS NULL, IS NOT NULL
- Conversion: TO_CHAR, TO_DATE, TO_NUMBER, CAST
- CASE (standard), DECODE (Oracle-specific)
- NULL with aggregate functions (GREATEST/LEAST) returns NULL

### Important Syntax

```sql
-- Case functions
SELECT UPPER(name), LOWER(name), INITCAP(name) FROM table;

-- Extraction
SELECT LENGTH(str), SUBSTR(str, 1, 3), INSTR(str, 'a') FROM table;

-- Manipulation
SELECT REPLACE(str, 'old', 'new'), TRANSLATE(str, 'aeiou', '12345') FROM table;

-- Numeric
SELECT ROUND(123.456, 2), TRUNC(123.456, 2), CEIL(123.1), FLOOR(123.9) FROM table;

-- Date
SELECT EXTRACT(YEAR FROM SYSDATE), ADD_MONTHS(SYSDATE, 3), LAST_DAY(SYSDATE) FROM dual;

-- NULL handling
SELECT NVL(col, 0), NVL2(col, 'yes', 'no'), COALESCE(c1, c2, c3, 'default') FROM table;

-- Conversion
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD'), TO_DATE('2026-07-28', 'YYYY-MM-DD') FROM dual;

-- Conditional
SELECT CASE WHEN salary > 50000 THEN 'High' ELSE 'Low' END FROM employees;
```

<!-- QUICK_SHEET_START -->

## Quick Sheet

- Character functions: `UPPER`, `LOWER`, `INITCAP`, `SUBSTR`, `INSTR`, `REPLACE`, `TRANSLATE`, `TRIM`, `LPAD`, `RPAD`.
- Numeric functions: `ROUND`, `TRUNC`, `MOD`, `CEIL`, `FLOOR`, `ABS`, `SIGN`, `POWER`.
- Date functions: `SYSDATE`, `CURRENT_DATE`, `ADD_MONTHS`, `MONTHS_BETWEEN`, `NEXT_DAY`, `LAST_DAY`, `EXTRACT`.
- General functions: `GREATEST`, `LEAST`, `CONCAT`, `CASE`, `DECODE`.
- Null and conversion: `NVL`, `NVL2`, `COALESCE`, `NULLIF`, `TO_CHAR`, `TO_DATE`, `TO_NUMBER`, `CAST`.

<!-- QUICK_SHEET_END -->

## Table of Contents

- [Categories](#categories)
- [Case Manipulation Functions](#case-manipulation-functions)
- [Character Manipulation Functions](#character-manipulation-functions)
- [Numeric Functions](#numeric-functions)
- [Date Functions](#date-functions)
- [General Functions](#general-functions)
- [Null Functions](#null-functions)
- [Conversion Functions](#conversion-functions)
- [Interview Questions](#interview-questions)

## Categories

1. Case manipulation
2. Numeric functions
3. Character manipulation
4. Date functions
5. General functions
6. Null functions
7. Conversion functions

```sql
SELECT * FROM hr.employees;
```

## Case Manipulation Functions

### 1. UPPER

Converts a string to uppercase.

```sql
SELECT UPPER(first_name) AS upper_first_name,
       UPPER(last_name) AS upper_last_name
FROM hr.employees;
```

### 2. LOWER

Converts a string to lowercase.

```sql
SELECT LOWER(first_name) AS lower_first_name,
       LOWER(last_name) AS lower_last_name
FROM hr.employees;
```

### 3. INITCAP

Capitalizes the first letter of each word in a string.

```sql
SELECT INITCAP(first_name) AS initcap_first_name,
       INITCAP(last_name) AS initcap_last_name
FROM hr.employees;
```

## Character Manipulation Functions

### 1. LENGTH

Returns the length of a string.

```sql
SELECT first_name,
       last_name,
       LENGTH(first_name) AS first_name_length,
       LENGTH(last_name) AS last_name_length
FROM hr.employees;
```

```sql
SELECT LENGTH(NULL), LENGTH('') AS length_of_empty_string FROM dual; -- null, null
```

### 2. SUBSTRING (SUBSTR in Oracle)

Extracts a substring from a string.

Syntax: `SUBSTR(string, start_position, length)`

```sql
SELECT first_name,
       last_name,
       SUBSTR(first_name, 3, 2) AS first_name_substring,
       SUBSTR(last_name, 1, 3) AS last_name_substring
FROM hr.employees;
```

```sql
SELECT SUBSTR('SOWPARNIKA', -4, 4) AS substring_example FROM dual;
```

### 3. INSTR

Returns the position of a substring within a string.

Syntax: `INSTR(string, substring, start_position, occurrence)`

```sql
SELECT first_name,
       last_name,
       INSTR(first_name, 'a', 1, 1) AS first_name_instr,
       INSTR(last_name, 'e', 1, 1) AS last_name_instr
FROM hr.employees;
```

```sql
SELECT INSTR('SOWPARNIKA', 'OWA', 1, 1) AS position_of_O FROM dual;
```

```sql
SELECT SUBSTR('ORACLE SQL', 4, 3), INSTR('ORACLE SQL', 'SQL') FROM dual;
```

### 4. REPLACE

Replaces occurrences of a substring within a string with another substring.

Syntax: `REPLACE(string, old_substring, new_substring)`

```sql
SELECT first_name,
       last_name,
       REPLACE(first_name, 'a', 'A') AS first_name_replaced,
       REPLACE(last_name, 'e', 'E') AS last_name_replaced
FROM hr.employees;
```

```sql
SELECT REPLACE('SOWPARNIKA', 'S', 'QW') AS replaced_string FROM dual;
```

### 5. TRANSLATE

Replaces characters in a string based on a mapping of characters.

Syntax: `TRANSLATE(string, from_string, to_string)`

```sql
SELECT first_name,
       last_name,
       TRANSLATE(first_name, 'aeiou', '1') AS first_name_translated,
       TRANSLATE(last_name, 'aeiou', '12345') AS last_name_translated
FROM hr.employees;
```

```sql
SELECT TRANSLATE('SOWPARNIKA', 'SA', '1234567890') AS translated_string FROM dual;
```

Difference between REPLACE and TRANSLATE:

- `REPLACE` replaces a specific substring with another substring.
- `TRANSLATE` replaces individual characters using one-to-one character mapping.

Which scenario to choose:

- Use `REPLACE` when replacing a whole substring (for example, replacing `cat` with `dog`).
- Use `TRANSLATE` when replacing character by character (for example, vowels with numbers).

### 6. REVERSE

Reverses the order of characters in a string.

```sql
SELECT first_name,
       last_name,
       REVERSE(first_name) AS first_name_reversed,
       REVERSE(last_name) AS last_name_reversed
FROM hr.employees;
```

### 7. TRIM

Removes leading and trailing spaces from a string.

```sql
SELECT TRIM('   SOWPAR NIKA   ') AS trimmed_string FROM dual;
```

7.1 `LTRIM`: Removes leading spaces from a string.  
7.2 `RTRIM`: Removes trailing spaces from a string.

```sql
SELECT LENGTH('ORACLE '), LENGTH(TRIM('ORACLE ')) AS trimmed_length FROM dual;
```

### 8. PAD

Adds padding to a string to reach a specified length.

`LPAD`: Adds padding to the left of a string.  
Syntax: `LPAD(string, length, pad_string)`

```sql
SELECT first_name,
       last_name,
       LPAD(first_name, 10, '<') AS first_name_padded,
       LPAD(last_name, 10, '#') AS last_name_padded
FROM hr.employees;
```

`RPAD`: Adds padding to the right of a string.  
Syntax: `RPAD(string, length, pad_string)`

```sql
SELECT first_name,
       last_name,
       LPAD(first_name, 10, '>') AS first_name_padded,
       RPAD(first_name, 10, '<') AS last_name_padded
FROM hr.employees;
```

## Numeric Functions

Definition: Numeric functions are used to perform calculations and manipulate numeric data in SQL.

### 1. ROUND

Rounds a numeric value to a specified number of decimal places.

Syntax: `ROUND(number, decimal_places)`

```sql
SELECT ROUND(123.4357, 2) AS rounded_value FROM dual; -- Output
```

Edge case without decimal places:

```sql
SELECT ROUND(123.567) AS rounded_value_no_decimal FROM dual; -- Output:
```

### 2. TRUNC

Truncates a numeric value to a specified number of decimal places.

Syntax: `TRUNC(number, decimal_places)`

```sql
SELECT TRUNC(123.9876, 2) AS truncated_value,
       TRUNC(123.9867, 3),
       TRUNC(123.9867)
FROM dual; -- Output: 123.98
```

### 3. MOD

Returns the remainder of a division operation.

Syntax: `MOD(dividend, divisor)`

```sql
SELECT MOD(10, 6) AS remainder FROM dual; -- Output: 1
```

### 4. CEIL

Rounds a numeric value up to the nearest integer.

Nearest integer here means the smallest integer that is greater than or equal to the given number.

```sql
SELECT CEIL(123.45), CEIL(123.66), CEIL(123.00) AS ceiling_value FROM dual; -- Output: 124
```

### 5. FLOOR

Rounds a numeric value down to the nearest integer.

Nearest integer here means the largest integer that is less than or equal to the given number.

How ROUND, CEIL, and FLOOR are different:

- `ROUND`: Uses rounding rules based on decimal values.
- `CEIL`: Always goes upward (or stays same if already an integer).
- `FLOOR`: Always goes downward (or stays same if already an integer).

```sql
SELECT ROUND(123.45) AS round_value,
       CEIL(123.45) AS ceil_value,
       FLOOR(123.45) AS floor_value
FROM dual;
```

### 6. ABS

Returns the absolute value of a number.

Syntax: `ABS(number)`

```sql
SELECT ABS(-123.45) AS absolute_value FROM dual; -- Output: 123.
```

### 7. SIGN

Returns the sign of a number (`-1` for negative, `0` for zero, `1` for positive).

Syntax: `SIGN(number)`

```sql
SELECT SIGN(-123.45) AS sign_negative,
       SIGN(0) AS sign_zero,
       SIGN(123.45) AS sign_positive;
```

### 8. POWER

Raises a number to a specified power.

Syntax: `POWER(base, exponent)`

```sql
SELECT POWER(2, 3) AS power_value FROM dual; -- Output: 8
```

Combined example:

```sql
SELECT ROUND(123.4567, 2) AS rounded_value,         -- 123.46
       TRUNC(123.4567, 2) AS truncated_value,       -- 123.45
       MOD(10, 3) AS remainder,                     -- 1
       CEIL(123.45) AS ceiling_value,               -- 124
       FLOOR(123.45) AS floor_value,                -- 123
       ABS(-123.45) AS absolute_value,              -- 123.45
       SIGN(-123.45) AS sign_negative,              -- -1
       SIGN(0) AS sign_zero,                        -- 0
       SIGN(123.45) AS sign_positive,               -- 1
       POWER(2, 3) AS power_value                   -- 8
FROM dual;
```

## Date Functions

### 1. SYSDATE

Returns the current date and time.

```sql
SELECT SYSDATE FROM dual;
```

### 2. CURRENT_DATE

Returns the current date in the session time zone.

Difference between `SYSDATE` and `CURRENT_DATE`:

- `SYSDATE`: Date/time from the database server system clock.
- `CURRENT_DATE`: Date/time in the client/session time zone.

```sql
SELECT SYSDATE AS sysdate_value,
       CURRENT_DATE AS current_date_value
FROM dual;
```

### 3. ADD_MONTHS

Adds a specified number of months to a date.

Syntax: `ADD_MONTHS(date, number_of_months)`

```sql
SELECT ADD_MONTHS(SYSDATE, 3),
       ADD_MONTHS(SYSDATE, -3) AS future_date
FROM dual;
```

### 4. MONTHS_BETWEEN

Returns the number of months between two dates.

Syntax: `MONTHS_BETWEEN(date1, date2)`

```sql
SELECT MONTHS_BETWEEN(SYSDATE, ADD_MONTHS(SYSDATE, 3)) AS months_difference
FROM dual;
```

```sql
SELECT MONTHS_BETWEEN(DATE '2026-08-26', DATE '2026-02-07') AS months_difference
FROM dual;
```

### 5. NEXT_DAY

Returns the date of the next specified weekday after a given date.

Syntax: `NEXT_DAY(date, weekday)`

```sql
SELECT NEXT_DAY(SYSDATE, 'MONDAY') AS next_monday,
       NEXT_DAY(SYSDATE, 'FRIDAY') AS next_friday,
       NEXT_DAY(SYSDATE, 'SUNDAY') AS next_sunday
FROM dual;
```

### 6. LAST_DAY

Returns the last day of the month for a given date.

Syntax: `LAST_DAY(date)`

```sql
SELECT LAST_DAY(SYSDATE) AS last_day_of_month,
       LAST_DAY(ADD_MONTHS(SYSDATE, 1)) AS last_day_next_month,
       LAST_DAY(ADD_MONTHS(SYSDATE, -1)) AS last_day_previous_month
FROM dual;
```

### 7. EXTRACT

Extracts a specific component (`YEAR`, `MONTH`, `DAY`, etc.) from a date.

Syntax: `EXTRACT(component FROM date)`

```sql
SELECT EXTRACT(YEAR FROM SYSDATE) AS current_year,
       EXTRACT(MONTH FROM SYSDATE) AS current_month,
       EXTRACT(DAY FROM SYSDATE) AS current_day
FROM dual;
```

## General Functions

### 1. DISTINCT/UNIQUE

Removes duplicate values from a result set.

```sql
SELECT DISTINCT department_id
FROM hr.employees;
```

### 2. GREATEST

Returns the largest value from a list of expressions.

Syntax: `GREATEST(expr1, expr2, ...)`

```sql
SELECT GREATEST(salary, commission_pct) AS greatest_value
FROM hr.employees;
```

```sql
SELECT GREATEST(10, 20, 30, 5) AS greatest_value FROM dual;
```

### 3. LEAST

Returns the smallest value from a list of expressions.

Syntax: `LEAST(expr1, expr2, ...)`

```sql
SELECT LEAST(salary, commission_pct) AS least_value
FROM hr.employees;
```

```sql
SELECT LEAST(10, 20, 30, 5) AS least_value FROM dual;
SELECT LEAST(10, 2, NULL, 8) AS least_value FROM dual;       -- null
SELECT GREATEST(10, 2, NULL, 8) AS greatest_value FROM dual; -- null
```

### 4. CONCAT

Concatenates two strings together.

Syntax: `CONCAT(string1, string2)`

```sql
SELECT CONCAT(first_name, last_name) AS full_name
FROM hr.employees;
```

### 5. CASE Statement

Allows conditional logic in SQL queries.

```sql
SELECT first_name,
       last_name,
       salary,
       CASE
            WHEN salary < 5000 THEN 'Low'
            WHEN salary BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'High'
       END AS salary_category
FROM hr.employees;
```

### 6. DECODE

Provides conditional logic similar to a `CASE` statement, but with a simpler syntax.

Syntax: `DECODE(expression, search_value1, result1, search_value2, result2, ...)`

```sql
SELECT first_name,
       last_name,
       salary,
       DECODE(salary, 5000, 'Low', 10000, 'Medium', 'High') AS salary_category
FROM hr.employees;
```

```sql
SELECT DECODE(10, 5, 'Low', 10, 'Medium', 'High') AS result FROM dual;
```

## Null Functions

Definition: Null functions are used to handle `NULL` values in SQL. `NULL` represents absence of value or unknown value.

### 1. NVL

Replaces `NULL` with a specified value.

Syntax: `NVL(expression, replacement_value)`

Trick to remember easily:

```sql
SELECT first_name,
       last_name,
       commission_pct,
       NVL(commission_pct, 1) AS commission
FROM hr.employees;
```

```sql
SELECT NVL(NULL, 'Default Value') AS result FROM dual;
```

### 2. NVL2

Returns one value if expression is not `NULL`, another if it is `NULL`.

Syntax: `NVL2(expression, value_if_not_null, value_if_null)`

```sql
SELECT first_name,
       last_name,
       commission_pct,
       NVL(commission_pct, 1) AS commission,
       NVL2(commission_pct, 'Has Commission', 'No Commission') AS commission_status
FROM hr.employees;
```

Difference between `NVL` and `NVL2`:

- `NVL(expr, replacement)` -> if expr is `NULL`, returns replacement.
- `NVL2(expr, value_if_not_null, value_if_null)` -> chooses between two return values based on whether expr is null.

Easy trick to remember this:

### 3. COALESCE

Returns the first non-`NULL` value from a list of expressions.

Syntax: `COALESCE(expr1, expr2, ...)`

```sql
SELECT first_name,
       last_name,
       commission_pct,
       COALESCE(commission_pct, 1) AS commission
FROM hr.employees;
```

```sql
SELECT COALESCE(NULL, '1', '2') AS result FROM dual;
```

### 4. NULLIF

Returns `NULL` if two expressions are equal; otherwise returns the first expression.

Syntax: `NULLIF(expr1, expr2)`

```sql
SELECT first_name,
       last_name,
       salary,
       NULLIF(2600, salary) AS salary_check
FROM hr.employees;
```

```sql
SELECT NULLIF(10, 10) AS result1,
       NULLIF(10, 5) AS result2
FROM dual;
```

### 5. IS NULL

Returns true if expression is `NULL`; otherwise false.

Syntax: `expression IS NULL`

```sql
SELECT first_name,
       last_name,
       commission_pct,
       (commission_pct IS NULL) AS is_commission_null
FROM hr.employees;
```

### 6. IS NOT NULL

Returns true if expression is not `NULL`; otherwise false.

## Interview Questions

### 1. Difference Between NVL, NVL2, COALESCE, NULLIF

- `NVL`: Two arguments; replace `NULL` with a value.
- `NVL2`: Three arguments; return one value for not-null and another for null.
- `COALESCE`: Multiple arguments; returns first non-null expression.
- `NULLIF`: Returns `NULL` when two expressions are equal.

### 2. Example

```sql
SELECT NVL(NULL, '1') AS result,
       NVL2(NULL, '1', '2') AS result,
       COALESCE(NULL, NULL, NULL, '1', '2') AS result,
       NULLIF(10, 10) AS result
FROM dual;
```

## Conversion Functions

### 1. TO_CHAR

Converts a date or number to a string.

Syntax: `TO_CHAR(expression, format)`

```sql
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD') AS formatted_date,
       TO_CHAR(SYSDATE, 'HH24:MI:SS') AS formatted_time,
       TO_CHAR(SYSDATE, 'D') AS day_of_week,
       TO_CHAR(SYSDATE, 'MM') AS month_number,
       TO_CHAR(SYSDATE, 'YY') AS year_number,
       TO_CHAR(SYSDATE, 'DY') AS day_abbreviation,
       TO_CHAR(SYSDATE, 'W') AS week_of_month,
       TO_CHAR(SYSDATE, 'DAY') AS day_name,
       TO_CHAR(SYSDATE, 'MONTH') AS month_name,
       TO_CHAR(SYSDATE, 'YYYY') AS year,
       TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') AS full_timestamp,
       TO_CHAR(12345.6789, '99999.99') AS formatted_number
FROM dual;
```

```sql
SELECT TO_CHAR(DATE '1999-08-26', 'DAY') FROM dual;
```

### 2. TO_DATE

Converts a string to a date.

Syntax: `TO_DATE(string, format)`

```sql
SELECT TO_DATE('26-08-26', 'dd-mm-yy') AS converted_date,
       TO_DATE('26-08-2026', 'DD-MM-YYYY') AS converted_date1,
       TO_DATE('26-AUG-2026', 'DD-MON-YYYY') AS converted_date2,
       TO_DATE('26-AUG-2026 10:30:00', 'DD-MON-YYYY HH24:MI:SS') AS converted_date3
FROM dual;
```

### 3. TO_NUMBER

Converts a string to a number.

Syntax: `TO_NUMBER(string, format)`

```sql
SELECT TO_NUMBER('12345.6789') AS converted_number,
       TO_NUMBER('12,345.67', '99,999.99') AS formatted_number
FROM dual;
```

### 4. CAST

Converts a value from one data type to another.

Syntax: `CAST(expression AS target_data_type)`

```sql
SELECT CAST('12345' AS NUMBER) AS converted_number,
       CAST(12345 AS VARCHAR2(10)) AS converted_string,
       CAST(SYSDATE AS TIMESTAMP) AS converted_timestamp
FROM dual;
```
