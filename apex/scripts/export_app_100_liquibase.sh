#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${ROOT_DIR}/apex/exports/thehub_app_100_liquibase"
CONTAINER_DIR="/tmp/thehub_app_100_liquibase"
SQLCL="/opt/oracle/product/26ai/dbhomeFree/sqlcl/bin/sql"
: "${THEHUB_CONNECT_STRING:?Set THEHUB_CONNECT_STRING, for example THEHUB/<password>@localhost:1521/FREEPDB1}"

rm -rf "${OUT_DIR}"
mkdir -p "${OUT_DIR}"

docker exec oracle26ai-db bash -lc "rm -rf '${CONTAINER_DIR}' && mkdir -p '${CONTAINER_DIR}'"

docker exec oracle26ai-db bash -lc "cd '${CONTAINER_DIR}' && printf '%s\n' \
  'connect ${THEHUB_CONNECT_STRING}' \
  'lb generate-apex-object -applicationid 100' \
  'lb validate -changelog-file apex_install.xml' \
  'exit' | '${SQLCL}' -S -nolog"

docker cp "oracle26ai-db:${CONTAINER_DIR}/." "${OUT_DIR}"

echo "Exported and validated ${OUT_DIR}/apex_install.xml"
