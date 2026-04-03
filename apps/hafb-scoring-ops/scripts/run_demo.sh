#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-8000}"
RELOAD="${RELOAD:-1}"

ARGS=(-m uvicorn app.main:app --host "$HOST" --port "$PORT")
if [[ "$RELOAD" == "1" ]]; then
  ARGS+=(--reload)
fi

if [[ -x ".venv/bin/python" ]]; then
  exec .venv/bin/python "${ARGS[@]}"
fi

exec python3 "${ARGS[@]}"
