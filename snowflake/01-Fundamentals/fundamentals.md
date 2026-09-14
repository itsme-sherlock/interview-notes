# Snowflake Fundamentals — Interview Study Guide

## Quick Sheet

* **Snowflake** = A fully managed cloud data platform primarily used for storing, processing, and analyzing data.
* **Cloud platforms:** Runs on **AWS, Microsoft Azure, and Google Cloud**.
* **Storage and compute are separated** → storage can scale independently from query processing.
* **Storage layer** → Snowflake manages compressed, columnar data organized internally into **micro-partitions**.
* **Compute layer** → **Virtual Warehouses** execute SQL and data-processing workloads.
* **Multiple warehouses** → ETL, BI, reporting, and other workloads can run independently without competing for the same compute resources.
* **Semi-structured data** → Native support for formats such as JSON, Avro, Parquet, and XML.
* **Fully managed** → Users don't manage database servers, operating systems, storage hardware, or cluster infrastructure.

---

# 1. What Is Snowflake?

### Simple Definition

**Snowflake is a cloud-native data platform that provides scalable storage and compute for data warehousing, analytics, data engineering, data sharing, and data-lake workloads.**

It is available on:

* Amazon Web Services (AWS)
* Microsoft Azure
* Google Cloud Platform (GCP)

### Why Is Snowflake Called Cloud-Native?

Snowflake was designed specifically for cloud environments rather than being an on-premises database that was later moved to the cloud.

You don't have to manage:

* Physical servers
* Operating systems
* Database storage hardware
* Compute clusters
* Manual infrastructure scaling

Snowflake manages the underlying infrastructure for you.

---

# 2. The Core Snowflake Architecture

The most important architectural concept for an interview is:

```text
                 SNOWFLAKE
                     │
          ┌──────────┴──────────┐
          │                     │
     STORAGE LAYER         COMPUTE LAYER
          │                     │
    Data managed by       Virtual Warehouses
       Snowflake               │
          │                     │
    Micro-partitions       Execute SQL
    Columnar storage       Process data
    Compression            Consume compute
```

The key idea:

> **Storage and compute are separated.**

This is one of the fundamental differences between Snowflake's architecture and many traditional database systems.

---

# 3. Storage Layer

Snowflake stores table data in cloud storage.

At the infrastructure level, Snowflake operates on cloud providers such as:

```text
Snowflake
   │
   ├── AWS
   │    └── Cloud storage infrastructure
   │
   ├── Azure
   │    └── Cloud storage infrastructure
   │
   └── GCP
        └── Cloud storage infrastructure
```

### Important Interview Point

Don't say:

> "I create my Snowflake tables directly inside my S3 bucket."

That's not how normal Snowflake managed-table storage works.

Instead:

> **Snowflake manages the underlying cloud storage for Snowflake tables.**

External cloud storage becomes particularly relevant when working with **external stages, external tables, data loading, and data lake integrations**.

---

# 4. How Snowflake Stores Table Data

Snowflake internally organizes table data into **micro-partitions**.

Conceptually:

```text
Table
│
├── Micro-partition 1
├── Micro-partition 2
├── Micro-partition 3
├── Micro-partition 4
└── ...
```

Snowflake stores the data in a compressed, columnar-oriented format.

This architecture enables Snowflake to efficiently scan only the relevant portions of data rather than blindly reading the entire table.

### Why Micro-Partitions Matter

They are important for:

* Query performance
* Data pruning
* Storage organization
* Clustering behavior
* Efficient large-scale analytics

We'll study micro-partitions in much greater depth in a later chapter.

---

# 5. Compute Layer — Virtual Warehouses

A **Virtual Warehouse** is Snowflake's compute resource.

It executes operations such as:

* SQL queries
* Data loading
* Data transformation
* DML operations
* Other computational workloads

Example:

```sql
CREATE WAREHOUSE etl_wh;

CREATE WAREHOUSE bi_wh;
```

Conceptually:

```text
                 Snowflake Storage
                       │
          ┌────────────┼────────────┐
          │            │            │
       ETL WH        BI WH       Data Science WH
          │            │            │
       ETL jobs      Reports      Analytics
```

The warehouses use the same underlying Snowflake data but provide **independent compute resources**.

---

# 6. Why Separate Virtual Warehouses?

Imagine a company has:

```text
ETL jobs
    ↓
Heavy transformations

BI users
    ↓
Dashboards + reports
```

If both workloads compete for the same compute resources, heavy ETL processing could affect dashboard performance.

Snowflake allows you to separate them:

```text
                 Snowflake Data
                       │
              ┌────────┴────────┐
              │                 │
          ETL_WH             BI_WH
              │                 │
        ETL workloads       BI workloads
```

Now the ETL workload and BI workload have separate compute resources.

### Interview Answer

**Q: How does Snowflake prevent ETL workloads from affecting BI workloads?**

**Answer:**

> Snowflake separates storage from compute and allows workloads to use separate virtual warehouses. For example, ETL jobs can run on one warehouse while BI queries run on another, reducing compute contention between workloads.

---

# 7. What Problems Does Snowflake Solve?

## Problem 1 — Storage and Compute Are Tightly Coupled

### Traditional Architecture

In many traditional systems:

```text
Database Server
├── CPU
├── Memory
└── Storage
```

Increasing capacity often means scaling the database server itself.

This can make scaling more complicated.

### Snowflake

Snowflake separates storage and compute:

```text
          Storage
             │
     ┌───────┼────────┐
     │       │        │
    WH1     WH2      WH3
```

Storage and compute can be managed independently.

### Interview Keyword

**Separation of storage and compute**

---

# 8. Problem 2 — Workload Contention

Suppose:

```text
ETL → Heavy queries
BI  → Dashboard queries
```

With shared compute, heavy ETL processing can compete with BI workloads.

Snowflake can use:

```text
ETL → ETL_WH
BI  → BI_WH
```

Each workload gets its own compute resources.

### Important Nuance

Don't say:

> "Multiple warehouses mean there is zero performance impact."

That's too absolute.

Better:

> **Separate warehouses isolate compute workloads and reduce resource contention.**

The query itself can still be slow because of poor SQL, insufficient warehouse size, data volume, concurrency, pruning issues, etc.

---

# 9. Problem 3 — Infrastructure Management

Traditional/on-premises platforms can require teams to manage:

* Servers
* Storage
* Operating systems
* Capacity planning
* Hardware
* Infrastructure scaling

Snowflake is a **fully managed service**.

The customer primarily focuses on:

```text
Data
  ↓
SQL
  ↓
Data pipelines
  ↓
Analytics
```

rather than managing the underlying infrastructure.

---

# 10. Problem 4 — Semi-Structured Data

Traditional relational systems are primarily designed around structured tables:

```text
CUSTOMER
------------------
ID | NAME | EMAIL
```

Modern applications frequently produce:

```json
{
  "customer_id": 101,
  "name": "John",
  "orders": [
    {
      "id": 5001,
      "amount": 250
    }
  ]
}
```

Snowflake provides native support for semi-structured data and data types such as:

* `VARIANT`
* `OBJECT`
* `ARRAY`

This makes it possible to load and query JSON and other semi-structured data without first forcing everything into a traditional relational structure.

---

# 11. Problem 5 — Cost of Always-On Compute

Traditional infrastructure may keep servers running even when workloads are low.

Snowflake provides capabilities such as:

* Auto-suspend
* Auto-resume
* Warehouse sizing
* Separate warehouses
* Scaling options

For example:

```sql
CREATE WAREHOUSE etl_wh
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE;
```

Conceptually:

```text
No workload
     ↓
Warehouse suspended
     ↓
No active compute consumption
     ↓
New query arrives
     ↓
Warehouse resumes
```

This can help control compute costs.

**Important:** Storage and compute have separate cost considerations, and Snowflake billing has more nuance than simply "warehouse off = no Snowflake cost."

---

# 12. Snowflake Mental Model

Remember Snowflake using this:

```text
                 SNOWFLAKE
                     │
        ┌────────────┴────────────┐
        │                         │
     STORAGE                   COMPUTE
        │                         │
  Snowflake-managed         Virtual Warehouses
  cloud storage                   │
        │                    Execute workloads
  Micro-partitions                 │
  Compression                      │
  Columnar storage        ┌────────┼────────┐
                          │        │        │
                        ETL       BI     Analytics
                         WH        WH        WH
```

### The One Sentence to Remember

> **Snowflake separates storage from compute, allowing data to be centrally stored while different workloads use independent virtual warehouses for processing.**

---

# 13. Interview Q&A

### Q1. What is Snowflake?

**Answer:**

> Snowflake is a cloud-native, fully managed data platform used for data warehousing, analytics, data engineering, data sharing, and data-lake workloads. It runs on AWS, Azure, and GCP and separates storage from compute.

---

### Q2. What are the major layers of Snowflake architecture?

**Answer:**

> At a high level, Snowflake has a storage layer and a compute layer, with Snowflake-managed cloud services coordinating the platform. The storage layer manages persistent data, while virtual warehouses provide compute for executing workloads.

---

### Q3. What is a Virtual Warehouse?

**Answer:**

> A virtual warehouse is a Snowflake compute resource used to execute SQL queries and other data-processing workloads. It is independent from the storage layer.

---

### Q4. Why would you create separate warehouses for ETL and BI?

**Answer:**

> To isolate compute workloads. ETL jobs can consume significant resources, so placing ETL and BI workloads on separate warehouses reduces contention and helps maintain predictable BI performance.

---

### Q5. Does Snowflake store data in S3?

**Answer:**

**Careful answer:**

> Snowflake uses the underlying cloud provider's storage infrastructure, such as AWS, Azure, or GCP, for its managed storage. However, users don't normally manage the underlying bucket for standard Snowflake tables. External cloud storage is separately used through mechanisms such as external stages.

---

### Q6. What does separation of storage and compute mean?

**Answer:**

> Data storage and query-processing resources are independently managed. Snowflake can keep data in its storage layer while different virtual warehouses independently process that data.

---

### Q7. How does Snowflake handle semi-structured data?

**Answer:**

> Snowflake provides native semi-structured data support through types such as VARIANT, OBJECT, and ARRAY, allowing formats such as JSON to be stored and queried alongside relational data.

---

### Q8. Is Snowflake just a database?

**Answer:**

> No. Snowflake is broader than a traditional database. It is a cloud data platform providing data warehousing, analytics, data engineering, data sharing, and data-lake-related capabilities.

---

# 14. Common Interview Traps

### ❌ Trap 1

**"Snowflake is a database hosted on AWS."**

Too simplistic.

### ✅ Better

**"Snowflake is a cloud-native data platform that runs on AWS, Azure, and GCP."**

---

### ❌ Trap 2

**"Each warehouse stores its own copy of the data."**

Wrong.

### ✅ Correct

Multiple warehouses can access the same Snowflake-managed data while providing separate compute resources.

---

### ❌ Trap 3

**"Snowflake automatically makes every query fast."**

Nope.

Poor SQL can still be poor SQL.

Performance depends on things such as:

* Query design
* Data pruning
* Warehouse sizing
* Concurrency
* Clustering
* Caching
* Data volume
* Workload characteristics

---

### ❌ Trap 4

**"Snowflake = data warehouse only."**

Too narrow.

Snowflake has evolved into a broader cloud data platform.

---

# 15. 1-Minute Revision

Remember these **5 things**:

```text
1. Snowflake
   ↓
   Cloud-native data platform

2. Runs on
   ↓
   AWS / Azure / GCP

3. Architecture
   ↓
   Storage + Compute separated

4. Compute
   ↓
   Virtual Warehouses

5. Storage
   ↓
   Snowflake-managed cloud storage
   + micro-partitions
   + compressed columnar-oriented storage
```

### Interview Keywords

**Cloud-native** → Designed specifically for cloud environments.

**Separation of storage and compute** → Storage and processing scale/manage independently.

**Virtual Warehouse** → Independent Snowflake compute resource.

**Micro-partition** → Snowflake's internal unit of table-data organization.

**Fully managed** → Snowflake manages underlying infrastructure.

**VARIANT** → Snowflake data type commonly used for semi-structured data.

---

## What We Need to Learn Next

This foundation naturally leads to:

```text
Snowflake Fundamentals
        ↓
Snowflake Architecture
        ↓
Databases & Schemas
        ↓
Tables
        ↓
Micro-partitions ⭐
        ↓
Virtual Warehouses ⭐
        ↓
Caching
        ↓
Data Loading
        ↓
Stages
        ↓
COPY INTO
        ↓
Snowpipe
```

**Interview priority:** ⭐⭐⭐⭐⭐

The two concepts I want you to understand deeply—not memorize—are:

1. **Micro-partitions**
2. **Virtual Warehouses + separation of storage and compute**

Those two will keep coming back when we discuss **performance, scaling, cost optimization, and real-world Snowflake architecture**.
