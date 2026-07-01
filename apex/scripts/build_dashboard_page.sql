-- Replace an APEX application Page 1 with an export-safe dashboard shell.
--
-- The page itself is static APEX metadata so APEXLANG export stays stable.
-- Live KPI data is loaded from ORDS endpoint /ords/thehub/dashboard/summary.
--
-- Usage:
--   @build_dashboard_page.sql 101
--   @build_dashboard_page.sql 100

set define on verify off feedback on
whenever sqlerror exit sql.sqlcode rollback

define HUB_APP_ID = &1

alter session set container=FREEPDB1;

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

begin
  wwv_flow_imp_page.remove_page(
    p_flow_id => &HUB_APP_ID,
    p_page_id => 1
  );

  wwv_flow_imp_page.create_page(
    p_id                    => 1,
    p_name                  => 'Dashboard',
    p_alias                 => 'HOME',
    p_step_title            => 'The Hub',
    p_autocomplete_on_off   => 'OFF',
    p_step_template         => 4073832297226169690,
    p_page_template_options => '#DEFAULT#',
    p_protection_level      => 'C',
    p_page_component_map    => '13',
    p_inline_css            => q'~
.hub-dashboard {
  display: grid;
  gap: 16px;
  color: #111827;
}
.hub-hero-panel {
  position: relative;
  overflow: hidden;
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: 12px;
  align-items: start;
  border: 1px solid #dfe4ea;
  border-radius: 6px;
  background: #ffffff;
  padding: 18px 20px;
  box-shadow: 0 8px 20px rgba(20, 35, 50, 0.08);
}
.hub-hero-panel::after {
  content: "";
  position: absolute;
  inset: -42px -24px auto auto;
  width: 210px;
  height: 210px;
  background: url("#APP_FILES#brand/the-hub-logo.png") center / contain no-repeat;
  opacity: .075;
  pointer-events: none;
}
.hub-hero-copy,
.hub-window-controls {
  position: relative;
  z-index: 1;
}
.hub-brand-line {
  display: flex;
  gap: 12px;
  align-items: center;
}
.hub-brand-mark {
  width: 54px;
  height: 54px;
  object-fit: contain;
  flex: 0 0 auto;
}
.hub-hero-panel h1 {
  margin: 0;
  color: #111827;
  font-size: 1.55rem;
  line-height: 1.2;
  letter-spacing: 0;
}
.hub-hero-panel p {
  margin: 6px 0 0;
  color: #52606d;
}
.hub-window-controls {
  display: grid;
  grid-template-columns: minmax(10rem, 13rem) minmax(10rem, 13rem) auto;
  gap: 8px;
  align-items: end;
  max-width: 34rem;
  margin-top: 12px;
}
.hub-window-controls label {
  display: grid;
  gap: 4px;
  color: #52606d;
  font-size: .78rem;
  font-weight: 700;
}
.hub-window-controls input {
  min-height: 36px;
  border: 1px solid #cbd5df;
  border-radius: 4px;
  padding: 0 8px;
  color: #111827;
  background: #ffffff;
}
.hub-window-controls button {
  min-height: 36px;
  border: 1px solid #1f5eff;
  border-radius: 4px;
  padding: 0 13px;
  color: #ffffff;
  background: #1f5eff;
  font-weight: 700;
}
.hub-kpi-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(12rem, 1fr));
  gap: 12px;
}
.hub-kpi {
  min-height: 102px;
  border: 1px solid #dfe4ea;
  border-radius: 6px;
  background: #ffffff;
  padding: 14px 15px;
  box-shadow: 0 6px 16px rgba(20, 35, 50, 0.06);
}
.hub-kpi span {
  display: block;
  color: #52606d;
  font-size: .76rem;
  font-weight: 700;
  text-transform: uppercase;
}
.hub-kpi strong {
  display: block;
  margin-top: 8px;
  color: #111827;
  font-size: 2rem;
  line-height: 1;
}
.hub-kpi small {
  display: block;
  margin-top: 8px;
  color: #69737d;
}
.hub-kpi.is-danger {
  border-color: #efb8b8;
  background: #fffafa;
}
.hub-focus-grid {
  display: grid;
  grid-template-columns: minmax(0, 1.35fr) minmax(18rem, .65fr);
  gap: 12px;
}
.hub-panel {
  border: 1px solid #dfe4ea;
  border-radius: 6px;
  background: #ffffff;
  padding: 15px;
}
.hub-panel h2 {
  margin: 0 0 10px;
  font-size: 1rem;
  line-height: 1.25;
  letter-spacing: 0;
}
.hub-list {
  display: grid;
  gap: 0;
}
.hub-row {
  display: grid;
  grid-template-columns: 5.8rem minmax(0, 1fr) auto;
  gap: 10px;
  align-items: center;
  padding: 9px 0;
  border-top: 1px solid #edf0f2;
}
.hub-row:first-child {
  border-top: 0;
}
.hub-date {
  color: #52606d;
  font-variant-numeric: tabular-nums;
}
.hub-title {
  color: #111827;
  font-weight: 700;
}
.hub-meta {
  color: #69737d;
  font-size: .84rem;
}
.hub-pill {
  display: inline-flex;
  align-items: center;
  min-height: 22px;
  border-radius: 999px;
  padding: 0 8px;
  background: #eef4ff;
  color: #2355a3;
  font-size: .78rem;
  font-weight: 700;
}
.hub-pill.is-high {
  background: #fff0f0;
  color: #a12b2b;
}
.hub-state {
  color: #69737d;
}
/* mobile */ @media (max-width: 760px) {
  .hub-hero-panel,
  .hub-focus-grid,
  .hub-row {
    grid-template-columns: 1fr;
  }
  .hub-window-controls {
    grid-template-columns: minmax(0, 1fr);
    max-width: none;
  }
  .hub-brand-mark {
    width: 46px;
    height: 46px;
  }
}
~'
  );

  wwv_flow_imp_page.create_page_plug(
    p_id                    => wwv_flow_imp.id(to_number(to_char(&HUB_APP_ID) || '00010')),
    p_plug_name             => 'The Hub Dashboard',
    p_static_id             => 'the-hub-dashboard',
    p_region_template_options => '#DEFAULT#:t-Region--noPadding:t-Region--removeHeader',
    p_escape_on_http_output => 'N',
    p_plug_template         => 4073835273271169698,
    p_plug_display_sequence => 10,
    p_plug_display_point    => 'BODY',
    p_plug_item_display_point => 'ABOVE',
    p_plug_source           => q'~
<div class="hub-dashboard" id="hubDashboard">
  <section class="hub-hero-panel">
    <div class="hub-hero-copy">
      <div class="hub-brand-line">
        <img class="hub-brand-mark" src="#APP_FILES#brand/the-hub-logo.png" alt="">
        <h1>The Hub</h1>
      </div>
      <p>DBA planning command center for projects, milestones, coverage, meetings, and Oracle patch windows.</p>
      <div class="hub-window-controls">
        <label>Start <input id="hubPeriodStart" type="date"></label>
        <label>End <input id="hubPeriodEnd" type="date"></label>
        <button id="hubApplyWindow" type="button">Apply</button>
      </div>
    </div>
  </section>

  <section class="hub-kpi-grid" aria-live="polite">
    <div class="hub-kpi"><span>Active projects</span><strong id="hubActiveProjects">-</strong><small>overlaps selected window</small></div>
    <div class="hub-kpi"><span>Milestones</span><strong id="hubMilestones">-</strong><small>due in selected window</small></div>
    <div class="hub-kpi"><span>Leave hours</span><strong id="hubLeaveHours">-</strong><small>approved or planned</small></div>
    <div class="hub-kpi" id="hubConflictCard"><span>On-call conflicts</span><strong id="hubConflicts">-</strong><small>coverage weeks to review</small></div>
  </section>

  <section class="hub-focus-grid">
    <div class="hub-panel">
      <h2>Upcoming Milestones</h2>
      <div class="hub-list" id="hubMilestoneList"><div class="hub-state">Loading milestones...</div></div>
    </div>
    <div class="hub-panel">
      <h2>Planning Signal</h2>
      <p class="hub-meta">Next patch marker</p>
      <div class="hub-title" id="hubNextPatch">Loading...</div>
      <p class="hub-meta" id="hubUpdatedAt"></p>
    </div>
  </section>
</div>

<script>
(function () {
  const startInput = document.getElementById('hubPeriodStart');
  const endInput = document.getElementById('hubPeriodEnd');
  const applyButton = document.getElementById('hubApplyWindow');
  const text = (id, value) => { document.getElementById(id).textContent = value; };
  const esc = (value) => String(value == null ? '' : value).replace(/[<>"']/g, function (c) {
    return {'<':'\u0026lt;','>':'\u0026gt;','"':'\u0026quot;',"'":'\u0026#39;'}[c];
  });
  const iso = (date) => date.toISOString().slice(0, 10);
  const today = new Date();
  const start = new Date(today.getFullYear(), today.getMonth(), 1);
  const end = new Date(today.getFullYear(), today.getMonth() + 3, 0);
  const amp = String.fromCharCode(38);

  startInput.value = iso(start);
  endInput.value = iso(end);

  function renderMilestones(rows) {
    const list = document.getElementById('hubMilestoneList');
    if (!rows || rows.length === 0) {
      list.innerHTML = '<div class="hub-state">No milestones in this window.</div>';
      return;
    }
    list.innerHTML = rows.map(function (row) {
      const priority = esc(row.priority || 'Normal');
      const high = priority.toLowerCase() === 'high' ? ' is-high' : '';
      return '<div class="hub-row"><div class="hub-date">' + esc(row.milestone_date_label) + '</div><div><div class="hub-title">' + esc(row.milestone_name) + '</div><div class="hub-meta">' + esc(row.project_id) + '</div></div><span class="hub-pill' + high + '">' + priority + '</span></div>';
    }).join('');
  }

  async function loadDashboard() {
    const url = '/ords/thehub/dashboard/summary?period_start=' + encodeURIComponent(startInput.value) + amp + 'period_end=' + encodeURIComponent(endInput.value);
    const response = await fetch(url, { headers: { 'Accept': 'application/json' } });
    if (!response.ok) {
      throw new Error('Dashboard service returned ' + response.status);
    }
    const data = await response.json();
    text('hubActiveProjects', data.active_projects ?? 0);
    text('hubMilestones', data.milestones_in_period ?? 0);
    text('hubLeaveHours', data.leave_hours ?? 0);
    text('hubConflicts', data.on_call_conflicts ?? 0);
    text('hubNextPatch', data.next_patch || 'No future patch rows found');
    text('hubUpdatedAt', 'Window: ' + startInput.value + ' to ' + endInput.value);
    document.getElementById('hubConflictCard').classList.toggle('is-danger', Number(data.on_call_conflicts || 0) > 0);
    renderMilestones(data.milestones);
  }

  applyButton.addEventListener('click', function () {
    text('hubNextPatch', 'Loading...');
    document.getElementById('hubMilestoneList').innerHTML = '<div class="hub-state">Loading milestones...</div>';
    loadDashboard().catch(function (error) {
      document.getElementById('hubMilestoneList').innerHTML = '<div class="hub-state">' + esc(error.message) + '</div>';
    });
  });

  loadDashboard().catch(function (error) {
    document.getElementById('hubMilestoneList').innerHTML = '<div class="hub-state">' + esc(error.message) + '</div>';
  });
}());
</script>
~',
    p_attributes            => wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
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

prompt The Hub dashboard page build complete.
