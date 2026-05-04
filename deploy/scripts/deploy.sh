#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
COMPOSE_FILE="${REPO_ROOT}/deploy/docker-compose.yml"

cd "${REPO_ROOT}"

git pull --ff-only
git submodule sync --recursive
git submodule update --init --recursive

if [[ ! -d themes/papermod/layouts ]]; then
  echo "ERROR: themes/papermod is missing or empty. Run: git submodule update --init --recursive"
  exit 1
fi

docker compose -f "${COMPOSE_FILE}" build
docker compose -f "${COMPOSE_FILE}" up -d
