-- Verify The Hub APEX seed application and supporting metadata.

ALTER SESSION SET CONTAINER = FREEPDB1;
SET PAGESIZE 200 LINESIZE 220 TRIMSPOOL ON

COLUMN workspace FORMAT A20
COLUMN application_name FORMAT A40
COLUMN alias FORMAT A30
COLUMN owner FORMAT A20
COLUMN parsing_schema FORMAT A20
COLUMN page_name FORMAT A40

SELECT workspace,
       application_id,
       application_name,
       alias,
       owner
  FROM apex_applications
 WHERE application_id = 100;

SELECT application_id,
       page_id,
       page_name
  FROM apex_application_pages
 WHERE application_id = 100
 ORDER BY page_id;

SELECT COUNT(*) AS thehub_tables
  FROM dba_tables
 WHERE owner = 'THEHUB';

SELECT COUNT(*) AS saved_blueprints
  FROM apex_260100.wwv_flow_blueprint_repo
 WHERE security_group_id = (
       SELECT workspace_id
         FROM apex_workspaces
        WHERE workspace = 'THE_HUB'
       )
   AND name = 'The Hub';

EXIT

