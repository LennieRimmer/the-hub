# The Hub APEX Recovery Notes

## 2026-07-01

The first scripted dashboard attempt used low-level APEX import metadata APIs directly against app `100`.

Visible Page 1 metadata could be reset to the original Home page with `apex/scripts/reset_page_1_home.sql`, but `APEX_EXPORT.GET_APPLICATION(... APEXLANG ...)` still failed with:

```text
ORA-01403: no data found
ORA-06512: at "APEX_260100.WWV_FLOW_EXPORT_INT"
ORA-06512: at "APEX_260100.WWV_META_META_DATA"
ORA-06512: at "APEX_260100.WWV_FLOW_EXPORT_API"
```

Decision:

- Do not continue extending this app shell.
- Removed APEX application `100` from workspace `THE_HUB`.
- Recreate the barebones APEX app shell before the next build step.
- Going forward, build page/application changes through APEXlang artifacts and SQLcl validation/import gates, following the Oracle Skills guidance.

Fallback:

- `THEHUB` schema and seed data remain intact.
- APEX workspace `THE_HUB` remains intact.
- Verified after removal: `THEHUB` still has 21 tables, 13 project rows, and 216 milestone rows.
- Recreate app `100` in App Builder with:
  - Name: `The Hub`
  - Alias: `THE-HUB`
  - Schema: `THEHUB`
  - Authentication: Oracle APEX Accounts
  - Theme: Universal Theme
  - Navigation: Side Navigation

Clean baseline:

- App `100` was recreated in the GUI.
- Clean APEXLANG export succeeded.
- Canonical baseline artifacts:
  - `apex/exports/thehub_app_100_apexlang.zip`
  - `apex/exports/thehub_app_100_apexlang/`
- The flattened `apex/exports/thehub_app_100.apexlang` file is only an inspection artifact and is not valid as an import package.
- Verified ZIP export: 21 files, 46,759 byte ZIP, 54,437 bytes uncompressed.
- Verified markers in split project: `pages/p00001-home.apx`, `application.apx`, `.apex/apexlang.json`.
- Container SQLcl 26.1.1 found at `/opt/oracle/product/26ai/dbhomeFree/sqlcl/bin/sql`.
- Container SQLcl generated and validated the APEX Liquibase export:
  - `apex/exports/thehub_app_100_liquibase/apex_install.xml`
  - `apex/exports/thehub_app_100_liquibase/f100.sql`

REST status:

- `THEHUB` is REST enabled in ORDS.
- URL mapping: `http://localhost:8181/ords/thehub/`
- ORDS metadata shows `PARSING_SCHEMA = THEHUB`, `STATUS = ENABLED`, `AUTO_REST_AUTH = DISABLED`.
- HTTP smoke check on the base path returns ORDS `404 Not Found`, which is expected until REST modules/templates are created.

Next build rule:

- Do not push low-level APEX metadata scripts directly into app `100`.
- Generate APEXlang artifacts first.
- Validate through container SQLcl Liquibase APEX tooling before import/apply.
- Import only after validation passes.
