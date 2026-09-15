# 1.9 — Chapter 1 Checkpoint

## One-page mental model

### Data Engineering
Raw data → reliable pipelines → trustworthy data products.

### Lifecycle
Generation → Ingestion → Storage → Transformation → Serving.

### Undercurrents
Security, Data Management, Orchestration, Cost.

### OLTP vs OLAP
- OLTP: transactions, few rows, row-oriented
- OLAP: analytics, many rows/few columns, column-oriented

### Relational
- PK identifies row
- FK links tables
- Normalize for OLTP writes
- Denormalize for OLAP reads

### Batch vs Streaming
- Batch: simpler/cheaper, higher latency
- Streaming: fresher, more complex, more expensive

### ETL vs ELT
- ETL: Extract → Transform → Load
- ELT: Extract → Load → Transform

Modern cloud default is usually ELT.

### Distributed systems
Failure is normal. Think in terms of partitioning, replication, consistency, CAP/PACELC, consensus, and idempotency.

### Delivery guarantees
- At-most-once
- At-least-once
- Exactly-once

Most practical pattern:
> At-least-once + idempotent processing = exactly-once effect.

### DataFrames
When data is small enough, use single-machine tools.

- Eager: execute immediately
- Lazy: plan → optimize → execute

## 20 things to memorize
1. Data engineering moves raw data into trustworthy, usable outputs.
2. Pipeline = automated, repeatable movement/transformation.
3. Lifecycle = Generation → Ingestion → Storage → Transformation → Serving.
4. Undercurrents = Security, Data Management, Orchestration, Cost.
5. OLTP = many small fast transactions.
6. OLAP = large analytical scans/aggregations.
7. Row store = best for full-record access.
8. Column store = best for few columns across many rows.
9. Normalize for OLTP writes.
10. Denormalize for OLAP reads.
11. ACID = Atomicity, Consistency, Isolation, Durability.
12. Batch = bounded data, simpler/cheaper, higher latency.
13. Streaming = continuous data, low latency, higher complexity.
14. ETL = transform before load.
15. ELT = load then transform.
16. Distributed systems: assume failures.
17. Idempotency: retrying yields same final state.
18. At-least-once + idempotency = exactly-once effect.
19. Lazy execution = plan → optimize → execute.
20. Use the smallest tool that fits.

## Chapter transition
Chapter 1 asks: what does a data system do and which decisions govern it?

Chapter 2 asks: how are bytes physically stored to make those decisions efficient (Parquet, row groups, column chunks, pages, encoding, compression, partitioning, file sizing)?
