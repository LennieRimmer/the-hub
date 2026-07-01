-- Save The Hub blueprint seed in the APEX blueprint repository.
-- Run as SYS/SYSTEM in FREEPDB1 or another user that can execute APEX metadata APIs.

ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT ON

DECLARE
  l_workspace_id NUMBER;
BEGIN
  SELECT workspace_id
    INTO l_workspace_id
    FROM apex_workspaces
   WHERE workspace = 'THE_HUB';

  apex_util.set_security_group_id(l_workspace_id);

  DELETE FROM apex_260100.wwv_flow_blueprint_repo
   WHERE security_group_id = l_workspace_id
     AND name = 'The Hub';

  apex_260100.wwv_flow_blueprint_v3.save_blueprint(
    p_built_with_love       => 'N',
    p_learn_app_def         => 'Y',
    p_app_name              => 'The Hub',
    p_app_short_desc        => 'DBA planning and operations dashboard',
    p_app_desc              => 'A modern APEX console for DBA project planning, milestones, leave, on-call coverage, meetings, patch calendars, risk, and dependencies.',
    p_features              => 'activity-report:access-control:feedback',
    p_theme_style           => 'Vita',
    p_nav_position          => 'SIDE',
    p_app_icon_class        => 'fa-table-dashboard',
    p_app_color_hex         => '#2F6FED',
    p_base_table_prefix     => NULL,
    p_primary_language      => 'en',
    p_translated_langs      => NULL,
    p_authentication        => 'APEX',
    p_app_version           => '0.1.0',
    p_app_logging           => 'Y',
    p_app_debugging         => 'N',
    p_date_format           => 'YYYY-MM-DD',
    p_date_time_format      => 'YYYY-MM-DD HH24:MI',
    p_timestamp_format      => 'YYYY-MM-DD HH24:MI:SS',
    p_timestamp_tz_format   => 'YYYY-MM-DD HH24:MI:SS TZH:TZM',
    p_deep_linking          => 'N',
    p_max_session_length    => 28800,
    p_max_session_idle_time => 3600,
    p_page_count            => 9,
    p_feature_count         => 3
  );

  DBMS_OUTPUT.PUT_LINE('Saved The Hub blueprint seed for workspace THE_HUB.');
END;
/
