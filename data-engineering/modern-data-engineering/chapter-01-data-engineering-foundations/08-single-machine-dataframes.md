# 1.8 — Single-Machine DataFrames

Key correction:
> Not everything needs Spark.

If data fits comfortably in one machine’s memory, a dataframe approach is often simplest and fastest.

## DataFrame
Think of it as a table in program memory with rows, columns, and types.

## Pandas vs Polars

### Pandas
- mature ecosystem
- widespread usage
- eager execution
- generally single-threaded by default
- can become memory-heavy

### Polars
- Rust-based
- columnar/Arrow-backed
- multi-threaded
- supports lazy execution
- built for efficient dataframe processing

Avoid fixed speed claims; performance depends on workload.

## Eager vs Lazy (main concept)

### Eager
Each operation executes immediately.

Limitation: system cannot optimize the full pipeline globally.

### Lazy
Build plan first:

```text
Operations
    ↓
Query Plan
    ↓
Optimizer
    ↓
Execute
```

Optimizer can push filters/column selection toward scan.

Mental model:
> Describe → Optimize → Execute

This idea also appears in SQL engines, Spark, Polars, and query optimizers.

## Choosing tools
- Data fits in RAM → Pandas/Polars
- Set-based transforms → SQL/DuckDB/Warehouse
- Data exceeds one machine → Spark/distributed engine

Golden rule:
> Use the smallest tool that comfortably solves the problem.
