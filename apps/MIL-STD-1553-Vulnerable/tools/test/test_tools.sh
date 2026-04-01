#!/bin/bash
# Verification for Python attack tools (ephemeral serial-bus). Run: make test-mil1553-tools

set -euo pipefail

MIL_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REPO_ROOT="$(cd "$MIL_ROOT/../.." && pwd)"
COMPOSE_FILE="$REPO_ROOT/docker-compose.yaml"

echo "[TEST] Starting tool functionality verification..."
echo "[TEST] Note: publishes host UDP 5001 like the main stack — run 'make down' first if that port is already bound."

echo "[TEST] Building attacker image..."
docker build -t attacker "$MIL_ROOT/tools/attack" >/dev/null

PROJECT_NAME="test_tools_$(date +%s)"
echo "[TEST] Ephemeral project: $PROJECT_NAME"

cleanup() {
    echo ""
    echo "[TEST] Cleaning up ephemeral environment..."
    docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" down -v >/dev/null 2>&1 || true
}
trap cleanup EXIT

if ! docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" up -d serial-bus; then
    echo "[FAIL] docker compose up failed (port conflict? try: make down)"
    exit 1
fi
sleep 5

NETWORK="${PROJECT_NAME}_mil1553-avionics"
if ! docker network inspect "$NETWORK" >/dev/null 2>&1; then
    echo "[FAIL] Could not find network $NETWORK"
    exit 1
fi
echo "[TEST] Using network: $NETWORK"

run_test() {
    local TOOL_SCRIPT=$1
    local EXPECTED_LOG=$2
    local TEST_NAME=$3

    echo "[TEST] Running $TEST_NAME ($TOOL_SCRIPT)..."
    docker run --rm --network "$NETWORK" attacker python3 "$TOOL_SCRIPT"
    sleep 2

    local LOGS
    LOGS=$(docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" logs --tail=30 serial-bus 2>&1)
    if echo "$LOGS" | grep -q "$EXPECTED_LOG"; then
        echo "[PASS] $TEST_NAME successful."
    else
        echo "[FAIL] $TEST_NAME failed. Expected log '$EXPECTED_LOG' not found."
        echo "[DEBUG] Logs:"
        echo "$LOGS"
        return 1
    fi
}

run_test "start_engine.py" "IGNITION" "Engine Start" || exit 1
run_test "kill_engine.py" "EMERGENCY SHUTDOWN" "Engine Kill" || exit 1
run_test "fuzz_bus.py" "BUS MONITOR" "Bus Fuzzer" || exit 1

echo "[PASS] All tools verified."
exit 0
