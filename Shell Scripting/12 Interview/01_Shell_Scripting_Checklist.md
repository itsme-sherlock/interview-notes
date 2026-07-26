# Shell Scripting Interview Checklist

<!-- QUICK_SHEET_START -->

## Quick Sheet
- Know script structure, permissions, args, and exit codes.
- Be ready with file validation, logging, and SQLPlus integration patterns.
- Practice one mini automation flow end-to-end.
- Explain reliability choices: quoting, checks, non-zero exits.

<!-- QUICK_SHEET_END -->

## Table of Contents
- [Main Content](#main-content)
- [Module Checklist](#module-checklist)
- [Interview Practice Tasks](#interview-practice-tasks)
- [High-Value Questions](#high-value-questions)
- [Related Notes](#related-notes)

## Main Content

## Module Checklist
- [x] Shebang and execution permissions.
- [x] Variables and positional parameters.
- [x] `if`/`elif`/`else`, `case`, loops.
- [x] File test operators.
- [x] SQLPlus command execution from shell.
- [x] Logging with `>`, `>>`, and `2>&1`.
- [ ] Function-based script organization for larger scripts.
- [ ] Defensive options (`set -e`, `set -u`) with safe usage.

## Interview Practice Tasks
1. Build a script that validates a CSV and logs result.
2. Execute a SQL file and return clear success/failure status.
3. Export query output daily with timestamped filenames.
4. Compare pre and post data snapshots with row-count summary.

## High-Value Questions
- What is the difference between `$@` and `$*`?
- Why should shell scripts check `$?` or exit codes?
- How do you prevent failures from bad filenames with spaces?
- How do you make a script safe for cron execution?

## Related Notes
- Script fundamentals: [Shell Scripting Basics](../02%20Shell%20Basics/01_Shell_Scripting_Basics.md)
- Automation patterns: [Production Tasks Simple](../11%20Automation/01_Production_Tasks_Simple.md)
- Quick revision: [Shell Scripting Quick Revision](../Cheat%20Sheets/01_Shell_Scripting_Quick_Revision.md)
