# The Hub – DBA Support Runbook

**Environment:** WSL2 on Windows · Oracle Database Free 26ai · ORDS 26.1.2 · APEX 26.1.1  
**Last updated:** 2026-06-30  
**Purpose:** Reference for any DBA needing to rebuild, troubleshoot, or support The Hub application from scratch.

---

## 1. Environment Overview

| Component | Details |
|-----------|---------|
| Oracle Database | Oracle Database Free 26ai |
| DB Container | `oracle26ai-db` (Docker) |
| DB Port | 1521 (mapped to host) |
| PDB | `FREEPDB1` |
| ORDS Container | `ords26` (Docker) |
| ORDS Port | 8181 (mapped to host) |
| APEX Version | 26.1.1 |
| APEX URL | http://localhost:8181/ords/apex |
| APEX Admin URL | http://localhost:8181/ords/apex_admin |

---

## 2. Credentials Reference

Do not commit live passwords to this repository. Store local values in shell environment variables or in an untracked `.env` file.

Suggested variables:

| Variable | Purpose |
|----------|---------|
| `ORACLE_PWD` | SYS/SYSTEM password stored by the database container |
| `THEHUB_PASSWORD` | Application schema and workspace admin password |
| `THEHUB_CONNECT_STRING` | SQLcl/sqlplus connect string, for example `THEHUB/<password>@localhost:1521/FREEPDB1` |

You can confirm the container-side database password with:

```bash
docker exec oracle26ai-db printenv ORACLE_PWD
```

---

## 3. Connecting to the Database

### OS-authenticated SYSDBA (inside container – no password needed)
```bash
docker exec -it oracle26ai-db sqlplus / as sysdba
```
Then switch to the PDB:
```sql
ALTER SESSION SET CONTAINER = FREEPDB1;
```

### SQLcl from WSL2 host
```bash
# As SYS
sqlcl "sys/${ORACLE_PWD}@localhost:1521/FREEPDB1" as sysdba

# As application schema
sqlcl "${THEHUB_CONNECT_STRING}"
```
> **Tip:** The `!` character causes bash history expansion. Wrap passwords containing `!` in a shell script or use `set +H` first:
> ```bash
> set +H
> sqlcl "${THEHUB_CONNECT_STRING}"
> ```

### Oracle Developer Tools for VS Code
Install: `code --install-extension Oracle.oracledevtools`  
Connection settings:
- Hostname: `localhost`
- Port: `1521`
- Service Name: `FREEPDB1`
- Username: `THEHUB`
- Password: value of `THEHUB_PASSWORD`

---

## 4. Full Rebuild Procedure

Use this section to rebuild from scratch on a new database container.

### Step 1 – Verify the PDB is open

```bash
docker exec oracle26ai-db bash -c "sqlplus -S / as sysdba <<'EOF'
SELECT name, open_mode FROM v\$pdbs;
EXIT;
EOF"
```
Expected output: `FREEPDB1  READ WRITE`

If FREEPDB1 shows `MOUNTED`, open it:
```sql
ALTER PLUGGABLE DATABASE FREEPDB1 OPEN;
ALTER PLUGGABLE DATABASE FREEPDB1 SAVE STATE;
```

---

### Step 2 – Create the THEHUB schema user

Write the script to a file first to avoid bash `!` expansion issues:

```bash
cat > /tmp/thehub_create_user.sql << 'ENDSQL'
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT ON
SET ESCAPE OFF

DECLARE
  l_count NUMBER;
  l_pwd   VARCHAR2(100) := '&THEHUB_PASSWORD';
BEGIN
  SELECT COUNT(*) INTO l_count FROM dba_users WHERE username = 'THEHUB';
  IF l_count = 0 THEN
    EXECUTE IMMEDIATE 'CREATE USER THEHUB IDENTIFIED BY "' || l_pwd || '"';
    DBMS_OUTPUT.PUT_LINE('User THEHUB created.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('User THEHUB already exists.');
  END IF;
  EXECUTE IMMEDIATE 'GRANT CREATE SESSION TO THEHUB';
  EXECUTE IMMEDIATE 'ALTER USER THEHUB ACCOUNT UNLOCK';
  EXECUTE IMMEDIATE 'ALTER USER THEHUB QUOTA UNLIMITED ON USERS';
  EXECUTE IMMEDIATE 'GRANT CREATE TABLE, CREATE VIEW, CREATE SEQUENCE, '
    || 'CREATE PROCEDURE, CREATE TRIGGER, CREATE TYPE, CREATE JOB TO THEHUB';
  DBMS_OUTPUT.PUT_LINE('Grants complete.');
END;
/
EXIT;
ENDSQL

docker cp /tmp/thehub_create_user.sql oracle26ai-db:/tmp/thehub_create_user.sql
docker exec oracle26ai-db bash -c "sqlplus -S / as sysdba @/tmp/thehub_create_user.sql"
```

**Expected output:**
```
User THEHUB created.
Grants complete.
PL/SQL procedure successfully completed.
```

**Grants applied to THEHUB:**

| Privilege | Purpose |
|-----------|---------|
| `CREATE SESSION` | Allow login |
| `CREATE TABLE` | Schema object creation |
| `CREATE VIEW` | View creation |
| `CREATE SEQUENCE` | Sequence creation |
| `CREATE PROCEDURE` | Stored procedures/functions |
| `CREATE TRIGGER` | DML triggers |
| `CREATE TYPE` | Object types |
| `CREATE JOB` | DBMS_SCHEDULER jobs |
| `QUOTA UNLIMITED ON USERS` | Storage in USERS tablespace |

---

### Step 3 – Load schema and seed data

The schema DDL and all seed data are in `the_hub_schema_and_seed_data.sql`.

```bash
# Copy the file into the container
docker cp /home/oracle/hub/the_hub_schema_and_seed_data.sql \
  oracle26ai-db:/tmp/the_hub_schema_and_seed_data.sql

# Create a runner script (avoids ! quoting issues)
cat > /tmp/run_schema.sh << 'EOF'
#!/bin/bash
sqlplus -S "${THEHUB_CONNECT_STRING}" \
  @/tmp/the_hub_schema_and_seed_data.sql
EOF

docker cp /tmp/run_schema.sh oracle26ai-db:/tmp/run_schema.sh
docker exec oracle26ai-db bash /tmp/run_schema.sh 2>&1
```

**Verify the load:**
```bash
cat > /tmp/check_schema.sh << 'EOF'
#!/bin/bash
sqlplus -S "${THEHUB_CONNECT_STRING}" <<'ENDSQL'
SELECT table_name FROM user_tables ORDER BY 1;
SELECT COUNT(*) AS project_rows   FROM projects;
SELECT COUNT(*) AS milestone_rows FROM milestones;
SELECT COUNT(*) AS leave_rows     FROM leave;
EXIT;
ENDSQL
EOF
docker cp /tmp/check_schema.sh oracle26ai-db:/tmp/check_schema.sh
docker exec oracle26ai-db bash /tmp/check_schema.sh
```

**Expected results:**

| Object | Count |
|--------|-------|
| Tables | 21 |
| Projects | 13 |
| Milestones | 216 |

> **ORA-00955 errors on re-run are normal** – they mean objects already exist from a previous run. Data rows will be duplicated on re-run. To reset cleanly, drop and recreate the user (Step 2) before re-running Step 3.

---

### Step 4 – Create the APEX workspace

```bash
cat > /tmp/create_apex_workspace.sh << 'EOF'
#!/bin/bash
sqlplus -S / as sysdba <<'ENDSQL'
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT ON

DECLARE
  l_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO l_count
  FROM apex_workspaces
  WHERE workspace = 'THE_HUB';

  IF l_count = 0 THEN
    APEX_INSTANCE_ADMIN.ADD_WORKSPACE(
      p_workspace_id   => NULL,
      p_workspace      => 'THE_HUB',
      p_primary_schema => 'THEHUB'
    );
    DBMS_OUTPUT.PUT_LINE('Workspace THE_HUB created.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Workspace THE_HUB already exists.');
  END IF;
END;
/
EXIT;
ENDSQL
EOF

docker cp /tmp/create_apex_workspace.sh oracle26ai-db:/tmp/create_apex_workspace.sh
docker exec oracle26ai-db bash /tmp/create_apex_workspace.sh
```

**Expected output:** `Workspace THE_HUB created.`

---

### Step 5 – Create the APEX workspace admin user

```bash
cat > /tmp/create_apex_admin.sh << 'EOF'
#!/bin/bash
sqlplus -S / as sysdba <<'ENDSQL'
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT ON

DECLARE
  l_workspace_id NUMBER;
BEGIN
  SELECT workspace_id INTO l_workspace_id
  FROM apex_workspaces
  WHERE workspace = 'THE_HUB';

  APEX_UTIL.SET_WORKSPACE(p_workspace => 'THE_HUB');

  APEX_UTIL.CREATE_USER(
    p_user_name                    => 'ADMIN',
    p_email_address                => 'admin@thehub.local',
    p_web_password                 => '&THEHUB_PASSWORD',
    p_developer_privs              => 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL',
    p_change_password_on_first_use => 'N'
  );
  DBMS_OUTPUT.PUT_LINE('Workspace admin ADMIN created for THE_HUB.');
END;
/
EXIT;
ENDSQL
EOF

docker cp /tmp/create_apex_admin.sh oracle26ai-db:/tmp/create_apex_admin.sh
docker exec oracle26ai-db bash /tmp/create_apex_admin.sh
```

**Expected output:** `Workspace admin ADMIN created for THE_HUB.`

---

## 5. Verification Checklist

Run all checks in order after a fresh build:

```bash
# 1. PDB open
docker exec oracle26ai-db bash -c "sqlplus -S / as sysdba <<'EOF'
SELECT name, open_mode FROM v\$pdbs WHERE name='FREEPDB1';
EXIT;
EOF"

# 2. THEHUB user exists and is open
docker exec oracle26ai-db bash -c "sqlplus -S / as sysdba <<'EOF'
ALTER SESSION SET CONTAINER = FREEPDB1;
SELECT username, account_status FROM dba_users WHERE username='THEHUB';
EXIT;
EOF"

# 3. Tables and row counts
cat > /tmp/check_schema.sh << 'EOF'
#!/bin/bash
sqlplus -S "${THEHUB_CONNECT_STRING}" <<'ENDSQL'
SELECT COUNT(*) AS tables FROM user_tables;
SELECT COUNT(*) AS projects FROM projects;
SELECT COUNT(*) AS milestones FROM milestones;
EXIT;
ENDSQL
EOF
docker cp /tmp/check_schema.sh oracle26ai-db:/tmp/check_schema.sh
docker exec oracle26ai-db bash /tmp/check_schema.sh

# 4. APEX workspace exists
docker exec oracle26ai-db bash -c "sqlplus -S / as sysdba <<'EOF'
ALTER SESSION SET CONTAINER = FREEPDB1;
SELECT workspace, workspace_id FROM apex_workspaces WHERE workspace='THE_HUB';
EXIT;
EOF"

# 5. APEX admin user exists
docker exec oracle26ai-db bash -c "sqlplus -S / as sysdba <<'EOF'
ALTER SESSION SET CONTAINER = FREEPDB1;
SELECT user_name, account_locked FROM apex_workspace_apex_users WHERE workspace_name='THE_HUB';
EXIT;
EOF"
```

---

## 6. Application Login

| Login type | URL | Workspace | Username | Password |
|------------|-----|-----------|----------|----------|
| APEX workspace | http://localhost:8181/ords/apex | `THE_HUB` | `ADMIN` | value of `THEHUB_PASSWORD` |
| APEX instance admin | http://localhost:8181/ords/apex_admin | *(internal)* | `ADMIN` | *(set at ORDS install time)* |

---

## 7. Schema Object Inventory

| Table | Description |
|-------|-------------|
| `PROJECTS` | Core project tracker |
| `MILESTONES` | Project milestones |
| `LEAVE` | Team leave entries |
| `ON_CALL` | On-call rotation schedule |
| `MEETINGS` | Meeting register |
| `TEAM_MEMBERS` | DBA team member reference |
| `STATUSES` | Lookup – project/task statuses |
| `PRIORITIES` | Lookup – priority levels |
| `WORKSTREAMS` | Lookup – workstreams |
| `CATEGORIES` | Lookup – categories |
| `GOALS` | Lookup – goals |
| `MEETING_STATUSES` | Lookup – meeting statuses |
| `MEETING_TYPES` | Lookup – meeting types |
| `CADENCES` | Lookup – meeting cadences |
| `HOLIDAYS` | Holiday calendar |
| `HOLIDAY_NOTES` | Notes on holidays |
| `ORACLE_RU_CALENDAR` | Oracle release update calendar |
| `ORACLE_SECURITY_PATCHES` | Security patch reference |
| `RISK_REGISTER` | Project risk register |
| `DEPENDENCIES` | Project dependency mapping |
| `REPORT_TIMEFRAMES` | Reporting period reference |

---

## 8. Common Troubleshooting

### THEHUB account locked
```sql
ALTER SESSION SET CONTAINER = FREEPDB1;
ALTER USER THEHUB ACCOUNT UNLOCK;
```

### Reset THEHUB password
```sql
ALTER SESSION SET CONTAINER = FREEPDB1;
ALTER USER THEHUB IDENTIFIED BY "NewPassword01!";
```

### APEX workspace admin locked or forgotten password
```bash
cat > /tmp/reset_apex_admin.sh << 'EOF'
#!/bin/bash
sqlplus -S / as sysdba <<'ENDSQL'
ALTER SESSION SET CONTAINER = FREEPDB1;
BEGIN
  APEX_UTIL.SET_WORKSPACE(p_workspace => 'THE_HUB');
  APEX_UTIL.RESET_PASSWORD(
    p_user_name    => 'ADMIN',
    p_web_password => 'NewPassword01!'
  );
END;
/
EXIT;
ENDSQL
EOF
docker cp /tmp/reset_apex_admin.sh oracle26ai-db:/tmp/reset_apex_admin.sh
docker exec oracle26ai-db bash /tmp/reset_apex_admin.sh
```

### FREEPDB1 not open after container restart
```bash
docker exec oracle26ai-db bash -c "sqlplus -S / as sysdba <<'EOF'
ALTER PLUGGABLE DATABASE FREEPDB1 OPEN;
ALTER PLUGGABLE DATABASE FREEPDB1 SAVE STATE;
EXIT;
EOF"
```

### ORDS not responding (port 8181)
```bash
docker restart ords26
# Allow ~30 seconds for ORDS to start
curl -s -o /dev/null -w "%{http_code}" http://localhost:8181/ords/
```

### Shell `!` history expansion error when connecting
```bash
# Disable history expansion before any command with ! in the password
set +H
sqlcl "${THEHUB_CONNECT_STRING}"
```

---

## 9. Source Files

| File | Purpose |
|------|---------|
| `the_hub_schema_and_seed_data.sql` | Full schema DDL + all seed/reference data |
| `thehub_user_bootstrap.sql` | Interactive script to create THEHUB user (prompts for password) |
| `thehub_policy_promote_to_runtime.sql` | Hardens grants after build is complete |
| `thehub_policy_verify.sql` | Validates grants are correct |
| `apex/hub_apex_region_sql.sql` | All APEX region SQL, LOV queries, calendar queries |
| `apex/hub_apex_build_guide.md` | Step-by-step APEX page build guide |
| `the_hub_build_plan.md` | Architecture and workbook-to-table mapping |
