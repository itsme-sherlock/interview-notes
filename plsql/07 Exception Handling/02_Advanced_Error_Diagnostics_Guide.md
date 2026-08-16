# Advanced PL/SQL Error Handling and Diagnostics Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **`SQLCODE`** = Numeric code for the current exception.
- **`SQLERRM`** = Message for the current exception.
- **`FORMAT_ERROR_STACK`** = Full nested error stack.
- **`FORMAT_ERROR_BACKTRACE`** = Source location where the error began.
- **`FORMAT_CALL_STACK`** = Current call path.
- **Error logging** = Persist diagnostics with enough context to investigate and replay.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Better Diagnostics?](#1-why-do-we-need-better-diagnostics)
2. [What Are Diagnostic APIs?](#2-what-are-diagnostic-apis)
3. [Capturing Error Context](#3-capturing-error-context)
4. [Centralized Error Logging](#4-centralized-error-logging)
5. [Bulk and Distributed Errors](#5-bulk-and-distributed-errors)
6. [Comparison Matrix](#6-comparison-matrix)
7. [Best Practices](#7-best-practices)
8. [Common Mistakes](#8-common-mistakes)
9. [Interview Q&A](#9-interview-qa)
10. [Revision Summary](#10-revision-summary)

---

## 1. Why Do We Need Better Diagnostics?

`SQLERRM` alone may say what failed but not where or through which nested calls. Production troubleshooting needs the error stack, backtrace, call path, inputs, and a correlation identifier.

---

## 2. What Are Diagnostic APIs?

Oracle exposes diagnostic information through `SQLCODE`, `SQLERRM`, and `DBMS_UTILITY` formatting functions.

```sql
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_STACK);
    DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_CALL_STACK);
    RAISE;
END;
/
```

---

## 3. Capturing Error Context

Capture the operation name, business key, database user, timestamp, error code, message, stack, and backtrace. Do not log passwords, tokens, or unnecessary personal data.

```sql
INSERT INTO error_log(
  operation_name, business_key, error_code, error_message,
  error_stack, error_backtrace, created_at
) VALUES (
  'employee_hire', TO_CHAR(p_employee_id), SQLCODE, SQLERRM,
  DBMS_UTILITY.FORMAT_ERROR_STACK,
  DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
  SYSTIMESTAMP
);
```

---

## 4. Centralized Error Logging

A shared logger keeps format and retention consistent. It may use an autonomous transaction when logs must survive a caller rollback, but that design must avoid locking parent rows.

The normal handler should log and re-raise unexpected errors:

```sql
EXCEPTION
  WHEN OTHERS THEN
    error_logger.write('employee_hire', SQLCODE, SQLERRM);
    RAISE;
END;
```

---

## 5. Bulk and Distributed Errors

Bulk DML can raise `-24381`; inspect `SQL%BULK_EXCEPTIONS` for failed iteration indexes. Remote calls can add network, database-link, and two-phase transaction errors. Preserve the original error stack instead of replacing it with a generic message.

---

## 6. Comparison Matrix

| API | Tells you | Best use |
| --- | --- | --- |
| `SQLCODE` | Error number | Routing and classification |
| `SQLERRM` | Current message | Short caller message |
| Error stack | Nested messages | Root-cause context |
| Backtrace | Origin location | Source diagnosis |
| Call stack | Invocation path | Workflow diagnosis |

---

## 7. Best Practices

1. Handle expected exceptions specifically.
2. Log unexpected errors once at the correct boundary.
3. Re-raise after logging unless recovery is intentional.
4. Preserve `FORMAT_ERROR_BACKTRACE` before calling another routine.
5. Include correlation and business identifiers.

---

## 8. Common Mistakes

- `WHEN OTHERS THEN NULL`.
- Replacing every error with the same generic message.
- Logging only `SQLERRM` and losing the source location.
- Logging sensitive input values.
- Committing the parent transaction just to save a log.

---

## 9. Interview Q&A

**Q: `SQLERRM` versus `FORMAT_ERROR_BACKTRACE`?**

A: `SQLERRM` describes the error; the backtrace identifies where the error originated.

**Q: Why re-raise after logging?**

A: The caller must know the operation failed so it can roll back, retry, or report failure.

**Q: How should bulk errors be diagnosed?**

A: Inspect `SQL%BULK_EXCEPTIONS`, map each iteration index to its business key, and log the individual cause.

---

## 10. Revision Summary

- **`SQLCODE`** -> numeric error
- **`SQLERRM`** -> current message
- **Error stack** -> nested causes
- **Backtrace** -> origin line
- **Call stack** -> active path
- **Re-raise** -> preserve failure semantics

```sql
WHEN OTHERS THEN
  log_error(SQLCODE, SQLERRM,
            DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
  RAISE;
```
