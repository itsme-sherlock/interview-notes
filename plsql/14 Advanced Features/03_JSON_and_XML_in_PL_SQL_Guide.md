# JSON and XML Processing in PL/SQL Guide

<!-- QUICK_SHEET_START -->

## Quick Sheet

- **JSON** = Lightweight key-value and array document format.
- **XML** = Structured markup format suited to hierarchical and document exchange.
- **`JSON_OBJECT_T`** = PL/SQL object API for JSON values.
- **`JSON_TABLE`** = Projects JSON fields into relational rows and columns.
- **`XMLTABLE`** = Projects XML nodes into relational rows and columns.
- **Validation rule:** Check document structure, size, and required fields before processing.

<!-- QUICK_SHEET_END -->

## Table of Contents

1. [Why Do We Need Document Processing?](#1-why-do-we-need-document-processing)
2. [What Are JSON and XML APIs?](#2-what-are-json-and-xml-apis)
3. [JSON in PL/SQL](#3-json-in-plsql)
4. [XML in PL/SQL](#4-xml-in-plsql)
5. [Relational Projection and Validation](#5-relational-projection-and-validation)
6. [Comparison Matrix](#6-comparison-matrix)
7. [Best Practices](#7-best-practices)
8. [Common Mistakes](#8-common-mistakes)
9. [Interview Q&A](#9-interview-qa)
10. [Revision Summary](#10-revision-summary)

---

## 1. Why Do We Need Document Processing?

Applications often receive flexible payloads from APIs or external systems. PL/SQL must extract values, validate required fields, and persist trustworthy relational data.

---

## 2. What Are JSON and XML APIs?

JSON and XML APIs parse documents and expose their fields to SQL or PL/SQL. Use JSON for common web payloads and XML when namespaces, schemas, or legacy integrations require it.

---

## 3. JSON in PL/SQL

```sql
DECLARE
  v_doc JSON_OBJECT_T;
BEGIN
  v_doc := JSON_OBJECT_T.parse('{"employee_id":100,"active":true}');
  DBMS_OUTPUT.PUT_LINE(v_doc.get_NUMBER('employee_id'));
END;
/
```

SQL can project JSON into rows:

```sql
SELECT employee_id, active
FROM JSON_TABLE(
  '{"employee_id":100,"active":true}', '$'
  COLUMNS (
    employee_id NUMBER PATH '$.employee_id',
    active     VARCHAR2(5) PATH '$.active'
  )
);
```

---

## 4. XML in PL/SQL

`XMLTYPE`, XPath, `XMLTABLE`, and XML query functions process hierarchical documents.

```sql
SELECT employee_name
FROM XMLTABLE(
  '/employee'
  PASSING XMLTYPE('<employee><name>Asha</name></employee>')
  COLUMNS employee_name VARCHAR2(100) PATH 'name'
);
```

Namespaces and malformed documents must be handled explicitly.

---

## 5. Relational Projection and Validation

Validate document length, required keys, data types, allowed values, and duplicate identifiers before DML. Use schema constraints after projection so document flexibility does not weaken relational integrity.

---

## 6. Comparison Matrix

| Aspect | JSON | XML | Relational columns |
| --- | --- | --- | --- |
| Typical use | Web/API payloads | Document/legacy integration | Stable queryable data |
| Shape | Flexible | Hierarchical and namespace-aware | Fixed schema |
| Query method | JSON functions | XML functions | SQL directly |
| Main concern | Missing or wrong types | Namespaces and verbosity | Migration rigidity |

---

## 7. Best Practices

1. Validate payloads before changing business tables.
2. Project only required fields.
3. Keep document size limits explicit.
4. Preserve raw payloads only when retention and privacy allow it.
5. Index commonly queried document paths deliberately.

---

## 8. Common Mistakes

- Assuming a missing JSON key is the same as a valid null.
- Ignoring XML namespaces.
- Storing every payload as a document when relational columns are stable.
- Concatenating untrusted document fragments into dynamic SQL.
- Skipping size and schema validation.

---

## 9. Interview Q&A

**Q: What does `JSON_TABLE` do?**

A: It converts JSON document fields into relational rows and columns that SQL can query.

**Q: When is XML preferable to JSON?**

A: When the integration requires XML schemas, namespaces, mixed document structure, or established XML tooling.

**Q: How should document data be secured?**

A: Validate structure and size, restrict access, avoid logging sensitive payloads, and apply normal table constraints after projection.

---

## 10. Revision Summary

- **`JSON_OBJECT_T`** -> PL/SQL JSON object API
- **`JSON_TABLE`** -> JSON-to-rows projection
- **`XMLTYPE`** -> Oracle XML value type
- **`XMLTABLE`** -> XML-to-rows projection
- **Validation** -> required before DML

```sql
SELECT * FROM JSON_TABLE(:payload, '$.items[*]'
  COLUMNS (item_id NUMBER PATH '$.id'));
```
