# 1.6 — Batch vs Streaming

## Batch
Process a bounded chunk of data.

Example: process yesterday's orders every night.

Characteristics:
- simpler
- cheaper
- easy to retry
- higher latency

## Streaming
Process an unbounded flow continuously.

Example: process each order event immediately.

Characteristics:
- low latency
- more complex
- continuously running
- harder failure handling

## Micro-batch
Middle ground: small batches every few seconds.

## Three-way tradeoff

```text
LOW LATENCY
                  ▲
                  │
                  │
COST ────────────┼──────────── COMPLEXITY
```

More freshness usually increases complexity and cost.

## When to use what?
Default → Batch (when real-time is unnecessary).

Use Streaming when freshness has clear business value:
- fraud detection
- real-time personalization
- live monitoring
- alerts

Interview rule:
> Don’t choose streaming because it sounds impressive; choose it when the business requires low latency.

## ETL vs ELT
Both include Extract, Load, Transform.

### ETL
Extract → Transform → Load

### ELT
Extract → Load → Transform

## Why ELT became popular
Cloud economics:
- cheap storage
- elastic compute

Benefits:
- retain raw data
- easy reprocessing
- fewer systems
- warehouse compute
- SQL transformations

ETL still fits when:
- sensitive data must be scrubbed before loading
- source→warehouse network is a bottleneck
- compliance requires preprocessing

Memory hook:
> ETL = transform before warehouse. ELT = warehouse does the transformation.
