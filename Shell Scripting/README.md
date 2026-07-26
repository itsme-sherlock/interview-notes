# Shell Scripting Learning Repository

<!-- QUICK_SHEET_START -->

## Quick Sheet
- Focus: shell scripting for database workflows (SQL/PLSQL automation).
- Study order: Shell basics -> automation tasks -> interview checklist.
- High-yield interview topics: input validation, exit codes, logging, idempotent scripts.
- Production rule: validate first, log everything, fail fast on errors.

<!-- QUICK_SHEET_END -->

## Table of Contents
- [Overview](#overview)
- [Learning Roadmap](#learning-roadmap)
- [Folder Guide](#folder-guide)
- [Recommended Study Order](#recommended-study-order)
- [Revision Strategy](#revision-strategy)
- [Interview Preparation Order](#interview-preparation-order)

## Overview
This section focuses on practical shell scripting patterns used to orchestrate SQL and PL/SQL tasks.

## Learning Roadmap
1. Shell syntax, variables, arguments, and control flow.
2. File checks, permissions, and safe command execution.
3. Production-style automation tasks around data movement and SQL execution.

## Folder Guide
- [02 Shell Basics](02%20Shell%20Basics): Core shell scripting concepts.
- [11 Automation](11%20Automation): Interview-ready production task templates.
- [12 Interview](12%20Interview): Checklist-driven interview preparation.
- [Practice Examples](Practice%20Examples): Minimal runnable scripts.

## Recommended Study Order
1. [Shell Scripting Basics](02%20Shell%20Basics/01_Shell_Scripting_Basics.md)
2. [Production Tasks Simple](11%20Automation/01_Production_Tasks_Simple.md)
3. [Shell Scripting Checklist](12%20Interview/01_Shell_Scripting_Checklist.md)
4. [Hello Script](Practice%20Examples/01_hello.sh)

## Revision Strategy
- Practice one script daily with validation + logging.
- Refactor one script weekly to improve error handling and readability.
- Simulate interview prompts: "automate export", "validate file", "run SQL with logs".

## Interview Preparation Order
1. Script structure, permissions, and arguments.
2. Conditionals, loops, and file test operators.
3. SQLPlus integration and error logging patterns.
4. Operational reliability patterns (retry, backup, safe exits).
