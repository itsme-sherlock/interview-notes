-- PL/SQL Basics Block Examples
-- Category: Practice Examples

-- Example 1: Basic block with variable declaration and output
DECLARE
  v_name  VARCHAR2(50) := 'Oracle';
  v_year  NUMBER := 2026;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Platform: ' || v_name || ', Year: ' || v_year);
END;
/

-- Example 2: SELECT INTO with exception handling
DECLARE
  v_first_name hr.employees.first_name%TYPE;
BEGIN
  SELECT first_name
  INTO v_first_name
  FROM hr.employees
  WHERE employee_id = 100;

  DBMS_OUTPUT.PUT_LINE('Employee: ' || v_first_name);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('No matching employee');
  WHEN TOO_MANY_ROWS THEN
    DBMS_OUTPUT.PUT_LINE('Query returned multiple rows');
END;
/

-- Example 3: Anchored declaration and simple IF
DECLARE
  v_salary hr.employees.salary%TYPE;
BEGIN
  SELECT salary INTO v_salary
  FROM hr.employees
  WHERE employee_id = 100;

  IF v_salary > 10000 THEN
    DBMS_OUTPUT.PUT_LINE('High salary');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Standard salary');
  END IF;
END;
/
