# Snowflake Virtual Warehouses & Performance — Interview Study Guide

**Purpose:** Snowflake Data Engineer Interview Preparation  
**Level:** Beginner → Intermediate  
**Status:** Chapter 02 — Draft Placeholder

---

## Quick Sheet

- **Virtual Warehouse:** Snowflake compute resource used to execute SQL queries and workloads.
- **Storage and compute separation:** Warehouses process data stored independently in Snowflake storage.
- **Scale up:** Increase the warehouse size to provide more compute resources.
- **Scale out:** Add clusters through a multi-cluster warehouse to support higher concurrency.
- **Auto-suspend:** Automatically pauses an idle warehouse to reduce compute consumption.
- **Auto-resume:** Automatically starts a suspended warehouse when a query requires it.
- **Workload isolation:** Separate warehouses can be used for ETL, BI, reporting, and ad-hoc workloads.
- **Performance tuning:** Query design, warehouse sizing, caching, pruning, clustering, and concurrency all affect performance.

---

# Table of Contents

1. [What Is a Virtual Warehouse?](#1-what-is-a-virtual-warehouse)
2. [Warehouse Architecture](#2-warehouse-architecture)
3. [Warehouse Sizing](#3-warehouse-sizing)
4. [Scale Up vs Scale Out](#4-scale-up-vs-scale-out)
5. [Multi-Cluster Warehouses](#5-multi-cluster-warehouses)
6. [Suspend and Resume](#6-suspend-and-resume)
7. [Workload Isolation](#7-workload-isolation)
8. [Performance Fundamentals](#8-performance-fundamentals)
9. [Caching](#9-caching)
10. [Query Performance Checklist](#10-query-performance-checklist)
11. [Common Interview Questions](#11-common-interview-questions)
12. [Scenarios](#12-scenarios)
13. [Revision Summary](#13-revision-summary)

---

# 1. What Is a Virtual Warehouse?

A **Virtual Warehouse** is a Snowflake compute resource that provides CPU, memory, and temporary compute capacity for executing workloads.

A warehouse can run:

- SQL queries
- ETL and ELT transformations
- Data loading and unloading
- BI dashboards
- Reporting workloads
- Ad-hoc analytics

```sql
CREATE WAREHOUSE etl_wh
    WAREHOUSE_SIZE = 'MEDIUM'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;
```

A warehouse does not contain the permanent table data. Snowflake stores data separately, allowing compute resources to be resized or isolated without moving the data.

---

# 2. Warehouse Architecture

```text
                    Snowflake Storage
                           │
             ┌─────────────┼─────────────┐
             │             │             │
          ETL_WH         BI_WH      ANALYTICS_WH
             │             │             │
          ETL/ELT      Dashboards      Ad-hoc SQL
```

The same data can be accessed by multiple warehouses, while each warehouse provides independent compute resources.

## Key Idea

> Storage stores the data. A virtual warehouse performs the work.

---

# 3. Warehouse Sizing

Snowflake warehouse sizes provide progressively more compute capacity.

```text
X-Small → Small → Medium → Large → X-Large → ...
```

A larger warehouse may help when:

- A single query needs more CPU or memory.
- A transformation processes a large volume of data.
- A query spills because available memory is insufficient.
- A batch workload has a strict completion deadline.

Increasing warehouse size is not a replacement for fixing inefficient SQL. Always investigate query plans, pruning, joins, filters, and data volume before scaling indefinitely.

## Example

```sql
ALTER WAREHOUSE etl_wh
    SET WAREHOUSE_SIZE = 'LARGE';
```

---

# 4. Scale Up vs Scale Out

| Concept | Meaning | Best Fit |
|---|---|---|
| **Scale up** | Increase the size of one warehouse | More resources for individual queries |
| **Scale out** | Add clusters to a multi-cluster warehouse | Higher concurrency |

## Scale Up

```text
Small Warehouse
       │
       ▼
Larger Warehouse
       │
       ▼
More resources for each workload
```

## Scale Out

```text
                 Multi-Cluster Warehouse
                         │
              ┌──────────┼──────────┐
              ▼          ▼          ▼
           Cluster 1  Cluster 2  Cluster 3
```

### Interview Answer

> Scaling up increases the compute capacity of a warehouse. Scaling out adds clusters so more concurrent workloads can run with less queuing.

---

# 5. Multi-Cluster Warehouses

A multi-cluster warehouse can start additional clusters when concurrency increases.

```sql
CREATE WAREHOUSE bi_wh
    WAREHOUSE_SIZE = 'MEDIUM'
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 3
    SCALING_POLICY = 'STANDARD';
```

Multi-cluster warehouses are primarily intended for concurrency management. They are not automatically the best solution for a single slow query.

## Use Multi-Cluster Warehouses When

- Many users query dashboards at the same time.
- Workloads queue because of concurrency.
- Demand varies during the day.
- A BI or serving workload needs additional clusters during peak periods.

---

# 6. Suspend and Resume

Suspending an idle warehouse releases its running compute resources while preserving the data in storage.

```sql
ALTER WAREHOUSE etl_wh SUSPEND;
ALTER WAREHOUSE etl_wh RESUME;
```

Automatic controls are commonly configured as follows:

```sql
ALTER WAREHOUSE etl_wh SET
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;
```

```text
No workload
     ↓
Warehouse suspends
     ↓
Compute usage stops
     ↓
New query arrives
     ↓
Warehouse resumes
     ↓
Query executes
```

A short auto-suspend interval can reduce idle cost, but frequent suspend/resume cycles may introduce startup latency. The appropriate setting depends on workload behavior.

---

# 7. Workload Isolation

Separate warehouses can isolate workloads that have different schedules, priorities, or concurrency patterns.

```text
Batch ETL       → ETL_WH
BI dashboards   → BI_WH
Data science    → DS_WH
Ad-hoc queries  → ANALYTICS_WH
```

This reduces competition for the same compute resources.

> Separate warehouses reduce compute contention; they do not guarantee that every query will be fast.

---

# 8. Performance Fundamentals

Snowflake query performance can be influenced by several areas:

- Warehouse size and availability
- Query complexity
- Amount of data scanned
- Micro-partition pruning
- Join strategy and join cardinality
- Data skew
- Clustering quality
- Concurrency and queuing
- Result and warehouse caching
- Data loading and table design

## Basic Performance Flow

```text
Query submitted
      ↓
Cloud Services parses and optimizes
      ↓
Warehouse executes the plan
      ↓
Storage provides required data
      ↓
Result returned
```

A slow query should be diagnosed rather than solved only by increasing warehouse size.

---

# 9. Caching

Snowflake can reuse work in appropriate situations through caching mechanisms.

At a high level, consider:

```text
Caching
├── Persisted query result reuse
├── Warehouse-local data cache
└── Metadata and optimization information
```

Cache reuse depends on factors such as query text, result validity, underlying data changes, warehouse state, and session or workload conditions. Do not assume that every repeated query will always be served from cache.

---

# 10. Query Performance Checklist

When investigating a slow query:

1. Confirm that the correct warehouse is being used.
2. Check whether the query is queued behind other workloads.
3. Review the query profile.
4. Check bytes scanned and partitions scanned.
5. Verify that filters enable effective pruning.
6. Avoid selecting unnecessary columns.
7. Review joins for unexpected row multiplication.
8. Check for data skew and spill behavior.
9. Consider clustering only when the workload justifies it.
10. Resize the warehouse or add clusters based on the diagnosed bottleneck.

## Example of Avoiding an Unnecessary Scan

```sql
SELECT customer_id, order_date, total_amount
FROM orders
WHERE order_date >= '2026-01-01';
```

Selecting only required columns and filtering on useful predicates can reduce the amount of data processed.

---

# 11. Common Interview Questions

## Q1. What is a virtual warehouse?

> A virtual warehouse is a Snowflake compute resource used to execute queries, transformations, loading, and other workloads. It is separate from the storage layer.

## Q2. What is the difference between scaling up and scaling out?

> Scaling up increases the size of a warehouse. Scaling out adds clusters to a multi-cluster warehouse to support more concurrent workloads.

## Q3. Does a larger warehouse always make a query faster?

> No. A larger warehouse can provide more resources, but poor SQL, excessive scanning, inefficient joins, or limited pruning may still be the main bottleneck.

## Q4. Why use separate warehouses for ETL and BI?

> Separate warehouses provide workload isolation and reduce compute contention between batch processing and interactive queries.

## Q5. What is auto-suspend?

> Auto-suspend automatically pauses a warehouse after it has been idle for a configured period, reducing unnecessary compute consumption.

## Q6. When would you use a multi-cluster warehouse?

> Use one when many users or queries run concurrently and workloads are queuing for warehouse resources.

---

# 12. Scenarios

## Scenario 1 — A Single Transformation Is Slow

### Symptoms

- One large transformation takes too long.
- There is little evidence of concurrency queuing.

### Possible Actions

- Review the query profile.
- Check joins, filters, and data scanned.
- Improve pruning and SQL logic.
- Increase warehouse size if the query genuinely needs more compute.

### Likely First Step

> Diagnose the query before adding clusters, because clusters primarily address concurrency.

---

## Scenario 2 — Dashboards Queue During Business Hours

### Symptoms

- Many users run dashboard queries simultaneously.
- Queries spend time queued.

### Possible Actions

- Use a dedicated BI warehouse.
- Configure a multi-cluster warehouse.
- Review minimum and maximum cluster counts.
- Optimize the dashboard queries and refresh patterns.

---

## Scenario 3 — A Warehouse Runs Overnight With No Work

### Symptoms

- The warehouse remains active between scheduled jobs.
- Compute is consumed while no queries are executing.

### Possible Actions

```sql
ALTER WAREHOUSE etl_wh SET AUTO_SUSPEND = 60;
ALTER WAREHOUSE etl_wh SET AUTO_RESUME = TRUE;
```

Choose the timeout carefully if jobs arrive frequently or resume latency matters.

---

# 13. Revision Summary

- A virtual warehouse is compute, not permanent storage.
- Storage and compute are separate in Snowflake.
- Scale up for more resources for a workload or query.
- Scale out for more concurrent workloads.
- Multi-cluster warehouses help manage concurrency and queuing.
- Auto-suspend reduces idle compute consumption.
- Auto-resume starts a warehouse when work arrives.
- Separate warehouses provide workload isolation.
- Query performance depends on SQL, data volume, pruning, joins, caching, warehouse capacity, and concurrency.
- Always diagnose the bottleneck before changing warehouse size or cluster count.

---

## What to Learn Next

- Query Profile and execution plans
- Micro-partition pruning
- Clustering and clustering depth
- Search Optimization Service
- Materialized views
- Query result caching
- Warehouse cost monitoring
- Resource monitors
- Snowflake tasks and streams
