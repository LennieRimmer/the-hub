--------------------------------------------------------------------------
-- THE HUB - Verify THEHUB user, roles, and effective system privileges
-- Run as ADMIN.
--------------------------------------------------------------------------

SET PAGESIZE 200
SET LINESIZE 200

PROMPT === User Status ===
SELECT username, account_status, default_tablespace, temporary_tablespace
FROM dba_users
WHERE username = 'THEHUB';

PROMPT === Role Grants ===
SELECT granted_role, admin_option, default_role
FROM dba_role_privs
WHERE grantee = 'THEHUB'
ORDER BY granted_role;

PROMPT === Direct System Privileges ===
SELECT privilege
FROM dba_sys_privs
WHERE grantee = 'THEHUB'
ORDER BY privilege;

PROMPT === Role System Privileges ===
SELECT rsp.role, rsp.privilege
FROM role_sys_privs rsp
WHERE rsp.role IN ('THEHUB_BUILD_ROLE','THEHUB_RUNTIME_ROLE')
ORDER BY rsp.role, rsp.privilege;
