# SQL Learning Repository

<!-- QUICK_SHEET_START -->

## Quick Sheet
- Focus: Oracle SQL for interviews and practical database work.
- Study order: Fundamentals -> Functions -> Views -> Indexes -> Performance -> Interview revision.
- High-yield interview topics: indexing strategy, view updatability, window functions, partition pruning.
- Daily revision: one topic note + one cheat sheet + two query drills.

<!-- QUICK_SHEET_END -->

## Table of Contents
- [Overview](#overview)
- [Learning Roadmap](#learning-roadmap)
- [Folder Guide](#folder-guide)
- [Recommended Study Order](#recommended-study-order)
- [Revision Strategy](#revision-strategy)
- [Interview Preparation Order](#interview-preparation-order)

## Overview
This section contains structured Oracle SQL study notes organized for progressive learning and interview preparation.

## Learning Roadmap
1. Core syntax and pseudocolumn behavior.
2. Single-row functions for transformation logic.
3. Views and materialized views for abstraction and performance.
4. Index internals and optimizer behavior.
5. Analytic/window functions and partitioning strategy.

## Folder Guide
- [01 Fundamentals](01%20Fundamentals): Foundation scripts and essential behavior.
- [04 Functions](04%20Functions): Character, numeric, date, conversion, and null functions.
- [07 Views](07%20Views): Views and materialized views.
- [08 Indexes](08%20Indexes): Index types, scans, and execution plan basics.
- [09 Performance](09%20Performance): Analytics and partitioning.
- [Cheat Sheets](Cheat%20Sheets): Fast revision docs.
- [11 Interview](11%20Interview): Reserved for interview-only notes.

## Recommended Study Order
1. [Pseudo Columns Guide](01%20Fundamentals/01_Pseudo_Columns_Guide.sql)
2. [Single Row Functions](04%20Functions/01_Single_Row_Functions.md)
3. [Views and Materialized Views](07%20Views/01_Views_and_Materialized_Views.md)
4. [Indexes and Execution Plans](08%20Indexes/01_Indexes_and_Execution_Plans.md)
5. [Window Functions and Analytics](09%20Performance/01_Window_Functions_and_Analytics.md)
6. [Table Partitioning](09%20Performance/02_Table_Partitioning.md)
7. [SQL Quick Revision](Cheat%20Sheets/01_SQL_Quick_Revision.md)

## Revision Strategy
- Weekday: 30 minutes concept reading + 20 minutes query practice.
- Weekend: one end-to-end mini case combining indexing + analytics + views.
- Before interview: revise all quick sheets and explain each topic aloud in 60 seconds.

## Interview Preparation Order
1. SQL functions and null handling edge cases.
2. Views vs materialized views (trade-offs and DML behavior).
3. Index usage conditions and optimizer choices.
4. Window functions for top-N, ranking, and running totals.
5. Partitioning and partition pruning with large tables.
