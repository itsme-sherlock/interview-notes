# 1.7 — Distributed Systems & Idempotency

## Fundamental reality
> Failure is normal.

At scale, machines/networks fail, messages delay/duplicate, jobs retry.

Design for failure, not perfect execution.

## Partitioning / Sharding
Split large datasets across machines.

Benefits:
- scale beyond one machine
- parallel processing
- skip irrelevant partitions

## Replication
Keep multiple copies for availability, durability, and fault tolerance.

Tradeoff:
> Consistency between copies.

## CAP theorem
During network partition, choose between:
- Consistency
- Availability

Examples:
- banking often prefers consistency
- social feeds may prefer availability

## PACELC
- During partitions: Availability vs Consistency
- Else: Latency vs Consistency

## Consistency spectrum
- Strong consistency
- Eventual consistency

Tradeoff:
- Strong: easier correctness, higher latency risk
- Eventual: faster/more available, possible stale reads

## Consensus
Machines agreeing despite failures (leader, commits, state).

Algorithms:
- Raft
- Paxos

## Idempotency (critical)
Definition:
> Running an operation multiple times yields the same final result as running it once.

Example:
- Set `balance = 500` run multiple times → still 500.

Why it matters:
Retries should not create duplicates.

Use patterns like:
- replace partition
- merge/upsert with keys

## Delivery guarantees
- At-most-once (can lose)
- At-least-once (can duplicate)
- Exactly-once (hard/expensive)

Most important pattern:
> At-least-once delivery + idempotent processing = exactly-once effect.

Exactly-once effect is not the same as exactly-once delivery.

## Data format vocabulary
- Structured (fixed schema)
- Semi-structured (JSON, XML)
- Unstructured (images, audio, free text)

## Text vs Binary
Text: CSV, JSON, XML (human-readable but larger/slower)

Binary: Parquet (compact, machine-efficient)

## Schema-on-write vs Schema-on-read
- Schema-on-write: validate at write time
- Schema-on-read: store raw first, interpret at read time

Common association:
- ELT ↔ schema-on-read/raw landing
- ETL ↔ earlier validation/transformation
