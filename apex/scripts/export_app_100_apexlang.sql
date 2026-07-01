-- Export APEX application 100 as a flattened APEXLANG inspection file.
-- Writes /tmp/thehub_app_100.apexlang inside oracle26ai-db.
-- Run inside oracle26ai-db as SYSDBA.

set serveroutput on size unlimited
whenever sqlerror exit sql.sqlcode rollback

alter session set container=FREEPDB1;

DECLARE
  l_workspace_id NUMBER;
  l_files        apex_t_export_files;
  l_clob         CLOB;
  l_file         UTL_FILE.file_type;
  l_pos          PLS_INTEGER;
  l_len          PLS_INTEGER;
  l_chunk        VARCHAR2(32767);
BEGIN
  EXECUTE IMMEDIATE 'grant inherit privileges on user SYS to APEX_260100';

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

  l_file := UTL_FILE.fopen('THEHUB_APEX_IO', 'thehub_app_100.apexlang', 'w', 32767);

  FOR i IN 1 .. l_files.COUNT LOOP
    l_clob := l_files(i).contents;
    l_len := DBMS_LOB.getlength(l_clob);
    l_pos := 1;

    WHILE l_pos <= l_len LOOP
      l_chunk := DBMS_LOB.substr(l_clob, 30000, l_pos);
      UTL_FILE.put_line(l_file, l_chunk);
      l_pos := l_pos + 30000;
    END LOOP;
  END LOOP;

  UTL_FILE.fclose(l_file);
  EXECUTE IMMEDIATE 'revoke inherit privileges on user SYS from APEX_260100';

  DBMS_OUTPUT.put_line('Exported /tmp/thehub_app_100.apexlang');
  DBMS_OUTPUT.put_line('Files: ' || l_files.COUNT);
EXCEPTION
  WHEN OTHERS THEN
    BEGIN
      EXECUTE IMMEDIATE 'revoke inherit privileges on user SYS from APEX_260100';
    EXCEPTION
      WHEN OTHERS THEN NULL;
    END;
    IF UTL_FILE.is_open(l_file) THEN
      UTL_FILE.fclose(l_file);
    END IF;
    RAISE;
END;
/

exit
