# SQL Sequences and Defaults Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Sequence** = Generates unique numeric values in order.
- **DEFAULT** = Supplies a value automatically when none is provided.
- **Why sequences matter** = They help create unique identifiers without manual logic.
- **Interview keyword** = Sequences are database objects, not table columns themselves.
- **Best use case** = Primary key generation for transactional systems.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Sequences and Defaults?](#1-why-do-we-need-sequences-and-defaults)
2. [What Is a Sequence?](#2-what-is-a-sequence)
3. [Creating and Using a Sequence](#3-creating-and-using-a-sequence)
4. [NEXTVAL and CURRVAL](#4-nextval-and-currval)
5. [DEFAULT Values](#5-default-values)
6. [Sequence vs Identity vs Manual ID Generation](#6-sequence-vs-identity-vs-manual-id-generation)
7. [Comparison Matrix](#7-comparison-matrix)
8. [Best Practices](#8-best-practices)
9. [Common Mistakes](#9-common-mistakes)
10. [Interview Q&A](#10-interview-qa)
11. [Revision Summary](#11-revision-summary)

---

## 1. Why Do We Need Sequences and Defaults?

### The Problem: Unique IDs and Missing Values Are Common

Applications often need:
- a unique row identifier for every record
- a default value when the user does not provide one

Without sequencing or defaults, developers may create duplicate IDs or depend on manual values.

**Problems with manual generation:**
- Duplicates can occur
- Multiple sessions may conflict
- Missing values create inconsistent records

### The Solution: Sequences and Defaults

A **sequence** provides unique numbers automatically, and a **default** gives a value when the user omits one.

### Real-World Scenarios

- **Banking:** create a new account ID
- **HR:** assign a new employee number
- **Log tables:** assign event IDs in order

---

**➡ Transition:** Let’s define what a sequence is and why Oracle uses it. 

---

## 2. What Is a Sequence?

### Simple Definition

A **sequence** is a database object that generates unique numeric values in order.

### Analogy: Real-World Comparison

**Think of a numbered ticket dispenser**:
- Every time you request a number, the database gives the next unique value
- Different sessions can safely consume different values

### Key Characteristics

- Generates numbers automatically
- Usually used for surrogate keys
- Keeps values unique and increasing
- Independent of table data

### Example

```sql
CREATE SEQUENCE emp_seq
START WITH 1
INCREMENT BY 1;
```

This generates 1, 2, 3, 4, ...

---

**➡ Transition:** The actual sequence value is retrieved using NEXTVAL and CURRVAL. 

---

## 3. Creating and Using a Sequence

### The Challenge

You want a database-managed numeric key for new rows.

### How It Works

You create the sequence once, then reference it whenever inserting rows.

### Syntax/Usage

```sql
CREATE SEQUENCE dept_seq
START WITH 1
INCREMENT BY 1
MAXVALUE 9999;
```

### Insert example

```sql
INSERT INTO departments (department_id, department_name)
VALUES (dept_seq.NEXTVAL, 'QA');
```

### Why It Matters

- Avoids duplicate key errors
- Simplifies automatic ID generation
- Works well with large multi-user systems

---

**➡ Transition:** The sequence has two commonly used values: NEXTVAL and CURRVAL. 

---

## 4. NEXTVAL and CURRVAL

### The Challenge

You need to generate or retrieve sequence values during inserts and queries.

### How It Works

- `NEXTVAL` returns the next value and advances the sequence
- `CURRVAL` returns the current value for the session

### Example

```sql
SELECT dept_seq.NEXTVAL FROM dual;
SELECT dept_seq.CURRVAL FROM dual;
```

### Insert with NEXTVAL

```sql
INSERT INTO employees (employee_id, first_name, last_name)
VALUES (emp_seq.NEXTVAL, 'John', 'Doe');
```

### Important Rule

`CURRVAL` can only be used after `NEXTVAL` has been called in the same session.

---

**➡ Transition:** A DEFAULT value is similar in idea, but it is assigned by the column definition instead of a separate database object. 

---

## 5. DEFAULT Values

### The Challenge

When a user does not provide a value, the database should supply a sensible one.

### How It Works

A column can have a default value assigned at the time of table creation or via `ALTER TABLE`.

### Syntax/Usage

```sql
CREATE TABLE employees (
    employee_id NUMBER PRIMARY KEY,
    first_name VARCHAR2(50),
    status VARCHAR2(20) DEFAULT 'ACTIVE',
    hire_date DATE DEFAULT SYSDATE
);
```

### Example

```sql
INSERT INTO employees (employee_id, first_name)
VALUES (1001, 'Alice');
```

The `status` will become `'ACTIVE'` and `hire_date` will use the current date automatically.

### Why It Matters

- Avoids nulls in required default fields
- Makes data entry easier
- Keeps application logic simpler

---

**➡ Transition:** We can now compare sequences with other ways to generate IDs. 

---

## 6. Sequence vs Identity vs Manual ID Generation

### The Challenge

There are several ways to generate identifiers, and the right one depends on the database and system.

### How It Works

| Method | Meaning | Best For |
| --- | --- | --- |
| Sequence | Database object generating unique numbers | Oracle, custom ID needs |
| Identity | Auto-generated column in many databases | Simple keys in modern DBs |
| Manual ID | Developer assigns value | Rare, controlled use |

### Oracle Example

```sql
CREATE SEQUENCE emp_seq START WITH 1 INCREMENT BY 1;
```

### Manual generation example

```sql
INSERT INTO employees (employee_id, first_name)
VALUES (500, 'Alice');
```

This is possible but error-prone in busy systems.

### Best Practice

For most application systems, database-generated IDs are safer than manual assignment.

---

## 7. Comparison Matrix

### Sequence vs Default Value

| Aspect | Sequence | Default |
| --- | --- | --- |
| **Purpose** | Generate unique values | Fill in missing values |
| **Object type** | Database object | Column property |
| **Used for** | IDs, keys, counters | Status, dates, flags |
| **Value behavior** | Increases each call | Constant or expression |
| **Typical example** | `emp_seq.NEXTVAL` | `status DEFAULT 'ACTIVE'` |

---

## 8. Best Practices

### 1. Use sequences for primary keys when the database does not auto-generate them

```sql
CREATE SEQUENCE emp_seq START WITH 1 INCREMENT BY 1;
```

**Why:** It provides unique numeric values across sessions.

---

### 2. Use default values for obvious business defaults

```sql
status VARCHAR2(20) DEFAULT 'ACTIVE'
```

**Why:** This preserves sensible filler data without application logic.

---

### 3. Do not manually assign IDs if a sequence already exists

**Why:** Manual assignment increases the chance of duplicates or inconsistent IDs.

---

## 9. Common Mistakes

### Mistake 1: Using CURRVAL before NEXTVAL

**Problem:** The current value does not exist yet in that session.

**Solution:** Call `NEXTVAL` first.

---

### Mistake 2: Forgetting that a sequence is a separate object

**Problem:** People assume a sequence is attached to a table automatically.

**Solution:** Use it explicitly in insert statements.

---

### Mistake 3: Setting defaults that hide bad input

**Problem:** A default can mask real user mistakes.

**Solution:** Use defaults only when the business rule truly supports them.

---

## 10. Interview Q&A

### Conceptual Questions

**Q: What is a sequence in Oracle?**
A: A sequence is a database object that generates a unique numeric value each time it is called, usually for keys.

---

**Q: What is a default value?**
A: A default value is automatically inserted into a column when a user does not provide one.

---

### Comparison Questions

**Q: What is the difference between a sequence and a default value?**
A: A sequence generates a new unique value every time it is used. A default assigns a chosen fallback value to a column when none is supplied.

---

### Scenario Questions

**Q: How do you create a new employee ID automatically?**
A:
```sql
CREATE SEQUENCE emp_seq START WITH 1 INCREMENT BY 1;

INSERT INTO employees (employee_id, first_name)
VALUES (emp_seq.NEXTVAL, 'Alice');
```

---

## 11. Revision Summary

### 1-Minute Recap

**Sequence** = generates unique values; **default** = fills missing values.

- **Sequence** → `NEXTVAL` gives unique numbers
- **CURRVAL** → current value in the session
- **Default** → value used when user leaves column blank
- **Goal** → better keys and cleaner data entry

### Interview Keywords

- **Surrogate key** → artificial unique identifier
- **Auto-generated ID** → DB-managed key
- **Database object** → sequence is separate from table
- **Default behavior** → fallback values

### Important Syntax

```sql
CREATE SEQUENCE emp_seq START WITH 1 INCREMENT BY 1;

INSERT INTO employees (employee_id, first_name)
VALUES (emp_seq.NEXTVAL, 'John');

CREATE TABLE employees (
    employee_id NUMBER PRIMARY KEY,
    status VARCHAR2(20) DEFAULT 'ACTIVE'
);
```

---

**Done!** Sequences and defaults are foundational for creating reliable keys and consistent records in production systems.
