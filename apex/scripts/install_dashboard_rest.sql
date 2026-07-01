-- Install ORDS REST endpoints used by the APEX dashboard.
-- Run in FREEPDB1 as THEHUB or an administrator with ORDS privileges.

set define off verify off feedback on
whenever sqlerror exit sql.sqlcode rollback

create or replace procedure thehub.install_dashboard_rest_auth
authid definer
as
begin
  ords.define_module(
    p_module_name    => 'thehub.dashboard',
    p_base_path      => 'dashboard/',
    p_items_per_page => 25,
    p_status         => 'PUBLISHED',
    p_comments       => 'The Hub dashboard JSON services'
  );

  ords.define_template(
    p_module_name => 'thehub.dashboard',
    p_pattern     => 'summary'
  );

  ords.define_handler(
    p_module_name => 'thehub.dashboard',
    p_pattern     => 'summary',
    p_method      => 'GET',
    p_source_type => ords.source_type_plsql,
    p_source      => q'~
declare
  l_start date := to_date(nvl(:period_start, to_char(trunc(sysdate, 'MM'), 'YYYY-MM-DD')), 'YYYY-MM-DD');
  l_end   date := to_date(nvl(:period_end, to_char(last_day(add_months(trunc(sysdate, 'MM'), 2)), 'YYYY-MM-DD')), 'YYYY-MM-DD');
  l_first boolean := true;

  procedure write_num(p_name varchar2, p_value number) is
  begin
    apex_json.write(p_name, p_value);
  end;
begin
  owa_util.mime_header('application/json', false);
  htp.p('Cache-Control: no-store');
  owa_util.http_header_close;

  apex_json.open_object;

  for r in (
    select
      (select count(*)
         from projects p
        where p.status = 'Active'
          and nvl(p.finish_date, date '2999-12-31') >= l_start
          and nvl(p.start_date, date '1900-01-01') <= l_end) active_projects,
      (select count(*)
         from milestones m
        where m.milestone_date between l_start and l_end) milestones_in_period,
      (select nvl(sum(le.hours), 0)
         from leave le
        where le.leave_date between l_start and l_end
          and nvl(le.status, 'Approved') <> 'Cancelled') leave_hours,
      (select count(*)
         from on_call o
        where o.conflict_flag = 'Yes'
          and o.week_start <= l_end
          and o.week_end >= l_start) on_call_conflicts,
      (select min(patch_code || ' - ' || to_char(release_date, 'Mon DD'))
         from oracle_security_patches
        where release_date >= trunc(sysdate)) next_patch
    from dual
  ) loop
    write_num('active_projects', r.active_projects);
    write_num('milestones_in_period', r.milestones_in_period);
    write_num('leave_hours', r.leave_hours);
    write_num('on_call_conflicts', r.on_call_conflicts);
    apex_json.write('next_patch', r.next_patch);
  end loop;

  apex_json.open_array('milestones');
  for m in (
    select project_id,
           milestone_name,
           to_char(milestone_date, 'YYYY-MM-DD') milestone_date,
           to_char(milestone_date, 'Mon DD') milestone_date_label,
           priority
      from (
        select distinct project_id,
               milestone_name,
               milestone_date,
               priority
          from milestones
         where milestone_date between l_start and l_end
      )
     order by milestone_date,
              case priority when 'High' then 1 when 'Medium' then 2 else 3 end,
              project_id
     fetch first 7 rows only
  ) loop
    apex_json.open_object;
    apex_json.write('project_id', m.project_id);
    apex_json.write('milestone_name', m.milestone_name);
    apex_json.write('milestone_date', m.milestone_date);
    apex_json.write('milestone_date_label', m.milestone_date_label);
    apex_json.write('priority', m.priority);
    apex_json.close_object;
  end loop;
  apex_json.close_array;

  apex_json.close_object;
end;
~',
    p_items_per_page => 0
  );

  commit;
end;
/

begin
  thehub.install_dashboard_rest_auth;
end;
/

drop procedure thehub.install_dashboard_rest_auth;

prompt The Hub dashboard REST services installed.
