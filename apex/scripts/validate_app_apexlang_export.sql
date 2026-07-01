-- Validate that an APEX app can be exported as APEXLANG.
--
-- Usage:
--   @validate_app_apexlang_export.sql 101
--   @validate_app_apexlang_export.sql 100

set define on verify off feedback on serveroutput on size unlimited
whenever sqlerror exit sql.sqlcode rollback

define HUB_APP_ID = &1

alter session set container=FREEPDB1;

declare
  l_workspace_id number;
  l_files        apex_t_export_files;
begin
  execute immediate 'grant inherit privileges on user SYS to APEX_260100';

  select workspace_id
    into l_workspace_id
    from apex_workspaces
   where workspace = 'THE_HUB';

  apex_util.set_security_group_id(l_workspace_id);

  l_files := apex_export.get_application(
    p_application_id => &HUB_APP_ID,
    p_type           => apex_export.c_type_apexlang,
    p_split          => false,
    p_with_date      => false
  );

  execute immediate 'revoke inherit privileges on user SYS from APEX_260100';

  dbms_output.put_line('APEXLANG export ok for app ' || &HUB_APP_ID || '. Files: ' || l_files.count);
exception
  when others then
    begin
      execute immediate 'revoke inherit privileges on user SYS from APEX_260100';
    exception
      when others then
        null;
    end;
    raise;
end;
/
