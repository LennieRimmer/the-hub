#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${ROOT_DIR}/apex/exports"

mkdir -p "${OUT_DIR}"

docker cp "${ROOT_DIR}/apex/scripts/export_app_100_apexlang.sql" oracle26ai-db:/tmp/export_app_100_apexlang.sql
docker exec oracle26ai-db bash -lc "sqlplus -S / as sysdba @/tmp/export_app_100_apexlang.sql"
docker cp oracle26ai-db:/tmp/thehub_app_100.apexlang "${OUT_DIR}/thehub_app_100.apexlang"

echo "Exported ${OUT_DIR}/thehub_app_100.apexlang"
