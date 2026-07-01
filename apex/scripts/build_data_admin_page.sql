-- Build The Hub Data Admin page with an authenticated APEX AJAX CRUD callback.
--
-- Usage:
--   @build_data_admin_page.sql 101
--   @build_data_admin_page.sql 100

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
    p_page_id => 20
  );

  wwv_flow_imp_page.create_page(
    p_id                    => 20,
    p_name                  => 'Data Admin',
    p_alias                 => 'DATA-ADMIN',
    p_step_title            => 'Data Admin',
    p_autocomplete_on_off   => 'OFF',
    p_step_template         => 4073832297226169690,
    p_page_template_options => '#DEFAULT#',
    p_protection_level      => 'C',
    p_page_component_map    => '13',
    p_javascript_code       => q'~
function hubBootDataAdmin() {
  if (window.hubDataAdminStarted) {
    return;
  }
  window.hubDataAdminStarted = true;

  const state = { catalog: [], active: null, rows: [], selected: null };
  const nav = document.getElementById('hubTableNav');
  const gridWrap = document.getElementById('hubGridWrap');
  const title = document.getElementById('hubTableTitle');
  const help = document.getElementById('hubTableHelp');
  const fields = document.getElementById('hubEditorFields');
  const editor = document.getElementById('hubEditorForm');
  const newButton = document.getElementById('hubNew');
  const refreshButton = document.getElementById('hubRefresh');
  const deleteButton = document.getElementById('hubDelete');
  const saveButton = document.getElementById('hubSave');
  const entity = String.fromCharCode(38);
  const esc = (v) => String(v == null ? '' : v).replace(/[<>"']/g, c => ({
    '<': entity + 'lt;',
    '>': entity + 'gt;',
    '"': entity + 'quot;',
    "'": entity + '#39;'
  }[c]));
  const fail = (target, error) => {
    target.innerHTML = '<div class="hub-state">' + esc(error ? (error.message ? error.message : error) : 'Unknown error') + '</div>';
  };
  const call = (action, data) => {
    if (!window.apex || !window.apex.server) {
      return Promise.reject(new Error('APEX server API is not ready. Refresh the page and sign in again if needed.'));
    }
    return window.apex.server.process('THEHUB_ADMIN_API', Object.assign({x01: action}, data || {}), {dataType: 'json'});
  };
  const display = (value) => value == null ? '' : String(value).slice(0, 120);
  const columnInputType = (col) => col.type === 'DATE' ? 'date' : col.type === 'NUMBER' ? 'number' : 'text';
  const pkColumn = () => state.active ? (state.active.columns[0] ? state.active.columns[0].name : null) : null;

  if (!nav || !gridWrap || !title || !help || !fields || !editor) {
    return;
  }

  function byGroups(tables) {
    return tables.reduce((groups, table) => {
      (groups[table.group] = groups[table.group] || []).push(table);
      return groups;
    }, {});
  }

  function renderNav() {
    const groups = byGroups(state.catalog);
    nav.innerHTML = Object.keys(groups).map(group => (
      '<div class="hub-table-group">' + esc(group) + '</div>' +
      groups[group].map(table => '<button type="button" class="hub-table-button' + (state.active ? (state.active.key === table.key ? ' is-active' : '') : '') + '" data-table="' + esc(table.key) + '"><span>' + esc(table.label) + '</span></button>').join('')
    )).join('');
    nav.querySelectorAll('button').forEach(button => button.addEventListener('click', () => selectTable(button.dataset.table)));
  }

  function renderGrid() {
    if (!state.active) return;
    const cols = state.active.columns.slice(0, 8);
    if (!state.rows.length) {
      gridWrap.innerHTML = '<div class="hub-state">No rows found.</div>';
      return;
    }
    gridWrap.innerHTML = '<table class="hub-grid"><thead><tr>' + cols.map(c => '<th>' + esc(c.label) + '</th>').join('') + '</tr></thead><tbody>' +
      state.rows.map((row, i) => '<tr data-index="' + i + '"' + (state.selected === row ? ' class="is-selected"' : '') + '>' + cols.map(c => '<td>' + esc(display(row[c.name])) + '</td>').join('') + '</tr>').join('') +
      '</tbody></table>';
    gridWrap.querySelectorAll('tbody tr').forEach(tr => tr.addEventListener('click', () => editRow(state.rows[Number(tr.dataset.index)])));
  }

  function renderEditor(row) {
    const current = row || {};
    fields.innerHTML = state.active.columns.map(col => {
      const value = current[col.name] == null ? '' : String(current[col.name]).slice(0, 10);
      const readonly = col.generated ? (current[col.name] ? '' : ' readonly') : '';
      const required = col.required ? ' required' : '';
      const longText = col.name.indexOf('NOTES') >= 0 || col.name.indexOf('GUIDANCE') >= 0 || col.name.indexOf('MITIGATION') >= 0;
      const input = longText
        ? '<textarea name="' + esc(col.name) + '"' + readonly + required + '>' + esc(current[col.name] || '') + '</textarea>'
        : '<input name="' + esc(col.name) + '" type="' + columnInputType(col) + '" value="' + esc(value) + '"' + readonly + required + '>';
      return '<div class="hub-field"><label>' + esc(col.label) + '</label>' + input + '</div>';
    }).join('');
    if (deleteButton) {
      deleteButton.disabled = !row;
    }
  }

  function editRow(row) {
    state.selected = row;
    renderGrid();
    renderEditor(row);
  }

  async function loadRows() {
    if (!state.active) return;
    gridWrap.innerHTML = '<div class="hub-state">Loading rows...</div>';
    try {
      const data = await call('rows', {x02: state.active.key});
      if (data ? data.ok === false : false) {
        throw new Error(data.error || 'Unable to load rows.');
      }
      state.rows = data.rows || [];
      state.selected = null;
      renderGrid();
      renderEditor(null);
    } catch (error) {
      fail(gridWrap, error);
    }
  }

  async function selectTable(key) {
    if (!state.catalog.length) {
      gridWrap.innerHTML = '<div class="hub-state">Loading table metadata...</div>';
      return;
    }
    state.active = state.catalog.find(table => table.key === key);
    if (!state.active) {
      gridWrap.innerHTML = '<div class="hub-state">Unknown table: ' + esc(key) + '</div>';
      return;
    }
    title.textContent = state.active.label;
    help.textContent = state.active.group + ' / ' + state.active.table_name;
    renderNav();
    await loadRows();
  }

  function payloadFromEditor() {
    const payload = {};
    editor.querySelectorAll('input, textarea, select').forEach(item => {
      if (item.name) {
        payload[item.name] = item.value;
      }
    });
    return payload;
  }

  if (saveButton) {
    saveButton.addEventListener('click', async function () {
    if (!state.active) return;
    const payload = payloadFromEditor();
    await call('save', {x02: state.active.key, p_clob_01: JSON.stringify(payload)});
    await loadRows();
    });
  }

  if (newButton) {
    newButton.addEventListener('click', () => {
      state.selected = null;
      renderEditor(null);
    });
  }
  if (refreshButton) {
    refreshButton.addEventListener('click', loadRows);
  }
  if (deleteButton) {
    deleteButton.addEventListener('click', async function () {
      if (!state.active || !state.selected) return;
      const pk = pkColumn();
      await call('delete', {x02: state.active.key, x03: state.selected[pk]});
      await loadRows();
    });
  }

  nav.querySelectorAll('button[data-table]').forEach(button => {
    button.addEventListener('click', () => selectTable(button.dataset.table));
  });

  call('catalog').then(data => {
    if (data ? data.ok === false : false) {
      throw new Error(data.error || 'Unable to load table catalog.');
    }
    state.catalog = data.tables || [];
    renderNav();
    if (state.catalog.length) {
      selectTable(state.catalog[0].key);
    }
  }).catch(error => {
    fail(nav, error);
  });
}
~',
    p_javascript_code_onload => q'~
hubBootDataAdmin();
~',
    p_inline_css            => q'~
.hub-admin {
  display: grid;
  grid-template-columns: minmax(13rem, 18rem) minmax(0, 1fr);
  gap: 14px;
  color: #111827;
}
.hub-admin-sidebar,
.hub-admin-main,
.hub-admin-editor {
  border: 1px solid #dfe4ea;
  border-radius: 6px;
  background: #ffffff;
}
.hub-admin-sidebar {
  padding: 10px;
}
.hub-admin-main {
  min-width: 0;
  overflow: hidden;
}
.hub-admin-editor {
  padding: 14px;
}
.hub-admin-logo {
  width: 58px;
  height: 58px;
  object-fit: contain;
}
.hub-admin-title {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 14px;
  border-bottom: 1px solid #edf0f2;
}
.hub-admin-title h1 {
  margin: 0;
  font-size: 1.25rem;
  line-height: 1.2;
}
.hub-admin-title p,
.hub-admin-muted {
  margin: 3px 0 0;
  color: #64707d;
  font-size: .86rem;
}
.hub-table-group {
  margin: 10px 0 6px;
  color: #64707d;
  font-size: .74rem;
  font-weight: 800;
  text-transform: uppercase;
}
.hub-table-button {
  display: flex;
  width: 100%;
  min-height: 34px;
  align-items: center;
  justify-content: space-between;
  border: 0;
  border-radius: 4px;
  background: transparent;
  color: #111827;
  padding: 0 8px;
  text-align: left;
  font-weight: 700;
}
.hub-table-button:hover,
.hub-table-button.is-active {
  background: #eef4ff;
  color: #184ea3;
}
.hub-toolbar {
  display: flex;
  gap: 8px;
  align-items: center;
  justify-content: space-between;
  padding: 12px 14px;
  border-bottom: 1px solid #edf0f2;
}
.hub-toolbar h2 {
  margin: 0;
  font-size: 1rem;
}
.hub-actions {
  display: flex;
  gap: 8px;
}
.hub-actions button,
.hub-admin-editor button {
  min-height: 34px;
  border: 1px solid #cbd5df;
  border-radius: 4px;
  background: #ffffff;
  color: #111827;
  padding: 0 11px;
  font-weight: 800;
}
.hub-actions button.is-primary,
.hub-admin-editor button.is-primary {
  border-color: #1f5eff;
  background: #1f5eff;
  color: #ffffff;
}
.hub-admin-editor button.is-danger {
  border-color: #c43a3a;
  color: #a12b2b;
}
.hub-grid-wrap {
  overflow: auto;
  max-height: 58vh;
}
.hub-grid {
  width: 100%;
  border-collapse: collapse;
  font-size: .86rem;
}
.hub-grid th,
.hub-grid td {
  border-bottom: 1px solid #edf0f2;
  padding: 8px 10px;
  text-align: left;
  white-space: nowrap;
}
.hub-grid th {
  position: sticky;
  top: 0;
  background: #f8fafc;
  color: #52606d;
  font-size: .72rem;
  text-transform: uppercase;
}
.hub-grid tr {
  cursor: pointer;
}
.hub-grid tr:hover,
.hub-grid tr.is-selected {
  background: #f4f7fb;
}
.hub-editor-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(13rem, 1fr));
  gap: 10px;
}
.hub-field {
  display: grid;
  gap: 4px;
}
.hub-field label {
  color: #52606d;
  font-size: .76rem;
  font-weight: 800;
}
.hub-field input,
.hub-field textarea {
  width: 100%;
  min-height: 35px;
  border: 1px solid #cbd5df;
  border-radius: 4px;
  padding: 7px 8px;
  color: #111827;
  background: #ffffff;
}
.hub-field textarea {
  min-height: 74px;
  resize: vertical;
}
.hub-editor-actions {
  display: flex;
  gap: 8px;
  justify-content: flex-end;
  margin-top: 12px;
}
.hub-state {
  padding: 16px;
  color: #64707d;
}
/* mobile */ @media (max-width: 900px) {
  .hub-admin {
    grid-template-columns: 1fr;
  }
  .hub-grid-wrap {
    max-height: none;
  }
}
~'
  );

  wwv_flow_imp_page.create_page_plug(
    p_id                    => wwv_flow_imp.id(to_number(to_char(&HUB_APP_ID) || '200010')),
    p_plug_name             => 'The Hub Data Admin',
    p_static_id             => 'the-hub-data-admin',
    p_region_template_options => '#DEFAULT#:t-Region--noPadding:t-Region--removeHeader',
    p_escape_on_http_output => 'N',
    p_plug_template         => 4073835273271169698,
    p_plug_display_sequence => 10,
    p_plug_display_point    => 'BODY',
    p_plug_source           => q'~
<div class="hub-admin" id="hubAdmin">
  <aside class="hub-admin-sidebar">
    <div class="hub-admin-title">
      <img class="hub-admin-logo" src="#APP_FILES#brand/the-hub-logo.png" alt="">
      <div>
        <h1>Data Admin</h1>
        <p>Maintain operational data and lookup values.</p>
      </div>
    </div>
    <div id="hubTableNav">
      <div class="hub-table-group">Lookup Values</div>
      <button type="button" class="hub-table-button" data-table="cadences"><span>Cadences</span></button>
      <button type="button" class="hub-table-button" data-table="categories"><span>Categories</span></button>
      <button type="button" class="hub-table-button" data-table="goals"><span>Goals</span></button>
      <button type="button" class="hub-table-button" data-table="meeting_statuses"><span>Meeting Statuses</span></button>
      <button type="button" class="hub-table-button" data-table="meeting_types"><span>Meeting Types</span></button>
      <button type="button" class="hub-table-button" data-table="priorities"><span>Priorities</span></button>
      <button type="button" class="hub-table-button" data-table="report_timeframes"><span>Report Timeframes</span></button>
      <button type="button" class="hub-table-button" data-table="statuses"><span>Statuses</span></button>
      <button type="button" class="hub-table-button" data-table="workstreams"><span>Workstreams</span></button>
      <div class="hub-table-group">Operational Data</div>
      <button type="button" class="hub-table-button" data-table="dependencies"><span>Dependencies</span></button>
      <button type="button" class="hub-table-button" data-table="leave"><span>Leave</span></button>
      <button type="button" class="hub-table-button" data-table="meetings"><span>Meetings</span></button>
      <button type="button" class="hub-table-button" data-table="milestones"><span>Milestones</span></button>
      <button type="button" class="hub-table-button" data-table="on_call"><span>On Call</span></button>
      <button type="button" class="hub-table-button" data-table="projects"><span>Projects</span></button>
      <button type="button" class="hub-table-button" data-table="risk_register"><span>Risk Register</span></button>
      <button type="button" class="hub-table-button" data-table="team_members"><span>Team Members</span></button>
      <div class="hub-table-group">Reference Calendars</div>
      <button type="button" class="hub-table-button" data-table="holidays"><span>Holidays</span></button>
      <button type="button" class="hub-table-button" data-table="holiday_notes"><span>Holiday Notes</span></button>
      <button type="button" class="hub-table-button" data-table="oracle_ru_calendar"><span>Oracle RU Calendar</span></button>
      <button type="button" class="hub-table-button" data-table="oracle_security_patches"><span>Security Patches</span></button>
    </div>
  </aside>

  <main class="hub-admin-main">
    <div class="hub-toolbar">
      <div>
        <h2 id="hubTableTitle">Select a table</h2>
        <p class="hub-admin-muted" id="hubTableHelp"></p>
      </div>
      <div class="hub-actions">
        <button type="button" id="hubRefresh">Refresh</button>
        <button type="button" class="is-primary" id="hubNew">New</button>
      </div>
    </div>
    <div class="hub-grid-wrap" id="hubGridWrap"><div class="hub-state">Choose a table to begin.</div></div>
  </main>

  <section class="hub-admin-editor">
    <div class="hub-toolbar">
      <div>
        <h2>Editor</h2>
        <p class="hub-admin-muted" id="hubEditorHint">Generated keys are filled by the database.</p>
      </div>
    </div>
    <div id="hubEditorForm">
      <div class="hub-editor-grid" id="hubEditorFields"></div>
      <div class="hub-editor-actions">
        <button type="button" class="is-danger" id="hubDelete">Delete</button>
        <button type="button" class="is-primary" id="hubSave">Save</button>
      </div>
    </div>
  </section>
</div>

~',
    p_attributes            => wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
      'expand_shortcuts', 'N',
      'output_as', 'HTML')).to_clob
  );

  wwv_flow_imp_page.create_page_process(
    p_id                    => wwv_flow_imp.id(to_number(to_char(&HUB_APP_ID) || '200020')),
    p_flow_id               => &HUB_APP_ID,
    p_flow_step_id          => 20,
    p_process_sequence      => 10,
    p_process_point         => 'ON_DEMAND',
    p_process_type          => 'NATIVE_PLSQL',
    p_process_name          => 'THEHUB_ADMIN_API',
    p_static_id             => 'THEHUB_ADMIN_API',
    p_process_sql_clob      => 'thehub.admin_api.handle_ajax;',
    p_process_clob_language => 'PLSQL',
    p_location              => 'LOCAL'
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
       and static_id = 'data-admin';

    wwv_flow_imp_shared.set_list_item_link_text(
      p_id        => l_entry_id,
      p_link_text => 'Data Admin'
    );
    wwv_flow_imp_shared.set_list_item_link_target(
      p_id          => l_entry_id,
      p_link_target => 'f?p=' || chr(38) || 'APP_ID.:20:' || chr(38) || 'APP_SESSION.::' || chr(38) || 'DEBUG.:::'
    );
    wwv_flow_imp_shared.set_list_item_sequence(
      p_id            => l_entry_id,
      p_item_sequence => 20
    );
  exception
    when no_data_found then
      wwv_flow_imp_shared.create_list_item(
        p_id                         => wwv_flow_imp.id(to_number(to_char(&HUB_APP_ID) || '200030')),
        p_list_id                    => l_list_id,
        p_list_item_display_sequence => 20,
        p_list_item_link_text        => 'Data Admin',
        p_static_id                  => 'data-admin',
        p_list_item_link_target      => 'f?p=' || chr(38) || 'APP_ID.:20:' || chr(38) || 'APP_SESSION.::' || chr(38) || 'DEBUG.:::',
        p_list_item_icon             => 'fa-table',
        p_list_item_current_type     => 'TARGET_PAGE',
        p_list_item_current_for_pages => '20'
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

prompt The Hub data admin page build complete.
