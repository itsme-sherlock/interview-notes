# PL/SQL Object Types and Methods Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **Object type** = A schema-level type combining attributes and methods.
- **Attribute** = Data stored in an object instance.
- **Member method** = Procedure or function defined for an object.
- **Constructor** = Built-in or custom operation that creates an object instance.
- **Inheritance** = A subtype can extend an object type when the model supports it.
- **Best use:** Model domain values that need both data and behavior, not ordinary relational rows.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Object Types?](#1-why-do-we-need-object-types)
2. [What Is an Object Type?](#2-what-is-an-object-type)
3. [Attributes and Methods](#3-attributes-and-methods)
4. [Object Tables and Collections](#4-object-tables-and-collections)
5. [Inheritance and Design Trade-offs](#5-inheritance-and-design-trade-offs)
6. [Comparison Matrix](#6-comparison-matrix)
7. [Best Practices](#7-best-practices)
8. [Common Mistakes](#8-common-mistakes)
9. [Interview Q&A](#9-interview-qa)
10. [Revision Summary](#10-revision-summary)

---

## 1. Why Do We Need Object Types?

Some domain values have both structured data and behavior. Repeating those calculations in many procedures can scatter business rules.

---

## 2. What Is an Object Type?

An object type is a schema-level definition containing attributes and methods. It provides object-oriented features while remaining usable from Oracle SQL.

```sql
CREATE OR REPLACE TYPE address_t AS OBJECT (
  street VARCHAR2(100),
  city   VARCHAR2(50),
  MEMBER FUNCTION display RETURN VARCHAR2
);
/
```

---

## 3. Attributes and Methods

The method body is implemented separately:

```sql
CREATE OR REPLACE TYPE BODY address_t AS
  MEMBER FUNCTION display RETURN VARCHAR2 IS
  BEGIN
    RETURN street || ', ' || city;
  END;
END;
/

SELECT address_t('1 Main St', 'Pune').display() FROM dual;
```

Methods can be member, static, constructor, or map/order methods depending on the comparison and construction needs.

---

## 4. Object Tables and Collections

Objects can be stored in object tables or used as elements of nested tables and VARRAYs. Relational tables with normal columns are often simpler for reporting, joins, and broad team familiarity.

```sql
CREATE TABLE addresses OF address_t;
INSERT INTO addresses VALUES (address_t('1 Main St', 'Pune'));
```

---

## 5. Inheritance and Design Trade-offs

A `NOT FINAL` object type can support subtypes. Inheritance can model genuine “is-a” relationships, but it adds schema complexity and may complicate SQL access, migrations, and team understanding.

---

## 6. Comparison Matrix

| Model | Strength | Limitation |
| --- | --- | --- |
| Relational table | Simple SQL and reporting | Behavior lives elsewhere |
| Object type | Data plus behavior | More complex schema |
| PL/SQL record | Fast local structure | Not schema-level persistence |
| JSON document | Flexible shape | Weaker relational constraints |

---

## 7. Best Practices

1. Use object types for stable domain concepts with meaningful behavior.
2. Keep methods deterministic when they are used in queries.
3. Design SQL access and indexing before adopting object storage.
4. Avoid inheritance unless the domain relationship is clear.
5. Document constructors, null behavior, and comparison semantics.

---

## 8. Common Mistakes

- Treating object types as a default replacement for relational tables.
- Hiding SQL side effects inside query-facing methods.
- Forgetting that type changes invalidate dependent objects.
- Creating deep inheritance hierarchies for simple data.
- Ignoring how tools and reporting clients consume object columns.

---

## 9. Interview Q&A

**Q: What is an object type?**

A: A schema-level type that groups attributes and methods into one reusable domain definition.

**Q: Object type versus PL/SQL record?**

A: An object type is schema-level and can persist or be used in SQL; a record is normally a PL/SQL-local composite value.

**Q: When should object types be avoided?**

A: When the data is primarily relational, heavily queried by generic tools, or does not benefit from attached behavior.

---

## 10. Revision Summary

- **Attribute** -> object data
- **Member method** -> object behavior
- **Constructor** -> creates an instance
- **Object table** -> stores object instances
- **Subtype** -> specialized object type

```sql
SELECT address_t('1 Main St', 'Pune').display() FROM dual;
```
