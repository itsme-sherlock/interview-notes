# Single Row Functions (Oracle SQL)

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














