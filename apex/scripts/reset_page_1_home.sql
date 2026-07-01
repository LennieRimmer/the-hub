-- Reset APEX application 100 page 1 to an export-safe Home page.
-- Use this to recover from experimental page metadata that blocks APEXLANG export.

set define off verify off feedback on
whenever sqlerror exit sql.sqlcode rollback

begin
  wwv_flow_imp.import_begin(
    p_version_yyyy_mm_dd      => '2026.03.30',
    p_release                 => '26.1.1',
    p_default_workspace_id    => 4826358844790905,
    p_default_application_id  => 100,
    p_default_id_offset       => 0,
    p_default_owner           => 'THEHUB'
  );
end;
/

begin
  wwv_flow_imp_page.remove_page(
    p_flow_id => 100,
    p_page_id => 1
  );

  wwv_flow_imp_page.create_page(
    p_id                    => 1,
    p_name                  => 'Home',
    p_alias                 => 'HOME',
    p_step_title            => 'The Hub',
    p_autocomplete_on_off   => 'OFF',
    p_step_template         => 4073832297226169690,
    p_page_template_options => '#DEFAULT#',
    p_protection_level      => 'C',
    p_page_component_map    => '13'
  );

  wwv_flow_imp_page.create_page_plug(
    p_id                       => wwv_flow_imp.id(5244700859422248),
    p_flow_id                  => 100,
    p_page_id                  => 1,
    p_plug_name                => 'The Hub',
    p_static_id                => 'the-hub',
    p_region_template_options  => '#DEFAULT#',
    p_escape_on_http_output    => 'Y',
    p_plug_template            => 2675494171183407654,
    p_plug_display_sequence    => 10,
    p_plug_display_point       => 'REGION_POSITION_01',
    p_plug_item_display_point  => 'ABOVE',
    p_plug_query_num_rows      => 15,
    p_region_image             => '#APP_FILES#icons/app-icon-512.png',
    p_plug_source_type         => 'NATIVE_STATIC_CONTENT',
    p_attributes               => wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
      'expand_shortcuts', 'N',
      'output_as', 'HTML')).to_clob
  );
end;
/

begin
  wwv_flow_imp.import_end(
    p_auto_install_sup_obj => false
  );
  commit;
end;
/

prompt The Hub page 1 reset complete.
