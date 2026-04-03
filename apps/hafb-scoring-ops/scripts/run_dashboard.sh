#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8080}"
RELOAD="${RELOAD:-0}"

ARGS=(-m uvicorn app.main:app --host "$HOST" --port "$PORT")
if [[ "$RELOAD" == "1" ]]; then
  ARGS+=(--reload)
fi

if [[ -x ".venv/bin/python" ]]; then
  exec .venv/bin/python "${ARGS[@]}"
fi

exec python3 "${ARGS[@]}"
