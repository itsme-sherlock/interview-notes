# PL/SQL Security, Oracle Features, and Operations Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Definer rights** = Code runs with the privileges of its owner.
- **Invoker rights** = Code runs with the privileges of the caller.
- **`AUTHID`** = Declares the privilege model for stored PL/SQL.
- **`UTL_FILE`** = Reads and writes files available to the database server.
- **`DBMS_SCHEDULER`** = Runs PL/SQL and other jobs on a schedule.
- **Least privilege** = Grant only the objects and operations the code needs.
- **Operational rule:** Treat external calls, files, jobs, and credentials as production boundaries.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Secure PL/SQL Operations?](#1-why-do-we-need-secure-plsql-operations)
2. [What Are the Main Security Models?](#2-what-are-the-main-security-models)
3. [Definer and Invoker Rights](#3-definer-and-invoker-rights)
4. [Files, Jobs, and External Services](#4-files-jobs-and-external-services)
5. [Oracle-Specific Pragmas and Features](#5-oracle-specific-pragmas-and-features)
6. [Comparison Matrix](#6-comparison-matrix)
7. [Best Practices](#7-best-practices)
8. [Common Mistakes](#8-common-mistakes)
9. [Interview Q&A](#9-interview-qa)
10. [Revision Summary](#10-revision-summary)

---

## 1. Why Do We Need Secure PL/SQL Operations?

Stored code may access tables, files, network services, and scheduled jobs. A routine that works technically can still violate privilege boundaries or expose sensitive data.

---

## 2. What Are the Main Security Models?

PL/SQL security has two layers: database privileges and the execution identity of stored code. External APIs add directory, network ACL, credential, and operating-system controls.

---

## 3. Definer and Invoker Rights

```sql
CREATE OR REPLACE PROCEDURE read_employee(p_id NUMBER)
AUTHID DEFINER
AS
BEGIN
  SELECT employee_id INTO ... FROM employees WHERE employee_id = p_id;
END;
/
```

`AUTHID DEFINER` is the default and uses owner privileges for object access. `AUTHID CURRENT_USER` uses the caller's privileges and is useful for generic utilities that should respect caller access.

Grant direct object privileges to the owner where required; privileges inherited through roles may not be available to definer-rights stored code.

---

## 4. Files, Jobs, and External Services

`UTL_FILE` works with database DIRECTORY objects and server-side paths, not arbitrary client paths. Validate filenames, restrict directories, and handle file exceptions.

`DBMS_SCHEDULER` defines programs, schedules, jobs, arguments, enabled state, and logging.

```sql
BEGIN
  DBMS_SCHEDULER.CREATE_JOB(
    job_name   => 'daily_employee_job',
    job_type   => 'PLSQL_BLOCK',
    job_action => 'BEGIN employee_batch.run; END;',
    start_date => SYSTIMESTAMP,
    repeat_interval => 'FREQ=DAILY',
    enabled => TRUE);
END;
/
```

`UTL_HTTP`, `UTL_SMTP`, and similar APIs require network controls and careful timeout and error handling.

---

## 5. Oracle-Specific Pragmas and Features

- `PRAGMA AUTONOMOUS_TRANSACTION` creates an independent transaction.
- `PRAGMA SERIALLY_REUSABLE` reduces persistent package state for suitable pooled workloads.
- `PRAGMA INLINE` can influence inlining of eligible calls.
- `NOCOPY` can reduce parameter copying but changes failure semantics.
- Object types provide data and methods; use them only when object modeling is justified.
- Pipelined table functions stream rows to SQL callers.
- JSON and XML APIs process document data, but validate size and structure.

These features should be introduced after measuring a real need; each adds operational or correctness constraints.

---

## 6. Comparison Matrix

| Model or API | Main capability | Key concern |
| --- | --- | --- |
| Definer rights | Owner-controlled access | Privilege escalation if exposed carelessly |
| Invoker rights | Caller-controlled access | Caller needs required privileges |
| `UTL_FILE` | Server file access | Directory and sensitive-file exposure |
| Scheduler | Automated execution | Duplicate, failed, or overlapping jobs |
| `UTL_HTTP` | Network calls | ACLs, timeouts, and secrets |

---

## 7. Best Practices

1. Use least privilege and direct grants for stored-code dependencies.
2. Choose `AUTHID` deliberately and document it.
3. Restrict DIRECTORY objects and network ACLs.
4. Store secrets in approved credential mechanisms, never source code.
5. Make scheduled jobs idempotent and observable.
6. Set timeouts and retry policies for external calls.

---

## 8. Common Mistakes

- Assuming a definer-rights routine can use privileges granted only through a role.
- Allowing arbitrary filenames or URLs from input.
- Scheduling a job without overlap, retry, and failure policy.
- Treating autonomous transactions as a way to bypass data design.
- Leaving package state in a pooled session without reset logic.

---

## 9. Interview Q&A

**Q: Definer rights versus invoker rights?**

A: Definer rights use the owner's privileges; invoker rights use the current caller's privileges.

**Q: Why are direct grants important for stored code?**

A: Roles may not be enabled during stored-code privilege resolution, so dependencies should be granted directly where required.

**Q: What does `UTL_FILE` access?**

A: Files on the database server through approved DIRECTORY objects, not arbitrary client machine paths.

**Q: What makes a scheduled PL/SQL job production-ready?**

A: Idempotency, logging, failure handling, controlled overlap, clear privileges, and an operational owner.

---

## 10. Revision Summary

- **Definer rights** -> owner privileges
- **Invoker rights** -> caller privileges
- **Least privilege** -> minimum access
- **`UTL_FILE`** -> controlled server file access
- **`DBMS_SCHEDULER`** -> managed recurring jobs
- **External API** -> timeout, ACL, and secret boundary

```sql
CREATE OR REPLACE PROCEDURE utility AUTHID CURRENT_USER AS
BEGIN
  NULL;
END;
/
```
