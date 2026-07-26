-- Oracle SQL Pseudocolumn Practice Examples
-- Category: Practice Examples

-- 1) ROWNUM: top-N rows (before ORDER BY unless wrapped)
SELECT *
FROM (
  SELECT employee_id, first_name, salary
  FROM hr.employees
  ORDER BY salary DESC
)
WHERE ROWNUM <= 5;

-- 2) ROWID: fetch row by physical locator (diagnostic/admin usage)
SELECT ROWID, employee_id, first_name
FROM hr.employees
WHERE employee_id = 100;

-- 3) USER and UID: current session identity
SELECT USER AS current_user, UID AS current_uid
FROM dual;

-- 4) SYSDATE and SYSTIMESTAMP
SELECT SYSDATE AS server_date, SYSTIMESTAMP AS server_timestamp
FROM dual;

-- 5) LEVEL with hierarchical query
SELECT employee_id,
       manager_id,
       LEVEL AS hierarchy_level
FROM hr.employees
START WITH manager_id IS NULL
CONNECT BY PRIOR employee_id = manager_id;
