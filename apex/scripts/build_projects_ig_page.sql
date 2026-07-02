-- Build a native APEX Interactive Grid pilot page for The Hub Projects table.

set define on verify off feedback on serveroutput on size unlimited
whenever sqlerror exit sql.sqlcode rollback

define HUB_APP_ID = '&1'

alter session set container=FREEPDB1;

begin
  wwv_flow_api.set_security_group_id(
    p_security_group_id => apex_util.find_security_group_id(p_workspace => 'THE_HUB')
  );
  wwv_flow_application_install.set_workspace('THE_HUB');
  wwv_flow_application_install.set_application_id(&HUB_APP_ID);
  wwv_flow_application_install.set_schema('THEHUB');
  wwv_flow_application_install.set_application_alias('THE_HUB');
end;
/

begin
  wwv_flow_imp.import_begin(
    p_version_yyyy_mm_dd     => '2026.03.30',
    p_default_workspace_id   => apex_util.find_security_group_id(p_workspace => 'THE_HUB'),
    p_default_application_id => &HUB_APP_ID,
    p_default_id_offset      => 0,
    p_default_owner          => 'THEHUB'
  );
end;
/

begin
  wwv_flow_imp_page.create_page(
    p_id                    => 30,
    p_name                  => 'Projects Grid',
    p_alias                 => 'PROJECTS-GRID',
    p_step_title            => 'Projects Grid',
    p_autocomplete_on_off   => 'OFF',
    p_step_template         => 4073832297226169690,
    p_page_template_options => '#DEFAULT#',
    p_protection_level      => 'C',
    p_page_component_map    => '03'
  );
end;
/

declare
  l_region_id number := wwv_flow_imp.id(to_number(to_char(&HUB_APP_ID) || '300010'));
begin
  wwv_flow_imp_page.create_page_plug(
    p_id                    => l_region_id,
    p_plug_name             => 'Projects',
    p_static_id             => 'projects-ig',
    p_region_template_options => '#DEFAULT#',
    p_plug_template         => 4073835273271169698,
    p_plug_display_sequence => 10,
    p_plug_display_point    => 'BODY',
    p_plug_source_type      => 'NATIVE_IG',
    p_location              => 'LOCAL',
    p_query_type            => 'TABLE',
    p_query_owner           => 'THEHUB',
    p_query_table           => 'PROJECTS',
    p_include_rowid_column  => false,
    p_is_editable           => true,
    p_edit_operations       => 'i:u:d',
    p_lost_update_check_type => 'VALUES',
    p_add_row_if_empty      => true,
    p_lazy_loading          => false,
    p_ajax_enabled          => 'Y'
  );

  wwv_flow_imp_page.create_region_column(
    p_id                    => wwv_flow_imp.id(to_number(to_char(&HUB_APP_ID) || '300101')),
    p_region_id             => l_region_id,
    p_name                  => 'PROJECT_ID',
    p_source_type           => 'DB_COLUMN',
    p_source_expression     => 'PROJECT_ID',
    p_data_type             => 'VARCHAR2',
    p_session_state_data_type => 'VARCHAR2',
    p_item_type             => 'NATIVE_TEXT_FIELD',
    p_heading               => 'Project ID',
    p_label                 => 'Project ID',
    p_display_sequence      => 10,
    p_is_primary_key        => true,
    p_enable_filter         => true,
    p_enable_sort_group     => true,
    p_is_required           => true,
    p_max_length            => 20
  );

  wwv_flow_imp_page.create_region_column(
    p_id                    => wwv_flow_imp.id(to_number(to_char(&HUB_APP_ID) || '300102')),
    p_region_id             => l_region_id,
    p_name                  => 'WORKSTREAM',
    p_source_type           => 'DB_COLUMN',
    p_source_expression     => 'WORKSTREAM',
    p_data_type             => 'VARCHAR2',
    p_session_state_data_type => 'VARCHAR2',
    p_item_type             => 'NATIVE_SELECT_LIST',
    p_heading               => 'Workstream',
    p_label                 => 'Workstream',
    p_display_sequence      => 20,
    p_is_required           => true,
    p_lov_type              => 'SQL_QUERY',
    p_lov_source            => 'select workstream_name d, workstream_name r from thehub.workstreams order by workstream_name',
    p_lov_display_extra     => false,
    p_lov_display_null      => true,
    p_enable_filter         => true,
    p_enable_sort_group     => true,
    p_max_length            => 100
  );

  wwv_flow_imp_page.create_region_column(
    p_id                    => wwv_flow_imp.id(to_number(to_char(&HUB_APP_ID) || '300103')),
    p_region_id             => l_region_id,
    p_name                  => 'INITIATIVE',
    p_source_type           => 'DB_COLUMN',
    p_source_expression     => 'INITIATIVE',
    p_data_type             => 'VARCHAR2',
    p_session_state_data_type => 'VARCHAR2',
    p_item_type             => 'NATIVE_TEXT_FIELD',
    p_heading               => 'Initiative',
    p_label                 => 'Initiative',
    p_display_sequence      => 30,
    p_is_required           => true,
    p_enable_filter         => true,
    p_enable_sort_group     => true,
    p_max_length            => 200
  );

  wwv_flow_imp_page.create_region_column(
    p_id                    => wwv_flow_imp.id(to_number(to_char(&HUB_APP_ID) || '300104')),
    p_region_id             => l_region_id,
    p_name                  => 'CATEGORY',
    p_source_type           => 'DB_COLUMN',
    p_source_expression     => 'CATEGORY',
    p_data_type             => 'VARCHAR2',
    p_session_state_data_type => 'VARCHAR2',
    p_item_type             => 'NATIVE_SELECT_LIST',
    p_heading               => 'Category',
    p_label                 => 'Category',
    p_display_sequence      => 40,
    p_is_required           => true,
    p_lov_type              => 'SQL_QUERY',
    p_lov_source            => 'select category_name d, category_name r from thehub.categories order by category_name',
    p_lov_display_extra     => false,
    p_lov_display_null      => true,
    p_enable_filter         => true,
    p_enable_sort_group     => true,
    p_max_length            => 100
  );

  wwv_flow_imp_page.create_region_column(
    p_id                    => wwv_flow_imp.id(to_number(to_char(&HUB_APP_ID) || '300105')),
    p_region_id             => l_region_id,
    p_name                  => 'OWNER',
    p_source_type           => 'DB_COLUMN',
    p_source_expression     => 'OWNER',
    p_data_type             => 'VARCHAR2',
    p_session_state_data_type => 'VARCHAR2',
    p_item_type             => 'NATIVE_TEXT_FIELD',
    p_heading               => 'Owner',
    p_label                 => 'Owner',
    p_display_sequence      => 50,
    p_is_required           => true,
    p_enable_filter         => true,
    p_enable_sort_group     => true,
    p_max_length            => 100
  );

  wwv_flow_imp_page.create_region_column(
    p_id                    => wwv_flow_imp.id(to_number(to_char(&HUB_APP_ID) || '300106')),
    p_region_id             => l_region_id,
    p_name                  => 'START_DATE',
    p_source_type           => 'DB_COLUMN',
    p_source_expression     => 'START_DATE',
    p_data_type             => 'DATE',
    p_session_state_data_type => 'VARCHAR2',
    p_item_type             => 'NATIVE_DATE_PICKER_APEX',
    p_heading               => 'Start Date',
    p_label                 => 'Start Date',
    p_display_sequence      => 60,
    p_is_required           => true,
    p_format_mask           => 'YYYY-MM-DD',
    p_enable_filter         => true,
    p_enable_sort_group     => true
  );

  wwv_flow_imp_page.create_region_column(
    p_id                    => wwv_flow_imp.id(to_number(to_char(&HUB_APP_ID) || '300107')),
    p_region_id             => l_region_id,
    p_name                  => 'FINISH_DATE',
    p_source_type           => 'DB_COLUMN',
    p_source_expression     => 'FINISH_DATE',
    p_data_type             => 'DATE',
    p_session_state_data_type => 'VARCHAR2',
    p_item_type             => 'NATIVE_DATE_PICKER_APEX',
    p_heading               => 'Finish Date',
    p_label                 => 'Finish Date',
    p_display_sequence      => 70,
    p_is_required           => true,
    p_format_mask           => 'YYYY-MM-DD',
    p_enable_filter         => true,
    p_enable_sort_group     => true
  );

  wwv_flow_imp_page.create_region_column(
    p_id                    => wwv_flow_imp.id(to_number(to_char(&HUB_APP_ID) || '300108')),
    p_region_id             => l_region_id,
    p_name                  => 'STATUS',
    p_source_type           => 'DB_COLUMN',
    p_source_expression     => 'STATUS',
    p_data_type             => 'VARCHAR2',
    p_session_state_data_type => 'VARCHAR2',
    p_item_type             => 'NATIVE_SELECT_LIST',
    p_heading               => 'Status',
    p_label                 => 'Status',
    p_display_sequence      => 80,
    p_is_required           => true,
    p_lov_type              => 'SQL_QUERY',
    p_lov_source            => 'select status_name d, status_name r from thehub.statuses order by status_name',
    p_lov_display_extra     => false,
    p_lov_display_null      => true,
    p_enable_filter         => true,
    p_enable_sort_group     => true,
    p_max_length            => 50
  );

  wwv_flow_imp_page.create_region_column(
    p_id                    => wwv_flow_imp.id(to_number(to_char(&HUB_APP_ID) || '300109')),
    p_region_id             => l_region_id,
    p_name                  => 'PRIORITY',
    p_source_type           => 'DB_COLUMN',
    p_source_expression     => 'PRIORITY',
    p_data_type             => 'VARCHAR2',
    p_session_state_data_type => 'VARCHAR2',
    p_item_type             => 'NATIVE_SELECT_LIST',
    p_heading               => 'Priority',
    p_label                 => 'Priority',
    p_display_sequence      => 90,
    p_is_required           => true,
    p_lov_type              => 'SQL_QUERY',
    p_lov_source            => 'select priority_name d, priority_name r from thehub.priorities order by priority_name',
    p_lov_display_extra     => false,
    p_lov_display_null      => true,
    p_enable_filter         => true,
    p_enable_sort_group     => true,
    p_max_length            => 50
  );

  wwv_flow_imp_page.create_region_column(
    p_id                    => wwv_flow_imp.id(to_number(to_char(&HUB_APP_ID) || '300110')),
    p_region_id             => l_region_id,
    p_name                  => 'GOAL',
    p_source_type           => 'DB_COLUMN',
    p_source_expression     => 'GOAL',
    p_data_type             => 'VARCHAR2',
    p_session_state_data_type => 'VARCHAR2',
    p_item_type             => 'NATIVE_SELECT_LIST',
    p_heading               => 'Goal',
    p_label                 => 'Goal',
    p_display_sequence      => 100,
    p_is_required           => true,
    p_lov_type              => 'SQL_QUERY',
    p_lov_source            => 'select goal_name d, goal_name r from thehub.goals order by goal_name',
    p_lov_display_extra     => false,
    p_lov_display_null      => true,
    p_enable_filter         => true,
    p_enable_sort_group     => true,
    p_max_length            => 200
  );

  wwv_flow_imp_page.create_region_column(
    p_id                    => wwv_flow_imp.id(to_number(to_char(&HUB_APP_ID) || '300111')),
    p_region_id             => l_region_id,
    p_name                  => 'GO_LIVE_FLAG',
    p_source_type           => 'DB_COLUMN',
    p_source_expression     => 'GO_LIVE_FLAG',
    p_data_type             => 'VARCHAR2',
    p_session_state_data_type => 'VARCHAR2',
    p_item_type             => 'NATIVE_SELECT_LIST',
    p_heading               => 'Go Live',
    p_label                 => 'Go Live',
    p_display_sequence      => 110,
    p_is_required           => true,
    p_lov_type              => 'STATIC',
    p_lov_source            => 'STATIC:Yes;Yes,No;No',
    p_lov_display_extra     => false,
    p_lov_display_null      => true,
    p_enable_filter         => true,
    p_enable_sort_group     => true,
    p_max_length            => 3
  );

  wwv_flow_imp_page.create_page_process(
    p_id                    => wwv_flow_imp.id(to_number(to_char(&HUB_APP_ID) || '300900')),
    p_process_sequence      => 10,
    p_process_point         => 'AFTER_SUBMIT',
    p_region_id             => l_region_id,
    p_process_type          => 'NATIVE_IG_DML',
    p_process_name          => 'Projects - Save Interactive Grid Data',
    p_attribute_01          => 'REGION_SOURCE',
    p_attribute_02          => 'THEHUB',
    p_attribute_03          => 'PROJECTS',
    p_attribute_05          => 'Y',
    p_attribute_06          => 'Y',
    p_attribute_08          => 'Y',
    p_error_display_location => 'INLINE_IN_NOTIFICATION',
    p_process_success_message => 'Projects saved.'
  );
end;
/

declare
  l_list_id  number;
  l_entry_id number;
begin
  select list_id
    into l_list_id
    from apex_260100.apex_application_lists
   where application_id = &HUB_APP_ID
     and list_name = 'Navigation Menu';

  begin
    select list_entry_id
      into l_entry_id
      from apex_260100.apex_application_list_entries
     where application_id = &HUB_APP_ID
       and list_name = 'Navigation Menu'
       and static_id = 'projects-grid';

    wwv_flow_imp_shared.set_list_item_link_text(
      p_id        => l_entry_id,
      p_link_text => 'Projects Grid'
    );
    wwv_flow_imp_shared.set_list_item_link_target(
      p_id          => l_entry_id,
      p_link_target => 'f?p=' || chr(38) || 'APP_ID.:30:' || chr(38) || 'APP_SESSION.::' || chr(38) || 'DEBUG.:::'
    );
    wwv_flow_imp_shared.set_list_item_sequence(
      p_id            => l_entry_id,
      p_item_sequence => 30
    );
  exception
    when no_data_found then
      wwv_flow_imp_shared.create_list_item(
        p_id                         => wwv_flow_imp.id(to_number(to_char(&HUB_APP_ID) || '300030')),
        p_list_id                    => l_list_id,
        p_list_item_display_sequence => 30,
        p_list_item_link_text        => 'Projects Grid',
        p_static_id                  => 'projects-grid',
        p_list_item_link_target      => 'f?p=' || chr(38) || 'APP_ID.:30:' || chr(38) || 'APP_SESSION.::' || chr(38) || 'DEBUG.:::',
        p_list_item_icon             => 'fa-edit',
        p_list_item_current_type     => 'TARGET_PAGE',
        p_list_item_current_for_pages => '30'
      );
  end;
end;
/

begin
  wwv_flow_imp.import_end(
    p_auto_install_sup_obj => false
  );
  commit;
end;
/

prompt The Hub Projects Interactive Grid pilot page build complete.
