# PL/SQL Server File and Network APIs Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **`UTL_FILE`** = Reads and writes approved files on the database server.
- **Directory object** = Database-controlled mapping to a server directory.
- **`UTL_HTTP`** = Makes HTTP requests from the database when network ACLs allow it.
- **`UTL_SMTP`** = Sends email through an SMTP server.
- **External boundary** = Requires timeouts, credentials, ACLs, and failure handling.
- **Security rule:** Never accept unrestricted paths, URLs, or secrets from callers.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need External APIs?](#1-why-do-we-need-external-apis)
2. [What Are the External APIs?](#2-what-are-the-external-apis)
3. [Server Files with UTL_FILE](#3-server-files-with-utl_file)
4. [HTTP and Email](#4-http-and-email)
5. [Security and Reliability](#5-security-and-reliability)
6. [Comparison Matrix](#6-comparison-matrix)
7. [Best Practices](#7-best-practices)
8. [Common Mistakes](#8-common-mistakes)
9. [Interview Q&A](#9-interview-qa)
10. [Revision Summary](#10-revision-summary)

---

## 1. Why Do We Need External APIs?

Database jobs often exchange files, call services, or send notifications. Doing this in PL/SQL can centralize workflows but also puts network and operating-system concerns inside the database.

---

## 2. What Are the External APIs?

These packages bridge PL/SQL to server resources:

| API | Purpose |
| --- | --- |
| `UTL_FILE` | Server-side file I/O |
| `UTL_HTTP` | HTTP requests |
| `UTL_SMTP` | SMTP email |

They require privileges and configuration outside the procedure itself.

---

## 3. Server Files with UTL_FILE

```sql
DECLARE
  v_file UTL_FILE.FILE_TYPE;
BEGIN
  v_file := UTL_FILE.FOPEN('REPORT_DIR', 'daily.csv', 'W', 32767);
  UTL_FILE.PUT_LINE(v_file, 'employee_id,status');
  UTL_FILE.PUT_LINE(v_file, '100,ACTIVE');
  UTL_FILE.FCLOSE(v_file);
EXCEPTION
  WHEN OTHERS THEN
    IF UTL_FILE.IS_OPEN(v_file) THEN
      UTL_FILE.FCLOSE(v_file);
    END IF;
    RAISE;
END;
/
```

The DIRECTORY object and grants determine where the database can access files. The client machine's filesystem is not the target.

---

## 4. HTTP and Email

`UTL_HTTP` requires network ACLs and should set connection/read timeouts. `UTL_SMTP` requires an allowed SMTP host and a correct protocol sequence. Treat response codes, partial sends, and retries as explicit failure states.

---

## 5. Security and Reliability

Use allow-lists for filenames and endpoints, least-privilege directory and network grants, approved credential storage, bounded payloads, timeouts, and idempotent retry logic. Log correlation IDs and status without recording secrets.

---

## 6. Comparison Matrix

| API | Resource | Main risk | Reliability control |
| --- | --- | --- | --- |
| `UTL_FILE` | Server filesystem | Sensitive file access | Directory allow-list |
| `UTL_HTTP` | Network service | SSRF and timeout | ACL, URL allow-list, timeout |
| `UTL_SMTP` | Mail server | Spam or data leak | Approved relay and content policy |

---

## 7. Best Practices

1. Configure DIRECTORY objects and ACLs centrally.
2. Close files in both success and failure paths.
3. Set network timeouts explicitly.
4. Make retries safe and bounded.
5. Keep secrets out of source code and logs.

---

## 8. Common Mistakes

- Passing an arbitrary OS path to `UTL_FILE`.
- Assuming a database server can access the developer's laptop files.
- Calling URLs supplied directly by users.
- Leaving a file handle open after an exception.
- Retrying non-idempotent requests without a request key.

---

## 9. Interview Q&A

**Q: Where does `UTL_FILE` read and write?**

A: On the database server through an approved DIRECTORY object.

**Q: What does `UTL_HTTP` need besides PL/SQL code?**

A: Network ACL permissions, endpoint validation, timeout policy, and appropriate authentication configuration.

**Q: How should external failures be handled?**

A: Apply timeouts, classify response failures, log correlation data, retry only safe operations, and expose failure to the owning workflow.

---

## 10. Revision Summary

- **`UTL_FILE`** -> approved server file I/O
- **DIRECTORY** -> controlled filesystem mapping
- **`UTL_HTTP`** -> HTTP integration
- **`UTL_SMTP`** -> email integration
- **ACL** -> network access control
- **Timeout** -> bounded external wait

```sql
v_file := UTL_FILE.FOPEN('REPORT_DIR', 'report.csv', 'W');
```
