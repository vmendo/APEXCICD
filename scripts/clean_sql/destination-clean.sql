SET SERVEROUTPUT ON
SET VERIFY OFF
COLUMN APPLICATION_ID FORMAT A10
COLUMN APPLICATION_NAME FORMAT A40

-- Get the current user and database
DECLARE
    v_username VARCHAR2(100);
    v_dbname VARCHAR2(100);
BEGIN
    SELECT USER INTO v_username FROM dual;
    SELECT sys_context('USERENV', 'DB_NAME') INTO v_dbname FROM dual;

    DBMS_OUTPUT.PUT_LINE('==========================================');
    DBMS_OUTPUT.PUT_LINE('WARNING: You are connected as ' || v_username || ' on ' || v_dbname);
    DBMS_OUTPUT.PUT_LINE('This operation will drop ALL tables, indexes, sequences, packages,');
    DBMS_OUTPUT.PUT_LINE('procedures, functions, triggers, views, and synonyms in this schema.');
    DBMS_OUTPUT.PUT_LINE('==========================================');
END;
/
-- Explicitly ask for confirmation before proceeding
ACCEPT response CHAR PROMPT 'Do you want to continue? (Y/N): '

BEGIN
    IF UPPER(TRIM('&response')) <> 'Y' THEN
        DBMS_OUTPUT.PUT_LINE('Operation cancelled. No changes were made.');
        RETURN;
    END IF;

    DBMS_OUTPUT.PUT_LINE('Dropping objects...');

    -- Drop Tables
    DECLARE v_count NUMBER := 0;
    BEGIN
        FOR t IN (SELECT table_name FROM user_tables) LOOP
            EXECUTE IMMEDIATE 'DROP TABLE "' || t.table_name || '" CASCADE CONSTRAINTS PURGE';
            v_count := v_count + 1;
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('Dropped ' || v_count || ' tables.');
    END;

    -- Drop Indexes
    DECLARE v_count NUMBER := 0;
    BEGIN
        FOR i IN (SELECT index_name FROM user_indexes WHERE table_owner = USER) LOOP
            EXECUTE IMMEDIATE 'DROP INDEX "' || i.index_name || '"';
            v_count := v_count + 1;
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('Dropped ' || v_count || ' indexes.');
    END;

    -- Drop Sequences
    DECLARE v_count NUMBER := 0;
    BEGIN
        FOR s IN (
            SELECT sequence_name
            FROM user_sequences
            WHERE sequence_name NOT LIKE 'ISEQ$$_%'
        ) LOOP
            EXECUTE IMMEDIATE 'DROP SEQUENCE "' || s.sequence_name || '"';
            v_count := v_count + 1;
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('Dropped ' || v_count || ' sequences.');
    END;

    -- Drop Packages
    DECLARE v_count NUMBER := 0;
    BEGIN
        FOR p IN (SELECT object_name FROM user_objects WHERE object_type = 'PACKAGE') LOOP
            EXECUTE IMMEDIATE 'DROP PACKAGE "' || p.object_name || '"';
            v_count := v_count + 1;
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('Dropped ' || v_count || ' packages.');
    END;

    -- Drop Procedures
    DECLARE v_count NUMBER := 0;
    BEGIN
        FOR p IN (SELECT object_name FROM user_objects WHERE object_type = 'PROCEDURE') LOOP
            EXECUTE IMMEDIATE 'DROP PROCEDURE "' || p.object_name || '"';
            v_count := v_count + 1;
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('Dropped ' || v_count || ' procedures.');
    END;

    -- Drop Functions
    DECLARE v_count NUMBER := 0;
    BEGIN
        FOR f IN (SELECT object_name FROM user_objects WHERE object_type = 'FUNCTION') LOOP
            EXECUTE IMMEDIATE 'DROP FUNCTION "' || f.object_name || '"';
            v_count := v_count + 1;
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('Dropped ' || v_count || ' functions.');
    END;

    -- Drop Triggers
    DECLARE v_count NUMBER := 0;
    BEGIN
        FOR t IN (SELECT trigger_name FROM user_triggers) LOOP
            EXECUTE IMMEDIATE 'DROP TRIGGER "' || t.trigger_name || '"';
            v_count := v_count + 1;
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('Dropped ' || v_count || ' triggers.');
    END;

    -- Drop Views
    DECLARE v_count NUMBER := 0;
    BEGIN
        FOR v IN (SELECT view_name FROM user_views) LOOP
            EXECUTE IMMEDIATE 'DROP VIEW "' || v.view_name || '"';
            v_count := v_count + 1;
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('Dropped ' || v_count || ' views.');
    END;

    -- Drop Synonyms
    DECLARE v_count NUMBER := 0;
    BEGIN
        FOR s IN (SELECT synonym_name FROM USER_SYNONYMS) LOOP
            EXECUTE IMMEDIATE 'DROP SYNONYM "' || s.synonym_name || '"';
            v_count := v_count + 1;
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('Dropped ' || v_count || ' synonyms.');
    END;

    -- Drop Types
    DECLARE
        v_count NUMBER := 0;
    BEGIN
        FOR t IN (SELECT object_name FROM user_objects WHERE object_type = 'TYPE') LOOP
            BEGIN
                EXECUTE IMMEDIATE 'DROP TYPE "' || t.object_name || '" FORCE';
                v_count := v_count + 1;
            EXCEPTION
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('Failed to drop type ' || t.object_name || ': ' || SQLERRM);
            END;
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('Dropped ' || v_count || ' types.');
    END;

    -- Drop Package Bodies
    DECLARE
        v_count NUMBER := 0;
    BEGIN
        FOR p IN (SELECT object_name FROM user_objects WHERE object_type = 'PACKAGE BODY') LOOP
            BEGIN
                EXECUTE IMMEDIATE 'DROP PACKAGE BODY "' || p.object_name || '"';
                v_count := v_count + 1;
            EXCEPTION
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('Failed to drop package body ' || p.object_name || ': ' || SQLERRM);
            END;
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('Dropped ' || v_count || ' package bodies.');
    END;


    DBMS_OUTPUT.PUT_LINE('Schema cleanup completed successfully.');
END;
/

-- List APEX applications
SELECT APPLICATION_ID, APPLICATION_NAME 
FROM APEX_APPLICATIONS 
ORDER BY APPLICATION_ID;

-- Ask for APEX Application ID to delete
ACCEPT app_id CHAR PROMPT 'Enter the APEX Application ID to delete (or press Enter to skip): '

BEGIN
    IF TRIM('&app_id') IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('Deleting APEX application ID: ' || '&app_id');

        -- Use WWV_FLOW_API.REMOVE_APPLICATION to delete the APEX application
        WWV_FLOW_API.REMOVE_APPLICATION(
            P_APPLICATION_ID  => TO_NUMBER('&app_id'),
            P_WORKSPACE_ID    => NULL, -- NULL means it deletes from the current workspace
            P_DELETE_FEEDBACK => TRUE
        );

        DBMS_OUTPUT.PUT_LINE('APEX application ID ' || '&app_id' || ' deleted successfully.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('No APEX application was deleted.');
    END IF;
END;
/

