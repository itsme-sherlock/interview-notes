# Oracle PL/SQL Triggers Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Trigger** = Stored code that runs automatically when a database event occurs.
- **Row-level trigger** = Runs once for each affected row and can use `:OLD` and `:NEW`.
- **Statement-level trigger** = Runs once for the whole statement.
- **Compound trigger** = One trigger with timing sections that share state.
- **`INSTEAD OF` trigger** = Makes complex views writable.
- **Mutating-table error** = A row trigger tries to read the table currently being changed.
- **Design rule:** Use constraints and explicit APIs before adding hidden trigger behavior.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Triggers?](#1-why-do-we-need-triggers)
2. [What Is a Trigger?](#2-what-is-a-trigger)
3. [Timing and Granularity](#3-timing-and-granularity)
4. [OLD, NEW, and Compound Triggers](#4-old-new-and-compound-triggers)
5. [View Triggers and Mutating Tables](#5-view-triggers-and-mutating-tables)
6. [Comparison Matrix](#6-comparison-matrix)
7. [Best Practices](#7-best-practices)
8. [Common Mistakes](#8-common-mistakes)
9. [Interview Q&A](#9-interview-qa)
10. [Revision Summary](#10-revision-summary)

---

## 1. Why Do We Need Triggers?

Some rules must apply regardless of which application changes a table. Triggers can audit changes, derive values, or make views writable. Their automatic nature also makes them easy to hide and misuse.

---

## 2. What Is a Trigger?

A trigger is a stored PL/SQL unit attached to an event such as `INSERT`, `UPDATE`, `DELETE`, DDL, or a database logon.

```sql
CREATE OR REPLACE TRIGGER employees_audit_trg
AFTER UPDATE OF salary ON employees
FOR EACH ROW
BEGIN
  INSERT INTO salary_audit(employee_id, old_salary, new_salary, changed_by)
  VALUES (:OLD.employee_id, :OLD.salary, :NEW.salary, USER);
END;
/
```

The triggering statement invokes it; callers do not call it directly.

---

## 3. Timing and Granularity

| Choice | Meaning |
| --- | --- |
| `BEFORE` | Run before the event; useful for validation or derived values |
| `AFTER` | Run after the row or statement succeeds |
| `FOR EACH ROW` | One execution per row |
| No row clause | One execution per statement |
| `INSTEAD OF` | Replace a view DML event |

Use `INSERTING`, `UPDATING`, and `DELETING` to branch by event.

---

## 4. OLD, NEW, and Compound Triggers

`:OLD` contains the previous value and `:NEW` contains the incoming value. `:NEW` can be assigned in a `BEFORE` row trigger; `:OLD` is read-only.

A compound trigger can collect row data and perform one statement-level action after the statement finishes, reducing mutating-table problems and repeated work.

```sql
CREATE OR REPLACE TRIGGER employees_set_date
BEFORE INSERT OR UPDATE ON employees
FOR EACH ROW
BEGIN
  :NEW.last_changed := SYSTIMESTAMP;
END;
/
```

---

## 5. View Triggers and Mutating Tables

An `INSTEAD OF` trigger translates DML against a complex view into DML against base tables.

A mutating-table error occurs when a row trigger queries the table being modified. Common solutions are a compound trigger, statement-level processing, or moving the rule into an explicit procedure.

---

## 6. Comparison Matrix

| Mechanism | Automatic | Visibility | Best use |
| --- | --- | --- | --- |
| Constraint | Yes | Explicit metadata | Declarative data rule |
| Trigger | Yes | Hidden from caller | Auditing or cross-cutting event |
| Procedure | No | Explicit API call | Business workflow |
| Application logic | No | Application-specific | User experience |

---

## 7. Best Practices

1. Prefer constraints for uniqueness, referential integrity, and simple checks.
2. Keep triggers short and deterministic.
3. Document firing order and side effects.
4. Use compound triggers for statement-wide coordination.
5. Avoid network calls, commits, and surprise DML in row triggers.
6. Disable or replace triggers through controlled deployment only.

---

## 8. Common Mistakes

- Querying the mutating table from a row trigger.
- Assuming trigger order without explicitly controlling it.
- Auditing with a trigger but forgetting transaction rollback behavior.
- Creating recursive trigger chains.
- Hiding core business workflows in automatic code.

---

## 9. Interview Q&A

**Q: Row-level versus statement-level trigger?**

A: A row trigger runs once per affected row and can access `:OLD` and `:NEW`; a statement trigger runs once per DML statement.

**Q: What causes a mutating-table error?**

A: A row trigger reads or modifies the table that is currently being changed by the triggering statement.

**Q: When use an `INSTEAD OF` trigger?**

A: To translate DML against a complex or non-updatable view into base-table operations.

**Q: Should every validation be a trigger?**

A: No. Use constraints for declarative rules and explicit procedures for visible business workflows.

---

## 10. Revision Summary

- **Timing** -> `BEFORE`, `AFTER`, `INSTEAD OF`
- **Granularity** -> row or statement
- **`:OLD/:NEW`** -> prior and incoming row values
- **Compound trigger** -> shared state across timing points
- **Mutating table** -> row trigger reads current table

```sql
IF UPDATING('SALARY') AND :NEW.salary < :OLD.salary THEN
  RAISE_APPLICATION_ERROR(-20020, 'Salary cannot decrease');
END IF;
```
