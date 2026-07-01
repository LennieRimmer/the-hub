# The Hub - Oracle APEX Build Guide

This guide turns the Hub schema and blueprint into a buildable Oracle APEX application named **The Hub**.

## 1) Pre-reqs

1. Oracle database/PDB with APEX and ORDS enabled.
2. Application schema user: `THEHUB`.
3. If `THEHUB` does not exist yet, run `thehub_user_bootstrap.sql` as `ADMIN` first.
4. SQL script loaded: `the_hub_schema_and_seed_data.sql`.
5. App Builder access in the same workspace/schema.

## 2) Run schema and seed script

Connect as `THEHUB` and execute `the_hub_schema_and_seed_data.sql` first.

Recommended setup flow:
1. Connect as `ADMIN` and run `thehub_user_bootstrap.sql`.
2. Connect as `THEHUB` and run `the_hub_schema_and_seed_data.sql`.
3. After build validation, connect as `ADMIN` and run `thehub_policy_promote_to_runtime.sql`.
4. Run `thehub_policy_verify.sql` to confirm final grants.

What it creates:
- Lookup/reference tables
- Core Phase 1 tables
- Phase 2 tables
- Starter views (`v_dashboard_kpis`, `v_leave_summary`, `v_coverage_risk_dates`, `v_goal_traceability`)
- `holiday_notes` for workbook annotation rows that are not date records

## 3) Existing app shell

The current environment already has the bootstrap app shell:

- Workspace: `THE_HUB`
- App ID: `100`
- Name: `The Hub`
- Alias: `THE-HUB`
- Parsing schema: `THEHUB`
- Authentication: APEX Accounts
- Theme: Universal Theme
- Runtime URL: `http://localhost:8181/ords/r/the_hub/the-hub`
- Builder URL: `http://localhost:8181/ords/apex`
- REST base URL: `http://localhost:8181/ords/thehub/`

Do not recreate or remove app `100` unless the APEXLANG export gate fails again and the recovery notes are updated first.

## 4) Source-Controlled APEXLANG Gate

The clean baseline exports as canonical split APEXLANG:

- ZIP: `apex/exports/thehub_app_100_apexlang.zip`
- Project directory: `apex/exports/thehub_app_100_apexlang/`

Export current app state with:

```bash
apex/scripts/export_app_100_apexlang_zip.sh
```

The older flattened export `apex/exports/thehub_app_100.apexlang` is inspection-only and is not an import package.

The container includes SQLcl 26.1.1 at:

```text
/opt/oracle/product/26ai/dbhomeFree/sqlcl/bin/sql
```

That SQLcl can generate and validate an APEX Liquibase package. Run:

```bash
apex/scripts/export_app_100_liquibase.sh
```

Generated gate artifacts:

- `apex/exports/thehub_app_100_liquibase/apex_install.xml`
- `apex/exports/thehub_app_100_liquibase/f100.sql`

The host SQLcl versions found earlier can export APEXLANG but do not expose the needed validate/import commands. Use the container SQLcl gate for command-line validation.

## 5) Shared components to create first

Create these List of Values (Shared Components -> List of Values):

- `LOV_STATUSES`
- `LOV_PRIORITIES`
- `LOV_WORKSTREAMS`
- `LOV_CATEGORIES`
- `LOV_GOALS`
- `LOV_TEAM_MEMBERS`

Use the SQL in `apex/hub_apex_region_sql.sql` under **Shared LOV SQL**.

## 6) Build Phase 1 pages

## Page 1 - Dashboard

Page type: Blank.

Current implementation:

- Static APEX page shell for export-safe APEXLANG.
- Client-side date controls.
- ORDS JSON endpoint for KPI and milestone data: `/ords/thehub/dashboard/summary`.
- Endpoint install script: `apex/scripts/install_dashboard_rest.sql`.
- Page build script: `apex/scripts/build_dashboard_page.sql`.

Build/update sequence:

1. Run `apex/scripts/install_dashboard_rest.sql`.
2. Run `apex/scripts/build_dashboard_page.sql 101` against disposable app `101`.
3. Verify app `101` exports as APEXLANG.
4. Run `apex/scripts/build_dashboard_page.sql 100`.
5. Export app `100` and verify the page still exports as APEXLANG.

Reason for this pattern: direct APEX dynamic PL/SQL region metadata caused APEXLANG export failures in disposable testing. The static shell plus ORDS data endpoint preserves exportability while still giving the dashboard live data.

## Page 2 - Projects

Page type: Report -> Interactive Report on `projects`.

Columns to enable filters/sorts:
- `project_id`, `initiative`, `owner`, `status`, `priority`, `goal`, `start_date`, `finish_date`, `go_live_flag`

Form page:
- Add modal form for create/edit/delete.
- Use LOVs:
  - `status` -> `LOV_STATUSES`
  - `priority` -> `LOV_PRIORITIES`
  - `workstream` -> `LOV_WORKSTREAMS`
  - `category` -> `LOV_CATEGORIES`
  - `goal` -> `LOV_GOALS`

## Page 3 - Milestones

Page type: Interactive Report + modal form on `milestones`.

Recommended form item setup:
- `milestone_date`: Date Picker
- `priority`: LOV from `LOV_PRIORITIES`
- Keep `project_id` free text (intentional, supports ORA-MRP/ORA-SEC buckets)

## Page 4 - Leave Calendar

Page type: Calendar (Month)

Source SQL: Leave calendar SQL from `apex/hub_apex_region_sql.sql`.

Calendar mapping:
- Display Column: `title`
- Start Date: `start_date`
- End Date: `end_date`
- CSS Class: `css_class`

## Page 5 - On-Call Calendar

Page type: Calendar (Month/Week)

Source SQL: On-call calendar SQL from `apex/hub_apex_region_sql.sql`.

Highlight conflicts:
- `conflict_flag = Yes` is already mapped to `apex-cal-red`.

## Page 6 - Meetings

Add two regions:
1. Calendar region using Meetings calendar SQL.
2. Interactive Report using Meetings report SQL.

Use `include_flag = Yes` for calendar visibility.

## 7) Navigation

Create a navigation menu in this order:
1. Dashboard
2. Projects
3. Milestones
4. Leave Calendar
5. On-Call Calendar
6. Meetings

## 8) Authorization and data quality checks

1. Restrict DML pages to admin role/group first.
2. Add validations:
- `projects.start_date <= projects.finish_date`
- `on_call.week_start <= week_end`
- `leave.hours <> 0`

## 9) Build Phase 2 pages

After Phase 1 works, add:
1. Patch Calendar / Timeline (`oracle_ru_calendar`, `oracle_security_patches`)
2. Risk Register (`risk_register`)
3. Dependencies (`dependencies`)

Starter SQL is included in `apex/hub_apex_region_sql.sql`.

## 10) Smoke test checklist

1. Dashboard period picker refreshes all KPI/report regions.
2. Projects create/edit/delete works.
3. Milestones report filters by date and project.
4. Leave calendar renders all leave events.
5. On-call calendar highlights conflict weeks.
6. Meetings calendar includes only `include_flag = Yes` rows.
7. No runtime errors from missing LOVs or invalid date binds.

## 11) Suggested next build (Phase 3)

1. Roadmap timeline page (projects + milestones).
2. Resource heatmap (leave entries pivot by person/week).
3. Goal traceability report (`v_goal_traceability`).
4. Admin page for lookup table maintenance.
