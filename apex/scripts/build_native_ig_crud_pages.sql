-- Build native APEX Interactive Grid CRUD pages for The Hub tables.
--
-- The script only creates pages that do not already exist. It does not remove
-- or replace existing pages, so it can be tested safely against app 101 before
-- being applied to app 100.
--
-- Usage:
--   @build_native_ig_crud_pages.sql 101
--   @build_native_ig_crud_pages.sql 100

set define on verify off feedback on serveroutput on size unlimited
whenever sqlerror exit sql.sqlcode rollback

define HUB_APP_ID = &1

alter session set container=FREEPDB1;

declare
  l_workspace_id number;
begin
  l_workspace_id := apex_util.find_security_group_id(p_workspace => 'THE_HUB');

  wwv_flow_api.set_security_group_id(p_security_group_id => l_workspace_id);
  wwv_flow_application_install.set_workspace('THE_HUB');
  wwv_flow_application_install.set_application_id(&HUB_APP_ID);
  wwv_flow_application_install.set_schema('THEHUB');

  wwv_flow_imp.import_begin(
    p_version_yyyy_mm_dd     => '2026.03.30',
    p_release                => '26.1.1',
    p_default_workspace_id   => l_workspace_id,
    p_default_application_id => &HUB_APP_ID,
    p_default_id_offset      => 0,
    p_default_owner          => 'THEHUB'
  );
end;
/

declare
  type t_page is record (
    page_id      number,
    table_name   varchar2(128),
    page_name    varchar2(200),
    nav_label    varchar2(200),
    nav_seq      number
  );

  type t_pages is table of t_page;

  l_pages t_pages := t_pages(
    t_page(50, 'MEETINGS',                'Meetings',                'Meetings',                50),
    t_page(51, 'MILESTONES',              'Milestones',              'Milestones',              51),
    t_page(52, 'LEAVE',                   'Leave',                   'Leave',                   52),
    t_page(53, 'ON_CALL',                 'On Call',                 'On Call',                 53),
    t_page(54, 'ORACLE_SECURITY_PATCHES', 'Oracle Security Patches', 'Security Patches',        54),
    t_page(55, 'ORACLE_RU_CALENDAR',      'Oracle RU Calendar',      'RU Calendar',             55),
    t_page(56, 'HOLIDAYS',                'Holidays',                'Holidays',                56),
    t_page(57, 'HOLIDAY_NOTES',           'Holiday Notes',           'Holiday Notes',           57),
    t_page(58, 'DEPENDENCIES',            'Dependencies',            'Dependencies',            58),
    t_page(59, 'RISK_REGISTER',           'Risk Register',           'Risk Register',           59),
    t_page(60, 'TEAM_MEMBERS',            'Team Members',            'Team Members',            60),
    t_page(70, 'STATUSES',                'Statuses',                'Statuses',                70),
    t_page(71, 'PRIORITIES',              'Priorities',              'Priorities',              71),
    t_page(72, 'WORKSTREAMS',             'Workstreams',             'Workstreams',             72),
    t_page(73, 'CATEGORIES',              'Categories',              'Categories',              73),
    t_page(74, 'GOALS',                   'Goals',                   'Goals',                   74),
    t_page(75, 'CADENCES',                'Cadences',                'Cadences',                75),
    t_page(76, 'MEETING_STATUSES',        'Meeting Statuses',        'Meeting Statuses',        76),
    t_page(77, 'MEETING_TYPES',           'Meeting Types',           'Meeting Types',           77),
    t_page(78, 'REPORT_TIMEFRAMES',       'Report Timeframes',       'Report Timeframes',       78)
  );

  l_region_id number;
  l_ig_id     number;
  l_report_id number;
  l_view_id   number;
  l_list_id   number;
  l_exists    number;

  function slug(p_value varchar2) return varchar2 is
  begin
    return lower(regexp_replace(p_value, '[^[:alnum:]]+', '-'));
  end;

  function title_case(p_value varchar2) return varchar2 is
  begin
    return initcap(replace(lower(p_value), '_', ' '));
  end;

  function pk_column(p_table_name varchar2, p_column_name varchar2) return boolean is
    l_count number;
  begin
    select count(*)
      into l_count
      from all_constraints ac
      join all_cons_columns acc
        on acc.owner = ac.owner
       and acc.constraint_name = ac.constraint_name
     where ac.owner = 'THEHUB'
       and ac.table_name = p_table_name
       and ac.constraint_type = 'P'
       and acc.column_name = p_column_name;

    return l_count > 0;
  end;

  function hide_pk_column(p_column_name varchar2, p_data_type varchar2) return boolean is
  begin
    return p_data_type = 'NUMBER' or p_column_name like '%\_ID' escape '\';
  end;

  function lov_query(p_table_name varchar2, p_column_name varchar2) return varchar2 is
  begin
    case
      when p_column_name = 'WORKSTREAM' then
        return 'select workstream_name d, workstream_name r from thehub.workstreams order by sort_order nulls last, workstream_name';
      when p_column_name = 'CATEGORY' then
        return 'select category_name d, category_name r from thehub.categories order by sort_order nulls last, category_name';
      when p_column_name = 'PRIORITY' then
        return 'select priority_name d, priority_name r from thehub.priorities order by sort_order nulls last, priority_name';
      when p_column_name = 'GOAL' then
        return 'select goal_name d, goal_name r from thehub.goals order by sort_order nulls last, goal_name';
      when p_column_name = 'PROJECT_ID' and p_table_name <> 'PROJECTS' then
        return 'select project_id || '' - '' || initiative d, project_id r from thehub.projects order by project_id';
      when p_column_name in ('MEMBER_ID', 'PRIMARY_MEMBER_ID') then
        return 'select full_name d, member_id r from thehub.team_members order by full_name';
      when p_column_name = 'CADENCE' then
        return 'select cadence_name d, cadence_name r from thehub.cadences order by sort_order nulls last, cadence_name';
      when p_column_name = 'MEETING_TYPE' then
        return 'select type_name d, type_name r from thehub.meeting_types order by sort_order nulls last, type_name';
      when p_table_name = 'MEETINGS' and p_column_name = 'STATUS' then
        return 'select status_name d, status_name r from thehub.meeting_statuses order by sort_order nulls last, status_name';
      when p_column_name = 'STATUS' then
        return 'select status_name d, status_name r from thehub.statuses order by sort_order nulls last, status_name';
      when p_column_name in ('ACTIVE_FLAG', 'CONFLICT_FLAG', 'INCLUDE_FLAG', 'GO_LIVE_FLAG') then
        return 'select ''Yes'' d, ''Y'' r from dual union all select ''No'' d, ''N'' r from dual';
      else
        return null;
    end case;
  end;

  procedure add_nav_entry(p_page_id number, p_label varchar2, p_seq number) is
    l_entry_id number;
    l_static_id varchar2(200);
  begin
    if l_list_id is null then
      return;
    end if;

    l_static_id := slug(p_label);

    begin
      select list_entry_id
        into l_entry_id
        from apex_260100.apex_application_list_entries
       where application_id = &HUB_APP_ID
         and list_name = 'Navigation Menu'
         and static_id = l_static_id;

      wwv_flow_imp_shared.set_list_item_link_text(
        p_id        => l_entry_id,
        p_link_text => p_label
      );
      wwv_flow_imp_shared.set_list_item_link_target(
        p_id          => l_entry_id,
        p_link_target => 'f?p=' || chr(38) || 'APP_ID.:' || p_page_id || ':' || chr(38) || 'APP_SESSION.::' || chr(38) || 'DEBUG.:::'
      );
      wwv_flow_imp_shared.set_list_item_sequence(
        p_id            => l_entry_id,
        p_item_sequence => p_seq
      );
    exception
      when no_data_found then
        wwv_flow_imp_shared.create_list_item(
          p_id                         => wwv_flow_imp.id(to_number(to_char(&HUB_APP_ID) || p_page_id || '0030')),
          p_list_id                    => l_list_id,
          p_list_item_display_sequence => p_seq,
          p_list_item_link_text        => p_label,
          p_static_id                  => l_static_id,
          p_list_item_link_target      => 'f?p=' || chr(38) || 'APP_ID.:' || p_page_id || ':' || chr(38) || 'APP_SESSION.::' || chr(38) || 'DEBUG.:::',
          p_list_item_icon             => 'fa-table',
          p_list_item_current_type     => 'TARGET_PAGE',
          p_list_item_current_for_pages => to_char(p_page_id)
        );
    end;
  end;

  procedure create_crud_page(p_page t_page) is
    l_col_id number;
    l_seq    number;
    l_lov    varchar2(4000);
    l_is_pk  boolean;
  begin
    select count(*)
      into l_exists
      from apex_260100.apex_application_pages
     where application_id = &HUB_APP_ID
       and page_id = p_page.page_id;

    if l_exists > 0 then
      dbms_output.put_line('Skipping existing page ' || p_page.page_id || ' (' || p_page.page_name || ')');
      return;
    end if;

    l_region_id := wwv_flow_imp.id(to_number(to_char(&HUB_APP_ID) || p_page.page_id || '0010'));
    l_ig_id     := wwv_flow_imp.id(to_number(to_char(&HUB_APP_ID) || p_page.page_id || '0020'));
    l_report_id := wwv_flow_imp.id(to_number(to_char(&HUB_APP_ID) || p_page.page_id || '0040'));
    l_view_id   := wwv_flow_imp.id(to_number(to_char(&HUB_APP_ID) || p_page.page_id || '0041'));

    wwv_flow_imp_page.create_page(
      p_id                    => p_page.page_id,
      p_name                  => p_page.page_name,
      p_alias                 => upper(slug(p_page.page_name)),
      p_step_title            => p_page.page_name,
      p_autocomplete_on_off   => 'OFF',
      p_step_template         => 4073832297226169690,
      p_page_template_options => '#DEFAULT#',
      p_protection_level      => 'C',
      p_page_component_map    => '03'
    );

    wwv_flow_imp_page.create_page_plug(
      p_id                    => l_region_id,
      p_plug_name             => p_page.page_name,
      p_static_id             => slug(p_page.page_name) || '-ig',
      p_region_template_options => '#DEFAULT#:t-IRR-region--hideHeader js-addHiddenHeadingRoleDesc',
      p_plug_template         => 2100526641005906379,
      p_plug_display_sequence => 10,
      p_plug_display_point    => 'BODY',
      p_plug_source_type      => 'NATIVE_IG',
      p_location              => 'LOCAL',
      p_query_type            => 'TABLE',
      p_query_owner           => 'THEHUB',
      p_query_table           => p_page.table_name,
      p_include_rowid_column  => false,
      p_is_editable           => true,
      p_edit_operations       => 'i:u:d',
      p_lost_update_check_type => 'VALUES',
      p_add_row_if_empty      => true,
      p_lazy_loading          => false,
      p_ajax_enabled          => 'Y'
    );

    wwv_flow_imp_page.create_interactive_grid(
      p_id                    => l_ig_id,
      p_flow_id               => &HUB_APP_ID,
      p_page_id               => p_page.page_id,
      p_region_id             => l_region_id,
      p_is_editable           => true,
      p_edit_operations       => 'i:u:d',
      p_lost_update_check_type => 'VALUES',
      p_add_row_if_empty      => true,
      p_lazy_loading          => false,
      p_show_toolbar          => true,
      p_toolbar_buttons       => 'SEARCH_COLUMN:SEARCH_FIELD:ACTIONS_MENU:RESET:SAVE',
      p_enable_save_public_report => false,
      p_enable_subscriptions  => false,
      p_enable_flashback      => false,
      p_define_chart_view     => false,
      p_enable_download       => true,
      p_download_formats      => 'CSV:HTML:XLSX:PDF',
      p_fixed_header          => 'PAGE',
      p_show_icon_view        => false,
      p_show_detail_view      => false
    );

    wwv_flow_imp_page.create_region_column(
      p_id                    => wwv_flow_imp.id(to_number(to_char(&HUB_APP_ID) || p_page.page_id || '0101')),
      p_region_id             => l_region_id,
      p_name                  => 'APEX$ROW_SELECTOR',
      p_session_state_data_type => 'VARCHAR2',
      p_item_type             => 'NATIVE_ROW_SELECTOR',
      p_display_sequence      => 10,
      p_attributes            => '{"enable_multi_select":"Y","show_select_all":"Y","hide_control":"N"}'
    );

    wwv_flow_imp_page.create_region_column(
      p_id                    => wwv_flow_imp.id(to_number(to_char(&HUB_APP_ID) || p_page.page_id || '0102')),
      p_region_id             => l_region_id,
      p_name                  => 'APEX$ROW_ACTION',
      p_session_state_data_type => 'VARCHAR2',
      p_item_type             => 'NATIVE_ROW_ACTION',
      p_display_sequence      => 20
    );

    for c in (
      select column_name, column_id, data_type, data_length, nullable
        from all_tab_columns
       where owner = 'THEHUB'
         and table_name = p_page.table_name
       order by column_id
    ) loop
      l_col_id := wwv_flow_imp.id(to_number(to_char(&HUB_APP_ID) || p_page.page_id || lpad(c.column_id + 200, 4, '0')));
      l_seq := (c.column_id + 2) * 10;
      l_lov := lov_query(p_page.table_name, c.column_name);
      l_is_pk := pk_column(p_page.table_name, c.column_name);
      if l_is_pk and hide_pk_column(c.column_name, c.data_type) then
        l_lov := null;
      end if;

      wwv_flow_imp_page.create_region_column(
        p_id                    => l_col_id,
        p_region_id             => l_region_id,
        p_name                  => c.column_name,
        p_source_type           => 'DB_COLUMN',
        p_source_expression     => c.column_name,
        p_data_type             => case when c.data_type like 'TIMESTAMP%' then 'TIMESTAMP' else c.data_type end,
        p_session_state_data_type => case when c.data_type = 'NUMBER' then 'VARCHAR2' else 'VARCHAR2' end,
        p_item_type             => case
                                     when l_is_pk and hide_pk_column(c.column_name, c.data_type) then 'NATIVE_HIDDEN'
                                     when l_lov is not null then 'NATIVE_SELECT_LIST'
                                     when c.data_type = 'DATE' then 'NATIVE_DATE_PICKER_APEX'
                                     else 'NATIVE_TEXT_FIELD'
                                   end,
        p_is_visible            => not (l_is_pk and hide_pk_column(c.column_name, c.data_type)),
        p_heading               => title_case(c.column_name),
        p_label                 => title_case(c.column_name),
        p_display_sequence      => l_seq,
        p_is_required           => c.nullable = 'N',
        p_is_primary_key        => l_is_pk,
        p_value_protected       => l_is_pk and hide_pk_column(c.column_name, c.data_type),
        p_include_in_export     => not (l_is_pk and hide_pk_column(c.column_name, c.data_type)),
        p_lov_type              => case when l_lov is not null then 'SQL_QUERY' end,
        p_lov_source            => l_lov,
        p_lov_display_extra     => case when l_lov is not null then false end,
        p_lov_display_null      => case when l_lov is not null and c.nullable = 'Y' then true end,
        p_format_mask           => case when c.data_type = 'DATE' then 'YYYY-MM-DD' end,
        p_max_length            => case when c.data_type = 'VARCHAR2' then c.data_length end,
        p_enable_filter         => true,
        p_filter_operators      => case when c.data_type = 'VARCHAR2' then 'C:NC:EQ:NEQ:N:NN' end,
        p_enable_sort_group     => true,
        p_enable_control_break  => true,
        p_enable_hide           => true,
        p_static_id             => slug(c.column_name),
        p_attributes            => case
                                     when c.data_type = 'DATE' then '{"show_time":"N","min_date":"NONE","max_date":"NONE","use_defaults":"Y"}'
                                     when c.data_type = 'VARCHAR2' and not l_is_pk then '{"trim_spaces":"BOTH"}'
                                   end
      );
    end loop;

    wwv_flow_imp_page.create_page_process(
      p_id                    => wwv_flow_imp.id(to_number(to_char(&HUB_APP_ID) || p_page.page_id || '0900')),
      p_process_sequence      => 10,
      p_process_point         => 'AFTER_SUBMIT',
      p_region_id             => l_region_id,
      p_process_type          => 'NATIVE_IG_DML',
      p_process_name          => p_page.page_name || ' - Save Interactive Grid Data',
      p_attribute_01          => 'REGION_SOURCE',
      p_attribute_02          => 'THEHUB',
      p_attribute_03          => p_page.table_name,
      p_attribute_05          => 'Y',
      p_attribute_06          => 'Y',
      p_attribute_08          => 'Y',
      p_error_display_location => 'INLINE_IN_NOTIFICATION',
      p_process_success_message => p_page.page_name || ' saved.'
    );

    wwv_flow_imp_page.create_ig_report(
      p_id                    => l_report_id,
      p_flow_id               => &HUB_APP_ID,
      p_page_id               => p_page.page_id,
      p_interactive_grid_id   => l_ig_id,
      p_type                  => 'PRIMARY',
      p_default_view          => 'GRID',
      p_show_row_number       => false
    );

    wwv_flow_imp_page.create_ig_report_view(
      p_id                    => l_view_id,
      p_flow_id               => &HUB_APP_ID,
      p_page_id               => p_page.page_id,
      p_report_id             => l_report_id,
      p_view_type             => 'GRID',
      p_stretch_columns       => true,
      p_edit_mode             => false
    );

    for rc in (
      select column_id, display_sequence, name
        from apex_260100.apex_appl_page_ig_columns
       where application_id = &HUB_APP_ID
         and page_id = p_page.page_id
         and name <> 'APEX$ROW_SELECTOR'
       order by display_sequence
    ) loop
      wwv_flow_imp_page.create_ig_report_column(
        p_id                  => wwv_flow_imp.id(to_number(to_char(&HUB_APP_ID) || p_page.page_id || lpad(rc.display_sequence + 500, 4, '0'))),
        p_view_id             => l_view_id,
        p_display_seq         => case when rc.name = 'APEX$ROW_ACTION' then 0 else rc.display_sequence end,
        p_column_id           => rc.column_id,
        p_is_visible          => true,
        p_is_frozen           => false
      );
    end loop;

    add_nav_entry(p_page.page_id, p_page.nav_label, p_page.nav_seq);
    dbms_output.put_line('Created page ' || p_page.page_id || ' (' || p_page.page_name || ')');
  end create_crud_page;
begin
  begin
    select list_id
      into l_list_id
      from apex_260100.apex_application_lists
     where application_id = &HUB_APP_ID
       and list_name = 'Navigation Menu';
  exception
    when no_data_found then
      l_list_id := null;
  end;

  for i in 1 .. l_pages.count loop
    create_crud_page(l_pages(i));
  end loop;
end;
/

begin
  wwv_flow_imp.import_end(p_auto_install_sup_obj => false);
  commit;
end;
/

prompt The Hub native IG CRUD pages build complete.
