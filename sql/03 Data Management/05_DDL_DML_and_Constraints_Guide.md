# SQL DDL, DML, and Constraints Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **DDL** = Data Definition Language; creates or changes database objects.
- **DML** = Data Manipulation Language; inserts, updates, or deletes table data.
- **CREATE TABLE** = Defines a new table structure.
- **ALTER TABLE** = Modifies an existing table.
- **INSERT / UPDATE / DELETE** = Changes row data.
- **Constraints** = Rules that enforce valid data.
- **Interview keyword** = Good schema design prevents bad data before it enters the system.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need DDL, DML, and Constraints?](#1-why-do-we-need-ddl-dml-and-constraints)
2. [What Are DDL and DML?](#2-what-are-ddl-and-dml)
3. [CREATE TABLE and Data Types](#3-create-table-and-data-types)
4. [ALTER TABLE and DROP TABLE](#4-alter-table-and-drop-table)
5. [INSERT, UPDATE, and DELETE](#5-insert-update-and-delete)
6. [Constraints](#6-constraints)
7. [Comparison Matrix](#7-comparison-matrix)
8. [Best Practices](#8-best-practices)
9. [Common Mistakes](#9-common-mistakes)
10. [Interview Q&A](#10-interview-qa)
11. [Revision Summary](#11-revision-summary)

---

## 1. Why Do We Need DDL, DML, and Constraints?

### The Problem: Data Must Be Structured and Controlled

Without a table definition, there is no clear place to store information. Without DML, there is no way to load or maintain data. Without constraints, invalid records can slip in.

```sql
INSERT INTO employees VALUES ('John', 'Smith', 99999);
```

If the schema is weak, data quality gets poor very quickly.

**Problems with unstructured data handling:**
- Duplicate records
- Missing business keys
- Invalid department references
- Broken reporting results

### The Solution: Schema Design and Data Rules

DDL defines the structure. DML adds and updates the data. Constraints enforce business rules.

### Real-World Scenarios

- **Banking:** Account numbers must be unique and not null.
- **HR:** Employee IDs must be unique and valid.
- **Sales:** Orders must reference existing customers.

---

**➡ Transition:** Let’s define the two main SQL data languages before we dive into table creation and updates. 

---

## 2. What Are DDL and DML?

### Simple Definition

- **DDL (Data Definition Language)** defines database objects such as tables, views, indexes, and sequences.
- **DML (Data Manipulation Language)** manipulates row data in those objects.

### Key Characteristics

- **DDL** changes structure: `CREATE`, `ALTER`, `DROP`
- **DML** changes data: `INSERT`, `UPDATE`, `DELETE`
- **Constraints** enforce data validity and referential integrity

### Common Examples

```sql
CREATE TABLE employees (...);
ALTER TABLE employees ADD email VARCHAR2(100);
INSERT INTO employees (...) VALUES (...);
UPDATE employees SET salary = salary + 1000;
DELETE FROM employees WHERE employee_id = 101;
```

---

**➡ Transition:** DDL starts with creating a table and choosing the correct data types. 

---

## 3. CREATE TABLE and Data Types

### The Challenge

Each column needs a proper type and a clear purpose.

### How It Works

`CREATE TABLE` defines the column names, data types, and optional constraints.

### Syntax/Usage

```sql
CREATE TABLE employees (
    employee_id NUMBER(6) PRIMARY KEY,
    first_name VARCHAR2(50) NOT NULL,
    last_name VARCHAR2(50) NOT NULL,
    email VARCHAR2(100) UNIQUE,
    salary NUMBER(10,2),
    department_id NUMBER(4)
);
```

### Example

```sql
CREATE TABLE departments (
    department_id NUMBER(4) PRIMARY KEY,
    department_name VARCHAR2(50) NOT NULL,
    location_id NUMBER(4)
);
```

### Common Data Types

| Type | Use | Example |
| --- | --- | --- |
| NUMBER | Numeric values | `NUMBER(10,2)` |
| VARCHAR2 | Variable text | `VARCHAR2(50)` |
| DATE | Date and time | `DATE` |
| CHAR | Fixed-length text | `CHAR(5)` |
| CLOB | Large text objects | `CLOB` |

### Important Design Principles

- Use the smallest suitable type
- Match data semantics to the type
- Use constraints to prevent invalid values

---

**➡ Transition:** After a table exists, you may need to adjust its structure or remove it. 

---

## 4. ALTER TABLE and DROP TABLE

### The Challenge

Business requirements change. New columns may be required or old ones removed.

### How It Works

`ALTER TABLE` modifies columns, adds constraints, renames objects, or changes data definitions.

### Syntax/Usage

```sql
ALTER TABLE employees ADD hire_date DATE;
ALTER TABLE employees MODIFY salary NUMBER(12,2);
ALTER TABLE employees DROP COLUMN hire_date;
```

### Example

```sql
ALTER TABLE employees
ADD CONSTRAINT fk_dept_id
FOREIGN KEY (department_id) REFERENCES departments(department_id);
```

### DROP TABLE

```sql
DROP TABLE departments;
```

This removes the table and its data permanently.

### Best Practice

- Avoid dropping objects casually in production
- Check dependencies before dropping a table
- Back up before major schema changes

---

**➡ Transition:** Now that we know how to define structure, let’s manipulate the actual rows. 

---

## 5. INSERT, UPDATE, and DELETE

### The Challenge

The database must receive and maintain live business data.

### How It Works

These DML commands change rows inside an existing table.

### Syntax/Usage

```sql
INSERT INTO employees (employee_id, first_name, last_name, salary)
VALUES (100, 'John', 'Smith', 7500);
```

### Example

**INSERT**
```sql
INSERT INTO employees (employee_id, first_name, last_name, department_id, salary)
VALUES (101, 'Alice', 'Brown', 10, 9000);
```

**UPDATE**
```sql
UPDATE employees
SET salary = salary + 500
WHERE employee_id = 101;
```

**DELETE**
```sql
DELETE FROM employees
WHERE employee_id = 101;
```

### Important Notes

- `INSERT` can add one row or multiple rows
- `UPDATE` changes existing values
- `DELETE` removes rows permanently
- Always use `WHERE` carefully in `UPDATE` and `DELETE`

---

**➡ Transition:** Data quality rules are enforced through constraints. 

---

## 6. Constraints

### The Challenge

The database must reject invalid data automatically.

### How It Works

Constraints are rules placed on columns or tables to preserve integrity.

### Common Types of Constraints

| Constraint | Purpose | Example |
| --- | --- | --- |
| PRIMARY KEY | Unique row identifier | `employee_id` |
| FOREIGN KEY | Protects referential integrity | Department ID must exist |
| UNIQUE | Prevents duplicates | Email address |
| NOT NULL | Requires a value | Last name not null |
| CHECK | Enforces a condition | `salary > 0` |
| DEFAULT | Supplies a value when none is given | `hire_date DEFAULT SYSDATE` |

### Example

```sql
CREATE TABLE employees (
    employee_id NUMBER(6) PRIMARY KEY,
    first_name VARCHAR2(50) NOT NULL,
    email VARCHAR2(100) UNIQUE,
    salary NUMBER(10,2) CHECK (salary > 0),
    department_id NUMBER(4),
    CONSTRAINT fk_emp_dept
        FOREIGN KEY (department_id) REFERENCES departments(department_id)
);
```

### Why Constraints Matter

- Prevent duplicate or invalid records
- Preserve referential relationships
- Improve data quality and reporting reliability

### Normalization Connection

A well-normalized schema uses primary keys, foreign keys, and constraints to avoid data duplication and inconsistency.

---

## 7. Comparison Matrix

### DDL vs DML vs Constraints

| Aspect | DDL | DML | Constraints |
| --- | --- | --- | --- |
| **Purpose** | Create or change schema | Add/update/delete data | Enforce rules |
| **Examples** | CREATE, ALTER, DROP | INSERT, UPDATE, DELETE | PK, FK, CHECK |
| **Affects** | Table structure | Table rows | Data validity |
| **Used when** | Designing schema | Managing data | Protecting data quality |
| **Example** | Create employee table | Insert employee rows | Salary must be positive |

---

## 8. Best Practices

### 1. Define keys before loading data

**Avoid:**
```sql
INSERT INTO employees (first_name, last_name)
VALUES ('John', 'Smith');
```

**Prefer:**
```sql
INSERT INTO employees (employee_id, first_name, last_name)
VALUES (1001, 'John', 'Smith');
```

**Why:** Primary keys and foreign keys make data reliable and joinable.

---

### 2. Use constraints instead of application-side checks alone

**Why:** The database should protect data, not only the UI or application logic.

---

### 3. Restrict updates and deletes with WHERE carefully

```sql
DELETE FROM employees
WHERE employee_id = 101;
```

**Why:** The `WHERE` clause prevents accidental mass deletion.

---

## 9. Common Mistakes

### Mistake 1: Forgetting NOT NULL for required fields

**Problem:** Missing values enter the system.

**Solution:**
```sql
first_name VARCHAR2(50) NOT NULL
```

---

### Mistake 2: Creating foreign keys without matching parent rows

**Problem:** Child rows reference missing departments or customers.

**Solution:** Add the parent row first, or use a valid referential design.

---

### Mistake 3: Updating or deleting without a filter

**Problem:** This affects all rows in the table.

```sql
DELETE FROM employees;
```

**Solution:**
```sql
DELETE FROM employees
WHERE employee_id = 101;
```

---

## 10. Interview Q&A

### Conceptual Questions

**Q: What is the difference between DDL and DML?**
A: DDL changes the structure of a database object, while DML changes the actual rows or data inside those objects.

---

**Q: Why are constraints important?**
A: Constraints enforce data integrity, prevent invalid rows, and protect business rules such as uniqueness, non-null values, and valid references.

---

### Comparison Questions

**Q: What is the difference between UNIQUE and PRIMARY KEY?**
A: Both prevent duplicates, but a primary key is the main identity column for a table and is always NOT NULL. A table can have only one primary key, but multiple unique constraints.

---

### Scenario Questions

**Q: How would you prevent a new employee record from being inserted without a department?**
A: Use a foreign key from `employees.department_id` to `departments.department_id`, and make the column `NOT NULL` if required by business rule.

---

## 11. Revision Summary

### 1-Minute Recap

**DDL** defines tables, **DML** changes records, and **constraints** protect data quality.

- **CREATE TABLE** → defines the structure
- **ALTER TABLE** → changes the structure
- **INSERT** → adds row data
- **UPDATE** → modifies existing data
- **DELETE** → removes data
- **PK/FK/UNIQUE/CHECK** → enforce business rules

### Interview Keywords

- **Schema** → Structure of database objects
- **Integrity** → Correctness and validity of data
- **Referential integrity** → Parent/child relationship enforcement
- **Data quality** → Reliable and valid data
- **Business rule** → Constraint that reflects policy

### Important Syntax

```sql
CREATE TABLE departments (
    department_id NUMBER PRIMARY KEY,
    department_name VARCHAR2(50) NOT NULL
);

INSERT INTO departments (department_id, department_name)
VALUES (10, 'IT');

UPDATE employees
SET salary = salary + 1000
WHERE employee_id = 101;

DELETE FROM employees
WHERE employee_id = 101;
```

---

**Done!** Good database design is not just about storing rows—it is about making sure the right rows are stored in the right structure with the correct rules.
