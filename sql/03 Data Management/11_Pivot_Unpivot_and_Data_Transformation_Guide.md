# SQL Pivot, Unpivot, and Data Transformation Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Pivot** = Rotates rows into columns for reporting.
- **Unpivot** = Rotates columns back into rows.
- **Transformation** = Reshaping data for analysis or presentation.
- **Best use case** = Reporting summaries and cross-tab analysis.
- **Interview keyword** = Pivot changes the shape of the data, not the values themselves.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Pivot and Unpivot?](#1-why-do-we-need-pivot-and-unpivot)
2. [What Is Pivoting?](#2-what-is-pivoting)
3. [Simple Pivot Example](#3-simple-pivot-example)
4. [Unpivot Example](#4-unpivot-example)
5. [Data Transformation Concepts](#5-data-transformation-concepts)
6. [Comparison Matrix](#7-comparison-matrix)
7. [Best Practices](#8-best-practices)
8. [Common Mistakes](#9-common-mistakes)
9. [Interview Q&A](#10-interview-qa)
10. [Revision Summary](#11-revision-summary)

---

## 1. Why Do We Need Pivot and Unpivot?

### The Problem: Data Comes in Different Shapes

Sometimes data is stored in a long format, but reporting requires a wide format.

```text
Month    Sales
Jan      100
Feb      150
Mar      200
```

A report may want:

```text
Jan | Feb | Mar
100 | 150 | 200
```

**Problems with raw shape:**
- Not suitable for dashboard layout
- Hard to compare categories side by side
- Difficult for management reporting

### The Solution: Pivot and Unpivot

These features reshape the same data into a more readable or machine-friendly layout.

### Real-World Scenarios

- **Finance:** monthly revenue by month in columns
- **HR:** employees by department and status
- **Operations:** compare actual vs target by quarter

---

**➡ Transition:** What does pivoting actually do? 

---

## 2. What Is Pivoting?

### Simple Definition

**Pivot** transforms data from rows into a columnar layout, typically grouping by one dimension and showing metrics as columns.

### Analogy: Real-World Comparison

**Think of turning a list into a table**:
- Instead of many rows under one category,
- you arrange values into columns for comparison.

### Key Characteristics

- Rows become columns
- Grouping columns remain visible
- Used for reporting and cross-tab analysis
- Not a database table change; it is a query transformation

---

**➡ Transition:** Let’s look at a basic pivot example. 

---

## 3. Simple Pivot Example

### The Challenge

You want to see totals by month in one row, not many rows.

### How It Works

```sql
SELECT *
FROM (
    SELECT month_name, sales_amount
    FROM sales_data
)
PIVOT (
    SUM(sales_amount)
    FOR month_name IN ('Jan' AS jan_sales, 'Feb' AS feb_sales, 'Mar' AS mar_sales)
);
```

### Example Input

```text
MONTH_NAME SALES_AMOUNT
Jan        100
Feb        150
Mar        200
```

### Output

```text
JAN_SALES FEB_SALES MAR_SALES
100       150       200
```

### Why It Matters

This makes comparisons across months straightforward in reports.

---

**➡ Transition:** The inverse operation is unpivot, which turns columns back into row values. 

---

## 4. Unpivot Example

### The Challenge

You have a wide report table and need to normalize it into rows for analysis.

### How It Works

`UNPIVOT` turns multiple columns into one value column plus a category column.

### Syntax/Usage

```sql
SELECT *
FROM sales_wide
UNPIVOT (
    sales_amount FOR month_name IN (jan_sales AS 'Jan', feb_sales AS 'Feb', mar_sales AS 'Mar')
);
```

### Example Input

```text
JAN_SALES FEB_SALES MAR_SALES
100       150       200
```

### Output

```text
MONTH_NAME SALES_AMOUNT
Jan        100
Feb        150
Mar        200
```

### Why It Matters

Unpivot is often used to normalize data before further analysis or loading into a fact table.

---

**➡ Transition:** Pivot and unpivot are examples of broader data transformation patterns. 

---

## 5. Data Transformation Concepts

### The Challenge

Data is often stored in a shape that does not match the required reporting or analysis structure.

### How It Works

Transformations reshape the data for readability, aggregation, or downstream processing.

### Common Transformations

- Column-to-row conversion
- Row-to-column conversion
- Filtered aggregation
- Derived calculations
- String-to-date conversion

### Example

```sql
SELECT department_id,
       SUM(CASE WHEN status = 'ACTIVE' THEN 1 ELSE 0 END) AS active_count,
       SUM(CASE WHEN status = 'INACTIVE' THEN 1 ELSE 0 END) AS inactive_count
FROM employees
GROUP BY department_id;
```

This transforms row-based employee statuses into a summarized report format.

### Key Idea

Transformation does not change the underlying business fact; it changes how the fact is presented.

---

## 6. Comparison Matrix

### Pivot vs Unpivot vs CASE-based shaping

| Aspect | Pivot | Unpivot | CASE-based shaping |
| --- | --- | --- | --- |
| **Purpose** | Convert rows to columns | Convert columns to rows | Compute conditional analysis |
| **Best use** | Cross-tab reports | Normalization | Business grouping |
| **Complexity** | Moderate | Moderate | Simple to moderate |
| **Output shape** | Wide | Long | Flexible |

---

## 7. Best Practices

### 1. Use pivot only when the output shape is truly needed

**Why:** It can make queries bulkier and harder to maintain when a simple grouped query is enough.

---

### 2. Normalize data before analytical transforms when possible

**Why:** A normal form is easier to maintain and validate before pivoting.

---

### 3. Use explicit aliases for transformed columns

```sql
PIVOT (SUM(amount) FOR month_name IN ('Jan' AS jan_amt, 'Feb' AS feb_amt))
```

**Why:** Clear alias names make the output readable.

---

## 8. Common Mistakes

### Mistake 1: Pivoting without clearly defining the aggregation

**Problem:** The output may not make sense or may be ambiguous.

**Solution:** Always specify the aggregate function, such as `SUM`, `COUNT`, or `AVG`.

---

### Mistake 2: Forgetting to include the source column names precisely

**Problem:** The transformation may fail or produce incorrect columns.

**Solution:** Validate the input columns before pivoting or unpivoting.

---

### Mistake 3: Using pivot when simple CASE logic suffices

**Problem:** Over-complicated SQL adds maintenance cost.

**Solution:** Choose the simpler representation when the report is not a true matrix.

---

## 9. Interview Q&A

### Conceptual Questions

**Q: What is pivoting in SQL?**
A: Pivoting turns row-based data into a column-based report format, often for dashboards and comparisons.

---

**Q: What is unpivoting?**
A: Unpivoting turns a wide table into a long table, often to normalize or analyze data.

---

### Comparison Questions

**Q: When would you choose pivot instead of GROUP BY?**
A: Use pivot when you want an output shaped like a matrix, with categories represented as columns rather than rows.

---

### Scenario Questions

**Q: A manager wants monthly sales side by side in one row. What technique would you use?**
A: Use `PIVOT` to convert the month names into separate columns and aggregate sales amounts.

---

## 10. Revision Summary

### 1-Minute Recap

**Pivot** = rows to columns; **Unpivot** = columns to rows.

- **Pivot** → reshape for reporting matrices
- **Unpivot** → reshape for analysis or normalization
- **Transformation** → changing the form of data without changing the meaning
- **Best practice** → use the simplest structure that matches the report need

### Interview Keywords

- **Cross-tab report** → pivoted output
- **Long format** → row-based data
- **Wide format** → column-based data
- **Aggregation** → sum or count used inside pivot

### Important Syntax

```sql
SELECT *
FROM sales_data
PIVOT (
    SUM(amount)
    FOR month_name IN ('Jan' AS jan_amt, 'Feb' AS feb_amt)
);

SELECT *
FROM sales_wide
UNPIVOT (
    amount FOR month_name IN (jan_amt AS 'Jan', feb_amt AS 'Feb')
);
```

---

**Done!** Pivot and unpivot are essential for turning raw transactional data into the exact shape required by analysts and managers.
