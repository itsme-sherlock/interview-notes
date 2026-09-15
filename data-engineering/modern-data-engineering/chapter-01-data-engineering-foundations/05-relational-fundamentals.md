# 1.5 — Relational Fundamentals

A relational database stores:

```text
Tables
 ↓
Rows + Columns
 ↓
Relationships through keys
```

## Primary Key
Uniquely identifies a row.
- `orders.order_id`
- `customers.customer_id`

Properties:
- unique
- not null

## Foreign Key
References another table's primary key.

`orders.customer_id` → `customers.customer_id`

Purpose:
> Establish relationships between tables.

## Referential Integrity
Ensures foreign keys point to valid referenced rows.

## Normalization
Goal:
> Store each fact once and avoid unnecessary duplication.

Avoids:
- update anomalies
- inconsistent data
- unnecessary storage

### 1NF
Atomic values.

### 2NF
1NF + every non-key attribute depends on the whole primary key.

### 3NF
2NF + non-key attributes do not depend on other non-key attributes.

Memory trick:
- 1NF → Atomic
- 2NF → Whole key
- 3NF → Nothing but the key

## Normalization vs Denormalization
- OLTP: normalize for safe updates
- OLAP: denormalize for simpler/faster reads

Interview rule:
> Normalize for writes; denormalize for reads.

## Transactions
A transaction is a group of operations treated as one unit.

## ACID
- Atomicity
- Consistency
- Isolation
- Durability

## Isolation levels (weaker → stronger)
- Read Uncommitted
- Read Committed
- Repeatable Read
- Serializable

Higher isolation usually means more correctness and more overhead.

## Index
Separate data structure to find rows quickly.

Benefits:
- fast selective lookups

Costs:
- additional storage
- slower writes
- index maintenance

Distinction:
- OLTP → indexes
- OLAP → column pruning + partitioning
