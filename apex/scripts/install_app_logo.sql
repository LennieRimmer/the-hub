-- Install The Hub logo and derived app icons as APEX application static files.
--
-- Usage:
--   @install_app_logo.sql 101
--   @install_app_logo.sql 100
--
-- Expected files inside the database container:
--   /tmp/the-hub-logo.png
--   /tmp/app-icon-32.png
--   /tmp/app-icon-144-rounded.png
--   /tmp/app-icon-192.png
--   /tmp/app-icon-256-rounded.png
--   /tmp/app-icon-512.png

set define on verify off feedback on serveroutput on size unlimited
whenever sqlerror exit sql.sqlcode rollback

define HUB_APP_ID = &1

alter session set container=FREEPDB1;

create or replace directory THEHUB_APEX_IO as '/tmp';

begin
  wwv_flow_imp.import_begin(
    p_version_yyyy_mm_dd      => '2026.03.30',
    p_release                 => '26.1.1',
    p_default_workspace_id    => 4826358844790905,
    p_default_application_id  => &HUB_APP_ID,
    p_default_id_offset       => 0,
    p_default_owner           => 'THEHUB'
  );
end;
/

declare
  type t_file_names is table of varchar2(255) index by pls_integer;

  l_static_names t_file_names;
  l_source_names t_file_names;
  l_blob         blob;

  function load_blob(p_file_name varchar2) return blob is
    l_bfile bfile;
    l_blob  blob;
  begin
    dbms_lob.createtemporary(l_blob, true);
    l_bfile := bfilename('THEHUB_APEX_IO', p_file_name);
    dbms_lob.fileopen(l_bfile, dbms_lob.file_readonly);
    dbms_lob.loadfromfile(l_blob, l_bfile, dbms_lob.getlength(l_bfile));
    dbms_lob.fileclose(l_bfile);
    return l_blob;
  exception
    when others then
      if dbms_lob.fileisopen(l_bfile) = 1 then
        dbms_lob.fileclose(l_bfile);
      end if;
      if dbms_lob.istemporary(l_blob) = 1 then
        dbms_lob.freetemporary(l_blob);
      end if;
      raise;
  end load_blob;

  procedure replace_static_file(
    p_slot        pls_integer,
    p_static_name varchar2,
    p_source_name varchar2
  ) is
    l_file_id number;
  begin
    begin
      select application_file_id
        into l_file_id
        from apex_260100.apex_application_static_files
       where application_id = &HUB_APP_ID
         and file_name = p_static_name;

      wwv_flow_imp_shared.remove_app_static_file(
        p_id      => l_file_id,
        p_flow_id => &HUB_APP_ID
      );
    exception
      when no_data_found then
        l_file_id := to_number(to_char(&HUB_APP_ID) || '70000000' || lpad(p_slot, 2, '0'));
    end;

    l_blob := load_blob(p_source_name);

    wwv_flow_imp_shared.create_app_static_file(
      p_id           => l_file_id,
      p_flow_id      => &HUB_APP_ID,
      p_file_name    => p_static_name,
      p_mime_type    => 'image/png',
      p_file_charset => null,
      p_file_content => l_blob,
      p_created_by   => 'CODEX',
      p_created_on   => sysdate,
      p_updated_by   => 'CODEX',
      p_updated_on   => sysdate
    );

    if dbms_lob.istemporary(l_blob) = 1 then
      dbms_lob.freetemporary(l_blob);
    end if;

    dbms_output.put_line('Installed ' || p_static_name || ' from ' || p_source_name);
  end replace_static_file;
begin
  l_static_names(1) := 'brand/the-hub-logo.png';
  l_source_names(1) := 'the-hub-logo.png';
  l_static_names(2) := 'icons/app-icon-32.png';
  l_source_names(2) := 'app-icon-32.png';
  l_static_names(3) := 'icons/app-icon-144-rounded.png';
  l_source_names(3) := 'app-icon-144-rounded.png';
  l_static_names(4) := 'icons/app-icon-192.png';
  l_source_names(4) := 'app-icon-192.png';
  l_static_names(5) := 'icons/app-icon-256-rounded.png';
  l_source_names(5) := 'app-icon-256-rounded.png';
  l_static_names(6) := 'icons/app-icon-512.png';
  l_source_names(6) := 'app-icon-512.png';

  for i in 1 .. l_static_names.count loop
    replace_static_file(i, l_static_names(i), l_source_names(i));
  end loop;
end;
/

begin
  wwv_flow_imp.import_end(
    p_auto_install_sup_obj => false
  );
  commit;
end;
/

prompt The Hub logo static files installed.
