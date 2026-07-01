# The Hub APEX Blueprint

The Hub is a DBA planning and operations application for project tracking, milestone planning, leave visibility, on-call coverage, recurring meetings, Oracle patch calendars, risk, and dependency management.

The app should feel like a modern operations console: dense enough for repeated DBA use, visually calm, and refined without becoming decorative. It should avoid the flat, legacy APEX look by using consistent spacing, strong page hierarchy, restrained color, and dashboard summaries that help users decide what needs attention.

## Build Strategy

The initial app shell was created in APEX App Builder as application `100` in workspace `THE_HUB`, parsing schema `THEHUB`.

After this bootstrap, changes should be driven from source-controlled artifacts where practical:

- `apex/the_hub_blueprint.md`: human blueprint and design intent.
- `apex/the_hub_blueprint.apex.json`: APEX Create App blueprint seed.
- `apex/hub_apex_region_sql.sql`: SQL library for regions, calendars, reports, and LOVs.
- `apex/exports/thehub_app_100_apexlang.zip`: canonical APEXLANG export archive for app `100`.
- `apex/exports/thehub_app_100_apexlang/`: expanded APEXLANG project directory.
- `apex/scripts/export_app_100_apexlang_zip.sh`: exports app `100` into the canonical ZIP and project directory.
- `apex/scripts/export_app_100_liquibase.sh`: exports app `100` through container SQLcl 26.1.1 as an APEX Liquibase package and validates it.
- `apex/scripts/save_blueprint_seed.sql`: saves the blueprint seed into the APEX blueprint repository.

The GUI remains acceptable for first-contact app setup, theme style inspection, and visual checks. Routine work should prefer APEXLANG exports, source-controlled edits, and a validation/import gate through SQL Developer Extension or a SQLcl/APEX Developer Tools build that supports APEXLANG validation and import.

Do not use low-level `wwv_flow_imp_page` scripts against app `100` for normal feature work. The first direct metadata attempt left the app in a state where APEXLANG export failed, so Page 1 and later pages should be changed through importable APEXLANG artifacts.

## Information Architecture

### Phase 1

Page 1: Dashboard

Status: implemented as the first dashboard increment. Page 1 uses export-safe static APEX metadata for the visual shell and loads live KPI/milestone data from ORDS endpoint `/ords/thehub/dashboard/summary`.

- Purpose: single command center for the next planning window.
- Items: `P1_PERIOD_START`, `P1_PERIOD_END`.
- Regions:
  - Planning Window date controls.
  - KPI cards loaded from ORDS.
  - Upcoming milestone focus list loaded from ORDS.
  - Planning signal panel for the next patch marker.
- Data sources: `projects`, `milestones`, `leave`, `on_call`, `meetings`, `team_members`.

Page 2: Projects

- Purpose: primary project inventory and status management.
- Region: Interactive Report over `projects`.
- Form: modal edit/create page.
- Important filters: status, priority, workstream, goal, go-live flag, owner.

Page 3: Milestones

- Purpose: planning date backbone across projects, patch cycles, go-lives, and change windows.
- Region: Interactive Report over `milestones`.
- Form: modal edit/create page.
- Important filters: milestone date, project, type, priority, owner.

Page 4: Leave Calendar

- Purpose: show DBA availability by day and identify future capacity pressure.
- Region: Calendar over `leave`.
- Visual rules:
  - Approved/planned leave: blue.
  - Unplanned leave: red.

Page 5: On-Call Calendar

- Purpose: show weekly coverage and conflict weeks.
- Region: Calendar over `on_call`.
- Visual rules:
  - Normal coverage: green.
  - Conflict weeks: red.

Page 6: Meetings

- Purpose: one view for recurring DBA meetings and reportable meeting load.
- Regions:
  - Calendar for included meetings.
  - Interactive Report for all meeting rows.

### Phase 2

Page 7: Patch Calendar

- Purpose: operational planning around Oracle RU, MRP, and security patch cycles.
- Region: timeline/report over `oracle_security_patches` and later `oracle_ru_calendar`.

Page 8: Risk Register

- Purpose: visible project risk and mitigation management.
- Region: Interactive Report with modal form over `risk_register`.

Page 9: Dependencies

- Purpose: show predecessor/successor planning relationships.
- Region: Interactive Report with modal form over `dependencies`.

### Phase 3

Page 10: Roadmap

- Purpose: timeline view of projects and milestone pressure.
- Sources: `projects`, `milestones`.

Page 11: Resource Heatmap

- Purpose: availability and load scan by week/person.
- Sources: `leave`, `on_call`, later project ownership/load.

Page 12: Goal Traceability

- Purpose: executive trace from goals to projects and milestone dates.
- Source: `v_goal_traceability`.

Page 13: Admin

- Purpose: maintain lookup values without editing raw tables directly.
- Sources: `statuses`, `priorities`, `workstreams`, `categories`, `goals`, `meeting_statuses`, `meeting_types`, `cadences`, `report_timeframes`.

## Visual Direction

The app should use Universal Theme, but with a composed visual layer:

- Layout: side navigation, compact page titles, dashboard-first landing.
- Density: operational, scan-friendly tables and cards; avoid oversized marketing-style regions.
- Palette: neutral page surface, white report surfaces, black/slate text, restrained accent colors for priority and state.
- Status color language:
  - Red: conflicts, high risk, cancelled/problem states.
  - Green: healthy coverage or completed/approved state.
  - Blue: planned informational events.
  - Amber: tentative, watch, medium risk.
- Typography: default Universal Theme font stack, no viewport-scaling type, no negative letter spacing.
- Components:
  - KPI cards should be compact and aligned in a single responsive row.
  - Tables should prioritize readable headings, useful default sort, and saved public reports.
  - Calendars should use meaningful CSS classes, not generic color noise.
  - Forms should use LOVs for controlled values and date pickers for dates.

## Data Quality Rules

Add validations as pages mature:

- `projects.start_date <= projects.finish_date`
- `on_call.week_start <= on_call.week_end`
- `leave.hours <> 0`
- `meetings.include_flag IN ('Yes','No')`
- `projects.go_live_flag IN ('Yes','No')`

## Verification Scenario

This repo and environment can handle the intended workflow when all checks pass:

1. Tables and seed data exist in schema `THEHUB`.
2. APEX workspace `THE_HUB` exists.
3. APEX application `100` exists.
4. Blueprint seed can be saved into APEX metadata.
5. Application `100` can be exported as canonical split APEXLANG.
6. Runtime URL responds through ORDS.
7. Schema `THEHUB` is REST enabled at `/ords/thehub/`.

Current verification notes:

- App `100` exports as `apex/exports/thehub_app_100_apexlang.zip`.
- Expanded project exists at `apex/exports/thehub_app_100_apexlang/`.
- Dashboard REST endpoint exists at `http://localhost:8181/ords/thehub/dashboard/summary`.
- Container SQLcl 26.1.1 is available at `/opt/oracle/product/26ai/dbhomeFree/sqlcl/bin/sql`.
- Container SQLcl generated and validated `apex/exports/thehub_app_100_liquibase/apex_install.xml`.
- Host SQLcl versions tested can export APEXLANG but do not expose `apex validate -input` or `apex import -input`.

Runtime URL:

`http://localhost:8181/ords/r/the_hub/the-hub`

Builder URL:

`http://localhost:8181/ords/apex`

REST base URL:

`http://localhost:8181/ords/thehub/`
