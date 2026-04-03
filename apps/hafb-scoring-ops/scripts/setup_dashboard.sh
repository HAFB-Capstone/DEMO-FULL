#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

WHEELHOUSE="${HAFB_PYTHON_WHEELHOUSE:-vendor/wheels}"

python3 -m venv .venv
source .venv/bin/activate

if [[ -d "$WHEELHOUSE" ]]; then
  python -m pip install --no-index --find-links "$WHEELHOUSE" -r requirements.txt
  echo "Installed dashboard dependencies from local wheelhouse: $WHEELHOUSE"
else
  echo "Local wheelhouse not found at $WHEELHOUSE; falling back to pip index access."
  echo "For a more air-gapped setup, pre-stage wheels and set HAFB_PYTHON_WHEELHOUSE if needed."
  python -m pip install --upgrade pip
  python -m pip install -r requirements.txt
fi

echo
echo "Dashboard environment ready."
echo "Run HOST=0.0.0.0 PORT=8080 ./scripts/run_dashboard.sh"
echo "Then browse to http://<controlOps-ip>:8080"
