# PL/SQL Packages Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Package** = A named container that groups related PL/SQL types, variables, procedures, and functions.
- **Specification** = The public API callers can use.
- **Body** = The implementation and private members.
- **Package state** = Package variables that live for a database session.
- **Initialization section** = Code that runs once when the package is first referenced in a session.
- **Overloading** = Multiple public routines with the same name but different signatures.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Packages?](#1-why-do-we-need-packages)
2. [What Is a Package?](#2-what-is-a-package)
3. [Specification and Body](#3-specification-and-body)
4. [Public and Private Members](#4-public-and-private-members)
5. [Package State and Initialization](#5-package-state-and-initialization)
6. [Comparison Matrix](#6-comparison-matrix)
7. [Best Practices](#7-best-practices)
8. [Common Mistakes](#8-common-mistakes)
9. [Interview Q&A](#9-interview-qa)
10. [Revision Summary](#10-revision-summary)

---

## 1. Why Do We Need Packages?

Scattering dozens of related procedures across a schema makes APIs hard to discover and dependencies hard to manage. A package gives callers one stable entry point.

```sql
BEGIN
  employee_api.hire_employee(101, 'Asha', 10);
END;
/
```

Packages improve organization, encapsulation, overloading, and deployment of related code.

---

## 2. What Is a Package?

A **package** is a two-part stored program unit: a specification and a body. The specification is the contract; the body contains the implementation.

Think of a package as a service counter: customers see the menu, while the kitchen remains private.

### Types of Members

| Member | Public when declared in | Typical use |
| --- | --- | --- |
| Procedure/function | Specification | Caller-facing operation |
| Type/constant | Specification | Shared API definition |
| Helper routine | Body only | Private implementation |
| Variable | Specification or body | State or internal data |

---

## 3. Specification and Body

```sql
CREATE OR REPLACE PACKAGE employee_api AS
  PROCEDURE hire_employee(p_id NUMBER, p_name VARCHAR2, p_dept NUMBER);
  FUNCTION employee_exists(p_id NUMBER) RETURN BOOLEAN;
END employee_api;
/

CREATE OR REPLACE PACKAGE BODY employee_api AS
  PROCEDURE hire_employee(p_id NUMBER, p_name VARCHAR2, p_dept NUMBER) IS
  BEGIN
    INSERT INTO employees(employee_id, first_name, department_id)
    VALUES (p_id, p_name, p_dept);
  END;

  FUNCTION employee_exists(p_id NUMBER) RETURN BOOLEAN IS
    v_count PLS_INTEGER;
  BEGIN
    SELECT COUNT(*) INTO v_count FROM employees WHERE employee_id = p_id;
    RETURN v_count = 1;
  END;
END employee_api;
/
```

The specification can compile before the body, allowing mutually dependent declarations and stable caller contracts.

---

## 4. Public and Private Members

Anything declared only in the body is private. Private helpers reduce the public surface and allow implementation changes without breaking callers.

```sql
CREATE OR REPLACE PACKAGE BODY employee_api AS
  FUNCTION valid_department(p_dept NUMBER) RETURN BOOLEAN IS
  BEGIN
    RETURN p_dept IS NOT NULL;
  END;
  -- Public routines call valid_department internally.
END employee_api;
/
```

Package types and constants in the specification can be shared by callers. Keep implementation details in the body whenever possible.

---

## 5. Package State and Initialization

Package variables persist for the life of a session, not globally across all sessions.

```sql
CREATE OR REPLACE PACKAGE session_context AS
  g_user_name VARCHAR2(128);
  PROCEDURE initialize(p_user_name VARCHAR2);
END session_context;
/

CREATE OR REPLACE PACKAGE BODY session_context AS
  PROCEDURE initialize(p_user_name VARCHAR2) IS
  BEGIN
    g_user_name := p_user_name;
  END;
BEGIN
  g_user_name := USER;
END session_context;
/
```

The body initialization block runs when the package is first referenced in a session. State can surprise connection pools because a reused session may retain old values.

---

## 6. Comparison Matrix

| Aspect | Package specification | Package body | Standalone routine |
| --- | --- | --- | --- |
| Visibility | Public | Private plus implementations | Public object |
| Main role | Contract | Code and state | One routine |
| Change impact | API changes affect callers | Internal changes usually do not | Object-specific |
| Best for | Stable module interface | Encapsulation | Small isolated operation |

---

## 7. Best Practices

1. Keep the specification small and intentional.
2. Put helper routines, cursors, and variables in the body.
3. Use package constants for shared business values.
4. Document package state and reset it when sessions are reused.
5. Compile specification and body together during deployment.
6. Avoid using package variables as hidden communication between unrelated calls.

---

## 8. Common Mistakes

- Declaring every helper public, which creates unnecessary coupling.
- Assuming package variables are shared across sessions.
- Forgetting that changing a specification invalidates dependent objects.
- Calling stateful package code from pooled sessions without initialization.
- Creating circular package dependencies without a clear design.

---

## 9. Interview Q&A

**Q: What is the difference between a package specification and body?**

A: The specification declares public members; the body implements them and contains private members.

**Q: When does package initialization run?**

A: Once per session, the first time the package is referenced in that session.

**Q: Why use packages instead of standalone procedures?**

A: Packages group related behavior, hide implementation details, support shared types/state, and provide a stable API.

**Q: Are package variables global?**

A: They are session-persistent, not database-global. Each session has its own package state.

---

## 10. Revision Summary

- **Specification** -> public contract
- **Body** -> implementation and private members
- **Package state** -> session-specific variables
- **Initialization block** -> runs on first reference per session
- **Dependency invalidation** -> changes can require recompilation

```sql
CREATE OR REPLACE PACKAGE p AS
  PROCEDURE run;
END p;
/
CREATE OR REPLACE PACKAGE BODY p AS
  PROCEDURE run IS BEGIN NULL; END;
END p;
/
```
