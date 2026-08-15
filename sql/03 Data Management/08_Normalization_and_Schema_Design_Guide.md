# SQL Normalization and Schema Design Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Normalization** = Organizing data to reduce duplication and improve consistency.
- **1NF** = Each column should store atomic values, and each row should be unique.
- **2NF** = No partial dependency on a composite key.
- **3NF** = No transitive dependency; all non-key fields should depend only on the key.
- **Denormalization** = Intentionally reintroducing redundancy for performance or reporting.
- **Interview keyword** = Normalization reduces update anomalies and makes schema cleaner.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Normalization?](#1-why-do-we-need-normalization)
2. [What Is Normalization?](#2-what-is-normalization)
3. [1NF: First Normal Form](#3-1nf-first-normal-form)
4. [2NF: Second Normal Form](#4-2nf-second-normal-form)
5. [3NF: Third Normal Form](#5-3nf-third-normal-form)
6. [Denormalization](#6-denormalization)
7. [Comparison Matrix](#7-comparison-matrix)
8. [Best Practices](#8-best-practices)
9. [Common Mistakes](#9-common-mistakes)
10. [Interview Q&A](#10-interview-qa)
11. [Revision Summary](#11-revision-summary)

---

## 1. Why Do We Need Normalization?

### The Problem: Repeated and Inconsistent Data

When data is stored in a flat or repeated way, updates become difficult and inconsistent.

```text
Customer_ID | Customer_Name | Order_ID | Product_Name | Product_Price
1           | Alice         | 100      | Laptop       | 1200
1           | Alice         | 101      | Mouse        | 50
```

This repeats customer information and can create anomalies when the same customer changes.

**Problems with poor schema design:**
- Duplicate data
- Update anomalies
- Insert anomalies
- Delete anomalies

### The Solution: Normalization

Normalization organizes tables so each fact is stored once, in the appropriate place, with clear relationships.

### Real-World Scenarios

- **Sales systems:** Orders should reference customers, not repeat customer details everywhere.
- **HR systems:** Employee role and department details should not be duplicated across every row.
- **Reporting:** Clean relational design reduces join complexity and inconsistencies.

---

**➡ Transition:** What exactly is normalization in database terms? 

---

## 2. What Is Normalization?

### Simple Definition

**Normalization** is the process of designing tables so they store data efficiently, avoid redundancy, and reduce anomalies.

### Analogy: Real-World Comparison

**Think of filing cabinets**:
- A poor design stores the same information in many folders
- A normalized design stores each fact in the correct folder and links them by keys

### Key Characteristics

- Reduces duplication
- Improves data integrity
- Makes updates easier and safer
- Supports reliable joins and constraints

### Common Normal Forms

| Normal Form | Main Idea |
| --- | --- |
| 1NF | Atomic data, no repeated groups |
| 2NF | No partial dependency |
| 3NF | No transitive dependency |

---

**➡ Transition:** Let’s start with the first rule: each cell should hold a single value. 

---

## 3. 1NF: First Normal Form

### The Challenge

A table should not hold repeated values or grouped data in a single field.

### How It Works

1NF requires:
- Each column has a single value
- Each row is unique
- No repeating groups

### Example of a non-1NF table

```text
Customer_ID | Products
1           | Laptop, Mouse, Monitor
```

This violates 1NF because one column stores multiple values.

### 1NF Example

```text
Customer_ID | Product
1           | Laptop
1           | Mouse
1           | Monitor
```

This is much cleaner because each row stores a single product entry.

### Why It Matters

- Easier to query
- Better for indexing and joins
- Avoids repeated values in one field

---

**➡ Transition:** The next form addresses dependencies inside a composite key. 

---

## 4. 2NF: Second Normal Form

### The Challenge

A table with a composite key should not have attributes depending only on part of that key.

### How It Works

2NF requires that data be in 1NF and that every non-key attribute be fully dependent on the whole primary key.

### Example

```text
Order_ID | Product_ID | Product_Name | Quantity
100       | 1          | Laptop       | 2
100       | 2          | Mouse        | 3
```

Here **Product_Name** depends on `Product_ID`, not on the full composite key (`Order_ID + Product_ID`).

### Better design

```text
Orders (Order_ID, Customer_ID, Order_Date)
Order_Items (Order_ID, Product_ID, Quantity)
Products (Product_ID, Product_Name, Product_Price)
```

This eliminates partial dependencies and keeps table roles clear.

### Why It Matters

- Prevents redundancy
- Makes updates more stable
- Usually supports cleaner schema design

---

**➡ Transition:** 3NF further removes indirect dependencies, so non-key data depends only on the key. 

---

## 5. 3NF: Third Normal Form

### The Challenge

A non-key column should not depend on another non-key column.

### How It Works

3NF requires that a table is in 2NF and every non-key attribute depends only on the primary key, not on other non-key attributes.

### Example of a violation

```text
Employee_ID | Department_ID | Department_Name
101         | 10            | IT
```

Here `Department_Name` depends on `Department_ID`, not on `Employee_ID` directly.

### Better design

```text
Employees (Employee_ID, Name, Department_ID)
Departments (Department_ID, Department_Name)
```

This removes the transitive dependency.

### Why It Matters

- Reduces data duplication
- Prevents inconsistent department names
- Helps maintain clean report queries

---

**➡ Transition:** Normalized design is ideal for consistency, but sometimes a database intentionally adds redundancy. 

---

## 6. Denormalization

### The Challenge

In analytics or reporting systems, too many joins may slow down queries.

### How It Works

**Denormalization** intentionally adds redundancy to reduce joins and improve read performance.

### Example

```text
Sales_Report (Order_ID, Customer_Name, Product_Name, Quantity, Total_Amount)
```

This stores data together for faster reporting, even if it repeats information.

### When to Use It

- Data warehouses
- Reporting tables
- Read-heavy analytics systems

### Trade-off

Denormalization improves read performance but reduces normalization benefits like update simplicity and data consistency.

---

## 7. Comparison Matrix

### Normalization vs Denormalization

| Aspect | Normalized Schema | Denormalized Schema |
| --- | --- | --- |
| **Redundancy** | Low | Higher |
| **Update complexity** | Easier to maintain | Harder to keep consistent |
| **Read performance** | Often slower with joins | Faster for reads |
| **Best for** | OLTP / transactional systems | Reporting / analytics |
| **Data integrity** | Stronger | More vulnerable |

---

## 8. Best Practices

### 1. Normalize transactional data first

**Why:** OLTP systems need correctness and clean relationships.

**Prefer:**
```text
Customers, Orders, Order_Items, Products
```

### 2. Use keys and constraints to enforce relationships

```sql
CREATE TABLE orders (
    order_id NUMBER PRIMARY KEY,
    customer_id NUMBER NOT NULL,
    CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
```

**Why:** Schema design should rely on keys and constraints, not ad hoc application logic.

---

### 3. Denormalize only for reporting performance when needed

**Why:** Reporting systems may require pre-joined data, but transactional systems should stay normalized.

---

## 9. Common Mistakes

### Mistake 1: Storing repeated customer or product details in every order row

**Problem:** Ties customer or product data to every order and causes redundancy.

**Solution:** Store shared data in separate tables and link them by keys.

---

### Mistake 2: Using non-key columns to derive other values

**Problem:** This creates transitive dependency and can make updates inconsistent.

**Solution:** Put those values in their own table or base them on the actual key.

---

### Mistake 3: Denormalizing too early

**Problem:** The design becomes hard to maintain.

**Solution:** Keep OLTP tables normalized and build reporting tables separately if needed.

---

## 10. Interview Q&A

### Conceptual Questions

**Q: What is normalization?**
A: Normalization is the process of structuring a database so data is stored efficiently, without unnecessary repetition, and with clear relationships.

---

**Q: Why is 3NF important?**
A: It reduces transitive dependencies and keeps non-key attributes dependent only on the primary key, which improves consistency.

---

### Comparison Questions

**Q: What is the difference between normalization and denormalization?**
A: Normalization improves data integrity by reducing redundancy, while denormalization intentionally adds redundancy for faster read-heavy reporting.

---

### Scenario Questions

**Q: A table stores customer name and product name in every order row. What is the problem?**
A: This duplicates data and can cause update anomalies. The correct design separates customers, products, and orders and links them through keys.

---

## 11. Revision Summary

### 1-Minute Recap

**Normalization** = Organize tables to reduce redundancy and improve integrity.

- **1NF** → atomic values, no repeated groups
- **2NF** → no partial dependency on composite keys
- **3NF** → no transitive dependency
- **Denormalization** → intentional redundancy for reporting speed

### Interview Keywords

- **Atomic** → single value per field
- **Redundancy** → repeated data
- **Transitive dependency** → indirect dependence on another non-key
- **Data integrity** → reliable and consistent data
- **OLTP vs OLAP** → transactional vs analytical workloads

### Important Syntax

```sql
CREATE TABLE orders (
    order_id NUMBER PRIMARY KEY,
    customer_id NUMBER NOT NULL,
    order_date DATE
);

CREATE TABLE order_items (
    order_id NUMBER,
    product_id NUMBER,
    quantity NUMBER,
    CONSTRAINT pk_order_items PRIMARY KEY (order_id, product_id)
);
```

---

**Done!** Good schema design starts by separating facts into the right tables and ensuring each relationship is defined clearly.
