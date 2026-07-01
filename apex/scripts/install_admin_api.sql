-- Install authenticated APEX AJAX CRUD helpers for The Hub data admin page.

set define off verify off feedback on serveroutput on size unlimited
whenever sqlerror exit sql.sqlcode rollback

alter session set container=FREEPDB1;

create or replace package thehub.admin_api authid definer as
  procedure handle_ajax;
end admin_api;
/

create or replace package body thehub.admin_api as
  subtype t_name is varchar2(128);

  type t_table_meta is record (
    table_name   t_name,
    pk_column    t_name,
    generated_pk boolean
  );

  function esc(p_value varchar2) return varchar2 is
  begin
    return replace(p_value, '''', '''''');
  end esc;

  function table_meta(p_key varchar2) return t_table_meta is
    l_key varchar2(128) := lower(trim(p_key));
    l_meta t_table_meta;
  begin
    case l_key
      when 'statuses' then l_meta := t_table_meta('STATUSES', 'STATUS_NAME', false);
      when 'priorities' then l_meta := t_table_meta('PRIORITIES', 'PRIORITY_NAME', false);
      when 'workstreams' then l_meta := t_table_meta('WORKSTREAMS', 'WORKSTREAM_NAME', false);
      when 'categories' then l_meta := t_table_meta('CATEGORIES', 'CATEGORY_NAME', false);
      when 'goals' then l_meta := t_table_meta('GOALS', 'GOAL_NAME', false);
      when 'meeting_statuses' then l_meta := t_table_meta('MEETING_STATUSES', 'STATUS_NAME', false);
      when 'meeting_types' then l_meta := t_table_meta('MEETING_TYPES', 'TYPE_NAME', false);
      when 'cadences' then l_meta := t_table_meta('CADENCES', 'CADENCE_NAME', false);
      when 'report_timeframes' then l_meta := t_table_meta('REPORT_TIMEFRAMES', 'TIMEFRAME_NAME', false);
      when 'team_members' then l_meta := t_table_meta('TEAM_MEMBERS', 'MEMBER_ID', true);
      when 'projects' then l_meta := t_table_meta('PROJECTS', 'PROJECT_ID', false);
      when 'milestones' then l_meta := t_table_meta('MILESTONES', 'MILESTONE_ID', true);
      when 'leave' then l_meta := t_table_meta('LEAVE', 'LEAVE_ID', true);
      when 'on_call' then l_meta := t_table_meta('ON_CALL', 'ON_CALL_ID', true);
      when 'meetings' then l_meta := t_table_meta('MEETINGS', 'MEETING_ID', true);
      when 'risk_register' then l_meta := t_table_meta('RISK_REGISTER', 'RISK_ID', false);
      when 'dependencies' then l_meta := t_table_meta('DEPENDENCIES', 'DEPENDENCY_ID', false);
      when 'oracle_ru_calendar' then l_meta := t_table_meta('ORACLE_RU_CALENDAR', 'RU', false);
      when 'oracle_security_patches' then l_meta := t_table_meta('ORACLE_SECURITY_PATCHES', 'PATCH_ID', true);
      when 'holidays' then l_meta := t_table_meta('HOLIDAYS', 'HOLIDAY_DATE', false);
      when 'holiday_notes' then l_meta := t_table_meta('HOLIDAY_NOTES', 'NOTE_KEY', false);
      else
        raise_application_error(-20000, 'Unsupported admin table: ' || p_key);
    end case;
    return l_meta;
  end table_meta;

  function key_for_table(p_table_name varchar2) return varchar2 is
  begin
    return lower(p_table_name);
  end key_for_table;

  procedure begin_json is
  begin
    owa_util.mime_header('application/json', false);
    htp.p('Cache-Control: no-store');
    owa_util.http_header_close;
  end begin_json;

  procedure catalog is
  begin
    begin_json;
    apex_json.open_object;
    apex_json.open_array('tables');

    for t in (
      select 'Lookup Values' group_name, 10 sort_group, 'STATUSES' table_name, 'Statuses' label from dual union all
      select 'Lookup Values', 10, 'PRIORITIES', 'Priorities' from dual union all
      select 'Lookup Values', 10, 'WORKSTREAMS', 'Workstreams' from dual union all
      select 'Lookup Values', 10, 'CATEGORIES', 'Categories' from dual union all
      select 'Lookup Values', 10, 'GOALS', 'Goals' from dual union all
      select 'Lookup Values', 10, 'MEETING_STATUSES', 'Meeting Statuses' from dual union all
      select 'Lookup Values', 10, 'MEETING_TYPES', 'Meeting Types' from dual union all
      select 'Lookup Values', 10, 'CADENCES', 'Cadences' from dual union all
      select 'Lookup Values', 10, 'REPORT_TIMEFRAMES', 'Report Timeframes' from dual union all
      select 'Operational Data', 20, 'TEAM_MEMBERS', 'Team Members' from dual union all
      select 'Operational Data', 20, 'PROJECTS', 'Projects' from dual union all
      select 'Operational Data', 20, 'MILESTONES', 'Milestones' from dual union all
      select 'Operational Data', 20, 'LEAVE', 'Leave' from dual union all
      select 'Operational Data', 20, 'ON_CALL', 'On Call' from dual union all
      select 'Operational Data', 20, 'MEETINGS', 'Meetings' from dual union all
      select 'Operational Data', 20, 'RISK_REGISTER', 'Risk Register' from dual union all
      select 'Operational Data', 20, 'DEPENDENCIES', 'Dependencies' from dual union all
      select 'Reference Calendars', 30, 'ORACLE_RU_CALENDAR', 'Oracle RU Calendar' from dual union all
      select 'Reference Calendars', 30, 'ORACLE_SECURITY_PATCHES', 'Security Patches' from dual union all
      select 'Reference Calendars', 30, 'HOLIDAYS', 'Holidays' from dual union all
      select 'Reference Calendars', 30, 'HOLIDAY_NOTES', 'Holiday Notes' from dual
      order by sort_group, label
    ) loop
      apex_json.open_object;
      apex_json.write('key', key_for_table(t.table_name));
      apex_json.write('label', t.label);
      apex_json.write('group', t.group_name);
      apex_json.write('table_name', t.table_name);
      apex_json.open_array('columns');
      for c in (
        select column_name, data_type, nullable, column_id,
               case
                 when table_name = 'TEAM_MEMBERS' and column_name = 'MEMBER_ID' then 'Y'
                 when table_name = 'MILESTONES' and column_name = 'MILESTONE_ID' then 'Y'
                 when table_name = 'LEAVE' and column_name = 'LEAVE_ID' then 'Y'
                 when table_name = 'ON_CALL' and column_name = 'ON_CALL_ID' then 'Y'
                 when table_name = 'MEETINGS' and column_name = 'MEETING_ID' then 'Y'
                 when table_name = 'ORACLE_SECURITY_PATCHES' and column_name = 'PATCH_ID' then 'Y'
                 else 'N'
               end generated_flag
          from all_tab_columns
         where owner = 'THEHUB'
           and table_name = t.table_name
         order by column_id
      ) loop
        apex_json.open_object;
        apex_json.write('name', c.column_name);
        apex_json.write('label', initcap(replace(c.column_name, '_', ' ')));
        apex_json.write('type', c.data_type);
        apex_json.write('required', c.nullable = 'N' and c.generated_flag = 'N');
        apex_json.write('generated', c.generated_flag = 'Y');
        apex_json.close_object;
      end loop;
      apex_json.close_array;
      apex_json.close_object;
    end loop;

    apex_json.close_array;
    apex_json.close_object;
  end catalog;

  procedure rows_for(p_key varchar2) is
    l_meta t_table_meta := table_meta(p_key);
    l_sql  clob;
    l_rows clob;
  begin
    begin_json;
    l_sql := 'select coalesce(json_arrayagg(json_object(* returning clob) returning clob), ''[]'') ' ||
             'from (select * from thehub.' || l_meta.table_name || ' order by ' || l_meta.pk_column || ' fetch first 250 rows only)';
    execute immediate l_sql into l_rows;
    htp.prn('{"rows":');
    htp.prn(l_rows);
    htp.prn('}');
  end rows_for;

  function value_expr(p_col varchar2, p_type varchar2) return varchar2 is
  begin
    if p_type = 'DATE' then
      return 'case when nullif(s.' || p_col || ', '''') is null then null else to_date(substr(s.' || p_col || ', 1, 10), ''YYYY-MM-DD'') end';
    elsif p_type = 'NUMBER' then
      return 'to_number(nullif(s.' || p_col || ', ''''))';
    else
      return 's.' || p_col;
    end if;
  end value_expr;

  procedure save_row(p_key varchar2, p_payload clob) is
    l_meta        t_table_meta := table_meta(p_key);
    l_json_cols   clob;
    l_select_cols clob;
    l_update_set  clob;
    l_insert_cols clob;
    l_insert_vals clob;
    l_sql         clob;
    l_sep         varchar2(2);
  begin
    for c in (
      select column_name, data_type,
             case when column_name = l_meta.pk_column then 'Y' else 'N' end is_pk
        from all_tab_columns
       where owner = 'THEHUB'
         and table_name = l_meta.table_name
       order by column_id
    ) loop
      l_json_cols := l_json_cols || l_sep || c.column_name || ' varchar2(4000) path ''$.' || c.column_name || ''' null on error';
      l_select_cols := l_select_cols || l_sep || value_expr(c.column_name, c.data_type) || ' ' || c.column_name;

      if c.is_pk = 'N' then
        l_update_set := l_update_set || l_sep || 't.' || c.column_name || ' = s.' || c.column_name;
      end if;

      if c.is_pk = 'N' or not l_meta.generated_pk then
        l_insert_cols := l_insert_cols || l_sep || c.column_name;
        l_insert_vals := l_insert_vals || l_sep || 's.' || c.column_name;
      end if;

      l_sep := ', ';
    end loop;

    l_sql := 'merge into thehub.' || l_meta.table_name || ' t using (' ||
             'select ' || l_select_cols || ' from json_table(:payload, ''$'' columns (' || l_json_cols || ')) s' ||
             ') s on (t.' || l_meta.pk_column || ' = s.' || l_meta.pk_column || ') ' ||
             'when matched then update set ' || l_update_set || ' ' ||
             'when not matched then insert (' || l_insert_cols || ') values (' || l_insert_vals || ')';

    execute immediate l_sql using p_payload;
    commit;

    begin_json;
    htp.prn('{"ok":true}');
  end save_row;

  procedure delete_row(p_key varchar2, p_pk varchar2) is
    l_meta t_table_meta := table_meta(p_key);
    l_type varchar2(128);
    l_sql  varchar2(1000);
  begin
    select data_type
      into l_type
      from all_tab_columns
     where owner = 'THEHUB'
       and table_name = l_meta.table_name
       and column_name = l_meta.pk_column;

    l_sql := 'delete from thehub.' || l_meta.table_name || ' where ' || l_meta.pk_column || ' = ';
    if l_type = 'DATE' then
      l_sql := l_sql || 'to_date(:pk, ''YYYY-MM-DD'')';
    elsif l_type = 'NUMBER' then
      l_sql := l_sql || 'to_number(:pk)';
    else
      l_sql := l_sql || ':pk';
    end if;

    execute immediate l_sql using p_pk;
    commit;

    begin_json;
    htp.prn('{"ok":true}');
  end delete_row;

  procedure handle_ajax is
    l_action varchar2(30) := lower(apex_application.g_x01);
    l_table  varchar2(128) := apex_application.g_x02;
    l_pk     varchar2(4000) := apex_application.g_x03;
  begin
    if l_action = 'catalog' then
      catalog;
    elsif l_action = 'rows' then
      rows_for(l_table);
    elsif l_action = 'save' then
      save_row(l_table, apex_application.g_clob_01);
    elsif l_action = 'delete' then
      delete_row(l_table, l_pk);
    else
      raise_application_error(-20001, 'Unsupported admin action: ' || l_action);
    end if;
  exception
    when others then
      rollback;
      begin_json;
      apex_json.open_object;
      apex_json.write('ok', false);
      apex_json.write('error', sqlerrm);
      apex_json.close_object;
  end handle_ajax;
end admin_api;
/

show errors package body thehub.admin_api

prompt The Hub admin API installed.
