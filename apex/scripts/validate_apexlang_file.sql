-- Validate an APEXLANG application export using the server-side APEX parser.
--
-- Usage inside oracle26ai-db:
--   sqlplus -S "$THEHUB_CONNECT_STRING" @/tmp/validate_apexlang_file.sql thehub_app_100.apexlang
--
-- Prerequisite:
--   CREATE OR REPLACE DIRECTORY THEHUB_APEX_IO AS '/tmp';
--   GRANT READ, WRITE ON DIRECTORY THEHUB_APEX_IO TO THEHUB;

set serveroutput on size unlimited
set feedback on
whenever sqlerror exit sql.sqlcode rollback

DECLARE
  l_filename     VARCHAR2(255) := NVL('&1', 'thehub_app_100.apexlang');
  l_bfile        BFILE;
  l_clob         CLOB;
  l_dest_offset  INTEGER := 1;
  l_src_offset   INTEGER := 1;
  l_lang_context INTEGER := DBMS_LOB.default_lang_ctx;
  l_warning      INTEGER;
  l_source       apex_t_export_files;
  l_info         apex_application_install.t_file_info;
BEGIN
  DBMS_LOB.createtemporary(l_clob, TRUE);
  l_bfile := BFILENAME('THEHUB_APEX_IO', l_filename);
  DBMS_LOB.fileopen(l_bfile, DBMS_LOB.file_readonly);
  DBMS_LOB.loadclobfromfile(
    dest_lob     => l_clob,
    src_bfile    => l_bfile,
    amount       => DBMS_LOB.lobmaxsize,
    dest_offset  => l_dest_offset,
    src_offset   => l_src_offset,
    bfile_csid   => DBMS_LOB.default_csid,
    lang_context => l_lang_context,
    warning      => l_warning
  );
  DBMS_LOB.fileclose(l_bfile);

  l_source := apex_t_export_files(
    apex_t_export_file(
      name     => 'application.apx',
      contents => l_clob
    )
  );

  l_info := apex_application_install.get_info(p_source => l_source);

  DBMS_OUTPUT.put_line('APEXLANG validation passed.');
  DBMS_OUTPUT.put_line('File type: ' || l_info.file_type);
  DBMS_OUTPUT.put_line('Workspace ID: ' || l_info.workspace_id);
  DBMS_OUTPUT.put_line('Version: ' || l_info.version);
  DBMS_OUTPUT.put_line('App ID: ' || l_info.app_id);
  DBMS_OUTPUT.put_line('App Name: ' || l_info.app_name);
  DBMS_OUTPUT.put_line('Alias: ' || l_info.app_alias);
  DBMS_OUTPUT.put_line('Owner: ' || l_info.app_owner);

  DBMS_LOB.freetemporary(l_clob);
EXCEPTION
  WHEN OTHERS THEN
    IF DBMS_LOB.fileisopen(l_bfile) = 1 THEN
      DBMS_LOB.fileclose(l_bfile);
    END IF;
    IF DBMS_LOB.istemporary(l_clob) = 1 THEN
      DBMS_LOB.freetemporary(l_clob);
    END IF;
    RAISE;
END;
/

exit
