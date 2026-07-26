# Oracle Single-Row Functions

<!-- QUICK_SHEET_START -->

## Quick Sheet
- Character: `UPPER`, `LOWER`, `INITCAP`, `SUBSTR`, `INSTR`, `REPLACE`, `TRIM`.
- Numeric: `ROUND`, `TRUNC`, `MOD`, `CEIL`, `FLOOR`, `ABS`, `POWER`.
- Date: `SYSDATE`, `CURRENT_DATE`, `ADD_MONTHS`, `MONTHS_BETWEEN`, `LAST_DAY`.
- Null handling: `NVL`, `NVL2`, `COALESCE`, `NULLIF`.
- Conversion: `TO_CHAR`, `TO_DATE`, `TO_NUMBER`, `CAST`.

<!-- QUICK_SHEET_END -->

## Table of Contents
- [Main Content](#main-content)
- [Character Functions](#character-functions)
- [Numeric Functions](#numeric-functions)
- [Date Functions](#date-functions)
- [Null Functions](#null-functions)
- [Conversion Functions](#conversion-functions)
- [Interview Insights](#interview-insights)
- [Related Notes](#related-notes)

## Main Content

## Character Functions
```sql
SELECT UPPER(first_name), LOWER(last_name), INITCAP(first_name)
FROM hr.employees;

SELECT SUBSTR('ORACLE', 2, 3), INSTR('ORACLE SQL', 'SQL')
FROM dual;

SELECT REPLACE('DATA', 'A', 'X'), TRIM('  SQL  ')
FROM dual;
```

## Numeric Functions
```sql
SELECT ROUND(123.456, 2),
       TRUNC(123.456, 2),
       MOD(10, 3),
       CEIL(10.1),
       FLOOR(10.9),
       ABS(-7),
       POWER(2, 4)
FROM dual;
```

## Date Functions
```sql
SELECT SYSDATE,
       CURRENT_DATE,
       ADD_MONTHS(SYSDATE, 1),
       MONTHS_BETWEEN(SYSDATE, DATE '2026-01-01'),
       LAST_DAY(SYSDATE)
FROM dual;
```

## Null Functions
```sql
SELECT NVL(commission_pct, 0),
       NVL2(commission_pct, 'Has commission', 'No commission'),
       COALESCE(NULL, NULL, 'fallback')
FROM hr.employees;

SELECT NULLIF(100, 100) AS same_is_null,
       NULLIF(100, 90)  AS different_returns_first
FROM dual;
```

## Conversion Functions
```sql
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') FROM dual;
SELECT TO_DATE('26-07-2026', 'DD-MM-YYYY') FROM dual;
SELECT TO_NUMBER('12345') FROM dual;
SELECT CAST(12345 AS VARCHAR2(10)) FROM dual;
```

## Interview Insights
- `COALESCE` is ANSI and supports multiple expressions.
- `NVL` evaluates both arguments; this can matter for expensive expressions.
- `ROWNUM` is not a single-row function; it is a pseudocolumn.

## Related Notes
- Performance and analytics: [Window Functions and Analytics](../09%20Performance/01_Window_Functions_and_Analytics.md)
- View design and abstraction: [Views and Materialized Views](../07%20Views/01_Views_and_Materialized_Views.md)
