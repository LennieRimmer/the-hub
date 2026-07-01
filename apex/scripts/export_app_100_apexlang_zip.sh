#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${ROOT_DIR}/apex/exports"
ZIP_FILE="${OUT_DIR}/thehub_app_100_apexlang.zip"
PROJECT_DIR="${OUT_DIR}/thehub_app_100_apexlang"
: "${THEHUB_CONNECT_STRING:?Set THEHUB_CONNECT_STRING, for example THEHUB/<password>@localhost:1521/FREEPDB1}"

mkdir -p "${OUT_DIR}" "${PROJECT_DIR}"

docker cp "${ROOT_DIR}/apex/scripts/export_app_100_apexlang_zip.sql" oracle26ai-db:/tmp/export_app_100_apexlang_zip.sql
docker exec oracle26ai-db bash -lc "sqlplus -S '${THEHUB_CONNECT_STRING}' @/tmp/export_app_100_apexlang_zip.sql"
docker cp oracle26ai-db:/tmp/thehub_app_100_apexlang.zip "${ZIP_FILE}"
unzip -q -o "${ZIP_FILE}" -d "${PROJECT_DIR}"

echo "Exported ${ZIP_FILE}"
echo "Expanded ${PROJECT_DIR}"
