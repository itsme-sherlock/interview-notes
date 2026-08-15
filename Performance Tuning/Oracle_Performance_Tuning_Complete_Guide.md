# Oracle Performance Tuning Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Performance Tuning** = Systematic approach to identify and eliminate database bottlenecks to improve query execution speed and resource efficiency
- **Key feature 1 (CBO):** Cost-Based Optimizer calculates execution plan costs using statistics to select the most efficient query path
- **Key feature 2 (Execution Plans):** EXPLAIN PLAN shows the step-by-step sequence Oracle uses to execute a query, revealing inefficiencies like full table scans
- **Key feature 3 (Statistics):** Table, column, and index statistics guide the optimizer; stale statistics cause suboptimal plan selection
- **Key feature 4 (Diagnostics):** ASH, ADDM, and AWR reports provide real-time and historical performance data to identify wait events and bottlenecks
- **Key feature 5 (SQL Tuning):** Index creation, bind variables, and cursor sharing reduce hard parsing and improve execution efficiency
- **Key feature 6 (Adaptive Optimization):** AQO learns from query execution feedback and SQL Plan Directives to improve future executions

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Performance Tuning?](#1-why-do-we-need-performance-tuning)
2. [What Is Performance Tuning?](#2-what-is-performance-tuning)
3. [Query Optimizer and Execution Plans](#3-query-optimizer-and-execution-plans)
4. [Statistics, Indexes, and Cardinality](#4-statistics-indexes-and-cardinality)
5. [Diagnostic Tools: ASH, ADDM, and AWR](#5-diagnostic-tools-ash-addm-and-awr)
6. [AWR Report Analysis and Trending](#6-awr-report-analysis-and-trending)
7. [Performance Tuning Methodology and Strategy](#7-performance-tuning-methodology-and-strategy)
8. [Long-Running Transactions and Session Management](#8-long-running-transactions-and-session-management)
9. [ROWID and ROWNUM: Pseudo-Columns for Data Access](#9-rowid-and-rownum-pseudo-columns-for-data-access)
10. [Comparison Matrix](#10-comparison-matrix)
11. [Best Practices](#11-best-practices)
12. [Common Mistakes](#12-common-mistakes)
13. [Interview Q&A](#13-interview-qa)
14. [Revision Summary](#14-revision-summary)

---

## 1. Why Do We Need Performance Tuning?

### The Problem: Slow Database Performance

**Situation:** You've deployed an application and everything works—but it's slow. Users complain that reports take 5 minutes to generate, transactions are sluggish, and the system bogs down during peak hours.

```
User submits report query → Query starts → 5 minutes pass → Results finally appear
Meanwhile: CPU is underutilized, I/O is maxed out, other users waiting
```

**Problems with untuned systems:**
- Long query execution times harm user experience
- Resource wastage (CPU, memory, I/O) impacts other concurrent queries
- Database bottlenecks create cascading delays across the application
- Hard parsing consumes CPU and memory, reducing capacity
- Suboptimal execution plans can perform 100x worse than ideal plans

### The Solution: Performance Tuning

Performance tuning is a systematic approach to identifying database bottlenecks and eliminating them through index optimization, statistics management, SQL rewriting, and query plan adjustment. It transforms 5-minute queries into 5-second queries through targeted improvements.

### Real-World Scenarios

- **E-commerce scenario:** Product search query returns results in 100ms instead of 5 seconds → 50x improvement = better customer experience
- **Financial reporting:** Month-end close report completes in 10 minutes instead of 3 hours → 18x speedup = business closes books on time
- **Telecom billing:** Call detail record processing handles 100,000 records/second instead of 10,000 → 10x throughput = system handles peak load

---

**➡ Transition:** Understanding the architecture of performance tuning requires knowing how Oracle decides to execute queries.

---

## 2. What Is Performance Tuning?

### Simple Definition

**Performance Tuning** is the practice of analyzing, diagnosing, and optimizing database and SQL behavior to minimize execution time and resource consumption while maintaining data consistency. It involves making informed changes to database structure, SQL code, and configuration parameters based on observed bottlenecks.

It addresses the problem by transforming poorly-performing queries into fast, efficient operations through systematic optimization.

### Analogy: Real-World Comparison

**Traffic optimization** works like **Performance Tuning**:
- Traffic engineer identifies congested highway (bottleneck analysis = ASH/ADDM reports)
- Engineer builds additional lanes, removes traffic lights (adds indexes, modifies execution plans)
- Reroutes traffic through less-congested streets (cursor sharing, bind variables)
- Monitors traffic flow to ensure improvement (AWR reports verify changes)
- Adjusts as needed when congestion returns (statistics refresh, plan adaptation)

### Key Characteristics

- **Data-driven:** Based on observable metrics (wait events, execution time, resource consumption)
- **Iterative:** Measure → Identify bottleneck → Fix → Verify improvement → Repeat
- **Priority-focused:** Target the slowest queries first (80/20 rule—20% of queries consume 80% of resources)
- **Non-destructive:** Changes are reversible; testing is essential before production deployment
- **Holistic:** Considers schema, SQL, statistics, indexes, and database configuration

### Types of Performance Tuning

| Type | Focus Area | Example |
| --- | --- | --- |
| **SQL Tuning** | Query rewriting and plan optimization | Add index, rewrite join order, use hints |
| **Index Tuning** | Index creation, maintenance, and removal | Create composite index on WHERE columns |
| **Statistics Tuning** | Optimizer statistics accuracy | Gather table stats, create histograms |
| **Database Tuning** | Configuration and resource allocation | Increase SGA, adjust optimizer parameters |
| **System Tuning** | Hardware and OS-level optimization | Add memory, optimize I/O subsystem |

---

**➡ Transition:** The foundation of tuning is understanding how Oracle's optimizer makes execution decisions.

---

## 3. Query Optimizer and Execution Plans

### The Challenge

How does Oracle decide whether to use an index or scan the entire table? Which join method is fastest—nested loop, hash join, or sort merge join? Should it read data from memory cache or disk? The optimizer must make these choices automatically, and wrong choices cause poor performance.

### How the Query Optimizer Works

Oracle's **Cost-Based Optimizer (CBO)** generates multiple possible execution plans for each query and selects the plan with the lowest estimated cost:

```
1. Parse Query
   ↓
2. Generate Alternative Plans (nested loop, hash join, FTS, index scan, etc.)
   ↓
3. Estimate Cardinality (rows returned) using statistics
   ↓
4. Calculate Cost for each plan (CPU + I/O operations)
   ↓
5. Select Plan with Lowest Cost
   ↓
6. Execute Chosen Plan
```

**Critical Point:** The optimizer relies on accurate statistics to estimate cardinality. Bad statistics = bad cost estimates = wrong plan selected = poor performance.

### Understanding Execution Plans

An **execution plan** is a sequence of operations that Oracle executes to retrieve query results. You view it with `EXPLAIN PLAN`:

**Syntax:**
```sql
EXPLAIN PLAN FOR
SELECT * FROM employees WHERE salary > 50000;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
```

**Example Output:**
```
| ID | Operation           | Name      | Rows | Bytes | Cost |
|----+---------------------+-----------+------+-------+------|
|  0 | SELECT STATEMENT    |           | 1000 | 40000 | 150  |
|  1 | TABLE ACCESS FULL   | EMPLOYEES | 1000 | 40000 | 150  |
```

**Reading the Plan:**
- **Operation:** What Oracle is doing (TABLE ACCESS FULL = full table scan, INDEX RANGE SCAN = index lookup)
- **Rows:** Optimizer's estimate of rows returned at this step
- **Cost:** Estimated resource units (CPU + I/O)

### Full Table Scan vs Index Scan Decision

**Full Table Scan (FTS):**
- Scans every row sequentially from beginning to end
- Example: Scanning 1 billion rows takes ~2 minutes
- Optimal when: Returning >20-30% of table rows OR no suitable index exists
- Resource impact: High CPU and I/O; blocks cache memory

```sql
-- Full table scan (10M rows = 2 min)
SELECT * FROM huge_table WHERE city = 'New York';
```

**Index Scan:**
- Uses index to locate rows directly (like book index for page numbers)
- Same 1 billion rows: ~30 seconds with index (4x faster)
- Optimal when: Returning <5-10% of table rows AND index exists on filtered column
- Resource impact: Low I/O; efficient CPU usage

```sql
-- Index scan (10M rows = 30 sec)
CREATE INDEX idx_city ON huge_table(city);
SELECT * FROM huge_table WHERE city = 'New York';  -- Now 30 sec
```

**Comparison:**
| Aspect | Full Table Scan | Index Scan |
|--------|-----------------|-----------|
| **Speed (1B rows)** | 2 minutes | 30 seconds |
| **I/O operations** | 200,000+ blocks | 100 blocks |
| **CPU usage** | High | Low |
| **Best for** | >20% of rows | <5% of rows |
| **Requires index** | No | Yes |

### Join Methods: Nested Loop, Hash Join, Sort Merge

The optimizer chooses among three join strategies:

**Nested Loop Join:**
- For each row in outer table, scan inner table
- Optimal for: Small outer result set (< 10,000 rows)
- Performance: Fast when inner table small, slow when large

```
Outer Table (100 rows)
  ↓ For each row
    Inner Table scan (1M rows)
      ↓ Find matching rows
Total: 100 × (scans of 1M) = potentially slow
```

**Hash Join:**
- Build hash table from smaller table in memory
- Scan larger table once, probe hash table
- Optimal for: Large result sets, sufficient memory
- Performance: Very fast for large joins, uses memory

```
1. Build hash table from employees (smaller)
2. Scan orders (larger), probe hash table for matches
Result: Single pass through both tables = fast
```

**Sort Merge Join:**
- Both tables pre-sorted, merge in single pass
- Optimal for: Already sorted data or when sort key exists
- Performance: Good when sort-once cost < scan-twice cost

### Common Execution Plan Pitfalls

**Pitfall 1: Full Table Scan When Index Available**
```sql
-- BAD PLAN: Causes full table scan
SELECT * FROM employees WHERE salary > 50000;
-- No index on salary → optimizer chooses FTS (wrong decision!)

-- FIX: Create index
CREATE INDEX idx_salary ON employees(salary);
SELECT * FROM employees WHERE salary > 50000;  -- Now uses index
```

**Pitfall 2: Wrong Join Order**
```sql
-- BAD: Joins smaller table to larger table
SELECT * FROM orders o, customers c 
WHERE o.cust_id = c.id;
-- Optimizer may scan 1M orders first, then for each, scan 100K customers

-- GOOD: Use hints to control join order
SELECT /*+ LEADING(c o) */ * FROM orders o, customers c
WHERE o.cust_id = c.id;
-- Scans 100K customers first, then matches 1M orders
```

**Pitfall 3: Suboptimal Index Choice**
```sql
-- BAD: Multiple single-column indexes
CREATE INDEX idx_last_name ON employees(last_name);
CREATE INDEX idx_first_name ON employees(first_name);

-- GOOD: Composite index for common query pattern
CREATE INDEX idx_name ON employees(last_name, first_name);
SELECT * FROM employees WHERE last_name = 'Smith' AND first_name = 'John';
```

---

**➡ Transition:** The optimizer makes all these decisions based on statistics; inaccurate statistics are the #1 cause of poor performance.

---

## 4. Statistics, Indexes, and Cardinality

### The Challenge

The optimizer receives the same query twice: once with 100 rows in a table, once with 1 million rows. Without accurate statistics, it doesn't know which scenario it's in. It might pick nested loop (fast for 100 rows, terrible for 1M), causing a 100x performance degradation.

### Understanding Cardinality and Statistics

**Cardinality** is the optimizer's estimate of how many rows a query will return at each step. It's calculated from statistics:

```
Cardinality Estimation Formula:
Estimated rows = (Total rows in table) / (Distinct values in column)

Example:
Table: 10,000,000 rows
Column salary: 100 distinct values
Query: SELECT * FROM employees WHERE salary = 50000
Estimated rows = 10,000,000 / 100 = 100,000 rows
```

**Types of Statistics:**

| Statistic | What It Tracks | Example |
|-----------|---------------|---------|
| **Table stats** | Total rows, data blocks, avg row size | 10M rows, 50K blocks |
| **Column stats** | Distinct values, min/max, null count | 500 distinct salaries, min=20K, max=500K |
| **Index stats** | Leaf blocks, clustering factor | 10 leaf blocks, well-organized |
| **Histograms** | Data distribution pattern | Most employees earn 30-60K, few executives earn 500K+ |

### Stale Statistics: The #1 Performance Killer

**Problem Scenario:**

```
Initial statistics: Table has 100 rows
Optimizer plan: Full table scan (fast for small table)

6 months later:
Actual data: 1,000,000 rows (10,000x growth!)
Statistics: Still show 100 rows (never refreshed)
Optimizer: Still picks full table scan
Reality: Full scan of 1M rows = SLOW (should use index)
```

**Impact of Stale Statistics:**
- Optimizer underestimates result size → picks nested loop when hash join needed
- Query that was fast becomes slow without code changes
- Unpredictable performance as data grows

**Gathering Statistics:**

```sql
-- Gather table statistics
EXEC DBMS_STATS.gather_table_stats(
  ownname => 'HR',
  tabname => 'EMPLOYEES'
);

-- Gather with histogram for skewed data
EXEC DBMS_STATS.gather_table_stats(
  ownname => 'HR',
  tabname => 'EMPLOYEES',
  method_opt => 'FOR ALL COLUMNS SIZE 254'  -- 254 histogram buckets
);

-- Check when statistics were last gathered
SELECT table_name, last_analyzed, num_rows, blocks
FROM dba_tables
WHERE owner = 'HR' AND table_name = 'EMPLOYEES';
```

### Index Design and Selection

**Index Strategy: When to Create Indexes**

Create an index when:
- ✅ Column is frequently used in WHERE clauses
- ✅ Returns < 10% of table rows (selective)
- ✅ Table is large (>10,000 rows)
- ✅ Column has high cardinality (many distinct values)

Avoid indexes when:
- ❌ Column is rarely queried
- ❌ Returns > 20% of table rows (low selectivity)
- ❌ Table is small (<1,000 rows)
- ❌ Column is updated frequently (index maintenance cost)

**B-Tree Index (Most Common):**
```sql
CREATE INDEX idx_employee_id ON employees(employee_id);
-- Use for: High-selectivity columns, range queries (>, <, BETWEEN)
-- Example: employee_id with 10,000 distinct values in 10M row table
```

**Bitmap Index (Low-Cardinality Columns):**
```sql
CREATE BITMAP INDEX idx_status ON employees(status);
-- Use for: Low-cardinality columns (few distinct values)
-- Example: status (Active/Inactive/Archived) in 10M row table
-- Efficient for AND/OR operations across multiple bitmap columns
```

**Composite Index (Multiple Columns):**
```sql
CREATE INDEX idx_name ON employees(last_name, first_name);
-- Use for: Common query patterns on multiple columns together
-- Example: WHERE last_name = 'Smith' AND first_name = 'John'
-- Tip: Put most selective column first (fewer rows to scan)
```

### Index Maintenance: Rebuilding and Fragmentation

**When Indexes Become Fragmented:**
- Many DELETE operations leave gaps
- After bulk INSERT/UPDATE operations
- Scanning efficiency decreases over time

**Rebuilding Indexes:**

```sql
-- Online rebuild (production-safe, users can query during rebuild)
ALTER INDEX idx_employee_id REBUILD ONLINE;

-- Offline rebuild (faster but blocks queries)
ALTER INDEX idx_employee_id REBUILD;

-- Monitor rebuild progress
SELECT * FROM v$session_longops 
WHERE opname = 'Index creation' AND totalwork > 0;
```

**Benefits of Rebuild:**
- Removes gaps → improves scan efficiency
- Reduces storage → reclaims space from deleted entries
- Improves performance → fewer blocks to read

### Histograms: Handling Skewed Data

**Problem:** Data isn't uniformly distributed

```
Employee Salary Distribution:
900 employees: $30K-60K (majority)
100 employees: $100K-500K (executives)

Query: SELECT * FROM employees WHERE salary > 400000
Without histogram: Optimizer estimates 5M rows (10M / 100 distinct salaries)
Actual rows: 100 (just the executives)
Optimizer picks full scan; should use index for such small result set
```

**Solution: Create Histogram**

```sql
EXEC DBMS_STATS.gather_table_stats(
  ownname => 'HR',
  tabname => 'EMPLOYEES',
  method_opt => 'FOR COLUMNS SIZE 254 (salary) FOR ALL COLUMNS SIZE 1'
);
-- SIZE 254: Create histogram with 254 buckets for salary column
-- SIZE 1: No histogram for other columns (only size needed stats)
```

**Result with Histogram:**
- Optimizer learns that most rows are below $60K
- Query for salary > $400K accurately estimates 100 rows
- Chooses index scan (correct decision)

---

**➡ Transition:** Even with perfect statistics and indexes, you need diagnostic tools to identify performance problems in production systems.

---

## 5. Diagnostic Tools: ASH, ADDM, and AWR

### The Challenge

A query runs slowly in production. Where is the problem? Is it CPU-bound? I/O-bound? Waiting for locks? Missing an index? Using wrong plan? Without diagnostic data, you're flying blind. Oracle provides three complementary tools for performance diagnosis.

### ASH: Active Session History

**Purpose:** Real-time visibility into what database sessions are doing and what they're waiting for.

**How It Works:**
- Samples every active session every 1 second
- Records: SQL ID, wait event, CPU usage, I/O stats
- Stored in SGA (memory) with 1-hour circular buffer
- Fast queries: doesn't generate I/O

**What It Captures:**
- Which SQL is running (SQL ID)
- What the session is waiting for (wait event)
- How much CPU is being used
- Session ID and username
- Database time consumed

**Common Wait Events:**

| Wait Event | Meaning | Typical Cause | Impact |
|------------|---------|---------------|--------|
| **db file sequential read** | Reading single block (index) | Index scan, slow I/O | High I/O latency |
| **db file scattered read** | Reading multiple blocks (FTS) | Full table scan, slow I/O | High I/O latency |
| **CPU** | Using CPU (not waiting) | CPU-intensive calculation | CPU bottleneck |
| **log file sync** | Waiting for commit to write | Slow disk I/O, many commits | Commit bottleneck |
| **latch free** | Waiting for internal Oracle lock | High contention, cache pressure | Serialization issue |
| **library cache lock** | Waiting for shared SQL object | Cursor compilation, DDL | SQL compilation bottleneck |

**ASH Queries:**

```sql
-- Current active sessions
SELECT sid, serial#, event, sql_id, seconds_in_wait
FROM v$session
WHERE status = 'ACTIVE'
ORDER BY seconds_in_wait DESC;

-- Top wait events in last hour
SELECT event, COUNT(*) as samples
FROM v$active_session_history
WHERE SAMPLE_TIME > SYSDATE - (1/24)  -- Last hour
GROUP BY event
ORDER BY COUNT(*) DESC;

-- Which SQL is consuming most CPU
SELECT sql_id, COUNT(*) as samples
FROM v$active_session_history
WHERE event = 'CPU' AND SAMPLE_TIME > SYSDATE - (1/24)
GROUP BY sql_id
ORDER BY COUNT(*) DESC;
```

### ADDM: Automatic Database Diagnostic Monitor

**Purpose:** Automated performance analysis that identifies root causes and recommends fixes.

**How It Works:**
1. Captures two AWR snapshots (typically 1 hour apart)
2. Analyzes differences between snapshots
3. Identifies top wait events and their impact (% of database time)
4. Determines root causes
5. Provides actionable recommendations with expected benefit %

**ADDM Output:**

```
PROBLEM STATEMENT 1: CPU bottleneck found (35% of DB time)
  Root Cause: Excessive CPU from single-threaded queries
  Recommendation 1: Add index on WHERE columns
    Expected Benefit: 25% improvement
  Recommendation 2: Consider parallel execution
    Expected Benefit: 15% improvement

PROBLEM STATEMENT 2: I/O bottleneck found (45% of DB time)
  Root Cause: Full table scans on large tables
  Recommendation 1: Create indexes on scan columns
    Expected Benefit: 40% improvement
```

**Running ADDM:**

```sql
-- View most recent ADDM analysis
SELECT dbid, instance_number, snap_id, analysis_date
FROM dba_advisor_tasks
WHERE task_name LIKE 'ADDM%'
ORDER BY snap_id DESC;

-- Get ADDM findings and recommendations
SELECT finding_id, finding_name, impact, benefit
FROM dba_advisor_findings
WHERE task_id = (SELECT task_id FROM dba_advisor_tasks WHERE task_name LIKE 'ADDM%' ORDER BY snap_id DESC FETCH FIRST ROW ONLY);
```

### AWR: Automatic Workload Repository

**Purpose:** Historical database performance metrics and statistics repository.

**What It Captures (Every Snapshot):**
- Top 30 SQL statements by CPU, I/O, elapsed time
- Wait events and their frequency
- System statistics (CPU usage, I/O operations)
- Library cache statistics (hard parse frequency, hit ratio)
- Table/index access statistics
- Parameter settings

**AWR Reports:**

```sql
-- Generate AWR report between two snapshots
@$ORACLE_HOME/rdbms/admin/awrrpt.sql

-- Specify:
-- Enter report type: html or text
-- Enter begin snap_id: [snap_id from 1 hour ago]
-- Enter end snap_id: [current snap_id]
```

**Analyzing AWR Reports:**

```
Report Section 1: Top Time Model
  DB CPU: 30% (CPU consumed)
  SQL Parsing: 5% (hard parse overhead)
  User I/O: 40% (waiting for disk reads/writes)
  Other: 25%

Analysis:
  40% in User I/O = I/O bottleneck
  Action: Add indexes to reduce FTS, optimize storage
```

### ASH vs ADDM vs AWR Comparison

| Aspect | ASH | ADDM | AWR |
|--------|-----|------|-----|
| **Purpose** | Real-time monitoring | Automated diagnosis | Historical metrics |
| **Sample frequency** | Every 1 second | Hourly analysis | Every 60 min (configurable) |
| **Retention** | 1 hour (SGA) | 7 days default | 7 days default |
| **Data type** | Raw samples | Findings + recommendations | Aggregated statistics |
| **Use case** | Current problem | Root cause analysis | Trend analysis, capacity planning |
| **For beginners** | ✓ Easy to understand | ✓ Automated recommendations | Manual interpretation needed |

---

**➡ Transition:** Deep understanding of AWR reports gives you visibility into historical performance trends.

---

## 6. AWR Report Analysis and Trending

### Key AWR Report Sections

**1. Load Profile:**
Shows overall database activity during the snapshot period

```
Database Time (seconds): 3,600
Physical Reads: 50,000
Physical Writes: 10,000
Logical Reads: 1,000,000
Parse Count (Hard): 2,000
Parse Count (Soft): 98,000
Execute Count: 100,000
```

**Interpretation:**
- Database Time should correlate with user load
- High Physical Reads indicate I/O bottleneck or insufficient caching
- Parse Count: Hard should be low, Soft high (plan reuse working)
- Execute/Parse ratio should be high (>50:1 is good)

**2. Top 5 Timed Events (Most Critical):**

```
Event                  | Seconds | % Total | Class
db file sequential read | 1,200   | 33%     | User I/O
db file scattered read  | 900     | 25%     | User I/O
CPU time                | 600     | 17%     | CPU
latch free              | 300     | 8%      | Concurrency
log file sync           | 300     | 8%      | System I/O
```

**Action Plan:**
- Identify top event (33% db file sequential read)
- Root cause: Index scans waiting for I/O (either missing indexes causing FTS or slow storage)
- Recommendation: Add indexes, optimize query plans, or upgrade storage

**3. Instance Efficiency Ratios:**

```
Library Cache Hit Ratio:    95%    (Should be >90%)
Buffer Cache Hit Ratio:     99.5%  (Should be >99%)
Soft Parse Ratio:           99%    (Should be >95%)
Execute to Parse Ratio:     50:1   (Should be >30:1)
```

**Red Flags:**
- Library Cache Hit < 90% → Excessive hard parsing (implement bind variables)
- Buffer Cache Hit < 99% → Physical I/O high (add memory or indexes)
- Soft Parse Ratio < 95% → Hard parsing impacting performance
- Execute to Parse < 20:1 → Each SQL executed only once (no reuse)

**4. Top SQL by Metric:**

```
Top SQL by Elapsed Time:
SQL ID  | SQL Text        | Elapsed (s) | Executions | Per Exec (ms) | CPU (s)
abc123  | SELECT * FROM.. | 500         | 100        | 5000          | 50
def456  | SELECT * FROM.. | 300         | 1000       | 300           | 200

Interpretation:
  - abc123: Slow per-execution (5 seconds), maybe 100 executions means total 500s
  - def456: Fast per-execution (300ms) but runs 1000x (total 300s still significant)
  
Action:
  - abc123: Optimize that specific query
  - def456: Optimize for scale (add caching or batch operations)
```

### Comparing Baseline to Problem Period

**Step 1: Identify when problem occurred**
- User reports query slow at 2 PM
- Generate AWR report for 1-2 PM (problem period)
- Generate AWR report for 10-11 AM (baseline/normal)
- Compare metrics

**Step 2: Look for changes**
```
Baseline (10-11 AM):     Problem (1-2 PM):
- Database Time: 1,800s  - Database Time: 3,600s (2x!)
- Top event: CPU 40%     - Top event: I/O 50%
- Top SQL: Query A       - Top SQL: Query B (different!)
```

**Step 3: Investigate changed SQL**
- New Query B not in baseline top 30?
- Where did Query B come from?
- Recent code deployment?
- Changed data size?
- Different user running different workload?

**Step 4: Drill into Query B**
```sql
-- Get execution plan for SQL ID from report
SELECT * FROM v$sql WHERE sql_id = 'xyz123';

-- Explain plan
EXPLAIN PLAN FOR SELECT * FROM ... ;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
```

**Step 5: Implement fix and verify**
- Add missing index
- Update statistics
- Rewrite query
- Monitor with new AWR report (same time period next day)

---

**➡ Transition:** Performance tuning methodology provides the systematic approach to apply these diagnostic tools.

---

## 7. Performance Tuning Methodology and Strategy

### The Five-Step Tuning Process

**Step 1: Establish Baseline**
- Define normal performance thresholds
- Document response times, resource usage
- Create comparison point for future issues
- Use AWR to capture historical average

```sql
-- Baseline query for key metrics
SELECT 
  TO_CHAR(TRUNC(SYSDATE, 'HH24'), 'HH24') as hour,
  AVG(db_cpu_time) as avg_cpu,
  AVG(physical_reads) as avg_io
FROM dba_hist_sysstat
WHERE snap_id BETWEEN 100 AND 110  -- Last 10 hours
GROUP BY TRUNC(SYSDATE, 'HH24')
ORDER BY hour;
```

**Step 2: Monitor Continuously**
- Set up alerts for metric deviations
- Track response times daily
- Monitor wait events for patterns
- Maintain performance dashboard

**Step 3: Identify Bottleneck**
- What's the limiting factor: CPU, I/O, Memory, Network?
- Which queries contribute most?
- Is it database or application issue?
- Use ASH/ADDM/AWR to determine

**Step 4: Implement Fix**
- Create index on frequently filtered columns
- Update stale statistics
- Rewrite inefficient SQL
- Adjust parameters if needed
- Test thoroughly in non-production

**Step 5: Verify Improvement**
- Measure new response times
- Compare to baseline
- Confirm fix solved the issue
- Monitor for side effects
- Document changes made

### Performance Tuning Scenarios

**Scenario 1: Slow Query Complaint**
```
User says: "Query running 10 seconds, usually 1 second"

Steps:
1) Get SQL ID from v$session or application logs
2) EXPLAIN PLAN to check execution plan
3) Check if full table scan (bad) vs index scan (good)
4) Check if statistics stale (DBMS_STATS.gather_table_stats)
5) If plan bad, add index or use hint
6) Verify plan improves, measure response time
```

**Scenario 2: High CPU During Peak Hours**
```
Problem: Database CPU maxed at 2 PM daily

Steps:
1) Generate AWR report for 1-2 PM
2) Find top SQL by CPU in "Top SQL" section
3) Identify if same SQL as baseline or new
4) Check execution plan for inefficiency
5) Add index or rewrite SQL
6) Monitor next day at same time
```

**Scenario 3: High I/O Impacting Users**
```
Problem: "Disk I/O high, queries slow"

Steps:
1) Check AWR "Top 5 Timed Events"
2) If "db file sequential read" high → missing indexes
3) If "db file scattered read" high → full table scans
4) Identify which table (use top SQL section)
5) Create index on table columns
6) Verify plan changes to index scan
```

**Scenario 4: Memory Pressure**
```
Problem: "SGA full, performance degrading"

Steps:
1) Check v$sga for current allocation
2) Identify memory-consuming queries (large hash joins, sorts)
3) Either: increase SGA_TARGET or optimize queries
4) For query side: add index to reduce sort, use smaller result set
5) For infrastructure side: allocate more memory to database
```

### Database Parameters for Tuning

**Critical Parameters:**

| Parameter | Purpose | Good Value |
|-----------|---------|------------|
| SGA_TARGET | Total shared memory | 50-75% of available RAM |
| PGA_AGGREGATE_TARGET | Work memory for sorts/joins | 25-50% of available RAM |
| DB_FILE_MULTIBLOCK_READ_COUNT | I/O efficiency | 16-128 (OS dependent) |
| CURSOR_SHARING | Cursor reuse strategy | SIMILAR (production) |
| OPTIMIZER_MODE | Response vs throughput | ALL_ROWS (batch) or FIRST_ROWS (OLTP) |
| STATISTICS_LEVEL | Metrics collection | TYPICAL |

**Tuning Approach:**
- Start with Oracle defaults
- Monitor key metrics
- Adjust based on observed bottleneck
- Test thoroughly before production
- Document rationale for all changes

### Interview Questions - Performance Tuning

**Q1 (Basic):** What are the five steps of performance tuning methodology?
**A:** Establish baseline, monitor continuously, identify bottleneck, implement fix, verify improvement.

**Q2 (Intermediate):** You notice high I/O in AWR. How would you prioritize which indexes to create?
**A:** 1) Find top SQL by elapsed time. 2) Check EXPLAIN PLAN for FTS. 3) Prioritize columns in WHERE clause (high selectivity). 4) Create index on most frequently filtered column first. 5) Test to verify improvement. 6) Avoid over-indexing.

**Q3 (Advanced):** Design a comprehensive performance monitoring strategy for production OLTP system.
**A:** 1) Set baseline metrics (response time, CPU %, I/O rate). 2) Configure ADDM to run hourly. 3) Set alerts for deviations. 4) Review AWR daily for trends. 5) Use ASH for real-time issues. 6) Establish SLA thresholds. 7) Document all tuning changes. 8) Perform monthly trend analysis.

---

**➡ Transition:** Understanding long-running transactions helps identify and resolve production bottlenecks quickly.

---

## 8. Long-Running Transactions and Session Management

### Identifying Long-Running Operations

**Primary Query - Active Sessions:**
```sql
SELECT 
  sid, 
  serial#,
  username,
  sql_id,
  elapsed_time / 1000000 as elapsed_seconds,
  event
FROM v$session
WHERE status = 'ACTIVE'
ORDER BY elapsed_time DESC;
```

**Extended Query - With Progress:**
```sql
SELECT 
  s.sid,
  s.serial#,
  s.username,
  s.sql_id,
  l.opname,
  l.elapsed_seconds,
  l.time_remaining,
  ROUND(100 * l.work_done / NULLIF(l.totalwork, 0)) as progress_pct,
  l.target
FROM v$session s
JOIN gv$session_longops l ON s.sid = l.sid AND s.serial# = l.serial#
WHERE l.status = 'EXECUTING'
ORDER BY elapsed_seconds DESC;
```

**Output Example:**
```
SID  | USERNAME | OPNAME              | ELAPSED | TIME_REMAINING | PROGRESS | TARGET
71   | HR_APP   | SELECT              | 1800    | 600            | 75%      | EMPLOYEES
72   | FINANCE  | Index Rebuild       | 3600    | 2400           | 60%      | IDX_ACCT
73   | ADMIN    | Table Scan          | 300     | 120            | 71%      | ARCHIVE_LOG
```

**Interpretation:**
- Session 71: Query running 30 minutes, ~10 more minutes expected, 75% done
- Session 72: Index rebuild running 1 hour, ~40 minutes left (long operation)
- Session 73: Quick operation (5 minutes), nearly done

### Root Causes of Slowness

**1. Inefficient SQL Queries**
- Full table scan on large table (should use index)
- Missing WHERE clause (returns too many rows)
- Bad join order (joins large to small)
- Suboptimal join method (nested loop instead of hash)
- Correlated subqueries (executes for every row)

**2. Resource Bottleneck**
- CPU fully utilized (competing processes)
- I/O subsystem saturated (storage array maxed)
- Memory insufficient (paging to disk)
- Network congestion (distributed query slow)
- Undo tablespace full (cannot generate undo)

**3. Lock Contention**
- One session blocking others
- Row-level lock on frequently updated row (hot row)
- Table lock in exclusive mode (DDL waiting)
- Enqueue waits (internal Oracle locks)
- Library cache lock (cursor creation contention)

**4. Maintenance Operations**
- Backup job consuming resources (heavy I/O)
- Index rebuild running (tables locked)
- Statistics gathering (table scan)
- Export/import operations
- Batch jobs running overnight

**5. External Factors**
- OS CPU limit reached (licensing limit)
- Storage array performance degraded
- Network connectivity issue
- SAN cache misses
- Other databases on shared infrastructure

### Killing Problematic Sessions

**When to Kill:**
- Query running far longer than normal (> 2x typical time)
- Application team confirms session hung
- User requests to stop their own session
- Blocking other users and cannot proceed otherwise

**Never Kill Without Approval:**
- Production database during business hours
- Batch jobs (coordinate with ops)
- Backup operations
- Unknown sessions (verify ownership first)

**Killing a Session:**

```sql
-- Step 1: Identify session
SELECT sid, serial#, username, sql_id, seconds_in_wait
FROM v$session
WHERE status = 'ACTIVE'
ORDER BY seconds_in_wait DESC;

-- Example output: SID=71, SERIAL#=12345

-- Step 2: Verify it's correct session (check SQL, username, elapsed time)
SELECT sql_text FROM v$sql WHERE sql_id = (SELECT sql_id FROM v$session WHERE sid=71);

-- Step 3: Kill the session
ALTER SYSTEM KILL SESSION '71,12345' IMMEDIATE;

-- Step 4: Verify killed
SELECT sid FROM v$session WHERE sid=71;
-- If no rows returned, session killed successfully
```

**What Happens When Killed:**
- Session terminated
- Open cursor closed
- Locks released
- Uncommitted changes rolled back
- User receives "Session terminated" error
- Other sessions unblocked

### Handling Backup Job Impacts

**If Backup Causing Slowness:**

```
Backup scheduled: Midnight to 4 AM
Now: 6 AM, backup still running
Users now complaining (business hours)

Options:
1) Kill backup, restart later
   - Pro: Users get access immediately
   - Con: Backup didn't finish, no recovery backup
   
2) Increase backup parallelism
   - Pro: Finishes faster, completes backup
   - Con: More CPU/I/O, might affect users more
   
3) Let backup finish
   - Pro: Complete recovery backup
   - Con: Users slow temporarily

Decision: Option 2 (increase parallelism 4→8 channels)
```

### Interview Questions - Long Transactions

**Q1 (Basic):** What query shows long-running operations?
**A:** SELECT sid, serial#, opname, elapsed_time FROM gv$session_longops WHERE status='EXECUTING'; Shows operation type, elapsed time, and session identifiers.

**Q2 (Intermediate):** Walk through killing a session that's been running 4 hours and blocking other users.
**A:** 1) Query v$session ordered by elapsed_time to find session. 2) Get SID and SERIAL# (e.g., 71, 12345). 3) Verify correct session—check SQL, username. 4) Check for approval from user/application team. 5) Execute: ALTER SYSTEM KILL SESSION '71,12345' IMMEDIATE;. 6) Verify killed by querying v$session again.

**Q3 (Advanced):** Backup scheduled midnight-4AM is still running at 8 AM. Users complaining. Walk through your decision process.
**A:** 1) Check how far backup progressed (50%, 75%, almost done?). 2) If almost done (>95%), let finish. 3) If early stage (<50%), kill and restart. 4) Alternative: increase channels to speed up. 5) Communication: notify users of impact timeline. 6) Adjust future schedules (start earlier, run incremental, use different server).

---

**➡ Transition:** ROWID and ROWNUM are pseudo-columns crucial for advanced data manipulation and performance.

---

## 9. ROWID and ROWNUM: Pseudo-Columns for Data Access

### ROWID: The Physical Address

**What is ROWID:**
A pseudo-column providing the unique physical address (location) of each row in the database. It's assigned automatically and is the fastest way to access a specific row.

**Key Characteristics:**
- Not physically stored as a column
- Unique within database (doesn't change while row exists)
- Contains file, block, and slot information
- Assigned automatically by Oracle
- Immutable (permanent for row lifetime)
- Fastest direct row access method

**ROWID Format:**
```
AAAAAAAA.XXXX.YYYY

AAAAAAAA = Data object ID (table identifier)
XXXX     = File number (which datafile)
YYYY     = Block number (location in datafile)
ZZZZ     = Row slot (position within block)
```

**Why ROWID is Fastest:**

| Access Method | Speed | How It Works |
|---------------|-------|-------------|
| **ROWID direct** | Fastest | Goes to block, reads row directly |
| **Index scan** | Fast | Uses index to find ROWID, then reads row |
| **Full table scan** | Slowest | Scans every row looking for match |

### ROWID Use Cases

**Use Case 1: Deleting Duplicates (Keep Oldest)**

```sql
-- Find duplicates
SELECT name, COUNT(*) as cnt
FROM employees
GROUP BY name
HAVING COUNT(*) > 1;

-- Delete duplicates, keep MIN ROWID (oldest)
DELETE FROM employees
WHERE name IN (
  SELECT name FROM employees 
  GROUP BY name 
  HAVING COUNT(*) > 1
)
AND ROWID NOT IN (
  SELECT MIN(ROWID) FROM employees 
  GROUP BY name
);

COMMIT;
```

**How It Works:**
- Finds rows with duplicate names
- GROUP BY name, MIN(ROWID) keeps oldest
- Deletes all others
- Fast because uses ROWID directly (no search needed)

**Use Case 2: Bulk Deletion in Chunks**

```sql
-- Problem: Need to delete 10 million old records
-- Solution: Delete in batches to avoid locks/undo issues

BEGIN
  LOOP
    DELETE FROM audit_log
    WHERE created < TRUNC(SYSDATE) - 90  -- Older than 90 days
    AND ROWNUM < 20001;  -- Delete 20,000 at a time
    
    COMMIT;  -- Commit after each batch
    
    EXIT WHEN SQL%ROWCOUNT = 0;  -- Exit when no more rows
  END LOOP;
END;
/
```

**Benefits:**
- Deletes in chunks (doesn't lock entire table)
- COMMIT after each batch releases locks
- Allows other users to query between batches
- Prevents undo tablespace overflow
- Can monitor progress (batch size known)

### ROWNUM: Row Sequence Number

**What is ROWNUM:**
A pseudo-column that assigns a sequence number to rows as they're returned by a query. Important: Assigned during retrieval, BEFORE ORDER BY.

**Key Characteristics:**
- Temporary (only exists for that query execution)
- Assigned sequentially starting at 1
- Assigned AFTER WHERE clause filtering
- Assigned BEFORE ORDER BY (critical point!)
- Doesn't correspond to row physical order

**Critical ROWNUM Behavior:**

```sql
-- WRONG: ROWNUM assigned before ORDER BY
SELECT * FROM employees 
ORDER BY hire_date 
WHERE ROWNUM <= 10;

Result: Returns first 10 rows in arbitrary order, THEN orders
(Wrong - you wanted first 10 by hire_date)

-- RIGHT: Use subquery (ORDER in subquery first)
SELECT * FROM (
  SELECT * FROM employees 
  ORDER BY hire_date
) 
WHERE ROWNUM <= 10;

Result: Subquery orders first, outer query limits to 10
(Correct - first 10 by hire_date)
```

**Why This Matters:**
```
Timeline:
1. WHERE clause applied (filters rows)
2. ROWNUM assigned (1, 2, 3, ...)
3. ORDER BY applied (reorders rows, but ROWNUM doesn't change)

So: WHERE ROWNUM <= 10 gives you first 10 rows encountered, 
not first 10 after sorting!
```

### ROWNUM Use Cases

**Use Case 1: Limit Result Set**

```sql
-- Get first 10 employees (arbitrary order)
SELECT * FROM employees
WHERE ROWNUM <= 10;

-- Get first 10 by hire date
SELECT * FROM (
  SELECT * FROM employees ORDER BY hire_date
)
WHERE ROWNUM <= 10;
```

**Use Case 2: Pagination (Get Rows 21-30)**

```sql
SELECT * FROM (
  SELECT e.*, ROWNUM as rn FROM (
    SELECT * FROM employees 
    ORDER BY employee_id
  ) e
  WHERE ROWNUM <= 30  -- Get first 30 rows
)
WHERE rn > 20;  -- Then keep rows 21-30
```

**How Pagination Works:**
- Subquery 1: ORDER BY employee_id (sort)
- Middle query: ROWNUM <= 30 (get rows 1-30)
- Outer query: WHERE rn > 20 (keep rows 21-30)
- Result: Rows 21-30 of sorted result

**Use Case 3: Bulk Update/Delete in Batches**

```sql
-- Update only first 1000 rows
UPDATE employees SET salary = salary * 1.1
WHERE ROWNUM <= 1000;

-- Delete old records in batches (as shown earlier)
BEGIN
  LOOP
    DELETE FROM archive_log
    WHERE created < TRUNC(SYSDATE) - 365
    AND ROWNUM <= 50000;
    COMMIT;
    EXIT WHEN SQL%ROWCOUNT = 0;
  END LOOP;
END;
/
```

### ROWID vs ROWNUM Comparison

| Aspect | ROWID | ROWNUM |
|--------|-------|--------|
| **Type** | Physical address (pseudo-column) | Sequence number (pseudo-column) |
| **Scope** | Database-wide | Single query |
| **Purpose** | Direct row access | Result limiting |
| **Performance** | Excellent (direct) | Good (sequence) |
| **Persistence** | Permanent (while row exists) | Query execution only |
| **Immutability** | Immutable | Changes per query |
| **Use case** | Delete duplicates, direct access | Pagination, batch operations |
| **Speed** | Fastest possible | Moderate |

**When to Use:**
- **ROWID:** When you have specific row to access or update
- **ROWNUM:** When you need first N rows or pagination

### Interview Questions - ROWID & ROWNUM

**Q1 (Basic):** What is ROWID and why is it fastest?
**A:** ROWID is a pseudo-column with the physical address of each row. It's fastest because Oracle goes directly to the block and slot location without searching.

**Q2 (Intermediate):** Design a solution to delete 10 million old records efficiently.
**A:** Delete in batches using ROWNUM < 20001. Loop until no rows deleted. COMMIT after each batch. This prevents locks, undo overflow, and allows monitoring.

**Q3 (Advanced):** Show me correct pagination query to get rows 51-75 ordered by hire_date.
**A:** Use nested subqueries: inner orders by hire_date, middle limits to 75, outer filters ROWNUM > 50. Each layer serves purpose—ORDER in inner, ROWNUM in middle, filter in outer.

---

**➡ Transition:** Now let's compare all approaches and create a comprehensive reference.

---

## 10. Comparison Matrix

---

## 10. Comparison Matrix

### Performance Tuning Approaches

| Approach | When to Use | Effort | Impact | Best For |
|----------|------------|--------|--------|----------|
| **Index creation** | Column frequently filtered, returns <10% | Low (DDL only) | High (10-100x faster) | Selective queries |
| **Statistics refresh** | Data has grown significantly | Very low (automated) | High (fixes bad plans) | Recently modified tables |
| **SQL rewriting** | Complex logic, multiple joins | Medium (testing needed) | Medium (2-10x) | Suboptimal query logic |
| **Cursor sharing** | Hard parse overhead, many variations | Very low (parameter change) | Medium (30-50% overhead reduction) | OLTP systems |
| **Hints/SQL Profiles** | Optimizer making wrong join decisions | Medium (testing required) | Medium-high (5-50x) | Specific problem queries |
| **Parallel execution** | Large table scans, complex analytics | Medium (infrastructure) | High (2-8x on multi-core) | Batch/report queries |

### Index Types for Different Scenarios

| Index Type | Best For | Avoid When | Overhead |
|------------|----------|-----------|----------|
| **B-Tree** | High-selectivity columns, range queries | Column rarely queried | Moderate (index maintenance) |
| **Bitmap** | Low-cardinality columns (< 100 distinct) | Highly updated columns | Very low (compact storage) |
| **Composite** | Multi-column WHERE clauses | Single column queries only | Moderate (larger index) |
| **Function-based** | WHERE clauses with functions | Simple column filters | High (computation overhead) |
| **Full-text** | Text search patterns | Simple equality queries | Moderate (specialized) |

### Join Method Trade-offs

| Join Method | Optimal Scenario | CPU | Memory | I/O | Result |
|-------------|-----------------|-----|--------|-----|--------|
| **Nested Loop** | Small outer result | Low | Very Low | Potentially high | Fast for small outer sets |
| **Hash Join** | Large result sets | Moderate | High (hash table) | Low | Fast for large joins |
| **Sort Merge** | Pre-sorted data | Moderate | Moderate | Low | Good when sort exists |

---

## 11. Best Practices

### 1. Gather Statistics Regularly and Keep Them Fresh

**Avoid:**
```sql
# ❌ WRONG: Never gathering statistics
-- Table grows from 1K to 1M rows over 6 months
-- No stats refresh = optimizer still thinks 1K rows
-- Queries that should use indexes still do full scans
SELECT * FROM huge_table WHERE id = 123;  -- Full scan of 1M rows!
```

**Prefer:**
```sql
# ✅ CORRECT: Schedule automatic statistics gathering
-- Oracle 12c+: Automatic job runs nightly (default)
-- Verify it's enabled:
SELECT job_name, job_type, enabled
FROM dba_scheduler_jobs
WHERE job_name LIKE '%STATS%';

-- Or gather manually after bulk operations:
EXEC DBMS_STATS.gather_table_stats('HR', 'EMPLOYEES');
```

**Why:** Fresh statistics = accurate cardinality estimates = optimal plan selection. Stale statistics are the #1 cause of performance degradation.

---

### 2. Use Bind Variables and Avoid Hard Parsing

**Avoid:**
```sql
# ❌ WRONG: Literal values in SQL
SELECT * FROM employees WHERE id = 1;    -- Hard parse #1
SELECT * FROM employees WHERE id = 2;    -- Hard parse #2
SELECT * FROM employees WHERE id = 3;    -- Hard parse #3
-- Result: 3 plans in shared pool, 3x parse overhead
```

**Prefer:**
```sql
# ✅ CORRECT: Use bind variables
SELECT * FROM employees WHERE id = :id;
-- Bind :id = 1
-- Bind :id = 2
-- Bind :id = 3
-- Result: 1 plan in shared pool, fast execution
```

**Why:** Bind variables enable cursor reuse. Eliminates hard parsing overhead. Safer against SQL injection.

---

### 3. Create Selective Indexes Only

**Avoid:**
```sql
# ❌ WRONG: Index on low-selectivity column
CREATE INDEX idx_gender ON employees(gender);
-- Only 2-3 distinct values (M/F), returns 50% of rows
-- Index not useful (FTS faster for 50% of rows)
-- Wastes storage and maintenance cost
```

**Prefer:**
```sql
# ✅ CORRECT: Index on high-selectivity column
CREATE INDEX idx_employee_id ON employees(employee_id);
-- 10,000 distinct values, returns 0.01% of rows
-- Index highly beneficial, selector reduces result set to single row
```

**Why:** Indexes cost storage and maintenance. Only beneficial when reducing result set to <10%.

---

### 4. Design Composite Indexes for Common Query Patterns

**Avoid:**
```sql
# ❌ WRONG: Multiple single-column indexes for related queries
CREATE INDEX idx_last_name ON employees(last_name);
CREATE INDEX idx_first_name ON employees(first_name);
-- Query uses both: WHERE last_name = 'Smith' AND first_name = 'John'
-- Optimizer uses first index, then filters by first_name
-- Suboptimal: Index doesn't cover both columns
```

**Prefer:**
```sql
# ✅ CORRECT: Composite index for related query pattern
CREATE INDEX idx_name ON employees(last_name, first_name);
-- Query uses both: WHERE last_name = 'Smith' AND first_name = 'John'
-- Index covers both columns, optimizer uses entire index
-- Better: Single index, faster lookup
```

**Why:** Composite indexes cover multi-column queries efficiently. Reduces index count and maintenance cost.

---

### 5. Monitor Plan Consistency and Adapt to Plan Changes

**Avoid:**
```sql
# ❌ WRONG: Ignore execution plan changes
-- Q1 2024: Query runs in 1 second (good plan)
-- Q2 2024: Query runs in 30 seconds (plan changed!)
-- DBA notice: "But we didn't change anything!"
-- Root cause: Statistics refreshed, different plan selected
-- No action taken: Performance remains poor
```

**Prefer:**
```sql
# ✅ CORRECT: Capture and lock good plans
-- Capture baseline when plan is good
DECLARE
  v_plan_hash VARCHAR2(30);
BEGIN
  SELECT plan_hash_value INTO v_plan_hash FROM v$sql WHERE sql_id = 'abc123xyz';
  -- Create SQL baseline to force this plan
  EXEC DBMS_SPM.load_plans_from_cursor_cache(sql_id => 'abc123xyz');
END;
/

-- Baseline prevents optimizer from using bad plans
-- Monitor: SELECT * FROM dba_sql_plan_baselines WHERE sql_handle LIKE '%EMP%';
```

**Why:** Bad plans degrade performance unexpectedly. SQL Plan Baselines guarantee good plans persist across statistics changes.

---

### 6. Use EXPLAIN PLAN Before Running Production Queries

**Avoid:**
```sql
# ❌ WRONG: Run complex query without checking plan
SELECT * FROM orders o
  JOIN customers c ON o.cust_id = c.id
  JOIN order_items oi ON o.order_id = oi.order_id
WHERE c.region = 'US' AND o.order_date > TRUNC(SYSDATE) - 30;
-- Takes 30 minutes to find out plan is full table scan!
```

**Prefer:**
```sql
# ✅ CORRECT: Review EXPLAIN PLAN before executing
EXPLAIN PLAN FOR
SELECT * FROM orders o
  JOIN customers c ON o.cust_id = c.id
  JOIN order_items oi ON o.order_id = oi.order_id
WHERE c.region = 'US' AND o.order_date > TRUNC(SYSDATE) - 30;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
-- Review plan: any full table scans? High cost? Wrong join order?
-- Make corrections (add index, use hint) before running query
```

**Why:** EXPLAIN PLAN shows problems before wasting resources on slow execution. Early diagnosis = faster fix.

---

## 12. Common Mistakes

### Mistake 1: Assuming More Indexes = Faster Queries

**Problem:** DBA creates index on every column hoping to fix slow queries

```sql
# ❌ WRONG
CREATE INDEX idx_col1 ON table1(col1);
CREATE INDEX idx_col2 ON table1(col2);
CREATE INDEX idx_col3 ON table1(col3);
CREATE INDEX idx_col4 ON table1(col4);
CREATE INDEX idx_col5 ON table1(col5);
-- 5 indexes on a table with only 10,000 rows!
-- Overhead: Storage, maintenance cost, slower inserts
-- Benefit: Query might use one index (if lucky)
-- Result: Bad trade-off
```

**Why it fails:** Index creation has maintenance cost. Each INSERT/UPDATE/DELETE must update all indexes. With 5 indexes on 10K row table, inserts become 6x slower. Only 1 query benefits.

**Solution:**
```sql
# ✅ CORRECT
-- Analyze actual slow queries with EXPLAIN PLAN
EXPLAIN PLAN FOR SELECT * FROM table1 WHERE col1 = 123;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Create index ONLY if it improves that specific query
-- For query above on col1:
CREATE INDEX idx_col1 ON table1(col1);
-- For multi-column query:
-- CREATE INDEX idx_cols ON table1(col1, col2);

-- Verify improvement before creating additional indexes
```

---

### Mistake 2: Relying on Outdated or Missing Statistics

**Problem:** Query runs in 1 second, but suddenly takes 10 minutes without code changes

```sql
# ❌ WRONG: Statistics not gathered after bulk load
BULK INSERT 1,000,000 new rows into order_history;
-- No stats refresh
-- Optimizer still thinks table has 100 rows (old stats)
-- Picks nested loop join (fast for 100 rows, terrible for 1M)
-- Query that ran in 1s now takes 10 minutes
-- User complains: "You didn't change the code, why is it slow?!"
```

**Why it fails:** Optimizer makes decisions based on statistics. Stale stats = stale decisions = wrong plans.

**Solution:**
```sql
# ✅ CORRECT
BULK INSERT 1,000,000 new rows into order_history;

-- Refresh statistics immediately after bulk operations
EXEC DBMS_STATS.gather_table_stats('SCHEMA', 'ORDER_HISTORY');

-- Or configure automatic job:
BEGIN
  DBMS_SCHEDULER.create_job(
    job_name        => 'gather_stats_nightly',
    job_type        => 'STORED_PROCEDURE',
    job_action      => 'DBMS_STATS.gather_schema_stats',
    repeat_interval => 'FREQ=DAILY;BYHOUR=2',
    enabled         => TRUE
  );
END;
/
```

---

### Mistake 3: Not Understanding Join Order Impact

**Problem:** Query joins large table first instead of filtering first

```sql
# ❌ WRONG: Inefficient join order
SELECT * FROM orders o
  JOIN customers c ON o.cust_id = c.id
WHERE c.region = 'West' AND c.status = 'Active';

-- Optimizer might scan all 10M orders first (outer table)
-- Then for each order, look up customer
-- Result: 10M customer lookups, most filtered out later
-- Better: Filter customers first (1,000 rows match), then join orders
```

**Why it fails:** Driving table with fewer rows filters early. Joining large table first means scanning unnecessarily large intermediate result set.

**Solution:**
```sql
# ✅ CORRECT: Force optimizer to filter first
SELECT /*+ LEADING(c) */ * FROM orders o
  JOIN customers c ON o.cust_id = c.id
WHERE c.region = 'West' AND c.status = 'Active';
-- LEADING(c) hint forces customers as outer table
-- Filters to 1,000 rows, then joins 10M orders
-- Much faster

-- Or ensure statistics show customer table is smaller:
EXEC DBMS_STATS.gather_table_stats('SCHEMA', 'CUSTOMERS');
```

---

### Mistake 4: Creating Single-Column Index When Composite Index Is Better

**Problem:** Multiple indexes compete instead of cooperating

```sql
# ❌ WRONG: Single-column indexes for multi-column query
CREATE INDEX idx_emp_dept ON employees(department_id);
CREATE INDEX idx_emp_sal ON employees(salary);

SELECT * FROM employees 
WHERE department_id = 10 AND salary > 50000;

-- Optimizer uses index on department_id, filters by salary
-- Or uses index on salary, filters by department_id
-- Not ideal: Index doesn't cover both columns
```

**Why it fails:** Optimizer uses one index, then filters by second column. Wastes I/O on rows that won't match second filter.

**Solution:**
```sql
# ✅ CORRECT: Composite index covers both columns
CREATE INDEX idx_emp_dept_sal ON employees(department_id, salary);

SELECT * FROM employees 
WHERE department_id = 10 AND salary > 50000;

-- Index covers both columns in query
-- Range scan: department_id = 10 AND salary > 50000
-- Perfect index-only scan, minimal rows returned
```

---

### Mistake 5: Ignoring Wait Events in Diagnostic Reports

**Problem:** DBA reads AWR report but misses the root cause

```sql
# ❌ WRONG: Focusing on wrong metric
AWR Report shows:
  - Top Wait Event: db file sequential read (50% of time)
  - CPU Usage: 10% (seems low)
  
DBA concludes: "CPU isn't the problem, hardware is fine"
Misses: The reason db file sequential read is high is because full table scans
are reading massive amounts of data sequentially. Problem isn't storage; 
it's missing index causing FTS.
```

**Why it fails:** Wait events are symptoms, not root causes. "db file sequential read" means "waiting for disk." Cause could be missing index, bad statistics, or actually slow storage.

**Solution:**
```sql
# ✅ CORRECT: Trace wait events to root cause
-- AWR shows: db file sequential read is top wait event
-- Analysis:
SELECT sql_id, executions, elapsed_time / executions as avg_time
FROM v$sql
ORDER BY elapsed_time DESC;

-- Look for SQL with high I/O waits
EXPLAIN PLAN FOR
SELECT * FROM huge_table WHERE status = 'active';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Root cause: Full table scan, all 10M rows returned
-- Fix: Add index on status column (if selective)
CREATE INDEX idx_status ON huge_table(status);

-- Verify fix reduces wait events:
-- Run same query, compare wait events before/after
```

---

## 13. Interview Q&A

### Conceptual Questions

**Q: What is the relationship between statistics and execution plans?**

A: The optimizer uses statistics (table row count, column distinct values, data distribution) to estimate cardinality—how many rows a query will return at each step. It uses cardinality estimates to calculate the cost of alternative execution plans and selects the plan with the lowest cost. Therefore, **bad statistics = bad cardinality estimates = wrong plan selected = poor performance**. This is why stale statistics are the #1 cause of performance degradation.

---

**Q: Explain the difference between Full Table Scan and Index Scan. When would you choose each?**

A: 
- **Full Table Scan (FTS):** Reads every row in table sequentially from beginning to end. Optimal when query returns >20-30% of table rows. Example: 1B rows FTS = 2 minutes.
- **Index Scan:** Uses index to jump directly to matching rows (like book index). Optimal when query returns <5-10% of table rows and index exists. Example: 1B rows with index = 30 seconds (4x faster).

Choose FTS when: No suitable index exists OR query returns large percentage of rows (index overhead not justified).  
Choose Index Scan when: Index exists on filter column AND query returns small percentage of rows.

---

**Q: What causes an execution plan to change unexpectedly?**

A: 
1. **Statistics refresh:** When DBMS_STATS gathers new statistics, cardinality estimates may change, causing optimizer to select different plan.
2. **Parameter changes:** Setting `optimizer_mode`, `optimizer_features_enable`, or other init parameters can affect plan selection.
3. **Index changes:** Creating or dropping an index changes available execution paths.
4. **Cursor aging:** Plans age out of shared pool cache and are recompiled.
5. **Bind variable values:** With `cursor_sharing=FORCE`, different bind values might need different plans but share same plan (suboptimal for some values).

Solution: Use SQL Plan Baselines to lock good plans even when statistics change.

---

### Comparison Questions

**Q: Compare B-Tree Index vs Bitmap Index. When would you use each?**

A: 
| Aspect | B-Tree | Bitmap |
|--------|--------|--------|
| **Data type** | High-cardinality (many distinct values) | Low-cardinality (few distinct values) |
| **Selectivity** | Best for highly selective queries | Best for non-selective queries |
| **Storage** | Larger index size | Compact storage |
| **Updates** | Higher maintenance cost | Lower maintenance cost |
| **Example** | Employee ID (10K distinct in 1M rows) | Gender (M/F), Status (Active/Inactive) |
| **Best for** | Equality/range queries on unique columns | AND/OR operations across multiple low-cardinality columns |

---

**Q: Compare Nested Loop Join vs Hash Join. When is each optimal?**

A:
- **Nested Loop:** For each row in outer table, scan inner table. Optimal for small outer result set (<10K rows). CPU low, I/O potentially high.
- **Hash Join:** Build hash table from smaller table, scan larger table once. Optimal for large result sets, sufficient memory. CPU moderate, I/O low.

**Example Decision:**
```
Query: SELECT * FROM orders (10M rows) JOIN customers (100K rows)
If filtering customers first reduces result to 1K rows:
  → Use Nested Loop (outer: 1K customers, inner: scan orders for each)
If filtering customers returns 50K rows:
  → Use Hash Join (build hash from 50K customers, scan 10M orders once)
```

---

### Scenario Questions

**Q: A production query suddenly runs 10x slower without any code changes. How would you diagnose and fix the problem?**

A: 
**Step 1: Check if statistics are stale**
```sql
SELECT table_name, last_analyzed, num_rows
FROM dba_tables
WHERE table_name IN ('TABLE1', 'TABLE2', ...);
-- If last_analyzed is old (weeks/months), statistics may be stale
```

**Step 2: Compare execution plans before and after**
```sql
EXPLAIN PLAN FOR SELECT ...;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
-- Look for: Full table scan when index should be used?
-- Wrong join order? Suboptimal plan?
```

**Step 3: Check ASH/ADDM for wait events**
```sql
-- Top wait events in last hour?
SELECT event, COUNT(*) FROM v$active_session_history
WHERE sample_time > SYSDATE - (1/24)
GROUP BY event ORDER BY COUNT(*) DESC;
```

**Step 4: Identify root cause and fix**
- If stale stats: `EXEC DBMS_STATS.gather_table_stats(...)`
- If bad plan: Create index or use SQL hint
- If high I/O waits: Check if FTS caused by missing index
- If lock contention: Investigate sessions holding locks

**Step 5: Verify fix**
- Re-run query, measure execution time
- Compare to baseline (pre-degradation)
- Monitor for regression

---

**Q: Design a comprehensive tuning strategy for a large OLTP system experiencing random query slowdowns.**

A:
**Tier 1: Monitoring (Continuous)**
- ASH: Real-time session monitoring, identify hot queries
- ADDM: Automated root cause analysis, recommendations
- AWR: Trend analysis, capacity planning

**Tier 2: Statistics Management (Automated)**
```sql
-- Nightly stats gathering via scheduler
DBMS_SCHEDULER job:
  DBMS_STATS.gather_schema_stats (all tables)
  Runs: 2 AM daily (off-peak)
  
-- Lock statistics if optimal plan known
DBMS_STATS.lock_table_stats('SCHEMA', 'TABLE')
```

**Tier 3: Index Strategy**
- Identify frequently filtered columns (from AWR top SQL)
- Create B-Tree indexes on selective columns (<5% result set)
- Create composite indexes for related column queries
- Monitor index fragmentation, rebuild if needed

**Tier 4: SQL Optimization**
- Capture poor-performing SQL from AWR
- Review execution plans with EXPLAIN PLAN
- Add bind variables to reduce hard parsing
- Create SQL Plan Baselines for critical queries

**Tier 5: Database Configuration**
- Set `cursor_sharing=SIMILAR` for OLTP workload
- Enable `optimizer_dynamic_sampling=4` for missing stats
- Allocate sufficient SGA for shared pool/buffer cache
- Configure alert thresholds for degradation detection

**Monitoring Dashboard:**
- Query execution time trend
- Hard parse frequency
- Library cache hit ratio
- Buffer cache hit ratio
- Top wait events
- Index fragmentation ratio

---

## 14. Revision Summary

### 1-Minute Recap

**Performance Tuning** = Systematic approach to eliminate database bottlenecks by optimizing SQL execution, managing statistics and indexes, and using diagnostics to identify root causes.

- **CBO (Cost-Based Optimizer)** → Selects execution plan with lowest estimated cost using statistics
- **Execution Plan** → Step-by-step operations Oracle uses to retrieve results; shows if using optimal access methods
- **Statistics** → Cardinality data used by optimizer; stale stats = wrong plans = poor performance
- **Indexes** → Provide fast row access for selective queries; only beneficial for <5% result set queries
- **Diagnostics (ASH/ADDM/AWR)** → Identify root causes (CPU, I/O, waits, bad plans) and track improvements

### Interview Keywords

- **Cardinality** → Estimated or actual number of rows a query returns at each step
- **Hard Parse** → Full parsing of query statement; expensive, happens when cursor not found in cache
- **Soft Parse** → Plan reuse from cache, minimal overhead; enabled by bind variables
- **Cursor Sharing** → Parameter controlling whether identical queries reuse execution plans
- **Full Table Scan (FTS)** → Sequential read of entire table; optimal for queries returning >20% of rows
- **Index Scan** → Using index to access rows; optimal for selective queries (<5% of rows)
- **Execution Plan** → Oracle's step-by-step sequence to execute query; shows join methods, access paths, estimated vs actual rows
- **SQL Profile** → Custom execution plan hints to override optimizer decision; useful when optimizer makes wrong choice

### Important Syntax

```sql
-- Gather statistics for table
EXEC DBMS_STATS.gather_table_stats('SCHEMA_NAME', 'TABLE_NAME');

-- View execution plan
EXPLAIN PLAN FOR SELECT * FROM table WHERE condition;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Check stale statistics
SELECT table_name, last_analyzed, num_rows FROM dba_tables
WHERE owner = 'SCHEMA_NAME';

-- Create index
CREATE INDEX idx_name ON table_name(column_name);

-- Monitor active sessions (ASH)
SELECT sid, event, sql_id FROM v$session WHERE status='ACTIVE';

-- View top wait events (ASH)
SELECT event, COUNT(*) FROM v$active_session_history 
WHERE sample_time > SYSDATE - (1/24)
GROUP BY event ORDER BY COUNT(*) DESC;

-- Lock good execution plan
EXEC DBMS_SPM.load_plans_from_cursor_cache(sql_id => 'sql_id_here');
```

---

**Master this guide!** You now have the foundation to diagnose and fix real-world performance problems. Start with ASH/ADDM reports in production, identify top wait events, and work through the 10-step tuning process systematically.
