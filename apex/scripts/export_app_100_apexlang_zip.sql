-- Export APEX application 100 as a canonical APEXLANG ZIP archive.
-- Writes /tmp/thehub_app_100_apexlang.zip inside oracle26ai-db.
-- Run inside oracle26ai-db as SYSDBA.

set serveroutput on size unlimited
whenever sqlerror exit sql.sqlcode rollback

alter session set container=FREEPDB1;

DECLARE
  l_workspace_id NUMBER;
  l_files        apex_t_export_files;
  l_zip          BLOB;
  l_file         UTL_FILE.file_type;
  l_pos          INTEGER := 1;
  l_amount       BINARY_INTEGER := 32767;
  l_len          INTEGER;
BEGIN
  execute immediate 'grant inherit privileges on user SYS to APEX_260100';

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

  l_zip := apex_export.zip(l_files);
  l_len := DBMS_LOB.getlength(l_zip);

  l_file := UTL_FILE.fopen('THEHUB_APEX_IO', 'thehub_app_100_apexlang.zip', 'wb', 32767);
  WHILE l_pos <= l_len LOOP
    UTL_FILE.put_raw(l_file, DBMS_LOB.substr(l_zip, l_amount, l_pos), TRUE);
    l_pos := l_pos + l_amount;
  END LOOP;
  UTL_FILE.fclose(l_file);

  DBMS_OUTPUT.put_line('Exported /tmp/thehub_app_100_apexlang.zip');
  DBMS_OUTPUT.put_line('Files: ' || l_files.COUNT);
  DBMS_OUTPUT.put_line('Bytes: ' || l_len);

  execute immediate 'revoke inherit privileges on user SYS from APEX_260100';
EXCEPTION
  WHEN OTHERS THEN
    BEGIN
      execute immediate 'revoke inherit privileges on user SYS from APEX_260100';
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
