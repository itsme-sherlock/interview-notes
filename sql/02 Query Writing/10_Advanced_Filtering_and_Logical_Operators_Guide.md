# SQL Advanced Filtering and Logical Operators Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **WHERE** = Filters rows before final output.
- **AND / OR / NOT** = Combine conditions in logical expressions.
- **IN** = Checks if a value matches any item in a list.
- **BETWEEN** = Matches a value within a range.
- **LIKE** = Matches pattern-based strings.
- **IS NULL / IS NOT NULL** = Checks for missing values.
- **Interview keyword** = NULL is not equal to anything, so it must be checked explicitly.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Advanced Filtering?](#1-why-do-we-need-advanced-filtering)
2. [What Are Logical Operators?](#2-what-are-logical-operators)
3. [AND, OR, and NOT](#3-and-or-and-not)
4. [IN, BETWEEN, and LIKE](#4-in-between-and-like)
5. [NULL Handling](#5-null-handling)
6. [Precedence and Evaluation Order](#6-precedence-and-evaluation-order)
7. [Comparison Matrix](#7-comparison-matrix)
8. [Best Practices](#8-best-practices)
9. [Common Mistakes](#9-common-mistakes)
10. [Interview Q&A](#10-interview-qa)
11. [Revision Summary](#11-revision-summary)

---

## 1. Why Do We Need Advanced Filtering?

### The Problem: A Simple Equality Check Is Not Enough

A report may need to show:
- employees in departments 10 or 20
- salaries between 5000 and 10000
- names beginning with 'S'
- rows with no manager assigned

A simple `WHERE salary = 5000` does not cover these cases.

**Problems with limited filtering:**
- You miss important records
- Business logic is hard to express
- Null conditions behave unexpectedly

### The Solution: Advanced Filtering Logic

SQL provides logical operators and pattern predicates to express complex rules clearly.

### Real-World Scenarios

- **Customer reports:** customers in specific regions or tiers
- **Payroll:** salaries in certain ranges
- **Support systems:** unresolved tickets with no owner

---

**➡ Transition:** Let’s define the core logical operators and how they work together. 

---

## 2. What Are Logical Operators?

### Simple Definition

Logical operators combine or negate conditions in a SQL `WHERE` clause.

### Key Characteristics

- Build complex filters from smaller conditions
- Support business rules
- Can combine positive and negative checks
- Must be carefully ordered to avoid wrong results

### Common Operators

| Operator | Meaning |
| --- | --- |
| AND | Both conditions must be true |
| OR | At least one condition must be true |
| NOT | Reverses a condition |

---

**➡ Transition:** Let’s see the most common pattern: combining conditions with AND and OR. 

---

## 3. AND, OR, and NOT

### The Challenge

You need to filter rows using multiple business rules.

### How It Works

- `AND` narrows the result set
- `OR` broadens the result set
- `NOT` excludes matched rows

### Syntax/Usage

```sql
SELECT *
FROM employees
WHERE department_id = 10
  AND salary > 5000;
```

### Example

**Example 1: AND**

```sql
SELECT *
FROM employees
WHERE department_id = 20
  AND salary > 8000;
```

This returns only employees in department 20 with salary above 8000.

**Example 2: OR**

```sql
SELECT *
FROM employees
WHERE department_id = 10
   OR department_id = 20;
```

This returns employees from either department.

**Example 3: NOT**

```sql
SELECT *
FROM employees
WHERE NOT department_id = 30;
```

This returns everything except department 30.

### Important Rule

`AND` and `OR` can change the meaning of a query dramatically. Parentheses are often necessary.

```sql
WHERE (department_id = 10 OR department_id = 20)
  AND salary > 8000;
```

---

**➡ Transition:** A few special operators make range and pattern checks easy. 

---

## 4. IN, BETWEEN, and LIKE

### The Challenge

You need concise filters for sets, ranges, and text patterns.

### How It Works

- `IN` checks membership in a list
- `BETWEEN` checks inclusion within a range
- `LIKE` matches pattern-based text

### Syntax/Usage

```sql
SELECT *
FROM employees
WHERE department_id IN (10, 20, 30);
```

### Example

**IN**

```sql
SELECT *
FROM employees
WHERE first_name IN ('John', 'Alice', 'Steven');
```

**BETWEEN**

```sql
SELECT *
FROM employees
WHERE salary BETWEEN 5000 AND 15000;
```

**LIKE**

```sql
SELECT *
FROM employees
WHERE first_name LIKE 'S%';
```

This matches names starting with S.

### Wildcards

| Wildcard | Meaning |
| --- | --- |
| `%` | Any number of characters |
| `_` | Exactly one character |

### Example with wildcard

```sql
SELECT *
FROM employees
WHERE email LIKE '%@gmail.com';
```

This matches all email addresses ending in `@gmail.com`.

---

**➡ Transition:** NULLs need special handling because they are not normal values. 

---

## 5. NULL Handling

### The Challenge

`NULL` means “unknown” or “missing,” not zero or empty string.

### How It Works

Expressions with `NULL` do not behave like normal values. You must test for `NULL` explicitly.

### Syntax/Usage

```sql
SELECT *
FROM employees
WHERE manager_id IS NULL;
```

### Example

```sql
SELECT *
FROM employees
WHERE manager_id IS NOT NULL;
```

### Key Point

```sql
WHERE manager_id = NULL
```

This is never true.

### Why It Matters

- Missing values are common in real systems
- Business rules often depend on “has no manager” or “has no end date”
- Proper NULL logic is a common interview topic

---

**➡ Transition:** The order of evaluation matters when conditions are mixed together. 

---

## 6. Precedence and Evaluation Order

### The Challenge

A query with many conditions can be misread if you do not understand precedence.

### How It Works

SQL evaluates conditions in a predictable order, but parentheses make logic clear and safe.

### Example

```sql
WHERE department_id = 10 OR department_id = 20 AND salary > 8000
```

This is not the same as:

```sql
WHERE (department_id = 10 OR department_id = 20) AND salary > 8000
```

### Best Practice

Always use parentheses when mixing `AND` and `OR`.

### Example with safe grouping

```sql
WHERE (department_id IN (10, 20) AND salary > 8000)
   OR department_id = 30;
```

This is easier to understand and less error-prone.

---

## 7. Comparison Matrix

### Filtering Operators Compared

| Operator | Use Case | Example |
| --- | --- | --- |
| AND | Require both conditions | `salary > 5000 AND dept = 10` |
| OR | Either condition may match | `dept = 10 OR dept = 20` |
| IN | Match any value in a list | `dept IN (10,20,30)` |
| BETWEEN | Match a range | `salary BETWEEN 5000 AND 10000` |
| LIKE | Match text pattern | `name LIKE 'S%'` |
| IS NULL | Missing value check | `manager_id IS NULL` |

---

## 8. Best Practices

### 1. Use parentheses whenever AND and OR are mixed

**Avoid:**
```sql
WHERE department_id = 10 OR department_id = 20 AND salary > 8000
```

**Prefer:**
```sql
WHERE (department_id = 10 OR department_id = 20)
  AND salary > 8000
```

**Why:** It makes the logic intentional and correct.

---

### 2. Use IN for list checks instead of repeated ORs

```sql
WHERE department_id IN (10, 20, 30)
```

**Why:** Simpler and more readable.

---

### 3. Check NULL explicitly

```sql
WHERE manager_id IS NULL
```

**Why:** `= NULL` is not valid logic.

---

## 9. Common Mistakes

### Mistake 1: Using `= NULL` instead of `IS NULL`

**Problem:** This never returns true.

```sql
WHERE manager_id = NULL;
```

**Solution:**
```sql
WHERE manager_id IS NULL;
```

---

### Mistake 2: Forgetting parentheses with mixed logic

**Problem:** A query may match too many or too few rows.

**Solution:** Group conditions intentionally.

---

### Mistake 3: Using LIKE without understanding wildcards

**Problem:** `%` and `_` can match more than expected.

**Solution:** Use the right wildcard pattern for the business need.

---

## 10. Interview Q&A

### Conceptual Questions

**Q: What is the difference between AND and OR?**
A: `AND` requires all conditions to be true. `OR` requires at least one condition to be true.

---

**Q: Why do we use `IS NULL` instead of `= NULL`?**
A: Because `NULL` represents an unknown value, and SQL requires explicit null checks with `IS NULL` or `IS NOT NULL`.

---

### Comparison Questions

**Q: When should you use IN instead of OR?**
A: Use `IN` when comparing one column to a list of values. It is cleaner and easier to maintain than repeated `OR` conditions.

---

### Scenario Questions

**Q: Find all employees in departments 10, 20, or 30 whose salary is above 5000.**
A:
```sql
SELECT *
FROM employees
WHERE department_id IN (10, 20, 30)
  AND salary > 5000;
```

---

## 11. Revision Summary

### 1-Minute Recap

**Filtering logic** = using SQL predicates to decide which rows are included.

- **AND** → both conditions must match
- **OR** → either condition may match
- **NOT** → exclude a condition
- **IN** → value is in a list
- **BETWEEN** → value is in a range
- **LIKE** → pattern-based string match
- **IS NULL** → explicit missing-value check

### Interview Keywords

- **Predicate** → a condition in a WHERE clause
- **Precedence** → evaluation order of conditions
- **NULL** → unknown or missing value
- **Pattern match** → `LIKE` with `%` and `_`
- **Business filter** → rule-based row selection

### Important Syntax

```sql
SELECT *
FROM employees
WHERE department_id IN (10, 20, 30)
  AND salary BETWEEN 5000 AND 15000;

SELECT *
FROM employees
WHERE first_name LIKE 'S%';

SELECT *
FROM employees
WHERE manager_id IS NULL;
```

---

**Done!** Advanced filtering is the core of practical SQL because most reports depend on selecting exactly the right set of rows.
