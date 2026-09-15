# 1.4 — OLTP vs OLAP

## Fundamental distinction

### OLTP (Online Transaction Processing)
Designed for many small, fast transactions.

Example:
```sql
SELECT *
FROM orders
WHERE order_id = 8841;
```

Typical characteristics:
- many concurrent users
- frequent reads/writes
- millisecond latency
- individual/small number of rows
- usually row-oriented

### OLAP (Online Analytical Processing)
Designed for large scans, aggregations, and analysis.

Example:
```sql
SELECT category, SUM(amount)
FROM orders
GROUP BY category;
```

Typical characteristics:
- huge datasets
- fewer queries
- large scans
- aggregations
- few columns across many rows
- often column-oriented

## Interview table

| OLTP | OLAP |
|---|---|
| Transactions | Analytics |
| Small reads/writes | Large scans |
| Many users | Fewer analytical jobs |
| Milliseconds | Seconds/minutes acceptable |
| Row-oriented | Column-oriented |
| Frequent updates | Mostly reads/bulk loads |
| Correctness + transaction speed | Scan/aggregation throughput |

## Why separate OLTP and OLAP?
Do not run heavy analytics directly on production OLTP databases.

Reasons:
1. Performance impact on apps
2. Different physical design goals
3. Fundamentally different workloads

```text
Production DB
     ↓
Data pipeline
     ↓
Analytics system
```

## Row vs Column storage

Row store:
```text
[1, John, 30, 50000]
[2, Bob, 35, 60000]
```
Best for one complete row.

Column store:
```text
ID:     [1,2]
Name:   [John,Bob]
Age:    [30,35]
Salary: [50000,60000]
```
Best for one/few columns across many rows.

## Why columnar is powerful
1. Column pruning
2. Better compression
3. Efficient analytical processing

> OLTP = few rows, many columns. OLAP = many rows, few columns.
