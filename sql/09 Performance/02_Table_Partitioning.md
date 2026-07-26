# Table Partioning

<!-- QUICK_SHEET_START -->

## Quick Sheet
- Partitioning splits one logical table into multiple physical segments.
- Common methods: range, list, hash, composite.
- Partition pruning scans only relevant partitions when the partition key is in the predicate.
- Partitioning complements indexes; it does not replace them.
- Good partition-key choice is critical for balance and performance.

<!-- QUICK_SHEET_END -->

## Table of Contents
- [Syntax](#syntax)
- [Partion pruning](#partion-pruning)
- [Types of Partitioning](#types-of-partitioning)
- [Adavantages of Partitioning](#adavantages-of-partitioning)
- [disadvantages of Partitioning](#disadvantages-of-partitioning)
- [interview question](#interview-question)

## Table Partioning
Table Partitioning is a database design technique that involves dividing a large table into smaller, more manageable pieces called partitions. 

Each partition can be stored separately, allowing for improved performance, easier maintenance, and better organization of data. However, it is still one logical table.

Partitioning can be based on various criteria, such as range, list, hash, or composite methods.

## Syntax
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


