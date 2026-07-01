# The Hub APEXLANG Workflow

## Current Tool Reality

The host SQLcl versions tested are:

- `/mnt/c/sqlcl/sqlcl/bin/sql`: SQLcl 25.1.1
- `/home/oracle/software/sqlcl_25.3.0.0/bin/sql`: SQLcl 25.3.0

Both expose APEX export commands, but neither exposes the newer Oracle Skills gate commands:

- `apex validate -input`
- `apex import -input`

The database container includes SQLcl 26.1.1 at:

- `/opt/oracle/product/26ai/dbhomeFree/sqlcl/bin/sql`

That SQLcl includes the APEXLANG compiler jar and can generate/validate an APEX Liquibase package with:

```text
lb generate-apex-object -applicationid 100
lb validate -changelog-file apex_install.xml
```

Use that container SQLcl path as the current command-line validation/deployment gate.

## Clean Baseline

The fresh GUI-created app `100` exports cleanly as APEXLANG.

Canonical export artifacts:

- `apex/exports/thehub_app_100_apexlang.zip`
- `apex/exports/thehub_app_100_apexlang/`
- `apex/exports/thehub_app_100_liquibase/apex_install.xml`
- `apex/exports/thehub_app_100_liquibase/f100.sql`
- `apex/exports/thehub_app_100.apexlang` is a flattened inspection artifact only. Do not use it for import.

## Export

Run:

```bash
apex/scripts/export_app_100_apexlang_zip.sh
```

This writes the canonical ZIP and expands it into a split APEXLANG project directory.

For the SQLcl Liquibase gate, run:

```bash
apex/scripts/export_app_100_liquibase.sh
```

This writes `apex_install.xml` and `f100.sql`, then runs `lb validate -changelog-file apex_install.xml` inside the container.

## Build Rule

1. Export the clean app as split APEXLANG.
2. Make changes in the split project directory or a working copy.
3. Generate and validate the SQLcl Liquibase APEX package with container SQLcl.
4. Import/apply only after validation passes.
5. Export again immediately after import and confirm the new live app can export cleanly.

## Guardrail

Do not use low-level `wwv_flow_imp_page` or direct APEX metadata scripts for new page work unless the change is a throwaway experiment in a disposable app. The previous app shell had to be removed after direct metadata edits caused `APEX_EXPORT.GET_APPLICATION(... APEXLANG ...)` to fail with `ORA-01403`.
