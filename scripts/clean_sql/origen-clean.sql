SET SERVEROUTPUT ON
SET VERIFY OFF
SET FEEDBACK OFF
COLUMN APPLICATION_ID FORMAT A10
COLUMN APPLICATION_NAME FORMAT A40

-- Display database details
DECLARE
    v_username VARCHAR2(100);
    v_dbname   VARCHAR2(100);
    v_host     VARCHAR2(100);
    v_instance VARCHAR2(100);
BEGIN
    SELECT USER INTO v_username FROM dual;
    SELECT sys_context('USERENV', 'DB_NAME') INTO v_dbname FROM dual;
    SELECT sys_context('USERENV', 'HOST') INTO v_host FROM dual;
    SELECT sys_context('USERENV', 'INSTANCE_NAME') INTO v_instance FROM dual;

    DBMS_OUTPUT.PUT_LINE('==========================================');
    DBMS_OUTPUT.PUT_LINE('WARNING: You are connected as ' || v_username || ' on ' || v_dbname);
    DBMS_OUTPUT.PUT_LINE('Host: ' || v_host || ' | Instance: ' || v_instance);
    DBMS_OUTPUT.PUT_LINE('This operation will drop ONLY objects related to EBA_DEMO_MERCHANDISE.');
    DBMS_OUTPUT.PUT_LINE('==========================================');
END;
/

-- Explicit confirmation before proceeding
ACCEPT response CHAR PROMPT 'Do you want to continue? (Y/N): '

BEGIN
    IF UPPER(TRIM('&response')) <> 'Y' THEN
        DBMS_OUTPUT.PUT_LINE('Operation cancelled. No changes were made.');
        RETURN;
    END IF;

    DBMS_OUTPUT.PUT_LINE('Dropping objects related to EBA_DEMO_MERCHANDISE...');

    -- Drop Column from eba_demo_load_emp table

    BEGIN
        EXECUTE IMMEDIATE 'ALTER TABLE eba_demo_load_emp DROP COLUMN merchandise_allowed';
        DBMS_OUTPUT.PUT_LINE('Dropped column MERCHANDISE_ALLOWED from EBA_DEMO_LOAD_EMP.');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Warning: could not drop column MERCHANDISE_ALLOWED: ' || SQLERRM);
    END;
           

    -- Drop Primary Key Constraint (if exists)
    BEGIN
        FOR c IN (SELECT constraint_name FROM user_constraints 
                  WHERE table_name = 'EBA_DEMO_MERCHANDISE' AND constraint_type = 'P') LOOP
            EXECUTE IMMEDIATE 'ALTER TABLE EBA_DEMO_MERCHANDISE DROP CONSTRAINT ' || c.constraint_name;
            DBMS_OUTPUT.PUT_LINE('Dropped Primary Key Constraint: ' || c.constraint_name);
        END LOOP;
    END;

    -- Drop Table (if exists)
    BEGIN
        FOR t IN (SELECT table_name FROM user_tables WHERE table_name = 'EBA_DEMO_MERCHANDISE') LOOP
            EXECUTE IMMEDIATE 'DROP TABLE EBA_DEMO_MERCHANDISE CASCADE CONSTRAINTS PURGE';
            DBMS_OUTPUT.PUT_LINE('Dropped Table: ' || t.table_name);
        END LOOP;
    END;

    -- Drop Index (if exists)
    BEGIN
        FOR i IN (SELECT index_name FROM user_indexes WHERE table_name = 'EBA_DEMO_MERCHANDISE') LOOP
            EXECUTE IMMEDIATE 'DROP INDEX ' || i.index_name;
            DBMS_OUTPUT.PUT_LINE('Dropped Index: ' || i.index_name);
        END LOOP;
    END;

    DBMS_OUTPUT.PUT_LINE('Cleanup completed for EBA_DEMO_MERCHANDISE.');
END;
/

-- List available APEX applications
SELECT APPLICATION_ID, APPLICATION_NAME 
FROM APEX_APPLICATIONS 
ORDER BY APPLICATION_ID;

-- Prompt for APEX Application ID
ACCEPT app_id CHAR PROMPT 'Enter the APEX Application ID to delete a page from (or press Enter to skip): '

-- Display pages for the selected application
COLUMN PAGE_ID FORMAT 99999
COLUMN PAGE_NAME FORMAT A50

SELECT PAGE_ID, PAGE_NAME
FROM APEX_APPLICATION_PAGES
WHERE APPLICATION_ID = TO_NUMBER('&app_id')
ORDER BY PAGE_ID;

-- Now prompt for APEX Page ID to delete
ACCEPT page_id CHAR PROMPT 'Enter the APEX Page ID to delete (or press Enter to skip): '

-- Execute the deletion in PL/SQL block
DECLARE
    v_workspace_id NUMBER;
BEGIN
    IF TRIM('&page_id') IS NOT NULL THEN
      -- Get the workspace ID for the selected application
      SELECT workspace_id 
      INTO v_workspace_id 
      FROM APEX_APPLICATIONS 
      WHERE APPLICATION_ID = TO_NUMBER('&app_id');

      -- Set the security group ID for the session
      APEX_UTIL.SET_SECURITY_GROUP_ID(v_workspace_id);

      -- Confirm the deletion process
      DBMS_OUTPUT.PUT_LINE('Deleting APEX Page ID ' || '&page_id' || ' from Application ID ' || '&app_id');

      -- Delete the page
      WWV_FLOW_API.REMOVE_PAGE(
          P_FLOW_ID => TO_NUMBER(TRIM('&app_id')), -- Application ID
          P_PAGE_ID => TO_NUMBER(TRIM('&page_id')) -- Page ID
      );

      DBMS_OUTPUT.PUT_LINE('Page ' || '&page_id' || ' successfully deleted from application ' || '&app_id');
    ELSE
        DBMS_OUTPUT.PUT_LINE('No APEX page was deleted.');
    END IF;
END;
/
