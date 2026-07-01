-- Replace APEX application 100 page 1 with The Hub dashboard.
-- Run connected to FREEPDB1 as THEHUB or an APEX administrator.

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
    p_name                  => 'Dashboard',
    p_alias                 => 'HOME',
    p_step_title            => 'The Hub',
    p_step_template         => 4073832297226169690,
    p_page_template_options => '#DEFAULT#',
    p_autocomplete_on_off   => 'OFF',
    p_protection_level      => 'C',
    p_page_component_map    => '18',
    p_inline_css            => q'~ 
.hub-shell {
  display: grid;
  gap: 1rem;
}

.hub-hero {
  background: linear-gradient(135deg, #101820 0%, #26343d 58%, #355c67 100%);
  color: #fff;
  border-radius: 6px;
  padding: 1.2rem 1.35rem;
  box-shadow: 0 12px 26px rgba(16, 24, 32, .18);
}

.hub-hero h1 {
  margin: 0;
  font-size: 1.55rem;
  line-height: 1.2;
  letter-spacing: 0;
}

.hub-hero p {
  margin: .35rem 0 0;
  max-width: 58rem;
  color: rgba(255,255,255,.82);
}

.hub-kpis {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: .75rem;
}

.hub-kpi {
  min-height: 6.3rem;
  border: 1px solid rgba(16, 24, 32, .08);
  border-radius: 6px;
  padding: .85rem .95rem;
  background: #fff;
  box-shadow: 0 6px 18px rgba(16, 24, 32, .07);
}

.hub-kpi span {
  display: block;
  color: #59636e;
  font-size: .76rem;
  font-weight: 700;
  text-transform: uppercase;
}

.hub-kpi strong {
  display: block;
  margin-top: .35rem;
  color: #111827;
  font-size: 2rem;
  line-height: 1;
}

.hub-kpi small {
  display: block;
  margin-top: .4rem;
  color: #69737d;
}

.hub-kpi.is-danger {
  border-color: rgba(186, 43, 43, .26);
  background: #fffafa;
}

.hub-focus {
  display: grid;
  grid-template-columns: minmax(0, 1.35fr) minmax(18rem, .65fr);
  gap: .9rem;
}

.hub-panel {
  border: 1px solid rgba(16, 24, 32, .08);
  border-radius: 6px;
  background: #fff;
  padding: .95rem;
}

.hub-panel h2 {
  margin: 0 0 .7rem;
  font-size: 1rem;
  letter-spacing: 0;
}

.hub-list {
  display: grid;
  gap: .55rem;
}

.hub-row {
  display: grid;
  grid-template-columns: 6.5rem minmax(0, 1fr) auto;
  gap: .7rem;
  align-items: center;
  padding: .55rem 0;
  border-top: 1px solid #edf0f2;
}

.hub-row:first-child {
  border-top: 0;
}

.hub-date {
  color: #59636e;
  font-variant-numeric: tabular-nums;
}

.hub-title {
  color: #111827;
  font-weight: 650;
}

.hub-meta {
  color: #69737d;
  font-size: .82rem;
}

.hub-pill {
  display: inline-flex;
  align-items: center;
  min-height: 1.45rem;
  border-radius: 999px;
  padding: .12rem .55rem;
  background: #eef4ff;
  color: #2355a3;
  font-size: .78rem;
  font-weight: 700;
}

.hub-pill.is-high {
  background: #fff0f0;
  color: #a12b2b;
}

~'
  );

  wwv_flow_imp_page.create_page_plug(
    p_id                    => wwv_flow_imp.id(100010),
    p_flow_id               => 100,
    p_page_id               => 1,
    p_plug_name             => 'Planning Window',
    p_static_id             => 'planning-window',
    p_plug_display_point    => 'BODY',
    p_plug_template         => 4073835273271169698,
    p_plug_display_sequence => 10,
    p_plug_item_display_point => 'ABOVE',
    p_plug_source_type      => 'NATIVE_STATIC_CONTENT',
    p_plug_new_grid         => true,
    p_plug_new_grid_row     => true,
    p_region_template_options => '#DEFAULT#:t-Region--noPadding:t-Region--removeHeader',
    p_attributes            => wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
      'expand_shortcuts', 'N',
      'output_as', 'HTML')).to_clob
  );

  wwv_flow_imp_page.create_page_item(
    p_id                    => wwv_flow_imp.id(100011),
    p_flow_id               => 100,
    p_flow_step_id          => 1,
    p_name                  => 'P1_PERIOD_START',
    p_data_type             => 'VARCHAR2',
    p_source_data_type      => 'VARCHAR2',
    p_item_sequence         => 10,
    p_item_plug_id          => wwv_flow_imp.id(100010),
    p_item_display_point    => 'BODY',
    p_use_cache_before_default => 'NO',
    p_item_default          => 'TRUNC(SYSDATE, ''MM'')',
    p_item_default_type     => 'EXPRESSION',
    p_item_default_language => 'PLSQL',
    p_prompt                => 'Start',
    p_display_as            => 'NATIVE_DATE_PICKER_APEX',
    p_format_mask           => 'YYYY-MM-DD',
    p_cSize                 => 12,
    p_field_template        => 2042262243893469891,
    p_item_template_options => '#DEFAULT#',
    p_attributes            => wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
      'show_on', 'FOCUS',
      'use_defaults', 'Y')).to_clob
  );

  wwv_flow_imp_page.create_page_item(
    p_id                    => wwv_flow_imp.id(100012),
    p_flow_id               => 100,
    p_flow_step_id          => 1,
    p_name                  => 'P1_PERIOD_END',
    p_data_type             => 'VARCHAR2',
    p_source_data_type      => 'VARCHAR2',
    p_item_sequence         => 20,
    p_item_plug_id          => wwv_flow_imp.id(100010),
    p_item_display_point    => 'BODY',
    p_use_cache_before_default => 'NO',
    p_item_default          => 'LAST_DAY(ADD_MONTHS(TRUNC(SYSDATE, ''MM''), 2))',
    p_item_default_type     => 'EXPRESSION',
    p_item_default_language => 'PLSQL',
    p_prompt                => 'End',
    p_display_as            => 'NATIVE_DATE_PICKER_APEX',
    p_format_mask           => 'YYYY-MM-DD',
    p_cSize                 => 12,
    p_field_template        => 2042262243893469891,
    p_item_template_options => '#DEFAULT#',
    p_attributes            => wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
      'show_on', 'FOCUS',
      'use_defaults', 'Y')).to_clob
  );

  wwv_flow_imp_page.create_page_button(
    p_id                    => wwv_flow_imp.id(100013),
    p_button_sequence       => 30,
    p_button_plug_id        => wwv_flow_imp.id(100010),
    p_button_name           => 'APPLY',
    p_static_id             => 'apply-window',
    p_button_action         => 'SUBMIT',
    p_button_template_id    => 4073839297780169708,
    p_button_is_hot         => 'Y',
    p_button_image_alt      => 'Apply',
    p_button_position       => 'NEXT'
  );

  wwv_flow_imp_page.create_page_plug(
    p_id                    => wwv_flow_imp.id(100020),
    p_flow_id               => 100,
    p_page_id               => 1,
    p_plug_name             => 'Dashboard Summary',
    p_static_id             => 'dashboard-summary',
    p_plug_display_point    => 'BODY',
    p_plug_template         => 4073835273271169698,
    p_plug_display_sequence => 20,
    p_plug_source_type      => 'NATIVE_PLSQL',
    p_function_body_language => 'PLSQL',
    p_plug_source           => q'~DECLARE
  l_start DATE := NVL(TO_DATE(:P1_PERIOD_START, 'YYYY-MM-DD'), TRUNC(SYSDATE, 'MM'));
  l_end   DATE := NVL(TO_DATE(:P1_PERIOD_END, 'YYYY-MM-DD'), LAST_DAY(ADD_MONTHS(TRUNC(SYSDATE, 'MM'), 2)));
  l_projects NUMBER;
  l_milestones NUMBER;
  l_leave_hours NUMBER;
  l_conflicts NUMBER;
  l_next_patch VARCHAR2(200);
BEGIN
  SELECT COUNT(*) INTO l_projects
  FROM projects p
  WHERE p.status = 'Active'
    AND NVL(p.finish_date, DATE '2999-12-31') >= l_start
    AND NVL(p.start_date, DATE '1900-01-01') <= l_end;

  SELECT COUNT(*) INTO l_milestones
  FROM milestones m
  WHERE m.milestone_date BETWEEN l_start AND l_end;

  SELECT NVL(SUM(le.hours), 0) INTO l_leave_hours
  FROM leave le
  WHERE le.leave_date BETWEEN l_start AND l_end
    AND NVL(le.status, 'Approved') <> 'Cancelled';

  SELECT COUNT(*) INTO l_conflicts
  FROM on_call o
  WHERE o.conflict_flag = 'Yes'
    AND o.week_start <= l_end
    AND o.week_end >= l_start;

  SELECT MIN(patch_code || ' - ' || TO_CHAR(release_date, 'Mon DD'))
    INTO l_next_patch
    FROM oracle_security_patches
   WHERE release_date >= TRUNC(SYSDATE);

  htp.p('<div class="hub-shell">');
  htp.p('<section class="hub-hero"><h1>The Hub</h1><p>DBA planning command center for projects, milestones, coverage, meetings, and Oracle patch windows.</p></section>');
  htp.p('<section class="hub-kpis">');
  htp.p('<div class="hub-kpi"><span>Active projects</span><strong>' || l_projects || '</strong><small>overlaps selected window</small></div>');
  htp.p('<div class="hub-kpi"><span>Milestones</span><strong>' || l_milestones || '</strong><small>due in selected window</small></div>');
  htp.p('<div class="hub-kpi"><span>Leave hours</span><strong>' || l_leave_hours || '</strong><small>approved or planned</small></div>');
  htp.p('<div class="hub-kpi ' || CASE WHEN l_conflicts > 0 THEN 'is-danger' END || '"><span>On-call conflicts</span><strong>' || l_conflicts || '</strong><small>coverage weeks to review</small></div>');
  htp.p('</section>');
  htp.p('<section class="hub-focus">');
  htp.p('<div class="hub-panel"><h2>Upcoming Milestones</h2><div class="hub-list">');
  FOR r IN (
    SELECT project_id, milestone_name, milestone_date, priority
      FROM milestones
     WHERE milestone_date BETWEEN l_start AND l_end
     ORDER BY milestone_date, CASE priority WHEN 'High' THEN 1 WHEN 'Medium' THEN 2 ELSE 3 END, project_id
     FETCH FIRST 7 ROWS ONLY
  ) LOOP
    htp.p('<div class="hub-row"><div class="hub-date">' || TO_CHAR(r.milestone_date, 'Mon DD') || '</div><div><div class="hub-title">' || apex_escape.html(r.milestone_name) || '</div><div class="hub-meta">' || apex_escape.html(r.project_id) || '</div></div><span class="hub-pill ' || CASE WHEN r.priority = 'High' THEN 'is-high' END || '">' || apex_escape.html(r.priority) || '</span></div>');
  END LOOP;
  htp.p('</div></div>');
  htp.p('<div class="hub-panel"><h2>Planning Signal</h2><p class="hub-meta">Next patch marker</p><div class="hub-title">' || apex_escape.html(NVL(l_next_patch, 'No future patch rows found')) || '</div><p class="hub-meta">Use the reports below for the raw schedule behind this summary.</p></div>');
  htp.p('</section></div>');
END;~',
    p_region_template_options => '#DEFAULT#:t-Region--noPadding:t-Region--removeHeader',
    p_plug_new_grid         => true,
    p_plug_new_grid_row     => true,
    p_attributes            => wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
      'expand_shortcuts', 'N')).to_clob
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

prompt The Hub dashboard page build complete.
