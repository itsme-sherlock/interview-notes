# Snowflake Fundamentals & Architecture — Interview Study Guide

**Purpose:** Snowflake Data Engineer Interview Preparation  
**Level:** Beginner → Intermediate  
**Status:** Chapter 01 — Consolidated

---

## Quick Sheet

- **Snowflake** = Cloud-native data platform used for data warehousing, analytics, data engineering, data sharing, and data-lake workloads.
- **Cloud platforms:** Snowflake runs on AWS, Microsoft Azure, and Google Cloud.
- **3 major architectural layers:** Cloud Services, Compute, and Storage.
- **Storage layer:** Snowflake-managed persistent storage where table data is organized into micro-partitions.
- **Compute layer:** Virtual Warehouses provide compute resources to execute queries and workloads.
- **Cloud Services layer:** Handles authentication, authorization, metadata, query parsing/optimization, coordination, and other control-plane functions.
- **Separation of storage and compute:** Storage and compute can be managed/scaled independently.
- **Virtual Warehouses:** Different workloads can use separate compute resources, reducing resource contention.
- **Micro-partitions:** Automatically created and managed by Snowflake; users don't manually create them for standard Snowflake tables.
- **Immutable data:** Micro-partitions are immutable; logical UPDATE/DELETE operations are handled without modifying an existing micro-partition in place.
- **Semi-structured data:** Snowflake supports JSON and similar data through types such as `VARIANT`, `OBJECT`, and `ARRAY`.
- **Warehouse scaling:** Scale up = larger warehouse; scale out = additional clusters in a multi-cluster warehouse.
- **Cost management:** Warehouses can be suspended and resumed; auto-suspend/auto-resume can reduce unnecessary compute usage.

---

# Table of Contents

1. [Why Do We Need Snowflake?](#1-why-do-we-need-snowflake)
2. [What Is Snowflake?](#2-what-is-snowflake)
3. [Snowflake 3-Layer Architecture](#3-snowflake-3-layer-architecture)
4. [Storage Layer](#4-storage-layer)
5. [Micro-Partitions](#5-micro-partitions)
6. [Columnar Storage](#6-columnar-storage)
7. [Immutable Data](#7-immutable-data)
8. [Compute Layer — Virtual Warehouses](#8-compute-layer--virtual-warehouses)
9. [Warehouse Scaling](#9-warehouse-scaling)
10. [Suspend and Resume](#10-suspend-and-resume)
11. [Caching](#11-caching)
12. [Cloud Services Layer](#12-cloud-services-layer)
13. [Query Execution Flow](#13-query-execution-flow)
14. [Why Snowflake Architecture Is Powerful](#14-why-snowflake-architecture-is-powerful)
15. [Snowflake and Semi-Structured Data](#15-snowflake-and-semi-structured-data)
16. [Common Interview Traps](#16-common-interview-traps)
17. [Interview Q&A](#17-interview-qa)
18. [Revision Summary](#18-revision-summary)
19. [What to Learn Next](#19-what-to-learn-next)

---

# 1. Why Do We Need Snowflake?

## The Traditional Problem

Traditional database/data-warehouse environments often have infrastructure where storage and compute are closely connected.

Conceptually:

```text
Traditional Database Server
│
├── CPU
├── Memory
└── Storage
```

If workload increases, scaling can involve scaling the underlying database infrastructure.

This can create challenges around:

- Capacity planning
- Infrastructure management
- Scaling
- Workload contention
- Maintenance
- Cost management

## Problem 1 — Storage and Compute Scaling

You may want to increase compute without necessarily increasing storage.

Snowflake separates the two:

```text
              STORAGE
                 │
       ┌─────────┼─────────┐
       │         │         │
     ETL_WH    BI_WH    ANALYTICS_WH
       │         │         │
      ETL       BI      Analytics
```

Storage and compute can therefore be managed independently.

## Problem 2 — Workload Contention

Suppose a company has:

```text
ETL jobs
   +
BI dashboards
   +
Ad-hoc analytics
```

If all workloads share the same compute resources, heavy ETL processing may compete with BI queries.

Snowflake allows:

```text
ETL        → ETL_WH
BI         → BI_WH
Analytics  → ANALYTICS_WH
```

This provides **workload isolation**.

## Problem 3 — Infrastructure Management

On-premises environments can require teams to manage:

- Servers
- Storage
- Operating systems
- Hardware
- Capacity
- Infrastructure scaling
- Database infrastructure

Snowflake is a **fully managed cloud service**, so the customer focuses primarily on data, SQL, pipelines, security, and workloads rather than managing the underlying infrastructure.

## Problem 4 — Semi-Structured Data

Modern applications generate data such as:

```json
{
  "customer_id": 101,
  "name": "John",
  "orders": [
    {
      "order_id": 5001,
      "amount": 250
    }
  ]
}
```

Snowflake supports semi-structured data natively using types such as:

- `VARIANT`
- `OBJECT`
- `ARRAY`

## Problem 5 — Always-On Compute

Traditional infrastructure may keep compute resources running even when workloads are low.

Snowflake provides warehouse controls such as:

- Auto-suspend
- Auto-resume
- Warehouse sizing
- Multi-cluster warehouses

These can help manage compute consumption and cost.

---

# 2. What Is Snowflake?

## Simple Definition

**Snowflake is a cloud-native data platform used for storing, processing, transforming, and analyzing data at scale.**

It supports workloads including:

- Data warehousing
- Data engineering
- Analytics
- Data sharing
- Data lake-related workloads
- Semi-structured data processing

Snowflake is available on:

- Amazon Web Services (AWS)
- Microsoft Azure
- Google Cloud

## Why Is Snowflake Cloud-Native?

Snowflake was designed specifically for cloud environments rather than simply being an on-premises database moved to the cloud.

Users do not normally manage:

- Physical servers
- Operating systems
- Storage hardware
- Compute hardware
- Database infrastructure

Snowflake manages the underlying platform infrastructure.

### Interview Answer

**Q: Is Snowflake just a database?**

> No. Snowflake is broader than a traditional database. It is a cloud data platform that supports data warehousing, analytics, data engineering, data sharing, and data-lake-related workloads.

---

# 3. Snowflake 3-Layer Architecture

Snowflake can be understood using three major architectural layers:

```text
                         SNOWFLAKE
                             │
             ┌───────────────┼────────────────┐
             │               │                │
             ▼               ▼                ▼
      Cloud Services      Compute          Storage
          Layer            Layer             Layer
        "Brain"          "Muscle"           "Data"
             │               │                │
      Authentication     Virtual WHs      Persistent Data
      Authorization       SQL execution    Micro-partitions
      Metadata            ETL/ELT           Compression
      Optimization        BI               Columnar storage
      Coordination        Analytics
```

### Easy Mental Model

```text
Cloud Services → Decides / Coordinates
Compute        → Does the Work
Storage        → Stores the Data
```

Or:

> **Cloud Services decides. Compute works. Storage remembers.**

---

# 4. Storage Layer

## What Does the Storage Layer Do?

The storage layer provides persistent storage for Snowflake data.

Snowflake operates on cloud platforms such as:

```text
AWS
Azure
GCP
```

The underlying cloud storage infrastructure is managed by Snowflake.

## Important Clarification

A common beginner explanation is:

> "Snowflake stores its data in S3/Blob Storage."

This is directionally correct at the infrastructure level but can be misleading.

For **Snowflake-managed tables**, customers do not normally create and manage the underlying S3/Azure Blob/GCS location themselves.

Snowflake manages the underlying storage.

External cloud storage is separately relevant when working with:

- External stages
- External tables
- Data lake integrations
- Loading/unloading data

## Storage Mental Model

```text
                 SNOWFLAKE
                     │
                     ▼
              Storage Layer
                     │
             Snowflake-managed
               cloud storage
                     │
             ┌───────┼───────┐
             ▼       ▼       ▼
           MP1     MP2     MP3
             │       │       │
             └── Micro-partitions ──┘
```

---

# 5. Micro-Partitions

## What Is a Micro-Partition?

A **micro-partition** is an automatically managed unit of Snowflake table storage.

Snowflake automatically organizes table data into micro-partitions.

Users do not manually create traditional partitions for standard Snowflake table storage.

## Conceptual Example

```text
EMPLOYEE TABLE
│
├── Micro-partition 1
├── Micro-partition 2
├── Micro-partition 3
├── Micro-partition 4
└── ...
```

## Micro-Partition Size

A YouTube explanation may say:

> "Micro-partitions are approximately 16 MB."

Do **not** memorize that as the Snowflake specification.

Snowflake documentation describes micro-partitions as generally containing roughly **50–500 MB of uncompressed data**.

The actual physical storage size can be smaller because of compression.

### Interview-safe statement

> Snowflake automatically divides table data into micro-partitions. Their size is managed by Snowflake and is not something users manually define like traditional database partitions.

## Why Micro-Partitions Matter

Micro-partitions are important for:

- Query performance
- Data pruning
- Metadata
- Compression
- Clustering
- Large-scale analytical queries

## Micro-Partition Metadata

Snowflake maintains metadata associated with micro-partitions.

This metadata can help Snowflake determine whether a micro-partition can contain relevant data.

For example:

```sql
SELECT *
FROM employee
WHERE salary > 100000;
```

Snowflake can use metadata to identify micro-partitions that are unlikely to contain matching values.

This leads to:

```text
Less data scanned
       ↓
Less processing
       ↓
Better query performance
```

This is called **data pruning**.

---

# 6. Columnar Storage

Snowflake uses a columnar-oriented storage architecture that is well suited to analytical workloads.

## Row-Oriented Thinking

```text
Row 1 → ID | Name | Salary | Country
Row 2 → ID | Name | Salary | Country
Row 3 → ID | Name | Salary | Country
```

## Columnar Thinking

```text
ID
→ 1, 2, 3, 4...

NAME
→ John, Ravi, Alex...

SALARY
→ 10000, 20000, 30000...

COUNTRY
→ India, USA, India...
```

Suppose the query is:

```sql
SELECT country, SUM(salary)
FROM employee
GROUP BY country;
```

The query primarily needs:

```text
COUNTRY
SALARY
```

It does not necessarily need:

```text
ID
NAME
```

Columnar storage is therefore particularly useful for analytical queries.

### Interview Keyword

> **Columnar storage → analytical workloads → efficient scanning and compression**

---

# 7. Immutable Data

One of the important Snowflake storage concepts is **immutable micro-partitions**.

## What Does Immutable Mean?

An existing micro-partition is not simply opened and modified in place.

Conceptually:

```text
Existing Micro-partition
        │
        │ UPDATE
        ▼
New storage representation
```

This is different from saying that Snowflake tables cannot be updated.

You can absolutely execute:

```sql
UPDATE employee
SET salary = 50000
WHERE id = 101;
```

The important distinction is:

> **The logical table can be updated, while the underlying micro-partitions are immutable.**

This architecture contributes to capabilities such as:

- Time Travel
- Data versioning behavior
- Consistent data management
- Zero-copy cloning architecture

---

# 8. Compute Layer — Virtual Warehouses

## What Is a Virtual Warehouse?

A **Virtual Warehouse** is a Snowflake compute resource used to execute workloads.

It provides compute resources such as:

- CPU
- Memory

A warehouse can execute:

- SQL queries
- ETL workloads
- ELT transformations
- Data loading
- BI workloads
- Analytical workloads

## Example

```sql
CREATE WAREHOUSE etl_wh;

CREATE WAREHOUSE bi_wh;
```

Conceptually:

```text
                Snowflake Data
                      │
             ┌────────┴────────┐
             │                 │
          ETL_WH             BI_WH
             │                 │
          ETL/ELT          Dashboards
```

Both warehouses can access the same underlying Snowflake data.

---

# 9. Warehouse Scaling

There are two important scaling concepts.

## 9.1 Scale Up

**Scale up = increase the size of a warehouse.**

Conceptually:

```text
Small
  ↓
Medium
  ↓
Large
  ↓
X-Large
```

You are giving one warehouse more compute capacity.

Useful when:

- Individual queries need more resources
- Transformations are heavy
- Queries are processing large amounts of data

## 9.2 Scale Out

**Scale out = add additional compute clusters.**

This is associated with **multi-cluster warehouses**.

Conceptually:

```text
                 BI Warehouse
                      │
          ┌───────────┼───────────┐
          ▼           ▼           ▼
       Cluster 1   Cluster 2   Cluster 3
          │           │           │
        Users       Users       Users
```

This is particularly useful for **high concurrency**.

## Scale Up vs Scale Out

| Concept | Meaning | Main Purpose |
|---|---|---|
| **Scale Up** | Increase warehouse size | More compute capacity |
| **Scale Out** | Add clusters | Handle more concurrent workloads |

### Interview Question

**Q: What is the difference between scaling up and scaling out in Snowflake?**

**Answer:**

> Scaling up means increasing the size of a virtual warehouse to provide more compute resources. Scaling out means adding clusters to a multi-cluster warehouse, primarily to handle higher concurrency.

---

# 10. Suspend and Resume

Snowflake warehouses can be suspended when they are not needed.

```sql
ALTER WAREHOUSE etl_wh SUSPEND;

ALTER WAREHOUSE etl_wh RESUME;
```

You can also configure automatic suspension and resumption.

Example:

```sql
CREATE WAREHOUSE etl_wh
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;
```

## How It Works

```text
No workload
     ↓
Warehouse suspended
     ↓
Compute resources released
     ↓
Query arrives
     ↓
Warehouse resumes
     ↓
Query executes
```

## Why Suspend a Warehouse?

Primarily:

> **To avoid unnecessary compute consumption when the warehouse is idle.**

Suspending a warehouse does **not** delete your data.

The data remains in the storage layer.

---

# 11. Caching

Snowflake uses caching mechanisms to improve query performance.

A beginner explanation may simply say:

> "Snowflake caches query results."

That's incomplete.

At a high level, think about:

```text
Caching
│
├── Query result reuse
├── Warehouse/local data cache
└── Metadata-related caching
```

Caching can reduce the amount of work required for subsequent queries in appropriate situations.

### Important

Cache reuse depends on conditions. It is not correct to assume every repeated query will always use cache.

A dedicated performance chapter will cover the different cache mechanisms in detail.

---

# 12. Cloud Services Layer

The Cloud Services layer is responsible for many of Snowflake's **control, coordination, and management functions**.

Think of it as the:

> **Brain of Snowflake**

## Major Responsibilities

### Authentication

Determines:

> Who are you?

### Authorization

Determines:

> What are you allowed to access?

This works closely with Snowflake's role-based access control (RBAC).

### Metadata Management

Maintains information about objects such as:

- Databases
- Schemas
- Tables
- Columns
- Views
- Other Snowflake objects

### Query Parsing

Understands the SQL submitted by the user.

### Query Optimization

Determines an efficient strategy for executing the query.

### Query Coordination

Coordinates execution across the Snowflake platform.

### Transaction Management

Supports transaction behavior and ACID properties.

## Cloud Services vs Compute

| Layer | Main Responsibility |
|---|---|
| **Cloud Services** | Management, coordination, metadata, authentication, optimization |
| **Compute / Warehouse** | Executes workloads using CPU and memory |
| **Storage** | Persists data |

### Easy Memory Trick

```text
Cloud Services → Brain
Virtual Warehouse → Muscle
Storage → Memory
```

---

# 13. Query Execution Flow

Suppose a user executes:

```sql
SELECT *
FROM employee
WHERE country = 'India';
```

## Step 1 — User Sends Query

The query can originate from:

- Snowsight
- SQL client
- BI tool
- Application
- Data pipeline

```text
User / BI Tool
      │
      ▼
SELECT ...
```

## Step 2 — Cloud Services

Cloud Services performs control and coordination functions such as:

```text
Authentication
      ↓
Authorization
      ↓
Parsing
      ↓
Optimization
      ↓
Coordination
```

## Step 3 — Compute Layer

The query is executed using the selected virtual warehouse.

```text
Cloud Services
      │
      ▼
Virtual Warehouse
      │
      ▼
CPU + Memory
```

## Step 4 — Storage Access

The warehouse accesses the required data from Snowflake's storage layer.

Snowflake can use micro-partition metadata for pruning.

Conceptually:

```text
Table
│
├── MP1 → irrelevant → skip
├── MP2 → irrelevant → skip
├── MP3 → possible match → scan
└── MP4 → possible match → scan
```

This can reduce unnecessary scanning.

## Step 5 — Result Returned

```text
Storage
   ↓
Virtual Warehouse
   ↓
Query processing
   ↓
Result
   ↓
User
```

---

# 14. Why Snowflake Architecture Is Powerful

## 1. Separation of Storage and Compute

```text
             STORAGE
                │
      ┌─────────┼─────────┐
      │         │         │
    ETL_WH    BI_WH    ANALYTICS_WH
```

Storage and compute can be managed independently.

## 2. Workload Isolation

```text
ETL        → ETL_WH
BI         → BI_WH
Analytics  → ANALYTICS_WH
```

This reduces compute contention.

### Important

Do not say:

> "There is zero performance impact."

Better:

> **Separate warehouses reduce compute resource contention and provide workload isolation.**

A poorly designed query can still be slow.

## 3. High Concurrency

Multi-cluster warehouses can add clusters to handle higher concurrent workloads.

## 4. Cost Optimization

Warehouses can be:

- Sized appropriately
- Suspended when idle
- Automatically resumed when needed

## 5. Reduced Infrastructure Management

Snowflake is fully managed.

The customer does not normally manage the underlying servers and storage infrastructure.

---

# 15. Snowflake and Semi-Structured Data

Snowflake supports structured and semi-structured data.

## Structured Data

```text
CUSTOMER

ID | NAME | EMAIL
---|------|------
1  | John | ...
2  | Ravi | ...
```

## Semi-Structured Data

Example:

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

Snowflake provides data types such as:

```text
VARIANT
OBJECT
ARRAY
```

These allow semi-structured data to be stored and queried.

---

# 16. Common Interview Traps

## Trap 1 — "Snowflake is just a database hosted on AWS."

### Too simplistic

Snowflake is a cloud-native data platform and is available across:

- AWS
- Azure
- GCP

### Better

> Snowflake is a cloud-native data platform that runs on AWS, Azure, and GCP.

---

## Trap 2 — "Snowflake stores my tables directly in my S3 bucket."

### Misleading

For normal Snowflake-managed tables, Snowflake manages the underlying storage.

### Better

> Snowflake uses the cloud provider's underlying storage infrastructure, while Snowflake manages the storage for standard Snowflake tables.

External stages are a separate concept.

---

## Trap 3 — "Micro-partitions are always 16 MB."

### Don't memorize this.

Micro-partition size is managed automatically by Snowflake.

### Better

> Snowflake automatically creates and manages micro-partitions, generally containing roughly 50–500 MB of uncompressed data.

---

## Trap 4 — "Snowflake tables cannot be updated because micro-partitions are immutable."

### Wrong

You can run:

```sql
UPDATE employee
SET salary = 50000
WHERE id = 101;
```

### Correct

> Snowflake supports logical DML operations, while the underlying micro-partitions remain immutable.

---

## Trap 5 — "Separate warehouses mean zero performance problems."

### Wrong

Separate warehouses reduce **compute contention**, but queries can still be slow because of:

- Poor SQL
- Large data scans
- Poor pruning
- Warehouse sizing
- Concurrency
- Clustering
- Other workload characteristics

---

## Trap 6 — "Auto scaling always means increasing warehouse size."

### Wrong

Snowflake has different scaling concepts.

```text
Scale Up
→ Increase warehouse size

Scale Out
→ Add clusters
```

---

# 17. Interview Q&A

## Basic Questions

### Q1. What is Snowflake?

**Answer:**

> Snowflake is a cloud-native, fully managed data platform used for data warehousing, analytics, data engineering, data sharing, and data-lake-related workloads. It runs on AWS, Azure, and GCP and separates storage from compute.

### Q2. What are the three major layers of Snowflake architecture?

**Answer:**

> Snowflake's architecture can be understood as Cloud Services, Compute, and Storage. Cloud Services handles management and coordination functions, Compute provides virtual warehouses that execute workloads, and Storage persists data.

### Q3. What is a Virtual Warehouse?

**Answer:**

> A virtual warehouse is a Snowflake compute resource that provides CPU and memory for executing queries and other workloads.

### Q4. Why use separate warehouses for ETL and BI?

**Answer:**

> Separate warehouses isolate compute workloads. ETL processing can therefore run on one warehouse while BI queries run on another, reducing resource contention.

### Q5. What is separation of storage and compute?

**Answer:**

> It means Snowflake's persistent data storage and query-processing compute resources are independently managed. Multiple virtual warehouses can access the same underlying data.

### Q6. What is a micro-partition?

**Answer:**

> A micro-partition is an automatically managed unit of Snowflake table storage. Snowflake organizes table data into micro-partitions and maintains metadata that can be used for efficient data pruning.

### Q7. Are micro-partitions manually created?

**Answer:**

> No. Snowflake automatically creates and manages micro-partitions for standard Snowflake tables.

### Q8. What is immutable data in Snowflake?

**Answer:**

> Snowflake micro-partitions are immutable. Logical DML operations such as UPDATE and DELETE are supported, but Snowflake does not simply modify an existing micro-partition in place.

### Q9. What is the difference between scale up and scale out?

**Answer:**

> Scale up increases the size of a warehouse to provide more compute resources. Scale out adds clusters in a multi-cluster warehouse to handle higher concurrency.

### Q10. What happens when a warehouse is suspended?

**Answer:**

> The warehouse's compute resources are suspended, but the data remains available in the storage layer. The warehouse can be resumed when required.

### Q11. How does Snowflake handle semi-structured data?

**Answer:**

> Snowflake supports semi-structured data using types such as VARIANT, OBJECT, and ARRAY, allowing formats such as JSON to be stored and queried alongside relational data.

---

## Intermediate Questions

### Q12. Explain Snowflake's architecture.

**Answer:**

> Snowflake uses a three-layer architecture: Cloud Services, Compute, and Storage. Cloud Services handles authentication, authorization, metadata management, query parsing, optimization, transaction management, and coordination. The Compute layer consists of virtual warehouses that execute workloads. The Storage layer persists data in Snowflake-managed cloud storage, with table data organized into micro-partitions.

### Q13. Why is Snowflake's separation of storage and compute important?

**Answer:**

> It allows storage and compute to be managed independently. It also allows different workloads to use separate virtual warehouses, reducing compute contention and improving workload isolation.

### Q14. How can Snowflake improve BI performance when ETL is running?

**Answer:**

> Use separate virtual warehouses for ETL and BI. The ETL workload runs on its own compute resources while BI queries use another warehouse, reducing competition for compute resources.

### Q15. How do micro-partitions improve query performance?

**Answer:**

> Snowflake maintains metadata about micro-partitions. When a query contains filters that can be evaluated using this metadata, Snowflake can prune micro-partitions that cannot contain matching data, reducing the amount of data that needs to be scanned.

### Q16. Does Snowflake automatically make every query fast?

**Answer:**

> No. Snowflake provides an architecture optimized for large-scale analytics, but query performance still depends on SQL design, data volume, pruning, warehouse sizing, concurrency, clustering, caching, and workload characteristics.

---

## Scenario Questions

### Q17. A heavy ETL job is slowing down BI dashboards. What would you do?

**Answer:**

> First, determine whether both workloads are sharing the same virtual warehouse. If so, separate them into dedicated warehouses such as ETL_WH and BI_WH. Then monitor query performance, concurrency, warehouse utilization, and cost. If necessary, adjust warehouse sizing or use multi-cluster capabilities for concurrency.

### Q18. A BI team says queries are slow during peak hours. What would you investigate?

**Answer:**

> I would investigate query history, warehouse utilization, concurrency, warehouse size, query execution details, data scanned, partition pruning, clustering, and caching behavior. If concurrency is the main problem, a multi-cluster warehouse may help. If individual queries are resource-intensive, increasing warehouse size may be more appropriate.

### Q19. Why don't Snowflake users manually partition tables like traditional databases?

**Answer:**

> Snowflake automatically organizes table data into micro-partitions. Users generally don't manually define the physical micro-partition structure. Instead, users can influence data organization through loading patterns and clustering strategies when necessary.

---

# 18. Revision Summary

## 1-Minute Recap

### Snowflake

Cloud-native data platform for:

```text
Warehousing
Analytics
Data Engineering
Data Sharing
Data Lake Workloads
```

### Architecture

```text
Cloud Services
      ↓
Management / Coordination

Compute
      ↓
Virtual Warehouses
      ↓
Execute workloads

Storage
      ↓
Persistent data
      ↓
Micro-partitions
```

## Most Important Concepts

### 1. Storage ≠ Compute

```text
Storage → stores data
Compute  → processes data
```

They are separated.

### 2. Virtual Warehouse

```text
Virtual Warehouse
       ↓
CPU + Memory
       ↓
Execute workload
```

### 3. Micro-Partitions

```text
Table
 ↓
Automatically organized
 ↓
Micro-partitions
 ↓
Metadata
 ↓
Pruning
 ↓
Less data scanned
```

### 4. Cloud Services

```text
Authentication
Authorization
Metadata
Parsing
Optimization
Coordination
Transactions
```

### 5. Scaling

```text
Scale UP
→ Bigger warehouse

Scale OUT
→ More clusters
```

## Interview Keywords

| Keyword | Meaning |
|---|---|
| **Cloud-native** | Designed specifically for cloud environments |
| **Cloud Services** | Management and coordination layer |
| **Virtual Warehouse** | Snowflake compute resource |
| **Storage Layer** | Persistent data storage |
| **Micro-partition** | Automatically managed unit of table storage |
| **Immutable** | Existing micro-partitions are not modified in place |
| **Data pruning** | Avoiding unnecessary micro-partition scans |
| **Columnar storage** | Data organized efficiently by columns for analytics |
| **Scale Up** | Increase warehouse size |
| **Scale Out** | Add clusters |
| **Workload isolation** | Separate workloads using separate warehouses |
| **VARIANT** | Data type commonly used for semi-structured data |

## Important SQL

### Create Warehouse

```sql
CREATE WAREHOUSE etl_wh;
```

### Create Warehouse with Auto Suspend/Resume

```sql
CREATE WAREHOUSE etl_wh
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;
```

### Suspend Warehouse

```sql
ALTER WAREHOUSE etl_wh SUSPEND;
```

### Resume Warehouse

```sql
ALTER WAREHOUSE etl_wh RESUME;
```

---

# 19. What to Learn Next

The next concepts should build directly on this architecture:

```text
Snowflake Fundamentals
        ↓
Databases & Schemas
        ↓
Tables & Views
        ↓
Micro-Partitions ⭐
        ↓
Partition Metadata
        ↓
Data Pruning ⭐
        ↓
Clustering ⭐
        ↓
Virtual Warehouse Deep Dive
        ↓
Warehouse Sizing
        ↓
Concurrency
        ↓
Caching
        ↓
Performance Optimization
```

### Highest Priority

For a **Snowflake Data Engineer interview**, don't just memorize the three-layer diagram.

You should eventually be able to explain this chain naturally:

```text
User Query
    ↓
Cloud Services
    ↓
Authentication / Authorization
    ↓
Parse + Optimize
    ↓
Virtual Warehouse
    ↓
Micro-partition Metadata
    ↓
Partition Pruning
    ↓
Read Required Data
    ↓
Process
    ↓
Return Result
```

That chain connects **architecture → performance → cost → troubleshooting**, which is exactly where interview questions tend to become scenario-based.

---

## Chapter Status

**Chapter 01: Snowflake Fundamentals & Architecture**

- [x] What is Snowflake?
- [x] Why Snowflake?
- [x] Cloud-native concept
- [x] 3-layer architecture
- [x] Storage layer
- [x] Columnar storage
- [x] Micro-partitions — fundamentals
- [x] Immutable data — fundamentals
- [x] Compute layer
- [x] Virtual Warehouses
- [x] Workload isolation
- [x] Scale up
- [x] Scale out
- [x] Suspend / Resume
- [x] Caching — introduction
- [x] Cloud Services layer
- [x] Query execution flow
- [x] Interview questions
- [x] Common interview traps

**Next:** Micro-partitions, pruning, clustering, and deeper warehouse concepts.
