--pseudo columns
--definition: Pseudo columns are special columns that behave like regular columns but do not exist in the table. They provide additional information about the rows in a table or the current session.
--all example in sinlge query
SELECT ROWNUM AS row_number,
       SYSDATE AS current_date,
       USER AS current_user,       
       ROWID AS row_identifier,
       systimestamp AS current_timestamp,
       uid  
FROM hr.employees;

--difference between rownum and row_number()
ROWNUM is a pseudo column that assigns a unique number to each row returned by a query, starting from 1 for the first row. It is assigned before any sorting or filtering is applied to the result set. ROWNUM is often used for limiting the number of rows returned by a query.

ROW_NUMBER() is an analytic function that assigns a unique number to each row within a result set, based on the specified ORDER BY clause. It is calculated after sorting and can be used for more complex ranking and pagination scenarios.

select rownum,first_name,salary from hr.employees where rownum <= 5 order by salary desc;

2.systimestamp: Returns the current date and time, including fractional seconds and time zone information. It is similar to SYSDATE but provides more precision.

3. USER: Returns the name of the current database user. It is useful for identifying  the user executing a query or for implementing security measures based on user roles.

4.ROWID: Returns the unique identifier for a row in a table. It can be used to quickly access and manipulate specific rows, especially in scenarios where the primary key is not available.
--can rowid changes dml and ddl operatiom
it can change under certain circumstances. 
DML operations like INSERT, UPDATE, and DELETE do not change the ROWID of existing rows. 
DDL operations such as TRUNCATE TABLE or ALTER TABLE can cause the ROWIDs to change because they may reorganize the storage of the table. 
if a row is deleted and then reinserted, it will receive a new ROWID.

--purpose of rowid
1. Fast Access: ROWID provides a direct pointer to the physical location of a row in the database, allowing for quick retrieval of data.
2. Uniqueness: Each ROWID is unique within a table, making it a reliable identifier for rows, especially when primary keys are not available.

5.uid: Returns the unique identifier for the current session. It can be used to track and manage user sessions, especially in multi-user environments.

6.level
--simple defintion: LEVEL is a pseudo column used in hierarchical queries to indicate the level of a node in a tree structure. It is often used with the CONNECT BY clause to traverse hierarchical data, such as organizational charts or bill of materials.
--example:
SELECT employee_id,
       first_name,
       last_name,
       LEVEL AS hierarchy_level
FROM hr.employees
CONNECT BY PRIOR employee_id = manager_id
START WITH employee_id = 100;

--simple example for level;






