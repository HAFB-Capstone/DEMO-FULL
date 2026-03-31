#!/bin/bash
# End-to-End Test for Operation Sky Shield

echo "[TEST] Starting Attack Chain Verification..."

# Reset Environment (Ephemeral)
PROJECT_NAME="test_chain_$(date +%s)"
echo "[TEST] Starting ephemeral environment (Project: $PROJECT_NAME)..."

# Ensure cleanup happens on exit
cleanup() {
    echo ""
    echo "[TEST] Cleaning up ephemeral environment..."
    docker compose -p "$PROJECT_NAME" down -v > /dev/null 2>&1
}
trap cleanup EXIT

# Start environment
docker compose -p "$PROJECT_NAME" up -d --build > /dev/null 2>&1

# Wait for services to stabilize
echo "[TEST] Waiting 10s for services..."
sleep 10

# Upload Payload
echo "[TEST] Uploading payload..."
curl -s -f -X POST -F "logfile=@tools/attack/attack_payload.sh;filename=daily_maintenance.sh" http://localhost:80/upload
if [ $? -ne 0 ]; then
    echo "[FAIL] Upload failed!"
    exit 1
fi

# Verify Logs
echo "[TEST] Monitoring logs for success (Timeout: 30s)..."
TIMEOUT=30
COUNT=0
while [ $COUNT -lt $TIMEOUT ]; do
    if docker compose -p "$PROJECT_NAME" logs maintenance-terminal 2>&1 | grep -q "Ignition Sequence Sent"; then
        echo "[PASS] Attack Chain Verified: Maintenance Terminal executed the payload."
        exit 0
    fi
    sleep 1
    COUNT=$((COUNT+1))
done

echo "[FAIL] Timeout waiting for attack execution."
exit 1
