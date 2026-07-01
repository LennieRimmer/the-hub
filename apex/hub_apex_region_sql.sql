-- The Hub - APEX Region SQL Library
-- Use these SQL statements as region sources in Oracle APEX.
-- Bind variables assume page items named P1_PERIOD_START and P1_PERIOD_END.

--------------------------------------------------------------------------------
-- Shared defaults for period picker (Page 1)
--------------------------------------------------------------------------------
-- Default value expression for P1_PERIOD_START:
-- TRUNC(SYSDATE, 'MM')
-- Default value expression for P1_PERIOD_END:
-- LAST_DAY(ADD_MONTHS(TRUNC(SYSDATE, 'MM'), 2))

--------------------------------------------------------------------------------
-- Dashboard cards (Page 1, Cards or KPI regions)
--------------------------------------------------------------------------------

-- Card: Active Projects in Period
SELECT COUNT(*) AS value
FROM projects p
WHERE p.status = 'Active'
  AND NVL(p.finish_date, DATE '2999-12-31') >= :P1_PERIOD_START
  AND NVL(p.start_date, DATE '1900-01-01') <= :P1_PERIOD_END;

-- Card: Milestones in Period
SELECT COUNT(*) AS value
FROM milestones m
WHERE m.milestone_date BETWEEN :P1_PERIOD_START AND :P1_PERIOD_END;

-- Card: Leave Hours in Period
SELECT NVL(SUM(le.hours), 0) AS value
FROM leave le
WHERE le.leave_date BETWEEN :P1_PERIOD_START AND :P1_PERIOD_END
  AND NVL(le.status, 'Approved') <> 'Cancelled';

-- Card: On-Call Conflict Weeks in Period
SELECT COUNT(*) AS value
FROM on_call o
WHERE o.conflict_flag = 'Yes'
  AND o.week_start <= :P1_PERIOD_END
  AND o.week_end >= :P1_PERIOD_START;

--------------------------------------------------------------------------------
-- Dashboard report regions (Page 1)
--------------------------------------------------------------------------------

-- Upcoming milestones
SELECT m.project_id,
       m.milestone_name,
       m.milestone_date,
       m.category,
       m.milestone_type,
       m.owner,
       m.priority
FROM milestones m
WHERE m.milestone_date BETWEEN :P1_PERIOD_START AND :P1_PERIOD_END
ORDER BY m.milestone_date, m.priority DESC;

-- Meetings in period (include flag only)
SELECT m.meeting_date,
       m.start_time,
       m.meeting_name,
       m.workspace_project,
       m.audience_owner,
       m.cadence,
       m.meeting_type,
       m.status
FROM meetings m
WHERE m.include_flag = 'Yes'
  AND m.meeting_date BETWEEN :P1_PERIOD_START AND :P1_PERIOD_END
ORDER BY m.meeting_date, m.start_time;

-- Leave summary by person in period
SELECT tm.full_name,
       le.time_type,
       COUNT(*) AS entry_count,
       SUM(le.hours) AS total_hours
FROM leave le
JOIN team_members tm ON tm.member_id = le.member_id
WHERE le.leave_date BETWEEN :P1_PERIOD_START AND :P1_PERIOD_END
GROUP BY tm.full_name, le.time_type
ORDER BY tm.full_name, le.time_type;

--------------------------------------------------------------------------------
-- Projects page (Interactive Report)
--------------------------------------------------------------------------------
SELECT p.project_id,
       p.workstream,
       p.initiative,
       p.category,
       p.owner,
       p.start_date,
       p.finish_date,
       p.status,
       p.priority,
       p.goal,
       p.go_live_flag
FROM projects p
ORDER BY p.start_date, p.project_id;

--------------------------------------------------------------------------------
-- Milestones page (Interactive Report)
--------------------------------------------------------------------------------
SELECT m.milestone_id,
       m.project_id,
       m.milestone_name,
       m.milestone_date,
       m.category,
       m.milestone_type,
       m.owner,
       m.priority,
       m.notes
FROM milestones m
ORDER BY m.milestone_date, m.project_id;

--------------------------------------------------------------------------------
-- Leave calendar page (Calendar region)
--------------------------------------------------------------------------------
SELECT le.leave_id AS id,
       tm.full_name || ' - ' || le.time_type || ' (' || le.hours || 'h)' AS title,
       le.leave_date AS start_date,
       le.leave_date AS end_date,
       CASE
         WHEN le.status = 'Unplanned' THEN 'apex-cal-red'
         ELSE 'apex-cal-blue'
       END AS css_class,
       le.notes AS description
FROM leave le
JOIN team_members tm ON tm.member_id = le.member_id;

--------------------------------------------------------------------------------
-- On-call calendar page (Calendar region)
--------------------------------------------------------------------------------
SELECT o.on_call_id AS id,
       tm.full_name || ' on-call (Mon–Mon 8AM)' AS title,
       o.week_start AS start_date,
       o.week_end - 1 AS end_date,
       CASE
         WHEN o.conflict_flag = 'Yes' THEN 'apex-cal-red'
         ELSE 'apex-cal-green'
       END AS css_class,
       o.conflict_details AS description
FROM on_call o
LEFT JOIN team_members tm ON tm.member_id = o.primary_member_id;

--------------------------------------------------------------------------------
-- Meetings page (Calendar + Interactive Report)
--------------------------------------------------------------------------------

-- Meetings calendar
SELECT m.meeting_id AS id,
       m.meeting_name AS title,
       m.meeting_date AS start_date,
       m.meeting_date AS end_date,
       CASE
         WHEN m.status = 'Cancelled' THEN 'apex-cal-red'
         WHEN m.status = 'Tentative' THEN 'apex-cal-yellow'
         ELSE 'apex-cal-blue'
       END AS css_class,
       m.purpose_notes AS description
FROM meetings m
WHERE m.include_flag = 'Yes';

-- Meetings report
SELECT m.meeting_id,
       m.meeting_date,
       m.start_time,
       m.meeting_name,
       m.workspace_project,
       m.audience_owner,
       m.cadence,
       m.meeting_type,
       m.status,
       m.include_flag,
       m.report_rank,
       m.dashboard_rank
FROM meetings m
ORDER BY m.meeting_date, m.start_time;

--------------------------------------------------------------------------------
-- Optional Phase 2 page SQL
--------------------------------------------------------------------------------

-- Patch timeline report (can back a timeline chart)
SELECT release_date,
       release_month,
       patch_code,
       release_type,
       planning_use,
       guidance
FROM oracle_security_patches
ORDER BY release_date, patch_code;

-- Risk register page
SELECT risk_id,
       project_id,
       risk,
       probability,
       impact,
       mitigation
FROM risk_register
ORDER BY risk_id;

-- Dependencies page
SELECT dependency_id,
       predecessor,
       successor,
       notes
FROM dependencies
ORDER BY dependency_id;

--------------------------------------------------------------------------------
-- Shared LOV SQL
--------------------------------------------------------------------------------

-- LOV: Statuses
SELECT status_name AS display_value,
       status_name AS return_value
FROM statuses
ORDER BY sort_order;

-- LOV: Priorities
SELECT priority_name AS display_value,
       priority_name AS return_value
FROM priorities
ORDER BY sort_order;

-- LOV: Workstreams
SELECT workstream_name AS display_value,
       workstream_name AS return_value
FROM workstreams
ORDER BY sort_order;

-- LOV: Categories
SELECT category_name AS display_value,
       category_name AS return_value
FROM categories
ORDER BY sort_order;

-- LOV: Goals
SELECT goal_name AS display_value,
       goal_name AS return_value
FROM goals
ORDER BY sort_order;

-- LOV: Team members
SELECT full_name AS display_value,
       member_id AS return_value
FROM team_members
WHERE active_flag = 'Y'
ORDER BY full_name;
