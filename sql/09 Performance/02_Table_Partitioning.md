# Oracle Table Partitioning

<!-- QUICK_SHEET_START -->

## Quick Sheet
- Partitioning splits one large table into smaller physical segments.
- It improves manageability and query performance via partition pruning.
- Common strategies: range, list, hash, composite.
- Good partition key choice is critical for balanced data and query targeting.
- Partitioning complements indexes; it does not replace them.

<!-- QUICK_SHEET_END -->

## Table of Contents
- [Main Content](#main-content)
- [What Is Partitioning](#what-is-partitioning)
- [Partition Pruning](#partition-pruning)
- [Partitioning Types](#partitioning-types)
- [Example DDL](#example-ddl)
- [Advantages and Trade-Offs](#advantages-and-trade-offs)
- [Interview Insights](#interview-insights)
- [Related Notes](#related-notes)

## Main Content

## What Is Partitioning
Partitioning stores one logical table in multiple physical partitions.
It is most useful for very large tables and date-heavy workloads.

## Partition Pruning
When predicates include the partition key, Oracle can scan only matching partitions.
This reduces I/O and improves response time.

## Partitioning Types
- Range: date or numeric intervals.
- List: categorical values.
- Hash: even distribution.
- Composite: combination (for example range-hash).

## Example DDL
```sql
CREATE TABLE orders_part (
  order_id      NUMBER,
  customer_id   NUMBER,
  order_date    DATE,
  total_amount  NUMBER
)
PARTITION BY RANGE (order_date) (
  PARTITION p_2024 VALUES LESS THAN (DATE '2025-01-01'),
  PARTITION p_2025 VALUES LESS THAN (DATE '2026-01-01'),
  PARTITION p_max  VALUES LESS THAN (MAXVALUE)
);
```

## Advantages and Trade-Offs
### Advantages
- Faster targeted reads through partition pruning.
- Easier archival and maintenance.
- Better scalability for large datasets.

### Trade-Offs
- Extra design and administration complexity.
- Wrong partition key can cause skew.
- Some operations need partition-aware indexing and stats strategy.

## Interview Insights
- Partition key should align with common filter predicates.
- Indexes and partitioning solve different problems and are often used together.
- For existing non-partitioned tables, migration often uses redefinition or CTAS + swap strategy.

## Related Notes
- Access paths and index behavior: [Indexes and Execution Plans](../08%20Indexes/01_Indexes_and_Execution_Plans.md)
- Reporting queries: [Window Functions and Analytics](01_Window_Functions_and_Analytics.md)
