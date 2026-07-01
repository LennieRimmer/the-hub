#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${ROOT_DIR}/apex/exports"
: "${THEHUB_CONNECT_STRING:?Set THEHUB_CONNECT_STRING, for example THEHUB/<password>@localhost:1521/FREEPDB1}"

mkdir -p "${OUT_DIR}"

docker cp "${ROOT_DIR}/apex/scripts/export_app_100_apexlang.sql" oracle26ai-db:/tmp/export_app_100_apexlang.sql
docker exec oracle26ai-db bash -lc "sqlplus -S '${THEHUB_CONNECT_STRING}' @/tmp/export_app_100_apexlang.sql"
docker cp oracle26ai-db:/tmp/thehub_app_100.apexlang "${OUT_DIR}/thehub_app_100.apexlang"

echo "Exported ${OUT_DIR}/thehub_app_100.apexlang"
