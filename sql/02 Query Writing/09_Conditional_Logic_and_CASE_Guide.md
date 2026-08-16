# SQL Conditional Logic and CASE Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **CASE** = Conditional expression used inside SELECT, WHERE, ORDER BY, and other clauses.
- **Simple CASE** = Compares a single expression to multiple values.
- **Searched CASE** = Evaluates boolean conditions.
- **COALESCE** = Returns the first non-null value from a list.
- **NULLIF** = Returns NULL when two expressions are equal.
- **Interview keyword** = CASE makes SQL dynamic and readable without writing multiple queries.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Conditional Logic?](#1-why-do-we-need-conditional-logic)
2. [What Is CASE in SQL?](#2-what-is-case-in-sql)
3. [Simple CASE Expression](#3-simple-case-expression)
4. [Searched CASE Expression](#4-searched-case-expression)
5. [COALESCE and NULLIF](#5-coalesce-and-nullif)
6. [CASE in WHERE and ORDER BY](#6-case-in-where-and-order-by)
7. [Comparison Matrix](#7-comparison-matrix)
8. [Best Practices](#8-best-practices)
9. [Common Mistakes](#9-common-mistakes)
10. [Interview Q&A](#10-interview-qa)
11. [Revision Summary](#11-revision-summary)

---

## 1. Why Do We Need Conditional Logic?

### The Problem: Real Data Is Not Always Uniform

A business rule may say:
- If salary is above 10000, label as “High”
- If it is between 5000 and 10000, label as “Medium”
- Otherwise, label as “Low”

Without conditional logic, SQL can only return raw values, not business categories.

**Problems with raw output:**
- Reporting is less readable
- Business rules are hidden in application code
- Data grouping becomes harder to explain

### The Solution: CASE Expressions

CASE lets you transform values based on rules without splitting queries into many branches.

### Real-World Scenarios

- **HR:** classify employees by salary band
- **Sales:** label orders as “Priority”, “Normal”, or “Low”
- **Finance:** show payment status based on due date and amount

---

**➡ Transition:** Now that we know why conditional logic matters, let’s define CASE clearly. 

---

## 2. What Is CASE in SQL?

### Simple Definition

A **CASE expression** is SQL logic that returns different values depending on conditions.

It is similar to an IF-ELSE structure, but it works inside a query.

### Analogy: Real-World Comparison

**Think of a decision tree**:
- Check one condition
- If true, return one result
- Else check another condition
- Otherwise return a default value

### Key Characteristics

- Works inside `SELECT`, `WHERE`, `ORDER BY`
- Can replace multiple if-else checks in one query
- Makes reports more readable
- Helps with data classification and formatting

### Types of CASE

| Type | When to Use | Example |
| --- | --- | --- |
| Simple CASE | Compare one expression to values | `CASE department_id WHEN 10 THEN 'IT'` |
| Searched CASE | Evaluate conditions | `CASE WHEN salary > 10000 THEN 'High'` |

---

**➡ Transition:** Let’s look at the simple CASE variant first. 

---

## 3. Simple CASE Expression

### The Challenge

You want to map one value to a display category.

### How It Works

`CASE expr WHEN value1 THEN result1 WHEN value2 THEN result2 ELSE default END`

### Syntax/Usage

```sql
SELECT employee_id,
       CASE department_id
           WHEN 10 THEN 'Administration'
           WHEN 20 THEN 'Marketing'
           ELSE 'Other'
       END AS department_group
FROM employees;
```

### Example

```sql
SELECT first_name, department_id,
       CASE department_id
           WHEN 10 THEN 'IT'
           WHEN 20 THEN 'Sales'
           WHEN 30 THEN 'Finance'
           ELSE 'Other'
       END AS department_name
FROM employees;
```

**Output:**

```text
FIRST_NAME  DEPARTMENT_ID DEPARTMENT_NAME
----------  ------------- ---------------
Steven      10            IT
Neena       20            Sales
Lex         30            Finance
```

### When to Use It

- Mapping a single column to labels
- Converting codes to user-friendly values
- Creating categories for reporting

---

**➡ Transition:** When conditions are more flexible than equality checks, use searched CASE. 

---

## 4. Searched CASE Expression

### The Challenge

The logic is not based on a single exact value but on a range or comparison.

### How It Works

`CASE WHEN condition1 THEN result1 WHEN condition2 THEN result2 ELSE default END`

### Syntax/Usage

```sql
SELECT first_name, salary,
       CASE
           WHEN salary >= 15000 THEN 'High'
           WHEN salary >= 8000 THEN 'Medium'
           ELSE 'Low'
       END AS salary_band
FROM employees;
```

### Example

```sql
SELECT employee_id, salary,
       CASE
           WHEN salary > 20000 THEN 'Executive'
           WHEN salary BETWEEN 10000 AND 20000 THEN 'Manager'
           ELSE 'Staff'
       END AS role_band
FROM employees;
```

**Output:**

```text
EMPLOYEE_ID SALARY ROLE_BAND
----------- ------ ---------
100         24000  Executive
101         17000  Manager
102         9000   Staff
```

### Why It Is More Powerful

Searched CASE supports:
- ranges
- comparisons
- `AND` / `OR` conditions
- multi-condition classification

---

**➡ Transition:** CASE is often used together with helper functions like COALESCE and NULLIF. 

---

## 5. COALESCE and NULLIF

### The Challenge

SQL often has missing data, and you want to handle it gracefully.

### How It Works

- `COALESCE(value1, value2, ...)` returns the first non-null value
- `NULLIF(value1, value2)` returns NULL if both values are equal; otherwise returns value1

### Syntax/Usage

```sql
SELECT COALESCE(manager_id, 0) AS manager_id
FROM employees;
```

### Example: COALESCE

```sql
SELECT first_name,
       COALESCE(phone_number, 'No Phone') AS phone_info
FROM employees;
```

This replaces missing values with a default label.

### Example: NULLIF

```sql
SELECT NULLIF(salary, 0) AS normalized_salary
FROM employees;
```

If salary is 0, it becomes NULL; otherwise it stays as salary.

### Why These Matter

- `COALESCE` handles missing values elegantly
- `NULLIF` helps avoid divide-by-zero or unwanted equality results

---

**➡ Transition:** CASE can also be used in WHERE and ORDER BY to build dynamic logic into filtering and sort behavior. 

---

## 6. CASE in WHERE and ORDER BY

### The Challenge

You want to filter or sort based on conditions that are not directly stored as a column.

### How It Works

CASE expressions can be used to compute a temporary classification and then use it in `WHERE` or `ORDER BY`.

### Example: CASE in WHERE

```sql
SELECT *
FROM employees
WHERE CASE
          WHEN salary > 15000 THEN 'High'
          ELSE 'Low'
      END = 'High';
```

### Example: CASE in ORDER BY

```sql
SELECT employee_id, first_name, salary
FROM employees
ORDER BY CASE
             WHEN salary >= 15000 THEN 1
             ELSE 2
         END,
         salary DESC;
```

This sorts high earners first.

### Important Note

CASE in `WHERE` can make logic more complex; sometimes a simpler boolean condition is clearer. Use it when it improves readability or expresses business rules.

---

## 7. Comparison Matrix

### CASE, COALESCE, and NULLIF

| Aspect | CASE | COALESCE | NULLIF |
| --- | --- | --- | --- |
| **Purpose** | Conditional output | First non-null value | Convert equal values to NULL |
| **Usage** | Rules and categories | Missing-data handling | Equality guard |
| **Complexity** | Flexible | Simple | Simple |
| **Best for** | Business logic | Clean defaulting | Remove unwanted equal values |

---

## 8. Best Practices

### 1. Use `ELSE` to avoid unexpected NULLs

**Avoid:**
```sql
CASE WHEN salary > 10000 THEN 'High' END
```

**Prefer:**
```sql
CASE WHEN salary > 10000 THEN 'High' ELSE 'Low' END
```

**Why:** A default value prevents ambiguous output.

---

### 2. Keep CASE logic readable and ordered

```sql
CASE
    WHEN salary >= 15000 THEN 'High'
    WHEN salary >= 8000 THEN 'Medium'
    ELSE 'Low'
END
```

**Why:** Putting the higher priority rules first is simpler to reason about.

---

### 3. Use COALESCE for default values instead of raw NVL patterns where possible

```sql
COALESCE(manager_id, 0)
```

**Why:** It is more general and can handle multiple fallback values clearly.

---

## 9. Common Mistakes

### Mistake 1: Forgetting the END keyword

**Problem:** SQL will not compile if CASE is not closed.

```sql
CASE WHEN salary > 10000 THEN 'High'
```

**Solution:**
```sql
CASE WHEN salary > 10000 THEN 'High' ELSE 'Low' END
```

---

### Mistake 2: Using CASE with no ELSE and expecting a value

**Problem:** Missing conditions return NULL.

**Solution:** Add an `ELSE` for a fallback result.

---

### Mistake 3: Putting logic in ORDER BY with no clarity

**Problem:** Hard-to-read sorting rules make maintenance difficult.

**Solution:** Use a clean CASE expression with good aliasing and comments if needed.

---

## 10. Interview Q&A

### Conceptual Questions

**Q: What is CASE in SQL?**
A: CASE is a conditional expression that returns different results based on rules, similar to if-else logic in programming.

---

**Q: When do we use COALESCE?**
A: We use COALESCE to replace NULLs with a useful default value.

---

### Comparison Questions

**Q: What is the difference between CASE and COALESCE?**
A: CASE evaluates conditions and returns different values. COALESCE simply returns the first non-null value from a list.

---

### Scenario Questions

**Q: Show employees in salary bands: High, Medium, Low.**
A:
```sql
SELECT first_name, salary,
       CASE
           WHEN salary >= 15000 THEN 'High'
           WHEN salary >= 8000 THEN 'Medium'
           ELSE 'Low'
       END AS salary_band
FROM employees;
```

---

## 11. Revision Summary

### 1-Minute Recap

**CASE** = SQL conditional logic.

- **Simple CASE** → compare one value to others
- **Searched CASE** → evaluate conditions
- **COALESCE** → first non-null value
- **NULLIF** → return NULL on equality
- **CASE in WHERE / ORDER BY** → dynamic filtering and sorting

### Interview Keywords

- **Conditional expression** → rules-based value selection
- **IF-ELSE equivalent** → CASE logic
- **NULL handling** → COALESCE and NULLIF
- **Classification** → salary bands, status labels

### Important Syntax

```sql
SELECT employee_id,
       CASE department_id
           WHEN 10 THEN 'IT'
           WHEN 20 THEN 'Sales'
           ELSE 'Other'
       END AS dept_group
FROM employees;

SELECT first_name,
       COALESCE(manager_id, 0) AS manager_id
FROM employees;

SELECT NULLIF(0, 0) AS result
FROM dual;
```

---

**Done!** CASE expressions are one of the most useful SQL tools because they let you encode real business logic directly inside the query.
