--------------------------------------------------------------------------
-- THE HUB - Practical Policy Bootstrap
-- Run as ADMIN (or another privileged DBA user).
-- 1) Prompts for THEHUB password at runtime (hidden input).
-- 2) Creates THEHUB schema if needed.
-- 3) Creates build/runtime roles.
-- 4) Applies build-time grants (safe for initial build phase).
--------------------------------------------------------------------------

ACCEPT HUB_PASSWORD CHAR PROMPT 'Enter password for THEHUB (must include lower/upper/number/special): ' HIDE
SET SERVEROUTPUT ON
VARIABLE HUB_PASSWORD_BIND VARCHAR2(512)
BEGIN
	:HUB_PASSWORD_BIND := '&&HUB_PASSWORD';
END;
/

SET DEFINE ON
UNDEFINE HUB_PASSWORD
SET DEFINE OFF

DECLARE
	l_count NUMBER;
	l_pwd   VARCHAR2(512) := :HUB_PASSWORD_BIND;
BEGIN
	SELECT COUNT(*) INTO l_count FROM dba_users WHERE username = 'THEHUB';
	IF l_count = 0 THEN
		EXECUTE IMMEDIATE 'CREATE USER THEHUB IDENTIFIED BY "' || REPLACE(l_pwd, '"', '""') || '"';
	END IF;
END;
/

BEGIN
	EXECUTE IMMEDIATE 'CREATE ROLE THEHUB_BUILD_ROLE';
EXCEPTION
	WHEN OTHERS THEN
		IF SQLCODE != -1921 THEN
			RAISE;
		END IF;
END;
/

BEGIN
	EXECUTE IMMEDIATE 'CREATE ROLE THEHUB_RUNTIME_ROLE';
EXCEPTION
	WHEN OTHERS THEN
		IF SQLCODE != -1921 THEN
			RAISE;
		END IF;
END;
/

-- Build-time object creation privileges.
GRANT CREATE TABLE TO THEHUB_BUILD_ROLE;
GRANT CREATE VIEW TO THEHUB_BUILD_ROLE;
GRANT CREATE SEQUENCE TO THEHUB_BUILD_ROLE;
GRANT CREATE PROCEDURE TO THEHUB_BUILD_ROLE;
GRANT CREATE TRIGGER TO THEHUB_BUILD_ROLE;
GRANT CREATE TYPE TO THEHUB_BUILD_ROLE;
GRANT CREATE JOB TO THEHUB_BUILD_ROLE;

-- Runtime role intentionally minimal; runtime DML on owned objects requires no extra grant.
GRANT CREATE SESSION TO THEHUB_RUNTIME_ROLE;

DECLARE
	l_count NUMBER;
BEGIN
	SELECT COUNT(*) INTO l_count FROM dba_users WHERE username = 'THEHUB';
	IF l_count = 1 THEN
		EXECUTE IMMEDIATE 'GRANT CREATE SESSION TO THEHUB';
		EXECUTE IMMEDIATE 'ALTER USER THEHUB ACCOUNT UNLOCK';
		EXECUTE IMMEDIATE 'ALTER USER THEHUB QUOTA UNLIMITED ON DATA';
		EXECUTE IMMEDIATE 'GRANT THEHUB_BUILD_ROLE TO THEHUB';
		EXECUTE IMMEDIATE 'GRANT THEHUB_RUNTIME_ROLE TO THEHUB';
		DBMS_OUTPUT.PUT_LINE('Bootstrap complete for THEHUB.');
		DBMS_OUTPUT.PUT_LINE('Next: connect as THEHUB and run @the_hub_schema_and_seed_data.sql');
	ELSE
		DBMS_OUTPUT.PUT_LINE('Bootstrap did not complete: THEHUB user was not created.');
		DBMS_OUTPUT.PUT_LINE('Check password policy and re-run this script with a compliant password.');
	END IF;
END;
/
