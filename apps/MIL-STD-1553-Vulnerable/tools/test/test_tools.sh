#!/bin/bash
# Verification script for Python attack tools

echo "[TEST] Starting Tool Functionality Verification..."

# Build Attacker Image
echo "[TEST] Building attacker image..."
docker build -t attacker tools/attack > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "[FAIL] Docker build failed!"
    exit 1
fi

# Setup Ephemeral Environment
PROJECT_NAME="test_tools_$(date +%s)"
echo "[TEST] Starting ephemeral serial-bus infrastructure (Project: $PROJECT_NAME)..."

# Ensure cleanup happens on exit
cleanup() {
    echo ""
    echo "[TEST] Cleaning up ephemeral environment..."
    docker compose -p "$PROJECT_NAME" down -v > /dev/null 2>&1
}
trap cleanup EXIT

docker compose -p "$PROJECT_NAME" up -d serial-bus
sleep 5

# Detect Network Name
# Docker Compose v2 names networks as <project>_<network>
NETWORK="${PROJECT_NAME}_avionics-net"

# Verify network exists
if ! docker network inspect "$NETWORK" > /dev/null 2>&1; then
    echo "[FAIL] Could not find network $NETWORK!"
    exit 1
fi
echo "[TEST] Using network: $NETWORK"

# Helper function to run a tool and check logs
run_test() {
    TOOL_SCRIPT=$1
    EXPECTED_LOG=$2
    TEST_NAME=$3

    echo "[TEST] Running $TEST_NAME ($TOOL_SCRIPT)..."
    
    # Run the tool in the avionics network
    # Remove silence > /dev/null to see errors
    docker run --rm --network $NETWORK attacker python3 $TOOL_SCRIPT
    
    # Give the bus a moment to process and flush logs
    sleep 2

    # Check if the serial-bus received it
    # We look at the last 20 lines to avoid matching old tests
    LOGS=$(docker compose -p "$PROJECT_NAME" logs --tail=20 serial-bus 2>&1)
    if echo "$LOGS" | grep -q "$EXPECTED_LOG"; then
        echo "[PASS] $TEST_NAME successful."
    else
        echo "[FAIL] $TEST_NAME failed. Expected log '$EXPECTED_LOG' not found."
        echo "[DEBUG] Logs found:"
        echo "$LOGS"
        return 1
    fi
}

# Test Start Engine
run_test "start_engine.py" "IGNITION" "Engine Start" || exit 1

# Test Kill Engine
run_test "kill_engine.py" "EMERGENCY SHUTDOWN" "Engine Kill" || exit 1

# Test Fuzz Bus (Check if it sends at least one)
# Fuzzer sends many, we just check if the bus saw traffic
# The bus prints "BUS MONITOR: Incoming Data -> 0x01" etc
run_test "fuzz_bus.py" "BUS MONITOR" "Bus Fuzzer" || exit 1

echo "[PASS] All tools verified."
exit 0
