# The Hub — Build Plan
DBA Team Planning Dashboard (APEX), mapped from `DBA_Team_Planning_Workbook_V42`

## What carries over, and how

The workbook split things into 30 tabs partly because Excel formulas can't dynamically
filter or paginate — so it pre-built fixed "display slots" (150 rows here, 250 rows
there) and a whole control panel (`REPORT SETTINGS`) just to keep every tab's date
range in sync. APEX doesn't need any of that: one set of tables, a page-level date
range item, and Interactive Reports/Calendars that query live and paginate themselves.

So the 30 tabs collapse into **11 real tables + a handful of lookup tables**, with
everything else becoming an APEX page, view, or just a different filter on the same data.

| Workbook tab(s) | Becomes |
|---|---|
| PROJECTS | `projects` table |
| MILESTONES | `milestones` table |
| LEAVE DATA - EDIT ME | `leave` table |
| ON-CALL DATA - EDIT ME | `on_call` table |
| MEETINGS - EDIT ME | `meetings` table |
| HOLIDAYS | `holidays` table |
| Oracle RU Calendar | `oracle_ru_calendar` table |
| Oracle Security Patches | `oracle_security_patches` table |
| Risk Register | `risk_register` table |
| Dependencies | `dependencies` table |
| LISTS - EDIT ME | `statuses`, `priorities`, `workstreams`, `categories`, `goals`, `meeting_statuses`, `meeting_types`, `cadences`, `report_timeframes` lookup tables — editable via one Admin page instead of a raw grid |
| Executive Dashboard | **Page 1: Dashboard** — Cards region on `v_dashboard_kpis`, period picker drives every region on the page |
| Leave Summary | View `v_leave_summary`, shown as a region on the Dashboard / Leave page |
| Goal Traceability | View `v_goal_traceability`, shown as a region on the Dashboard / Projects page |
| DBA Leave Calendar | **Page: Leave Calendar** — APEX Calendar region on `leave` |
| On-Call Calendar | **Page: On-Call Calendar** — APEX Calendar region on `on_call`, conflict days highlighted |
| Meeting Calendar / DBA Meeting Report | **Page: Meetings** — Calendar + Interactive Report on `meetings`, filtered by `include_flag` |
| Change Calendar / Go-Live Calendar | Filtered views of `milestones` (`milestone_type` / `project.go_live_flag`), not separate tables |
| 18-Month Roadmap / Quarterly Planning | **Page: Roadmap** — Gantt/Timeline region over `projects` + `milestones`, period-driven instead of a fixed 18-month grid |
| Resource Heatmap | **Page: Resource Heatmap** — Matrix/Pivot region on `leave` (and later, project load) |
| On-Call Report | Filtered Interactive Report on `on_call` |
| PERIOD CALCS, CALC - Dashboard Events, CALC - Dashboard Milestones, REPORT SETTINGS | Not needed — replaced by one page-level date range item (`:P1_PERIOD_START`/`:P1_PERIOD_END`) that every region's SQL filters on |
| Workbook Map, Instructions | **Page: About / Help** (optional, low priority) |
| VBA - OPTIONAL | Not needed — APEX Dynamic Actions / Automations replace any macro logic |

## Phased build order

**Phase 1 — core data + dashboard (build first)**
- Tables: `team_members`, `projects`, `milestones`, `leave`, `on_call`, `meetings`, `holidays`
- Pages: Dashboard (cards + period picker), Projects, Milestones, Leave Calendar, On-Call Calendar, Meetings
- This alone mirrors the Executive Dashboard + the four tabs your team edits most (`LEAVE DATA`, `ON-CALL DATA`, `MEETINGS`, plus Projects/Milestones)

**Phase 2 — Oracle patch tracking + risk**
- Tables: `oracle_ru_calendar`, `oracle_security_patches`, `risk_register`, `dependencies`
- Pages: Patch Calendar (RU + CSPU/MRP combined timeline), Risk Register, Dependencies

**Phase 3 — analytics / roadmap views**
- Pages: Roadmap (Gantt), Resource Heatmap, Goal Traceability — all built on existing tables, no new data entry needed
- Admin page for managing the lookup tables (replaces `LISTS - EDIT ME`)

## What's in the SQL script

`the_hub_schema_and_seed_data.sql` creates **Phase 1 + Phase 2 tables and lookups**,
seeded with your actual workbook data (13 projects, ~95 milestones, 25 leave entries,
85 on-call weeks, 116 meetings, holidays, the full Oracle RU/security patch calendars,
4 risks, 5 dependencies), plus 4 starter views (`v_dashboard_kpis`, `v_leave_summary`,
`v_coverage_risk_dates`, `v_goal_traceability`).

Run it in SQL Developer Web (or via the Oracle Developer Tools VS Code extension /
sqlcl) against your ADB free container, then point APEX's "Create App from Table"
or App Builder at the tables/views to start laying out Phase 1 pages.

## Notable data-shape decisions

- **`projects.owner`** stayed free text (not a foreign key) — your data mixes real
  people ("David Barth") with team labels ("Enterprise Apps / DBA"), so a strict FK
  to `team_members` would reject half the rows.
- **`milestones.project_id`** is free text for the same reason — `ORA-MRP` and
  `ORA-SEC` are grouping buckets for patch-cycle milestones, not real rows in `projects`.
- **`leave.member_id` and `on_call.primary_member_id`** *are*
  foreign keys to `team_members`, since those are always one of your three DBAs.
