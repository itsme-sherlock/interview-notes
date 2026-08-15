# Oracle Performance Tuning - Complete Study Guide
**Comprehensive Material from 9 Video Transcripts**

**Generated:** August 2026  
**Total Content:** ~10,000+ words  
**Modules:** 9  
**Interview Questions:** 50+  
**Difficulty Levels:** Basic, Intermediate, Advanced

---

## 📋 Table of Contents

1. [Module 1: Query Optimizer Fundamentals](#module-1-query-optimizer-fundamentals)
2. [Module 2: Cursor Sharing Strategy](#module-2-cursor-sharing-strategy)
3. [Module 3: Index Rebuilding & Statistics Gathering](#module-3-index-rebuilding--statistics-gathering)
4. [Module 4: Optimizer Statistics for Performance](#module-4-optimizer-statistics-for-performance)
5. [Module 5: ADDM & ASH Reports](#module-5-addm--ash-reports)
6. [Module 6: AWR Report Analysis](#module-6-awr-report-analysis)
7. [Module 7: Database Performance Tuning Introduction](#module-7-database-performance-tuning-introduction)
8. [Module 8: Long Running Transactions & Slowness](#module-8-long-running-transactions--slowness)
9. [Module 9: ROWID & ROWNUM Comprehensive Tutorial](#module-9-rowid--rownum-comprehensive-tutorial)

---

## Module 1: Query Optimizer Fundamentals
*119 mentions of "optimizer", 78 of "query", 75 of "plan"*

### Core Concept: What is the Oracle Query Optimizer?

The Query Optimizer is a sophisticated set of programs and procedures provided by Oracle that automatically selects the most efficient execution plan for SQL queries. It's the "brain" of the database - responsible for determining how to execute queries with minimum resource consumption and execution time.

**Key Responsibilities:**
- Generates multiple possible execution plans for a query
- Calculates cost for each plan using statistics
- Selects the plan with the lowest estimated cost
- Adapts plans based on data distribution and statistics

### Full Table Scan vs Index Scan

**Full Table Scan (FTS):**
- Scans every row in the table from beginning to end
- Example: 1 billion records = ~2 minutes execution time
- No index needed
- High CPU and I/O consumption
- When to occur: No index exists OR optimizer chooses FTS (mistakenly)
- Resource impact: Blocks memory, consumes I/O bandwidth, impacts other queries

**Index Scan:**
- Uses index to locate rows directly (like book index to page numbers)
- Same 1 billion records = ~30 seconds execution time
- 4x faster than FTS
- Lower resource consumption
- Preferred for large tables with selective queries
- Index must exist on queried column

**Real Example:**
```sql
-- Full Table Scan (slow)
SELECT * FROM HUGE_TABLE WHERE name = 'John';  -- Takes 2 minutes

-- With Index (fast)
CREATE INDEX idx_name ON HUGE_TABLE(name);
SELECT * FROM HUGE_TABLE WHERE name = 'John';  -- Takes 30 seconds
```

### 10 Magical Steps for Query Tuning

When facing performance issues with a query:

1. **Identify the problematic query** - Use long-running query views
2. **Capture the execution plan** - Get EXPLAIN PLAN output
3. **Analyze for full table scans** - Are they necessary?
4. **Check if indexes exist** - On the filter columns
5. **Verify index statistics** - Are they current?
6. **Review join order and methods** - Most selective table first
7. **Check bind variables** - Avoid parameter sniffing
8. **Consider parallel execution** - For large data sets
9. **Create SQL profiles/baselines** - Force good plans if needed
10. **Test and measure** - Before/after performance comparison

### Cost-Based Optimization (CBO)

The optimizer uses Cost-Based Optimization:
- **Estimates cardinality** (number of rows) using statistics
- **Calculates cost** in terms of CPU and I/O operations
- **Compares costs** of alternative plans
- **Selects minimum cost** plan

**Critical Point:** Bad statistics = bad cardinality estimates = wrong plan selection = poor performance

### Adaptive Query Optimization (AQO)

**Two Components:**

**1. Adaptive Plans:**
- Adjusts join methods at runtime (nested loop vs hash join)
- Changes parallel distribution methods
- Decides between bitmap vs B-tree indexing
- Optimizes based on actual data encountered

**2. Adaptive Statistics:**
- Dynamic sampling during query execution
- Automatic re-optimization when estimates are wrong
- SQL Plan Directives store findings for future queries
- Learns from execution feedback

### Plan Consistency and Plan Hash Values

**How long does optimizer use the same plan?**
- Until plan ages out from shared pool cache
- Until statistics change significantly
- Until optimizer features are modified
- Until database parameters change

**Plan Hash Value:**
```sql
-- Example: Same query, different plans
-- May 22, 12 PM: Plan Hash = 123456789
-- After stats update: Plan Hash = 987654321

-- Statistics change = Plan changes = Different hash value
```

### Optimizer Parameters

**Key Init Parameters:**
- `optimizer_mode`: ALL_ROWS (throughput) vs FIRST_ROWS (response time)
- `cursor_sharing`: EXACT, FORCE, SIMILAR - controls cursor reuse
- `optimizer_dynamic_sampling`: 0-11 - sampling level for missing stats
- `optimizer_features_enable`: Version-specific features (11.2.0.4, etc)

### Key Takeaways Module 1

✓ Optimizer generates plans based on statistics  
✓ Full Table Scan vs Index Scan is critical decision  
✓ Bad statistics lead to bad plans  
✓ Plan consistency depends on stats and parameters  
✓ Adaptive features help optimizer learn and improve  

---

## Module 2: Cursor Sharing Strategy
*17 mentions each of "sharing" and "query", 15 of "cursor"*

### Understanding Cursor Sharing

**What is Cursor Sharing?**
A parameter that determines whether Oracle reuses execution plans when the same query is executed multiple times with different literal values.

**Why It Matters:**
- **Hard Parsing:** Very expensive - parses query every time (~10x cost of soft parse)
- **Soft Parsing:** Reuses existing plan from shared pool
- **Cursor Sharing:** Mechanism to allow reuse by replacing literals with bind variables

**The Problem Scenario:**
```
User 1: SELECT * FROM EMP WHERE ID=1
  → Hard parse (first time, no plan exists)
  → Execution plan created and stored

User 2: SELECT * FROM EMP WHERE ID=2
  → Should reuse plan? Not with cursor_sharing=EXACT
  → Hard parse again! (different literal value)
  → Wasteful - identical query structure, just different data value
```

### Three Cursor Sharing Modes

**1. EXACT (Default)**
- Only statements with exact text match share the same cursor
- Different literal values = different execution plans
- **Problem:** Hard parsing happens frequently
- **Use when:** No performance issues, or need strict control
- **Query scenario:** First ID=1, then ID=2 = TWO plans created

**2. FORCE**
- Aggressively shares cursors regardless of bind variable values
- All similar queries share one execution plan
- **Advantage:** Maximum memory savings, less hard parsing
- **Disadvantage:** One plan for all values - may be suboptimal for some values
- **Risk:** Parameter sniffing - plan optimal for value 1 but bad for value 100
- **Use when:** Memory is constrained, or uniform data distribution
- **Query scenario:** ID=1 and ID=2 = ONE plan (may not be optimal for both)

**3. SIMILAR (Recommended for Production)**
- Balances memory usage and safety
- Shares cursor if estimated execution plans will be identical
- Detects when bind value might need different plan
- Creates new cursor when necessary
- **Best of both worlds:** Memory savings + optimal plans
- **Use when:** Production database, varied data distributions
- **Query scenario:** ID=1 and ID=2 = ONE plan IF same selectivity, separate if different

### Bind Variables: The Key to Cursor Sharing

**Without Bind Variables (Hard Parse Every Time):**
```sql
SELECT * FROM EMP WHERE ID=1;    -- Hard parse #1
SELECT * FROM EMP WHERE ID=2;    -- Hard parse #2
SELECT * FROM EMP WHERE ID=3;    -- Hard parse #3
-- Result: 3 plans in shared pool, slow performance
```

**With Bind Variables (Reuse Plan):**
```sql
SELECT * FROM EMP WHERE ID=:id;  -- Hard parse #1
-- Bind :id = 1
-- Bind :id = 2
-- Bind :id = 3
-- Result: 1 plan in shared pool, fast performance
```

### How to Change Cursor Sharing

```sql
-- Check current value
SHOW PARAMETER cursor_sharing;

-- Change for session
ALTER SESSION SET cursor_sharing=SIMILAR;

-- Change for database (permanent)
ALTER SYSTEM SET cursor_sharing=SIMILAR SCOPE=BOTH;
```

### Oracle Versions and Cursor Sharing

- **Oracle 9i:** Introduced FORCE cursor sharing
- **Oracle 11g onwards:** Three options - EXACT, FORCE, SIMILAR
- **Oracle 19c:** Only EXACT and FORCE (SIMILAR removed)
- **Default:** Always EXACT

### Why Use Bind Variables?

1. **Reduces hard parsing** - Most expensive operation
2. **Reduces memory consumption** - Fewer plans in shared pool
3. **Better performance** - Plans reused frequently
4. **Security** - Prevents SQL injection
5. **Best practice** - Recommended in all applications

### Interview Questions - Cursor Sharing

**Q1 (Basic):** What are the three cursor sharing modes?
**A:** EXACT (default, no sharing), FORCE (aggressive sharing), SIMILAR (recommended, balanced)

**Q2 (Intermediate):** Why would FORCE mode cause problems with different bind values?
**A:** If bind value 1 needs nested loop (fast for 10 rows) but value 100 returns 1M rows, then hash join needed. Single plan for both = suboptimal for one scenario.

**Q3 (Advanced):** Design a cursor sharing strategy for an OLTP app with highly varied data distributions.
**A:** Use SIMILAR mode. Bind all literals. Monitor library cache hit ratio. Set cursor_sharing=SIMILAR at database level. Application uses prepared statements with bind variables. Monitor execution plans for plan changes.

---

## Module 3: Index Rebuilding & Statistics Gathering
*80 mentions of "index", 39 of "statistics"*

### Index Types in Oracle

**B-Tree Index (Most Common):**
- Hierarchical tree structure
- Fast for equality and range queries (=, <, >, BETWEEN)
- Good for high-selectivity columns (many distinct values)
- Traditional choice for most scenarios
- Example: Employee ID index on large table

**Bitmap Index:**
- Stores bitmap of row positions
- Efficient for low-cardinality columns (few distinct values)
- Fast for AND/OR operations on multiple columns
- Good for read-heavy, rarely updated data
- Example: Gender (M/F), Status (Active/Inactive/Archived)

**Usage Guidelines:**
- Use B-Tree for highly selective columns
- Use Bitmap for low-cardinality (< 100 distinct values)
- Combine both if multi-column filtering on mixed cardinality

### Index Fragmentation and Rebuilding

**When Indexes Become Fragmented:**
- Many delete operations leave gaps
- After large bulk operations
- Performance degrades as gaps accumulate
- Scan efficiency decreases

**Why Rebuild an Index:**
- **Restore performance** - Removes gaps and compacts structure
- **Reduce storage** - Reclaims space from deleted entries
- **Improve access speed** - Optimizes block efficiency
- **Reduce I/O** - Fewer blocks to read for same data

**Online Index Rebuild (Recommended):**
- Users can continue queries while rebuild happens
- No downtime required
- Slightly slower than offline (but worth it for production)
- Production-safe method

**Command:**
```sql
-- Online rebuild (production safe)
ALTER INDEX index_name REBUILD ONLINE;

-- Offline rebuild (faster but blocks queries)
ALTER INDEX index_name REBUILD;

-- Monitor progress
SELECT * FROM v$session_longops WHERE opname='Index creation';
```

### Statistics Gathering: Critical for Optimizer

**Why Statistics Matter:**
- Optimizer uses statistics to estimate rows returned
- Example: 100 distinct values in 10M rows = estimated 100,000 rows per value
- Bad statistics = bad cardinality estimates = wrong plan selection
- Stale statistics common cause of performance degradation

**What Statistics Include:**
- Number of rows in table
- Number of data blocks used
- Average row length
- Column NDV (Number of Distinct Values)
- Column min/max values
- Data distribution (uniform vs skewed)

**Stale Statistics Problem:**
```
Table stats: 100 rows
Actual data: 1,000,000 rows (100x difference!)
Optimizer thinks small table → picks full scan
Actual: Large table with full scan = slow query
```

### Using DBMS_STATS Package

**Gather Table Statistics:**
```sql
-- Basic statistics gathering
EXEC DBMS_STATS.gather_table_stats(
  ownname => 'HR',
  tabname => 'EMPLOYEES'
);

-- With histogram for skewed data
EXEC DBMS_STATS.gather_table_stats(
  ownname => 'HR',
  tabname => 'EMPLOYEES',
  method_opt => 'FOR ALL COLUMNS SIZE 254'
);

-- Gather index statistics
EXEC DBMS_STATS.gather_index_stats('HR', 'idx_emp_id');
```

**Lock and Unlock Statistics:**
```sql
-- Lock statistics (prevent auto-update if optimal)
EXEC DBMS_STATS.lock_table_stats('HR', 'EMPLOYEES');

-- Unlock for updates
EXEC DBMS_STATS.unlock_table_stats('HR', 'EMPLOYEES');
```

**Check Statistics Age:**
```sql
SELECT table_name, last_analyzed, num_rows, blocks
FROM dba_tables
WHERE owner='HR' AND table_name='EMPLOYEES';
```

### Best Practices for Statistics Management

**1. Schedule Regular Gathering**
- Run during maintenance windows (off-peak)
- Use DBMS_SCHEDULER for automation
- Default: Automatic job in most Oracle versions

**2. Use Incremental Statistics**
- For large partitioned tables
- Gather stats on changed partitions only
- Faster than full table scan
- Reduces I/O impact

**3. Monitor Staleness**
- Track when stats were last gathered
- Use DBA_TAB_STATISTICS view
- Alert if older than defined threshold
- Plan regular refresh schedule

**4. Preserve Good Statistics**
- Lock if current plan is optimal
- Document locking rationale
- Use SQL baselines for guaranteed good plans
- Test before unlocking

### Interview Questions - Index & Statistics

**Q1 (Basic):** When would you rebuild an index?
**A:** When fragmented (many deletes), after bulk operations, or when performance degrades. Online rebuild recommended for production.

**Q2 (Intermediate):** Explain why stale statistics cause performance problems.
**A:** Optimizer estimates cardinality from stats. If stats show 100 rows but table has 1M, optimizer underestimates result size. Picks nested loop (fast for small results) when hash join (fast for large results) would be better. Query runs slowly.

**Q3 (Advanced):** Design statistics strategy for large partitioned table with daily inserts.
**A:** Use incremental stats gathering. Run nightly after load completes. Lock stats if partition stable. Use dynamic sampling for new partitions. Monitor partition staleness separately. Re-gather when percent of rows changed exceeds threshold.

---

## Module 4: Optimizer Statistics for Performance
*69 mentions of "statistics", 21 of "index", 19 of "optimizer"*

### Types of Statistics Available

**Table Statistics:**
- Total rows (cardinality)
- Number of data blocks (physical size)
- Average row length (storage efficiency)
- High water mark (growth tracking)

**Column Statistics:**
- Number of Distinct Values (NDV) - uniqueness
- Minimum value - range boundary
- Maximum value - range boundary
- Null count - missing data
- Data distribution pattern

**Index Statistics:**
- Leaf blocks (size of index)
- Branch levels (index depth)
- Clustering factor (how ordered data is)
- Leaf block density

### Histograms: Handling Skewed Data

**The Problem:**
Optimizer assumes uniform data distribution. Reality: Often data is heavily skewed.

**Example:**
```
Employee salaries: 
- 900 employees earning 30-60K (majority)
- 100 employees earning 100-500K (executives)

Query: SELECT * FROM employees WHERE salary > 400000
Without histogram: Estimated 500,000 rows (wrong!)
Actual rows: 100
Optimizer picks wrong plan for small result set
```

**Histogram Solution:**
Tracks actual data distribution in buckets

**Creating Histograms:**
```sql
-- Create histogram for salary column
EXEC DBMS_STATS.gather_table_stats(
  ownname => 'HR',
  tabname => 'EMPLOYEES',
  method_opt => 'FOR COLUMNS SIZE 254 (salary) FOR ALL COLUMNS SIZE 1'
);
-- SIZE 254: Number of histogram buckets (max)
-- SIZE 1: Other columns - no histogram
```

**Benefits:**
- Accurate cardinality estimates even with skewed data
- Better join order decisions
- Correct index vs full scan choice
- Plan stability across data ranges

### Dynamic Sampling

**Purpose:**
Gather runtime statistics when table statistics are missing or stale

**How It Works:**
1. During hard parse, if stats missing
2. Sample small portion of table
3. Estimate statistics from sample
4. Use for query optimization
5. Trade execution time for better plan selection

**Levels (0-11):**
- **Level 0:** Off (don't sample)
- **Level 1-3:** Sample small tables only
- **Level 4-7:** Sample when needed
- **Level 11:** Aggressive sampling

**Example:**
```sql
-- Enable dynamic sampling at session level
ALTER SESSION SET optimizer_dynamic_sampling=4;

-- Or database level
ALTER SYSTEM SET optimizer_dynamic_sampling=4;
```

**Trade-off:** Parse time increases but plan quality improves

### How Optimizer Uses Statistics

**1. Cardinality Estimation:**
```
Example: Table has 10,000,000 rows, column X has 100 distinct values
Query: SELECT * FROM table WHERE X = 5
Estimated rows = 10,000,000 / 100 = 100,000 rows
```

**2. Cost Calculation:**
```
Cost = (CPU_cycles / CPU_cost_per_cycle) + (I/O_operations * IO_cost)
Compares costs of:
- Nested loop join
- Hash join
- Sort merge join
Picks lowest cost
```

**3. Join Order Decision:**
```
Query: SELECT * FROM orders o, customers c WHERE o.cust_id = c.id
Most selective table first:
- If customers = 100 rows, orders = 10M rows
- Nested loop: start with customers (smaller)
- Estimated result set size affects choice
```

### Statistics Accuracy Impact

**Good Statistics:**
- ✓ Accurate cardinality estimates
- ✓ Optimal plan selection
- ✓ Fast query execution
- ✓ Predictable performance
- ✓ Reduced variability

**Bad Statistics:**
- ✗ Wrong cardinality estimates
- ✗ Suboptimal plan selection
- ✗ Slow query execution
- ✗ Unpredictable performance
- ✗ High variability

### Interview Questions - Optimizer Statistics

**Q1 (Basic):** What information does the optimizer use from statistics?
**A:** Cardinality (row count), column distribution, distinct values, min/max ranges, index efficiency metrics

**Q2 (Intermediate):** Why would you create a histogram on a specific column?
**A:** When data is skewed (not uniformly distributed). Histogram tracks actual distribution, improving cardinality estimates. Example: employee salaries with few executives.

**Q3 (Advanced):** Explain how stale statistics on join column lead to suboptimal joins.
**A:** If stats show 100 rows but column has 1M distinct values (actual), optimizer overestimates cardinality. For join on this column, underestimates result set. Picks nested loop when hash join needed. Results in poor performance.

---

## Module 5: ADDM & ASH Reports
*13 mentions of "AWR", 9 of "parsing", 6 of "bind variable"*

### ASH: Active Session History

**Purpose:**
Real-time monitoring of what sessions are actively doing and what they're waiting for

**How It Works:**
- Samples every session every second
- Records current activity at moment of sample
- Stored in SGA (memory)
- Limited history (circular buffer)

**What ASH Captures:**
- Session ID and username
- Wait event (what is session waiting for)
- SQL ID (which SQL is executing)
- CPU usage
- I/O statistics
- User I/O time
- Application wait time

**Key Wait Events:**

| Wait Event | Meaning | Typical Cause |
|------------|---------|---------------|
| db file sequential read | Single block read (index) | Index scan waiting for I/O |
| db file scattered read | Multi-block read (FTS) | Full table scan waiting for I/O |
| latch free | Internal Oracle lock | Heavy contention |
| log file sync | Commit waiting for writes | I/O subsystem slow |
| CPU | Using CPU (not waiting) | Good sign - CPU time |

**ASH Queries:**
```sql
-- Real-time active sessions
SELECT * FROM v$session WHERE status='ACTIVE';

-- Recent ASH history
SELECT * FROM v$active_session_history 
WHERE session_id=123 
ORDER BY sample_time DESC;

-- Top wait events (last hour)
SELECT event, count(*) FROM v$active_session_history 
GROUP BY event 
ORDER BY count(*) DESC;
```

### ADDM: Automatic Database Diagnostic Monitor

**Purpose:**
Analyzes database performance automatically and provides recommendations

**How It Works:**
1. Captures two AWR snapshots (typically 1 hour apart)
2. Analyzes performance differences
3. Identifies top wait events and impact
4. Determines root causes
5. Provides actionable recommendations with expected improvements

**ADDM Output Sections:**
- **Problem statements:** What's wrong (with % impact)
- **Root causes:** Why it's happening
- **Recommendations:** How to fix it (with expected benefit %)
- **Findings:** Supporting data and analysis

**Types of Issues ADDM Finds:**
- CPU bottleneck (queries consuming excessive CPU)
- I/O bottleneck (waiting for disk reads/writes)
- Memory insufficiency (SGA too small)
- Excessive parsing (hard parse frequency)
- Lock contention (sessions blocking each other)
- Inefficient SQL (suboptimal execution plans)

### ADDM vs AWR Comparison

| Aspect | ADDM | AWR |
|--------|------|-----|
| **Purpose** | Automated diagnosis | Metrics storage |
| **Output** | Recommendations | Raw statistics |
| **Interpretation** | Automatic | Manual analysis |
| **For beginners** | ✓ Good | Requires expertise |
| **Detail level** | Summary | Detailed |
| **Actions needed** | Follow recommendations | Analyze yourself |

### Using ADDM Reports

**Access ADDM Analysis:**
```sql
-- Create ADDM task
EXEC DBMS_ADVISOR.create_task('ADDM', 'my_analysis');
EXEC DBMS_ADVISOR.set_task_parameter('my_analysis', 'START_SNAPSHOT', 100);
EXEC DBMS_ADVISOR.set_task_parameter('my_analysis', 'END_SNAPSHOT', 101);

-- Execute analysis
EXEC DBMS_ADVISOR.execute_task('my_analysis');

-- View recommendations
SELECT * FROM dba_advisor_recommendations 
WHERE task_name='my_analysis' 
ORDER BY benefit DESC;
```

**Interpretation:**
Look for:
- **High-impact issues** (>10% database time)
- **Root causes** (database-related vs application)
- **Quick wins** (easy-to-implement fixes)
- **Plan** (what recommendation to follow)

### Parsing and Its Impact

**Hard Parse:**
- Fully parses SQL statement
- Checks syntax, validates objects
- Generates execution plan
- Very expensive (10x cost of soft parse)
- Consumes CPU and memory

**Soft Parse:**
- Reuses existing execution plan
- Minimal processing needed
- Fast operation
- Desired behavior

**Excessive Parsing Problem:**
- Each literal value triggers hard parse (cursor_sharing=EXACT)
- Application doesn't use bind variables
- Library cache thrashing (plans constantly evicted)
- CPU usage high, throughput low
- ADDM will recommend using bind variables

### Interview Questions - ADDM & ASH

**Q1 (Basic):** What is ASH and what does it monitor?
**A:** Active Session History tracks every active session in real-time, recording what it's doing, which SQL running, and what wait events occurring.

**Q2 (Intermediate):** How would you use ADDM to investigate CPU bottleneck issue?
**A:** Run ADDM analysis over snapshot pair when CPU high. Review findings - will identify top CPU-consuming SQL, missing indexes, or excessive parsing. Get recommendations with expected benefit %. Implement and measure.

**Q3 (Advanced):** ADDM recommends "reduce parsing" but application uses hardcoded SQL. Walk through your solution.
**A:** 1) Confirm hard parsing via ASH queries. 2) Analyze SQL statements in library cache. 3) Work with app team to implement bind variables. 4) Or set cursor_sharing=FORCE if app can't be changed. 5) Measure library cache hit ratio before/after. 6) Verify parsing count decreases.

---

## Module 6: AWR Report Analysis
*27 mentions of "AWR", 8 each of "performance" and "tuning"*

### AWR: Automatic Workload Repository

**Purpose:**
Captures comprehensive database performance snapshots and enables historical analysis

**What AWR Stores:**
- Database load profile (database time, reads, writes)
- Top SQL statements (by CPU, I/O, elapsed time)
- Wait events and timing
- Resource usage metrics
- Instance efficiency ratios
- Parameter changes
- Historical trends

**Storage & Retention:**
- Snapshots taken every hour (default)
- Retained for 7-8 days (configurable)
- Stored in SYSAUX tablespace
- Compressed to save space
- Historical data for trending

### Key AWR Report Sections to Analyze

**1. Load Profile:**
Shows overall database activity during snapshot period

```
Database Time (seconds): 3,600
Physical Reads: 50,000
Physical Writes: 10,000
Logical Reads: 1,000,000
Parse Count: 2,000
Execute Count: 100,000
```

**What to look for:**
- Database Time should correlate with user load
- Physical I/O reasonable for workload size
- High parse count indicates excessive cursor creation
- Execute/Parse ratio should be high (plan reuse)

**2. Top 5 Timed Events:**
Most critical section - shows what database spent time on

```
Event                  | Seconds | % Total
db file sequential read | 1,200   | 33%
db file scattered read  | 900     | 25%
CPU time                | 600     | 17%
latch free              | 300     | 8%
log file sync           | 300     | 8%
```

**Interpretation:**
- **db file sequential read high** → Index scan I/O waits
- **db file scattered read high** → Full table scan I/O waits
- **CPU time high** → CPU-bound workload
- **latch free high** → Contention (concurrent access)
- **log file sync high** → I/O subsystem slow

**Action:** Address top events first - they have highest impact

**3. SQL Statistics:**
Top SQL by various metrics

```
Top SQL by Elapsed Time:
SQL ID | SQL Text | Elapsed (s) | Executions | Per Exec (ms)
abc123 | SELECT...| 500         | 100        | 5000
def456 | SELECT...| 300         | 1000       | 300

Top SQL by CPU Time:
sql789 | SELECT...| 200         | 50         | 4000
```

**Interpretation:**
- Find slowest queries (highest elapsed time per execution)
- Find most-executed queries (high total time despite fast per-exec)
- Review execution plans for these queries
- Check if statistics fresh
- Look for opportunities to optimize

**4. Instance Efficiency Ratios:**

```
Library Cache Hit Ratio: 95%        (Should be >90%)
Buffer Cache Hit Ratio: 99.5%       (Should be >99%)
Soft Parse Ratio: 99%               (Should be >95%)
```

**What means what:**
- **Low Library Cache Hit:** Parse time high, plans evicted frequently
- **Low Buffer Cache Hit:** Physical I/O high, SGA too small or index inefficient
- **Low Soft Parse Ratio:** Excessive hard parsing, missing bind variables

**5. Wait Events Details:**
Deep dive into specific wait events

```
Event: db file sequential read
Count: 50,000
Total Wait Time (s): 1,200
Average Wait (ms): 24
Max Wait (ms): 500
Timeouts: 0
```

**Interpretation:**
- Count shows frequency
- Average wait shows I/O performance
- High average (>20ms) suggests slow disk

### Comparing Baseline to Problem Period

**Steps to Diagnose Degradation:**

1. **Generate AWR report for problem period**
   ```sql
   @$ORACLE_HOME/rdbms/admin/awrrpt.sql
   ```

2. **Compare to baseline (known good period)**
   - Database time increased?
   - Top events changed?
   - Top SQL different?
   - Parameter changes?

3. **Identify differences:**
   - "Top SQL by Elapsed Time" different?
   - "Top 5 Timed Events" different?
   - "Instance Efficiency Ratios" degraded?

4. **Dig deeper into changes:**
   - New top SQL? Analyze execution plan
   - Changed event? Check for blocks/waits
   - Degraded ratio? Check resource allocation

5. **Implement fix:**
   - Add missing index
   - Update statistics
   - Tune SQL
   - Adjust parameters

6. **Verify:**
   - Generate AWR report after fix
   - Compare metrics to baseline
   - Confirm improvement

### Interview Questions - AWR Analysis

**Q1 (Basic):** What time period does AWR typically cover?
**A:** Hourly snapshots retained for 7-8 days by default. Reports usually compare two snapshots (one hour apart).

**Q2 (Intermediate):** How do you identify if a problem is I/O-bound vs CPU-bound using AWR?
**A:** Check "Top 5 Timed Events" section. If "db file sequential/scattered read" events high, it's I/O-bound. If "CPU time" is #1 event, it's CPU-bound. Also check instance efficiency ratios.

**Q3 (Advanced):** You notice top SQL changed between baseline and problem AWR report. Walk through your analysis steps.
**A:** 1) Get SQL IDs of new top SQL. 2) Run EXPLAIN PLAN for new top SQL. 3) Compare plan to baseline period (if still running). 4) Check if statistics changed. 5) Review wait events for this SQL (latch contention?). 6) Check execution frequency - now running more often? 7) Identify root cause and implement fix.

---

## Module 7: Database Performance Tuning Introduction
*55 mentions of "tuning", 30 of "performance", 21 of "optimizer"*

### Performance Tuning Methodology

**The Systematic Approach:**

1. **Establish Baseline**
   - Define normal performance
   - Set acceptable thresholds
   - Document response times
   - Measure resource usage

2. **Monitor Continuously**
   - Use AWR/ADDM/ASH tools
   - Track metrics over time
   - Alert on deviations
   - Maintain performance history

3. **Identify Bottleneck**
   - What's the limiting factor?
   - CPU, I/O, Memory, Network?
   - Which SQL contributes most?
   - Is it database or application?

4. **Implement Fix**
   - Add missing indexes
   - Adjust parameters
   - Optimize SQL queries
   - Redesign if needed

5. **Verify Improvement**
   - Measure new baseline
   - Confirm issue resolved
   - Monitor for side effects
   - Document changes

### Common Performance Scenarios

**Scenario 1: Slow Query**
- Use EXPLAIN PLAN to review execution
- Check for full table scans
- Review statistics currency
- Consider query rewrite or hints
- Look for missing index opportunities

**Scenario 2: High CPU**
- Identify top SQL using AWR
- Review execution plans
- Check for inefficient loops
- Optimize expensive operations
- Consider parallel execution

**Scenario 3: High I/O**
- Check for missing indexes
- Review full table scans
- Verify I/O subsystem health
- Consider caching strategies
- Profile disk usage by file

**Scenario 4: Memory Pressure**
- Review SGA sizing
- Check PGA usage
- Identify memory-consuming queries
- Adjust parameters
- Reduce unnecessary sorting

### Index Strategy for Performance

**When to Create Indexes:**
- Frequently searched columns (WHERE clauses)
- Join columns (WHERE condition in JOINs)
- Order by columns (sorting overhead)
- Foreign key columns (referential integrity)

**When NOT to Create Indexes:**
- Columns rarely used in queries
- Low-cardinality columns (few distinct values)
- Columns with heavy INSERT/UPDATE
- Very small tables

**Index Maintenance:**
- Monitor fragmentation
- Rebuild when necessary
- Update statistics after rebuild
- Document index purpose

### Statistics Maintenance

**Regular Schedule:**
- Daily in OLTP systems
- Weekly in Data Warehouse
- After bulk operations
- After schema changes

**Best Practices:**
- Gather at off-peak hours
- Use incremental for large tables
- Lock if plan is optimal
- Monitor for staleness
- Archive old statistics if needed

### Database Parameter Tuning

**Key Parameters:**

```
SGA_TARGET: Total shared memory allocation
PGA_AGGREGATE_TARGET: Total program work memory
DB_FILE_MULTIBLOCK_READ_COUNT: I/O efficiency
CURSOR_SHARING: Cursor reuse strategy
OPTIMIZER_MODE: Response vs throughput
STATISTICS_LEVEL: Metrics collection
```

**Tuning Approach:**
- Start with defaults
- Monitor metrics
- Adjust based on bottleneck
- Test thoroughly before production
- Document rationale

### Common Mistakes to Avoid

1. **Tuning without baseline** - Don't know if better
2. **Tuning wrong thing** - Optimizing non-bottleneck
3. **Ignoring statistics** - Root cause of most issues
4. **Excessive parallel** - Wastes resources
5. **No testing** - Changes have side effects
6. **Over-indexing** - Hurts INSERT/UPDATE performance
7. **Ignoring cache misses** - Focus only on data movement

### Interview Questions - Performance Tuning

**Q1 (Basic):** What are the 5 steps of performance tuning methodology?
**A:** Establish baseline, monitor continuously, identify bottleneck, implement fix, verify improvement.

**Q2 (Intermediate):** How would you prioritize which queries to optimize when multiple queries are slow?
**A:** By impact: queries using most CPU/I/O, run most frequently, have highest response time requirements. AWR helps identify - optimize top SQL first.

**Q3 (Advanced):** You optimize a query from 10 seconds to 5 seconds, but notice overall database performance unchanged. Why? What would you do?
**A:** That query may not be your bottleneck. If it runs once daily (5 seconds saved) vs another query running 1000x daily (even slight slowness = major impact). Use AWR to identify database time consumers. Focus on queries with highest total database time impact, not individual response time.

---

## Module 8: Long Running Transactions & Slowness
*25 mentions of "session", 20 of "query", 8 each of "performance" and "ASH"*

### Identifying Long-Running Sessions

**Primary Query for Long Operations:**
```sql
SELECT 
  opname,              -- Operation name (backup, query execution)
  elapsed_seconds,     -- How long running
  time_remaining,      -- Estimated seconds until complete
  work_done,          -- Completed portion
  totalwork,          -- Total work needed
  target,             -- Table/object being worked on
  sid, serial#        -- Session identifiers
FROM gv$session_longops
WHERE status='EXECUTING'
ORDER BY elapsed_seconds DESC;
```

**Alternative - Check Active Sessions:**
```sql
SELECT 
  sid, 
  sql_id, 
  sql_text, 
  elapsed_time,
  status
FROM v$session
WHERE status='ACTIVE'
ORDER BY elapsed_time DESC;
```

**Key Columns Explained:**
- `opname`: What operation (SELECT, INSERT, Index Rebuild, Backup)
- `elapsed_seconds`: Duration so far
- `time_remaining`: How much longer (estimate)
- `work_done`: Progress percentage
- `target`: Which table/index being accessed
- `sid`: Session ID (needed for killing)
- `serial#`: Session serial number (needed for killing)

### Root Causes of Slowness

**1. Inefficient SQL Queries**
- Full table scan on large table
- Missing indexes
- Bad execution plan
- Inefficient joins (wrong join method/order)
- Subqueries instead of joins

**2. Resource Bottleneck**
- CPU fully utilized (contention)
- I/O subsystem saturated
- Memory insufficient (excessive paging)
- Network congestion (distributed query)
- Undo tablespace full

**3. Lock Contention**
- One session blocking others
- Row-level locks on hot data
- Table locks (exclusive mode)
- Index contention
- Enqueue waits

**4. Scheduled Maintenance**
- Backup job consuming resources
- Index rebuilds running
- Statistics gathering in progress
- Archive/export operations
- Batch jobs overnight

**5. External Factors**
- Operating system CPU limit
- Storage array bottleneck
- Network switch overloaded
- Other applications competing

### Handling Long-Running Backups

**Backup Best Practices:**
- Schedule during off-peak hours (midnight to 5 AM)
- Minimal user connections expected
- Reduces production impact
- Uses more resources without affecting users

**If Backup Causes Slowness:**
1. Increase parallel channels (backups simultaneously)
2. Use compression to reduce I/O
3. Reschedule to earlier/later time
4. Separate to different server if available
5. Exclude unnecessary tablespaces

### Killing Problematic Sessions

**When to Kill a Session:**
- Query running far longer than acceptable
- Has application team approval
- Session is stuck (no progress in time_remaining)
- Blocking other users

**Step 1: Get Session Information**
```sql
SELECT sid, serial#, username, sql_id, sql_text
FROM v$session
WHERE status='ACTIVE'
ORDER BY elapsed_time DESC;

-- Example output:
-- SID=71, SERIAL#=12345
```

**Step 2: Verify It's the Right Session**
- Check SQL running
- Confirm user
- Verify elapsed time

**Step 3: Kill the Session**
```sql
ALTER SYSTEM KILL SESSION '71,12345' IMMEDIATE;
```

**Clarification:**
- For RMAN backups - DBA can kill without approval
- For user queries - Get approval first
- For batch jobs - Coordinate with operations
- Document reason for killing

### Session Killing Scenarios

**Scenario 1: User Query Running Too Long**
```
Query: SELECT * FROM huge_table (running 2 hours)
Get SID: 71
Get SERIAL#: 12345
Verify: It's SELECT, user approved killing
Kill: ALTER SYSTEM KILL SESSION '71,12345' IMMEDIATE;
Result: Session terminated, user gets error, locks released
```

**Scenario 2: Backup Job Using Too Much Resource**
```
Backup started: 2 PM
Should finish: 4 PM
Now: 6 PM (still running, users slow)
Option 1: Increase channels to speed up
Option 2: Kill and restart later
Option 3: Let finish, users slow temporarily
Decision: Increase channels (ALTER SYSTEM SET parallelism=4)
```

**Scenario 3: Long-Running Index Build**
```
Index rebuild started: midnight
Should finish: 4 AM
Now: 10 AM, still running, users now working
Option 1: Wait for completion (minimal user impact if built online)
Option 2: Kill and rebuild later
Decision: Let finish (online means users can work)
```

### Interview Questions - Long Running Transactions

**Q1 (Basic):** What query shows long-running operations in the database?
**A:** SELECT * FROM gv$session_longops WHERE status='EXECUTING'; Shows opname, elapsed_seconds, time_remaining, and progress details.

**Q2 (Intermediate):** Walk through the complete steps to kill a session that's been running 3 hours.
**A:** 1) Query v$session ordered by elapsed_time to find the session. 2) Get SID and SERIAL# (e.g., 71, 12345). 3) Verify it's correct session and query running. 4) Get approval from application team. 5) Execute: ALTER SYSTEM KILL SESSION '71,12345' IMMEDIATE;. 6) Monitor to confirm termination.

**Q3 (Advanced):** You find a backup running since midnight that should've finished by 4 AM. It's now 6 AM and users are complaining about slowness. You can't kill backup. Walk through your options.
**A:** 1) Check AWR for top wait events. 2) If CPU-bound, backup parallelism fine. If I/O-bound, increase channels. 3) Can schedule next backup earlier (before users login). 4) Consider archiving old data to reduce backup size. 5) Or use incremental backup to speed up. 6) Communication: notify users when backup completes, expect temporary slowness during backups.

---

## Module 9: ROWID & ROWNUM Comprehensive Tutorial
*Focus on practical data manipulation and performance*

### ROWID: Physical Address of a Row

**What is ROWID?**
A pseudo-column that provides the unique physical address of each row in the database. It's the fastest way to access a specific row.

**Key Characteristics:**
- Not physically stored as a column
- Assigned automatically by Oracle
- Unique within the database
- Immutable (doesn't change while row exists)
- Fastest way to retrieve a row
- Contains file, block, and sequence information

**ROWID Format:**
```
AAAAAAA FFBBBBBB SSSSS
|       ||       |
|       ||       +-- Slot number (position in block)
|       |+---------- Block number (where row is stored)
|       +----------- File number (which datafile)
+------------------ Data object ID (which table)
```

**Practical Example:**
```sql
SELECT job_id, job_title, ROWID
FROM jobs
WHERE job_id = 'AD_PRES';

-- Output:
-- JOB_ID   JOB_TITLE       ROWID
-- AD_PRES  President       AAAAB3.AAA.AAAAAAA=
```

### Why ROWID is Fastest

**Performance Comparison:**
```sql
-- Slowest (full table scan)
SELECT * FROM jobs WHERE job_title='President';  
-- Scans every row looking for match

-- Faster (index scan)
SELECT * FROM jobs WHERE job_id='AD_PRES';
-- Uses index to find row, then reads block

-- Fastest (ROWID direct access)
SELECT * FROM jobs WHERE ROWID='AAAAB3.AAA.AAAAAAA=';
-- Goes directly to block, reads row (no search needed)
```

### ROWID Use Case 1: Deleting Duplicates

**Problem:**
Multiple employees with same name but different data entered twice

**Solution Using ROWID:**
```sql
-- Find duplicates
SELECT name, COUNT(*)
FROM employees
GROUP BY name
HAVING COUNT(*) > 1;

-- Delete duplicates, keep first occurrence
DELETE FROM employees
WHERE name IN (SELECT name FROM employees GROUP BY name HAVING COUNT(*)>1)
AND ROWID NOT IN (SELECT MIN(ROWID) FROM employees GROUP BY name);

COMMIT;
```

**How It Works:**
- Finds rows with duplicate names
- Keeps oldest (MIN ROWID)
- Deletes all others
- Fast because uses ROWID directly

### ROWID Use Case 2: Bulk Deletion in Chunks

**Problem:**
Need to delete 10 million old records but can't delete all at once (locks table, fills undo)

**Solution:**
```sql
-- Delete in chunks of 20,000 rows
BEGIN
  LOOP
    DELETE FROM audit_log
    WHERE audit_date < TRUNC(SYSDATE) - 90
    AND ROWNUM < 20001;  -- First 20,000 rows
    
    COMMIT;
    
    EXIT WHEN SQL%ROWCOUNT = 0;  -- Exit when no more rows
  END LOOP;
END;
/
```

**Why This Works:**
- Deletes in small chunks
- COMMIT after each chunk releases locks
- Allows other users to query between chunks
- Prevents undo tablespace overflow
- Can monitor progress

**Alternative with Bulk Collect:**
```sql
-- More efficient
DECLARE
  TYPE rowid_array IS TABLE OF ROWID;
  v_rowids rowid_array;
BEGIN
  LOOP
    SELECT ROWID BULK COLLECT INTO v_rowids FROM audit_log
    WHERE audit_date < TRUNC(SYSDATE) - 90
    AND ROWNUM <= 10000;
    
    EXIT WHEN v_rowids.COUNT = 0;
    
    FORALL i IN 1..v_rowids.COUNT
      DELETE FROM audit_log WHERE ROWID = v_rowids(i);
    
    COMMIT;
  END LOOP;
END;
/
```

### ROWNUM: Row Sequence Within Query

**What is ROWNUM?**
A pseudo-column that assigns a sequence number to rows as they're returned by a query. Important: Assigned AFTER retrieval, BEFORE ORDER BY.

**Key Characteristics:**
- Assigned during query execution
- Starts from 1 for first row returned
- Temporary (only exists for that query execution)
- Affected by WHERE clause filtering
- Not based on actual data order

**Critical Point - ROWNUM Quirk:**
```sql
-- WRONG: Won't work as expected
SELECT * FROM employees ORDER BY hire_date ROWNUM <= 10;
-- ROWNUM assigned before ORDER BY
-- Returns first 10 rows, THEN orders them (wrong!)

-- RIGHT: Use inline view
SELECT * FROM (
  SELECT * FROM employees ORDER BY hire_date
) WHERE ROWNUM <= 10;
-- Subquery orders, outer query limits (correct!)
```

### ROWNUM Use Cases

**Use Case 1: Limit Result Set**
```sql
-- Get first 10 employees
SELECT * FROM employees
WHERE ROWNUM <= 10;
-- Note: Use ROWNUM < 11 not ROWNUM <= 10 (clearer intent)
```

**Use Case 2: Pagination**
```sql
-- Get rows 21-30 (page 3, page size 10)
SELECT * FROM (
  SELECT e.*, ROWNUM as rn FROM (
    SELECT * FROM employees ORDER BY employee_id
  ) e
  WHERE ROWNUM <= 30
) 
WHERE rn > 20;
```

**Use Case 3: Bulk Operations**
```sql
-- Update only first 1000 rows
UPDATE employees SET salary = salary * 1.1
WHERE ROWNUM <= 1000;

-- Delete batches
DELETE FROM archive_log
WHERE created < TRUNC(SYSDATE) - 365
AND ROWNUM <= 50000;
COMMIT;
```

### ROWID vs ROWNUM Comparison

| Aspect | ROWID | ROWNUM |
|--------|-------|--------|
| **Type** | Pseudo-column (physical address) | Pseudo-column (sequence) |
| **Scope** | Entire database | Single query result |
| **Persistence** | Row exists | Query execution |
| **Purpose** | Direct row access | Result limiting |
| **Performance** | Excellent (direct) | Good (sequence) |
| **Usage** | WHERE clause | WHERE clause, pagination |
| **Immutability** | Doesn't change | Changes per query |
| **Storage** | Not stored | Assigned dynamically |

### Practical Performance Tips

**Tip 1: Use ROWID for Fastest Updates**
```sql
-- Very fast - direct row access
UPDATE employees 
SET salary = 50000
WHERE ROWID = 'AAAAC3.AAA.AAAAAAA=';

-- Slower - index lookup
UPDATE employees 
SET salary = 50000
WHERE employee_id = 1;
```

**Tip 2: ROWNUM for Sampling**
```sql
-- Get 1% sample of huge table
SELECT * FROM huge_table
WHERE DBMS_RANDOM.value < 0.01;

-- Or simple ROWNUM sample
SELECT * FROM huge_table
WHERE MOD(ROWID, 100) = 1;
```

**Tip 3: Pagination Pattern**
```sql
-- Reusable pagination template
SELECT * FROM (
  SELECT t.*, ROWNUM as rn FROM (
    SELECT * FROM data_table
    ORDER BY primary_key
  ) t
  WHERE ROWNUM <= :page_size * :page_number
)
WHERE rn > :page_size * (:page_number - 1);

-- Pass in parameters:
-- :page_number = 5 (5th page)
-- :page_size = 20 (20 rows per page)
-- Returns rows 81-100
```

### Interview Questions - ROWID & ROWNUM

**Q1 (Basic):** What is ROWID and why is it the fastest way to access data?
**A:** ROWID is a pseudo-column containing the physical address of each row. It's fastest because it goes directly to the exact block and slot without searching via index or scanning.

**Q2 (Intermediate):** Show me how you'd delete duplicate rows using ROWID, keeping only the first occurrence.
**A:** Find duplicates by grouping. Delete where name is duplicate AND ROWID NOT IN (SELECT MIN(ROWID) GROUP BY name). This keeps oldest, deletes newer duplicates.

**Q3 (Advanced):** Design a bulk deletion strategy for 10 million records with specific criteria, considering production impact.
**A:** 1) Delete in 20K-row chunks with COMMIT between. 2) Use ROWNUM < 20001 to limit each batch. 3) Loop until no rows deleted. 4) Runs during off-peak hours. 5) Monitors progress. 6) Allows other queries between commits. 7) Prevents table locks and undo overflow. 8) Can adjust chunk size based on available resources.

---

## 🎯 Comprehensive Interview Preparation

### Quick Reference: 50+ Critical Questions

**BASIC LEVEL - Foundation (10 Qs)**
1. What is the Query Optimizer and what does it do?
2. What is the difference between Full Table Scan and Index Scan?
3. What are the three cursor sharing modes?
4. What is ROWID and how does it work?
5. What is ROWNUM and how is it assigned?
6. What are the two types of indexes in Oracle?
7. Why are statistics important for the optimizer?
8. What is AWR and what does it capture?
9. What is ASH and what does it monitor?
10. What is ADDM and what does it do?

**INTERMEDIATE LEVEL - Application (15 Qs)**
11. Explain the 10 magical steps for query tuning
12. Why does FORCE cursor sharing cause problems?
13. How do you identify and kill a long-running session?
14. What happens with stale statistics?
15. How do bind variables help cursor sharing?
16. When would you use bitmap indexes vs B-tree?
17. Why would you rebuild an index?
18. How do you gather table statistics?
19. What is Adaptive Query Optimization and how does it work?
20. How do you compare ROWID and ROWNUM?
21. How would you delete bulk records efficiently?
22. What are histograms used for?
23. How do you identify if a problem is I/O-bound or CPU-bound?
24. What is the difference between ADDM and AWR?
25. How do you prevent hard parsing?

**ADVANCED LEVEL - Complex Scenarios (25 Qs)**
26. Walk through analyzing an AWR report to find performance issues
27. Explain how ADDM diagnosis and recommendations work
28. How do you handle a scenario where statistics keep changing?
29. Design an index strategy for a table with multiple query patterns
30. How would you troubleshoot a query that runs fine in dev but slow in prod?
31. Design a bulk deletion strategy for 10M records in production
32. Explain the trade-offs of cursor_sharing modes for different scenarios
33. How do you decide which queries to optimize?
34. Design a comprehensive statistics gathering strategy
35. How do optimizer costs relate to actual execution time?
36. Explain how adaptive plans work at runtime
37. What causes plan instability and how do you resolve it?
38. Design a monitoring and alerting strategy for performance
39. How would you approach tuning a legacy system with no baseline?
40. Explain the cost of bad execution plans in terms of resources
41. How do you measure if your tuning was successful?
42. Design a cursor sharing strategy for highly varied workloads
43. How would you handle the scenario where backup impacts users?
44. Explain why one query optimization didn't improve overall performance
45. What would you do if ADDM gives conflicting recommendations?
46. Design an index rebuild strategy for large tables
47. How do you handle memory pressure when tuning?
48. Explain how dynamic sampling improves plan quality
49. What's the relationship between I/O patterns and query performance?
50. How do you balance proactive vs reactive tuning?

---

## 📚 Recommended Study Plan

### 2-Week Intensive (Interview Prep)
- **Days 1-2:** Modules 1, 7 (Optimizer basics, intro)
- **Days 3-4:** Module 9 (ROWID/ROWNUM)
- **Days 5-6:** Modules 2, 3 (Cursor sharing, indexes)
- **Days 7-8:** Modules 4, 5, 6 (Statistics, reports)
- **Days 9-10:** Module 8 (Long transactions)
- **Days 11-14:** Practice interview questions, review weak areas

### 4-Week Comprehensive (Mastery)
- **Week 1:** Fundamentals (Modules 1, 7, 9) + Basic Q&A
- **Week 2:** Reporting tools (Modules 5, 6) + Intermediate Q&A
- **Week 3:** Advanced concepts (Modules 2, 3, 4) + Practice scenarios
- **Week 4:** Integration (Module 8 + real-world problems + Advanced Q&A)

### Daily Study Routine (45 minutes)
```
15 min - Read one module section or concept
15 min - Answer 3-4 interview questions (write out answers)
10 min - Practice SQL commands
5  min - Review flashcards or key points
```

---

## ✅ Key Takeaways from All 9 Modules

### Core Principles
1. **Statistics are foundational** - Stale/bad stats = wrong plans = poor performance
2. **Measure before assuming** - Use AWR/ADDM, don't guess
3. **Systematic approach** - Follow methodology, not random tuning
4. **Understand trade-offs** - No perfect solution, document choices
5. **Performance is iterative** - One fix often reveals next issue

### Critical Topics

**Optimizer Concepts:**
- Generates plans based on statistics
- Evaluates multiple alternatives
- Selects lowest cost plan
- Adaptive features help when stats wrong

**Cursor Sharing & Parsing:**
- Hard parse expensive, soft parse cheap
- Use bind variables to avoid hard parsing
- SIMILAR mode recommended for production
- EXACT mode safe but memory-consuming

**Index & Statistics:**
- Right indexes solve most performance issues
- Keep statistics current and accurate
- Lock statistics if plan is optimal
- Monitor fragmentation and rebuild when needed

**Diagnostic Tools:**
- **AWR:** Store metrics, enable trending
- **ADDM:** Analyze AWR, provide recommendations
- **ASH:** Real-time monitoring, active sessions
- Use together for complete diagnosis

**Performance Tuning:**
- Establish baseline before changes
- Identify bottleneck (CPU/I/O/Memory)
- Implement fix (index/stats/parameter)
- Verify improvement and monitor

### SQL Reference Commands

```sql
-- Check cursor sharing
SHOW PARAMETER cursor_sharing;
ALTER SYSTEM SET cursor_sharing=SIMILAR;

-- Gather statistics
EXEC DBMS_STATS.gather_table_stats('HR', 'EMPLOYEES');

-- Kill session
ALTER SYSTEM KILL SESSION '71,12345' IMMEDIATE;

-- Find long operations
SELECT * FROM gv$session_longops WHERE status='EXECUTING';

-- Check active sessions
SELECT * FROM v$session WHERE status='ACTIVE';

-- Rebuild index
ALTER INDEX idx_name REBUILD ONLINE;

-- Explain plan
EXPLAIN PLAN FOR SELECT ...;
SELECT * FROM TABLE(DBMS_XPLAN.display);

-- Generate AWR report
@$ORACLE_HOME/rdbms/admin/awrrpt.sql
```

---

## 🎓 What Makes an Excellent Answer

### Formula for Interview Success

1. **Brief Definition** (1-2 sentences)
2. **Key Points** (3-4 main concepts)
3. **Real Example** (practical scenario)
4. **Trade-offs** (pros and cons)
5. **When to Use** (context and applicability)

### Example: "What is ROWID?"

**Poor Answer:**
"It's a special column that identifies rows."

**Good Answer:**
"ROWID is a pseudo-column providing the unique physical address of each row. It's the fastest way to access a specific row because it goes directly to the block location without searching. Example: WHERE ROWID='AAAAC3.AAA.AAAAAAA=' retrieves row instantly. Trade-off: You need to know the ROWID first. Use when deleting duplicates or bulk operations where you have the ROWID."

**Excellent Answer:**
[Same as good + adds relevant context about performance impact, comparison to alternatives]

---

**Study Guide Complete!**  
*This material covers all 9 transcripts comprehensively with real content, key concepts, practical examples, and 50+ interview questions.*

Good luck with your Oracle Performance Tuning preparation! 🚀
