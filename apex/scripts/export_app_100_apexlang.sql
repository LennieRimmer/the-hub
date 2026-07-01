-- Export APEX application 100 as APEXLANG.
-- Run while connected to FREEPDB1 as THEHUB.
-- This writes /tmp/thehub_app_100.apexlang inside the database container.

SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK OFF HEADING OFF PAGESIZE 0 VERIFY OFF TRIMSPOOL ON TERMOUT OFF LONG 100000000 LONGCHUNKSIZE 32767 LINESIZE 32767

SPOOL /tmp/thehub_app_100.apexlang

DECLARE
  l_workspace_id NUMBER;
  l_files        apex_t_export_files;
  l_clob         CLOB;
  l_pos          PLS_INTEGER;
  l_len          PLS_INTEGER;
BEGIN
  SELECT workspace_id
    INTO l_workspace_id
    FROM apex_workspaces
   WHERE workspace = 'THE_HUB';

  apex_util.set_security_group_id(l_workspace_id);

  l_files := apex_export.get_application(
    p_application_id => 100,
    p_type           => apex_export.c_type_apexlang,
    p_split          => FALSE,
    p_with_date      => FALSE
  );

  FOR i IN 1 .. l_files.COUNT LOOP
    l_clob := l_files(i).contents;
    l_len := DBMS_LOB.getlength(l_clob);
    l_pos := 1;

    WHILE l_pos <= l_len LOOP
      DBMS_OUTPUT.put_line(DBMS_LOB.substr(l_clob, 30000, l_pos));
      l_pos := l_pos + 30000;
    END LOOP;
  END LOOP;
END;
/

SPOOL OFF
SET TERMOUT ON
EXIT
