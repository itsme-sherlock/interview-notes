# Table Partitioning Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Partitioning** = Splits one large table into multiple smaller physical segments based on a key column.
- **Partition key** = Column used to split data (e.g., order_date, country, region).
- **Partition pruning** = Query optimization: scan only relevant partitions, skip others (fast).
- **Range partitioning** = Divide by value ranges (dates: 2023, 2024, 2025).
- **List partitioning** = Divide by specific values (countries: USA, UK, India, Canada).
- **Hash partitioning** = Divide using hash function (even distribution, no manual ranges).
- **Composite partitioning** = Two-level: e.g., first by date (range), then by country (hash).
- **Benefits:** Faster queries (pruning), easier maintenance, parallel processing.
- **Drawback:** Wrong partition key = uneven distribution = performance degrades.
- **Partitioning + Indexes** = Complementary (indexes for specific rows, partitioning for data volume reduction).

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Partitioning?](#1-why-do-we-need-partitioning)
2. [What is Table Partitioning?](#2-what-is-table-partitioning)
3. [How Partitioning Works Internally](#3-how-partitioning-works-internally)
4. [Partition Key: Critical Choice](#4-partition-key-critical-choice)
5. [Creating Partitioned Tables](#5-creating-partitioned-tables)
6. [Range Partitioning](#6-range-partitioning)
7. [List Partitioning](#7-list-partitioning)
8. [Hash Partitioning](#8-hash-partitioning)
9. [Composite Partitioning](#9-composite-partitioning)
10. [Partition Pruning](#10-partition-pruning)
11. [Partitioning vs Indexes](#11-partitioning-vs-indexes)
12. [Partitioning Existing Tables](#12-partitioning-existing-tables)
13. [Partition Maintenance](#13-partition-maintenance)
14. [Best Practices](#14-best-practices)
15. [Common Mistakes](#15-common-mistakes)
16. [Interview Q&A](#16-interview-qa)
17. [Revision Summary](#17-revision-summary)

---

## 1. Why Do We Need Partitioning?

### The Problem: Very Large Tables Are Slow

**Scenario:** Your ORDERS table has 1 billion rows (10 GB of data).

```sql
-- Find all orders from January 2024
SELECT * FROM orders 
WHERE order_date BETWEEN TO_DATE('2024-01-01', 'YYYY-MM-DD') 
                    AND TO_DATE('2024-01-31', 'YYYY-MM-DD');
```

**Without partitioning:**
- Oracle scans entire table (1 billion rows, 10 GB)
- Even with an index, scans billions of blocks
- Takes 30 seconds ❌

**With partitioning (by year):**
- Oracle knows January 2024 data is in "2024" partition
- Scans only 2024 partition (100 million rows, 1 GB)
- Ignores other year partitions (2023, 2025, etc.)
- Takes 3 seconds ✅

### Business Impact

```
Large table queries:  Slow (scan entire table)
        ↓
Partitioned queries:  Fast (scan only relevant partition)
```

### Real-World Scenarios

- **E-commerce:** Orders table partitioned by year (2020, 2021, 2022...)
- **Banking:** Transactions partitioned by month (useful for archiving old data)
- **Logs:** Events partitioned by date (delete old logs quickly)
- **Sales:** Orders partitioned by region (regional reporting faster)

---

**➡ Transition:** Partitioning splits a big table into smaller pieces. Let's understand exactly how it works.

---

## 2. What is Table Partitioning?

### Simple Definition

**Partitioning** is dividing one logical table into **multiple physical segments** based on a column value.

Users still query it as one table; Oracle transparently searches only relevant segments.

### Analogy: Filing Cabinet

**Without partitioning:**
```
One giant file cabinet
All 10,000 documents in one drawer
To find Jan 2024 docs, search entire drawer
```

**With partitioning:**
```
Organized file cabinet
Drawer 1: 2020 documents
Drawer 2: 2021 documents
Drawer 3: 2022 documents
Drawer 4: 2023 documents
Drawer 5: 2024 documents

To find Jan 2024 docs, go straight to Drawer 5
```

### Key Characteristics

- **Logical:** Users see one table
- **Physical:** Stored in multiple segments/partitions
- **Transparent:** Application code unchanged
- **Performance:** Relevant partitions scanned, others skipped

### Partition Terminology

- **Partition:** One segment (e.g., "orders_2024")
- **Partition key:** Column used to split (e.g., order_date)
- **Partition pruning:** Oracle skips irrelevant partitions
- **Sub-partition:** Second level of partitioning (in composite)

---

**➡ Transition:** How does Oracle know which partition to search? That's partition pruning, the magic that makes queries fast.

---

## 3. How Partitioning Works Internally

### Query Execution with Partitioning

**Table: ORDERS partitioned by order_date (yearly):**
```
Partition 2022: orders from 2022
Partition 2023: orders from 2023
Partition 2024: orders from 2024
Partition 2025: orders from 2025
```

**Query:**
```sql
SELECT * FROM orders 
WHERE order_date BETWEEN TO_DATE('2024-01-01', 'YYYY-MM-DD') 
                    AND TO_DATE('2024-01-31', 'YYYY-MM-DD');
```

**Oracle Execution:**
```
Step 1: Check WHERE clause
        ↓
Step 2: Identify partition key (order_date)
        ↓
Step 3: Determine which partition(s) have matching data
        ↓
        Only 2024 partition matches (date range)
        ↓
Step 4: SKIP partitions 2022, 2023, 2025
        ↓
Step 5: Scan ONLY partition 2024 (100 million rows instead of 1 billion)
        ↓
Step 6: Return results
```

### Speed Difference

**Without partition pruning:** Full table scan
```
1 billion rows × 8KB per block = 125,000 blocks to read
```

**With partition pruning:** Partition scan
```
100 million rows × 8KB per block = 12,500 blocks to read (10x faster!)
```

### Partition Pruning Conditions

Pruning **works** when:
- WHERE clause includes partition key column
- Values clearly restrict partitions

```sql
-- ✅ Pruning works
WHERE order_date = TO_DATE('2024-06-01', 'YYYY-MM-DD');

-- ✅ Pruning works
WHERE order_date BETWEEN TO_DATE('2024-01-01', 'YYYY-MM-DD') 
                    AND TO_DATE('2024-12-31', 'YYYY-MM-DD');
```

Pruning **doesn't work** when:
- WHERE clause doesn't include partition key
- Queries involve functions on partition key

```sql
-- ❌ No pruning (no partition key)
WHERE customer_id = 1001;

-- ❌ No pruning (function on partition key)
WHERE YEAR(order_date) = 2024;
```

---

**➡ Transition:** Choosing the right partition key is critical. Wrong choice = uneven distribution = no performance benefit.

---

## 4. Partition Key: Critical Choice

### What Makes a Good Partition Key?

**Good partition key:**
- Frequently used in WHERE clauses
- Divides data **evenly** (balanced partitions)
- Commonly archived/deleted (for maintenance)
- Has range or distinct categories (not random)

**Bad partition key:**
- Rarely used in queries
- Creates **uneven** distribution (some partitions huge, others tiny)
- Too many partitions (overhead exceeds benefit)

### Example: Good vs Bad Partition Keys

**ORDERS table:**

**✅ GOOD:** Partition by order_date (date)
- Queries often filter by date range
- Natural evolution (2020, 2021, 2022 data grows yearly)
- Even distribution if business consistent
- Easy to archive old years

**✅ GOOD:** Partition by region (category)
- Queries often filter by region
- Well-defined categories (USA, Europe, Asia)
- Relatively even distribution

**❌ BAD:** Partition by order_id (random)
- Queries rarely filter by order_id alone
- Difficult to evenly distribute
- No pruning benefit for typical queries

**❌ BAD:** Partition by customer_name (too many values)
- Creates thousands of partitions
- Most partitions tiny
- Maintenance overhead

### Partition Key Strategy

Choose based on:
1. **Access patterns:** Columns in WHERE clauses
2. **Data lifecycle:** What gets archived/deleted
3. **Distribution:** Does it divide data evenly

---

**➡ Transition:** Now let's create partitioned tables and see the syntax for different partitioning types.

---

## 5. Creating Partitioned Tables

### Basic Syntax

```sql
CREATE TABLE table_name (
  column1 datatype,
  column2 datatype,
  ...
)
PARTITION BY partition_method (partition specifications);
```

### Example: Range Partitioning (Most Common)

```sql
CREATE TABLE orders (
  order_id NUMBER,
  customer_id NUMBER,
  order_date DATE,
  total_amount NUMBER
)
PARTITION BY RANGE (order_date) (
  PARTITION orders_2022 VALUES LESS THAN (TO_DATE('2023-01-01', 'YYYY-MM-DD')),
  PARTITION orders_2023 VALUES LESS THAN (TO_DATE('2024-01-01', 'YYYY-MM-DD')),
  PARTITION orders_2024 VALUES LESS THAN (TO_DATE('2025-01-01', 'YYYY-MM-DD')),
  PARTITION orders_future VALUES LESS THAN (MAXVALUE)
);
```

**Explanation:**
- `PARTITION BY RANGE (order_date)` = Use order_date as partition key
- Each PARTITION has a name and range
- `MAXVALUE` = "All remaining values" (catch-all)

---

**➡ Transition:** There are different partitioning methods. Let's explore each one.

---

## 6. Range Partitioning

### What It Does

Divides table by **ranges** of values (typically dates or numbers).

**Example ranges:**
- Dates: 2022, 2023, 2024
- Salary ranges: 0-50K, 50K-100K, 100K+
- ID ranges: 1-100K, 100K-200K, 200K+

### Syntax

```sql
PARTITION BY RANGE (partition_key) (
  PARTITION partition_name VALUES LESS THAN (upper_bound),
  ...
  PARTITION partition_name VALUES LESS THAN (MAXVALUE)
);
```

### Example: Orders by Year

```sql
CREATE TABLE orders (
  order_id NUMBER PRIMARY KEY,
  customer_id NUMBER,
  order_date DATE,
  total_amount NUMBER
)
PARTITION BY RANGE (order_date) (
  PARTITION q1_2024 VALUES LESS THAN (TO_DATE('2024-04-01', 'YYYY-MM-DD')),
  PARTITION q2_2024 VALUES LESS THAN (TO_DATE('2024-07-01', 'YYYY-MM-DD')),
  PARTITION q3_2024 VALUES LESS THAN (TO_DATE('2024-10-01', 'YYYY-MM-DD')),
  PARTITION q4_2024 VALUES LESS THAN (TO_DATE('2025-01-01', 'YYYY-MM-DD')),
  PARTITION future VALUES LESS THAN (MAXVALUE)
);
```

### Partition Pruning Example

```sql
-- Queries for Q2 2024 data
SELECT * FROM orders 
WHERE order_date BETWEEN TO_DATE('2024-04-01', 'YYYY-MM-DD') 
                    AND TO_DATE('2024-06-30', 'YYYY-MM-DD');
-- Oracle scans only q2_2024 partition ✅
```

### When to Use Range Partitioning

- Time-series data (dates, timestamps)
- Numeric ranges
- Data archival (delete/move old partitions)
- Regular data growth patterns

---

**➡ Transition:** Range works for continuous values. List partitioning works for specific category values.

---

## 7. List Partitioning

### What It Does

Divides table by **specific values** (categories, regions, status).

**Example lists:**
- Countries: USA, UK, Canada, India
- Status: ACTIVE, INACTIVE, SUSPENDED
- Region: North, South, East, West

### Syntax

```sql
PARTITION BY LIST (partition_key) (
  PARTITION partition_name VALUES (value1, value2, value3),
  ...
  PARTITION partition_name VALUES (DEFAULT)
);
```

### Example: Orders by Region

```sql
CREATE TABLE orders (
  order_id NUMBER PRIMARY KEY,
  customer_id NUMBER,
  region VARCHAR2(20),
  total_amount NUMBER
)
PARTITION BY LIST (region) (
  PARTITION americas VALUES ('USA', 'CANADA', 'MEXICO'),
  PARTITION europe VALUES ('UK', 'GERMANY', 'FRANCE', 'SPAIN'),
  PARTITION asia VALUES ('INDIA', 'JAPAN', 'CHINA'),
  PARTITION other VALUES (DEFAULT)
);
```

### Partition Pruning Example

```sql
-- Query for European orders
SELECT * FROM orders WHERE region = 'FRANCE';
-- Oracle scans only europe partition ✅
```

### When to Use List Partitioning

- Categorical data (regions, status, categories)
- Predetermined distinct values
- Business-driven categories
- Uneven distribution (some categories have more data)

---

**➡ Transition:** List and Range are manual. Hash partitioning is automatic—Oracle divides data evenly using math.

---

## 8. Hash Partitioning

### What It Does

Uses a **hash function** to automatically divide data evenly across partitions.

Oracle applies a math formula to partition key, result determines partition.

### Syntax

```sql
PARTITION BY HASH (partition_key)
PARTITIONS number_of_partitions;
```

### Example: Orders Partitioned by Hash

```sql
CREATE TABLE orders (
  order_id NUMBER PRIMARY KEY,
  customer_id NUMBER,
  order_date DATE,
  total_amount NUMBER
)
PARTITION BY HASH (order_id)
PARTITIONS 4;  -- Automatically splits into 4 partitions
```

**How it works internally:**
```
order_id=101 → hash_function(101) → partition 1
order_id=205 → hash_function(205) → partition 2
order_id=310 → hash_function(310) → partition 3
order_id=415 → hash_function(415) → partition 4
order_id=520 → hash_function(520) → partition 1 (cycles)
...
```

### Benefits of Hash Partitioning

- **Automatic distribution:** Oracle handles it, no manual ranges
- **Even spread:** Data distributed evenly across partitions
- **No pruning:** Can't skip partitions (don't know mapping in advance)
- **Parallel processing:** Each partition processed in parallel

### When to Use Hash Partitioning

- Large tables with no natural range/category key
- Want to distribute evenly without manual management
- Parallel processing is priority
- Queries rarely filter on partition key

### Hash vs Range vs List

| Aspect | Hash | Range | List |
| --- | --- | --- | --- |
| **Distribution** | Automatic, even | Manual, uneven possible | Manual, uneven possible |
| **Pruning** | No (don't know mapping) | Yes (know ranges) | Yes (know lists) |
| **Best for** | Even distribution | Time-series, archival | Categories, regions |
| **Query pattern** | Full table or parallel | Date filtering | Category filtering |

---

**➡ Transition:** Sometimes you need **two levels** of partitioning for more control. That's composite partitioning.

---

## 9. Composite Partitioning

### What It Does

Combines **two partitioning methods** in two levels:
- First level: Range, List, or Hash
- Second level: Range, List, or Hash

### Syntax

```sql
PARTITION BY method1 (key1)
  SUBPARTITION BY method2 (key2) (
    PARTITION partition_name VALUES ...
      SUBPARTITION subpartition_name VALUES ...
  );
```

### Example: Orders by Year Then Region

```sql
CREATE TABLE orders (
  order_id NUMBER,
  customer_id NUMBER,
  order_date DATE,
  region VARCHAR2(20),
  total_amount NUMBER
)
PARTITION BY RANGE (order_date)
  SUBPARTITION BY LIST (region) (
    PARTITION p_2023 VALUES LESS THAN (TO_DATE('2024-01-01', 'YYYY-MM-DD')) (
      SUBPARTITION p_2023_americas VALUES ('USA', 'CANADA'),
      SUBPARTITION p_2023_europe VALUES ('UK', 'FRANCE'),
      SUBPARTITION p_2023_asia VALUES ('INDIA', 'JAPAN')
    ),
    PARTITION p_2024 VALUES LESS THAN (TO_DATE('2025-01-01', 'YYYY-MM-DD')) (
      SUBPARTITION p_2024_americas VALUES ('USA', 'CANADA'),
      SUBPARTITION p_2024_europe VALUES ('UK', 'FRANCE'),
      SUBPARTITION p_2024_asia VALUES ('INDIA', 'JAPAN')
    )
  );
```

### Partition Pruning with Composite

```sql
-- Prunes on both year AND region
SELECT * FROM orders 
WHERE order_date >= TO_DATE('2024-01-01', 'YYYY-MM-DD') 
  AND region = 'USA';
-- Scans only p_2024_americas subpartition ✅
```

### When to Use Composite Partitioning

- Need multi-level filtering (date + region, date + category)
- Balance between automatic (hash) and manual (range/list)
- Complex archival scenarios
- Want partition pruning on multiple columns

---

**➡ Transition:** Partition pruning is the performance magic. Let's understand exactly when it triggers.

---

## 10. Partition Pruning

### What is Partition Pruning?

Oracle optimization: **Skip partitions** that can't contain matching data.

```
Normal query:  Scan all partitions
        ↓
With pruning:  Scan only matching partition(s)
        ↓
Result:  10x-100x faster queries
```

### Pruning Examples

**Query 1: Pruning WORKS ✅**
```sql
SELECT * FROM orders WHERE order_date >= TO_DATE('2024-01-01', 'YYYY-MM-DD');
-- Partitioned by year
-- Oracle knows to skip 2020, 2021, 2022, 2023 partitions
-- Scans only 2024, 2025 partitions
```

**Query 2: Pruning WORKS ✅**
```sql
SELECT * FROM orders WHERE region = 'USA';
-- Partitioned by region
-- Oracle knows USA data is in americas partition
-- Scans only americas partition
```

**Query 3: Pruning DOESN'T WORK ❌**
```sql
SELECT * FROM orders WHERE customer_id = 101;
-- Table partitioned by order_date, not customer_id
-- Partition key not in WHERE clause
-- Must scan all partitions
```

**Query 4: Pruning DOESN'T WORK ❌**
```sql
SELECT * FROM orders WHERE YEAR(order_date) = 2024;
-- Function on partition key prevents pruning
-- Oracle can't determine partition before executing function
-- Must scan all partitions
```

### Pruning Requirements

Pruning requires:
1. **Partition key in WHERE clause**
2. **No functions on partition key**
3. **Simple comparison** (=, <, >, BETWEEN, IN)
4. **Known values** (not derived from subqueries/joins)

---

**➡ Transition:** Partitioning and indexes seem similar but solve different problems. Let's understand their relationship.

---

## 11. Partitioning vs Indexes

### How They Differ

| Aspect | Index | Partition |
| --- | --- | --- |
| **Purpose** | Find specific rows quickly | Reduce data to scan |
| **Search** | Lookup by value (B-tree) | Skip irrelevant partitions |
| **Data volume** | Helps with specific rows | Helps with large datasets |
| **Overhead** | Storage, maintenance | Storage, complexity |
| **Use case** | "Find employee 101" | "Find all orders in 2024" |

### Scenario 1: Index Only

```sql
-- Find ONE employee
SELECT * FROM employees WHERE employee_id = 101;
-- Use index: Returns in nanoseconds
-- Partitioning unnecessary (doesn't help find one row)
```

### Scenario 2: Partition Only

```sql
-- Find ALL orders in 2024 (millions of rows)
SELECT * FROM orders WHERE order_date >= TO_DATE('2024-01-01', 'YYYY-MM-DD');
-- Use partitioning: Scan 2024 partition only (fast)
-- Index unnecessary (must return many rows anyway)
```

### Scenario 3: Both Together

```sql
-- Find orders for specific customer in 2024
SELECT * FROM orders 
WHERE order_date >= TO_DATE('2024-01-01', 'YYYY-MM-DD') 
  AND customer_id = 101;
-- Use partition pruning: Skip to 2024 partition
-- Use index on customer_id: Find customer 101 within partition
-- BOTH work together (fastest)
```

### When to Use What

**Use index when:**
- Searching for specific rows
- Query returns small % of data
- Can't partition naturally

**Use partitioning when:**
- Table is very large (> 10GB)
- Queries filter on partition key
- Maintenance benefits (archive old data)
- Data archival/deletion

**Use both when:**
- Large table + specific row searches
- Partition pruning + index lookup together

---

**➡ Transition:** You can't partition existing tables directly. But there are ways to convert them.

---

## 12. Partitioning Existing Tables

### Challenge

```sql
-- ❌ Can't partition non-partitioned table directly
ALTER TABLE orders PARTITION BY RANGE (order_date) ...;
-- Error: Not supported
```

### Option 1: Create New Table + Copy Data

```sql
-- Step 1: Create partitioned table with same structure
CREATE TABLE orders_new (
  order_id NUMBER,
  ...
) PARTITION BY RANGE (order_date) (...);

-- Step 2: Copy data
INSERT INTO orders_new SELECT * FROM orders;
COMMIT;

-- Step 3: Rename tables
ALTER TABLE orders RENAME TO orders_old;
ALTER TABLE orders_new RENAME TO orders;

-- Step 4: Drop old table
DROP TABLE orders_old;
```

**Downtime:** Yes (table locked during copy)

### Option 2: DBMS_REDEFINITION (Online)

```sql
-- Redefinition without downtime
BEGIN
  DBMS_REDEFINITION.start_redef_table(
    uname => 'SCHEMA_NAME',
    orig_table => 'ORDERS',
    int_table => 'ORDERS_TEMP'
  );
  
  DBMS_REDEFINITION.redef_table(
    uname => 'SCHEMA_NAME',
    orig_table => 'ORDERS'
  );
  
  DBMS_REDEFINITION.finish_redef_table(
    uname => 'SCHEMA_NAME',
    orig_table => 'ORDERS',
    int_table => 'ORDERS_TEMP'
  );
END;
/
```

**Downtime:** No (online redefinition)

---

**➡ Transition:** Once partitioned, tables need maintenance—adding new partitions, dropping old ones, etc.

---

## 13. Partition Maintenance

### Adding Partitions (Range/List)

```sql
-- Add 2025 partition for yearly table
ALTER TABLE orders ADD PARTITION orders_2025 
  VALUES LESS THAN (TO_DATE('2026-01-01', 'YYYY-MM-DD'));
```

### Dropping Old Partitions

```sql
-- Drop 2020 data (archival)
ALTER TABLE orders DROP PARTITION orders_2020;
-- Data is deleted permanently
```

### Truncating Partitions

```sql
-- Clear partition without deleting structure
ALTER TABLE orders TRUNCATE PARTITION orders_2023;
-- Partition still exists but empty
```

### Exporting Before Deletion

```sql
-- Good practice: Export data before deletion
CREATE TABLE orders_archive_2020 AS
SELECT * FROM orders PARTITION (orders_2020);

-- Then safely delete
ALTER TABLE orders DROP PARTITION orders_2020;
```

---

## 14. Best Practices

### 1. Choose Partition Key Based on Queries

**Avoid:**
```sql
-- Partition by random column
CREATE TABLE orders (...)
PARTITION BY HASH (order_id) PARTITIONS 4;
-- Queries rarely filter by order_id, no pruning benefit
```

**Prefer:**
```sql
-- Partition by frequently filtered column
CREATE TABLE orders (...)
PARTITION BY RANGE (order_date) (...);
-- Queries often filter by date, pruning works
```

---

### 2. Maintain Even Distribution

**Avoid:**
```sql
-- Uneven ranges
CREATE TABLE orders (...)
PARTITION BY RANGE (order_date) (
  PARTITION p1 VALUES LESS THAN (TO_DATE('2024-01-01', 'YYYY-MM-DD')),  -- 1000 rows
  PARTITION p2 VALUES LESS THAN (TO_DATE('2024-12-01', 'YYYY-MM-DD')),  -- 1M rows
  PARTITION p3 VALUES LESS THAN (MAXVALUE)                               -- 100 rows
);
```

**Prefer:**
```sql
-- Even distribution
CREATE TABLE orders (...)
PARTITION BY RANGE (order_date) (
  PARTITION p_2022 VALUES LESS THAN (TO_DATE('2023-01-01', 'YYYY-MM-DD')),  -- ~300K
  PARTITION p_2023 VALUES LESS THAN (TO_DATE('2024-01-01', 'YYYY-MM-DD')),  -- ~300K
  PARTITION p_2024 VALUES LESS THAN (TO_DATE('2025-01-01', 'YYYY-MM-DD')),  -- ~300K
  PARTITION p_future VALUES LESS THAN (MAXVALUE)                            -- ~100K
);
```

---

### 3. Automate Partition Creation

**Avoid:**
```sql
-- Manual partition addition every month
ALTER TABLE orders ADD PARTITION p_jan2025 ...;  -- Manual
ALTER TABLE orders ADD PARTITION p_feb2025 ...;  -- Manual
-- Easy to forget, error-prone
```

**Prefer:**
```sql
-- Automated job to create partitions quarterly
-- Use interval partitions (Oracle 11g+)
CREATE TABLE orders (...)
PARTITION BY RANGE (order_date)
INTERVAL (NUMTOYMINTERVAL(3, 'MONTH')) (
  PARTITION initial VALUES LESS THAN (TO_DATE('2024-01-01', 'YYYY-MM-DD'))
);
-- Oracle automatically creates new partitions as needed
```

---

### 4. Don't Over-Partition

**Avoid:**
```sql
-- Thousands of partitions
CREATE TABLE orders (...)
PARTITION BY LIST (customer_name) (
  PARTITION p_a VALUES ('Alice'),
  PARTITION p_b VALUES ('Bob'),
  ...thousands more...
);
-- Maintenance overhead exceeds benefit
```

**Prefer:**
```sql
-- Manageable number of partitions (typically 10-100)
CREATE TABLE orders (...)
PARTITION BY RANGE (order_date) (...);
-- Yearly or quarterly partitions (12-48 partitions)
```

---

## 15. Common Mistakes

### Mistake 1: Wrong Partition Key

```sql
-- ❌ WRONG: Partition by rarely-filtered column
CREATE TABLE orders (...) PARTITION BY HASH (order_id) PARTITIONS 4;

-- Queries
SELECT * FROM orders WHERE customer_id = 101;
-- No pruning (partition key is order_id, not customer_id)
-- Must scan all partitions

-- ✅ CORRECT: Partition by frequently-filtered column
CREATE TABLE orders (...) PARTITION BY RANGE (order_date) (...);
-- Queries filter by date, pruning works
```

---

### Mistake 2: Function on Partition Key

```sql
-- ❌ WRONG: Function disables pruning
SELECT * FROM orders WHERE YEAR(order_date) = 2024;
-- Oracle can't determine partition before executing YEAR()
-- No pruning, scans all partitions

-- ✅ CORRECT: Compare against actual values
SELECT * FROM orders 
WHERE order_date >= TO_DATE('2024-01-01', 'YYYY-MM-DD')
  AND order_date < TO_DATE('2025-01-01', 'YYYY-MM-DD');
-- Pruning works, scans only 2024 partition
```

---

### Mistake 3: Too Many Partitions

```sql
-- ❌ WRONG: Thousands of small partitions
CREATE TABLE orders (...)
PARTITION BY LIST (customer_id) (
  -- One partition per customer!
);
-- Management overhead, no performance benefit

-- ✅ CORRECT: Manageable number
CREATE TABLE orders (...)
PARTITION BY RANGE (order_date) (...);
-- Yearly or quarterly, typically 10-100 partitions
```

---

### Mistake 4: Forgetting Maintenance

```sql
-- ❌ WRONG: Partitions grow without limit
CREATE TABLE orders (...) 
PARTITION BY RANGE (order_date) (
  PARTITION p_2024 VALUES LESS THAN (TO_DATE('2025-01-01', 'YYYY-MM-DD')),
  PARTITION p_future VALUES LESS THAN (MAXVALUE)
);
-- Year 2025 data goes to p_future (unpartitioned!)
-- No pruning benefit for 2025+ queries

-- ✅ CORRECT: Add new partition before year ends
ALTER TABLE orders ADD PARTITION p_2025 
  VALUES LESS THAN (TO_DATE('2026-01-01', 'YYYY-MM-DD'));
```

---

## 16. Interview Q&A

### Conceptual

**Q: What is table partitioning and why do we need it?**

A: Partitioning divides a large table into smaller segments based on a column (partition key). It improves query performance through partition pruning (skipping irrelevant partitions) and enables easier maintenance (archiving/deleting old data).

---

**Q: What is partition pruning?**

A: Oracle optimization that skips partitions that can't contain matching data based on WHERE clause. If partition key is in WHERE clause, Oracle scans only relevant partition(s), making queries much faster.

---

**Q: What's the difference between range, list, and hash partitioning?**

A: Range divides by value ranges (dates, numbers). List divides by specific values (categories, regions). Hash uses a function to automatically divide evenly. Choose based on data characteristics and query patterns.

---

### Comparison

**Q: Partitioning vs Indexes?**

A: Indexes find specific rows quickly (good for single-row lookups). Partitioning reduces data to scan (good for large datasets). Both work together: pruning identifies partition, index finds rows within partition.

---

**Q: When would you partition vs not partition?**

A: Partition when table is very large (>10GB), queries filter on partition key, maintenance benefits matter. Don't partition if table small, no natural partition key, or queries don't filter on one column.

---

### Scenario

**Q: 1 billion order records, queries often filter by date. Design partitioning strategy.**

A: Partition by RANGE (order_date) yearly (2020, 2021, 2022...) or quarterly (Q1, Q2, Q3, Q4) depending on data distribution. Ensures pruning works for date-filtered queries. Add maintenance job to create new partitions before end of period.

---

**Q: Table partitioned by date, but query uses function: WHERE YEAR(order_date) = 2024. Is pruning used?**

A: No. Function on partition key prevents pruning. Rewrite as: WHERE order_date >= '2024-01-01' AND order_date < '2025-01-01' to enable pruning.

---

## 17. Revision Summary

### 1-Minute Revision

**Partitioning = Split large table into segments based on column; Oracle scans only relevant segment (partition pruning).**

1. **Partition key** = Column used to split data
2. **Partition pruning** = Skip partitions that can't have matching rows
3. **Range partitioning** = Divide by ranges (dates: 2022, 2023, 2024...)
4. **List partitioning** = Divide by categories (regions: USA, UK, India...)
5. **Hash partitioning** = Automatic even distribution
6. **Composite partitioning** = Two levels (e.g., date + region)
7. **Partition key must be in WHERE clause** for pruning to work
8. **Functions on partition key disable pruning**
9. **Partitioning + Indexes work together** (pruning + index lookup)
10. **Maintenance needed:** Add/drop partitions, automate with interval partitions

### Interview Keywords

- Partition key, partition pruning
- Range, List, Hash, Composite partitioning
- Pruning requirements (WHERE clause, no functions)
- Partition maintenance (adding, dropping)
- Partitioning vs Indexes (complementary, different purposes)
- MAXVALUE (catch-all partition)
- Interval partitioning (automatic)
- DBMS_REDEFINITION (online partitioning)

### Important Syntax

```sql
-- Range partitioning (by date)
CREATE TABLE orders (
  order_id NUMBER,
  order_date DATE,
  total_amount NUMBER
)
PARTITION BY RANGE (order_date) (
  PARTITION p_2023 VALUES LESS THAN (TO_DATE('2024-01-01', 'YYYY-MM-DD')),
  PARTITION p_2024 VALUES LESS THAN (TO_DATE('2025-01-01', 'YYYY-MM-DD')),
  PARTITION p_future VALUES LESS THAN (MAXVALUE)
);

-- List partitioning (by category)
CREATE TABLE orders (...)
PARTITION BY LIST (region) (
  PARTITION americas VALUES ('USA', 'CANADA'),
  PARTITION europe VALUES ('UK', 'FRANCE'),
  PARTITION other VALUES (DEFAULT)
);

-- Hash partitioning (automatic distribution)
CREATE TABLE orders (...)
PARTITION BY HASH (order_id)
PARTITIONS 4;

-- Interval partitioning (automatic partition creation)
CREATE TABLE orders (...)
PARTITION BY RANGE (order_date)
INTERVAL (NUMTOYMINTERVAL(3, 'MONTH')) (
  PARTITION initial VALUES LESS THAN (TO_DATE('2024-01-01', 'YYYY-MM-DD'))
);

-- Composite partitioning (date + region)
CREATE TABLE orders (...)
PARTITION BY RANGE (order_date) SUBPARTITION BY LIST (region) (...);

-- Add new partition
ALTER TABLE orders ADD PARTITION p_2025 
  VALUES LESS THAN (TO_DATE('2026-01-01', 'YYYY-MM-DD'));
```

## What is Table Partitioning

```sql
CREATE TABLE ORDERS_PART (
    order_id NUMBER,
    customer_id NUMBER,
    order_date DATE,
    total_amount NUMBER
)
PARTITION BY RANGE (order_date) (
    PARTITION orders_2022 VALUES LESS THAN (TO_DATE('2023-01-01', 'YYYY-MM-DD')),
    PARTITION orders_2023 VALUES LESS THAN (TO_DATE('2024-01-01', 'YYYY-MM-DD')),
    PARTITION orders_2024 VALUES LESS THAN (TO_DATE('2025-01-01', 'YYYY-MM-DD')),
    PARTITION - [Table Partioning](#table-partioning)
  - [Syntax from Orders Table](#syntax-from-orders-table)
  - [Partion pruning](#partion-pruning)
  - [Why We Need Partitioning When Index exists?](#why-we-need-partitioning-when-index-exists)
  - [Types of Partitioning](#types-of-partitioning)
    - [Range Partitioning](#range-partitioning)
    - [List Partitioning](#list-partitioning)
    - [Hash Partitioning](#hash-partitioning)
    - [Composite Partitioning](#composite-partitioning)
 VALUES LESS THAN (TO_DATE('2026-01-01', 'YYYY-MM-DD'))
    PARTITION other_partitions VALUES LESS THAN (MAXVALUE)
);
```

This example creates a partitioned table called `orders_part`, which is partitioned by the `order_date` column using range partitioning. Each partition corresponds to a specific year, allowing for efficient querying and management of order data based on their order date.

## Partion pruning

Partition pruning is a **performance optimization technique** .

It involves selectively **accessing only the relevant portion** of a partitioned table during query execution, rather than scanning the entire table.

This can significantly improve query performance by reducing the amount of data that needs to be processed.

## Types of Partitioning

1. Range Partitioning
2. List Partitioning
3. Hash Partitioning
4. Composite Partitioning

### Range Partitioning

Range partitioning divides a table into partitions based on a specified range of values in a column.

For example, an Orders table could be partitioned by year, with each partition containing data for a specific year.
mostly deals with **numeric or date values.**

### List Partitioning

List partitioning divides a table into partitions based on a list of specified values in a column.

For example, an Orders table could be partitioned by country, with each partition containing data for a specific country.
based on Specific values, mostly deals with **categorical data**.

### Hash Partitioning

Hash partitioning divides a table into partitions using a hash function.

For example, an Orders table could be partitioned by hashing the order ID, (hashing the order id means using a math formula on each value) with each partition containing data for a specific hash value.
mostly deals with **uniform distribution of data**.

### Composite Partitioning

Composite partitioning divides a table into partitions based on multiple columns.

For example, an Orders table could be partitioned by year and country, with each partition containing data for a specific year and country.

## Adavantages of Partitioning

1. Faster Query through partition pruning.
2. Easier Maintenance: Individual partitions can be managed separately, making it easier to perform tasks like backups, restores, and data archiving.
3. Improved Performance: Queries that can be restricted to specific partitions can be executed more efficiently.
4. Improved Availability: If one partition becomes unavailable, the rest of the table can still be accessed.

## disadvantages of Partitioning

1. Poor choice of partition key can lead to uneven distribution of data across partitions, resulting in performance issues.
2. Increased Complexity: Managing partitioned tables can be more complex than managing non-partitioned tables.
3. Potential Overhead: There may be additional storage and maintenance overhead associated with partitioned tables.

## interview question

### Q: What is partition key?

A partition key is a column or set of columns in a table that determines where the data belongs to.

### Q: Can we have indexes on partitioned tables?

Yes, we can have indexes on partitioned tables. Indexes can be created on individual partitions or on the entire partitioned table.

### Q: Can we create a partition to an existing table?

Yes, we can create a partition to an existing table simply not using the `ALTER TABLE` statement.

1.create a new partionied table and copy the data from the existing table to the new partitioned table.

2.DBMS_REDEFINITION package can be used to redefine the existing table as a partitioned table without downtime.

3.Data pump and reload the data into a new partitioned table.

### Q: Why We Need Partitioning When Index exists?

While indexes can improve query performance they have limitations with very large tables. Partitioning complements indexing by:

- Reducing the amount of data scanned for queries that can be restricted to specific partitions.
- Enhancing query performance for range queries, as only relevant partitions need to be scanned.
  
They solve different problems. Indexes help locate specific rows quickly, while partitioning reduces the amount of data that needs to be scanned for queries that can be restricted to specific partitions.
