#!/usr/bin/env bash
# Health checks for MIL-STD-1553 lab (expects root compose port map). Run: make test-mil1553
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

: "${MIL_LOGISTICS_PORT:=9080}"

PASSED=0
FAILED=0

check() {
    local label=$1
    local url=$2
    local expected=$3

    local response
    response=$(curl -s --connect-timeout 5 "$url" 2>/dev/null || true)

    if echo "$response" | grep -q "$expected"; then
        echo -e "${GREEN}[PASS]${NC} $label"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}[FAIL]${NC} $label"
        echo "       URL: $url"
        echo "       Expected: $expected"
        echo "       Got: $response"
        FAILED=$((FAILED + 1))
    fi
}

echo ""
echo "========================================"
echo "  MIL-STD-1553 lab service health check"
echo "========================================"
echo ""

check "Logistics Portal is running" \
    "http://localhost:${MIL_LOGISTICS_PORT}/health" \
    "UP"

check "Logistics Portal index responds" \
    "http://localhost:${MIL_LOGISTICS_PORT}/" \
    "UNITED STATES AIR FORCE"

# For non-HTTP services, we check if they are running via docker compose ps
# We use the service names from the root docker-compose.yaml
if docker compose ps serial-bus --format "{{.Status}}" 2>/dev/null | grep -qi "Up"; then
    # Additionally check logs for the crash reported by the user
    if docker compose logs --tail=100 serial-bus 2>&1 | grep -q "PermissionError: \[Errno 13\] Permission denied"; then
        echo -e "${RED}[FAIL]${NC} Serial Bus is running but has PermissionError in logs"
        FAILED=$((FAILED + 1))
    else
        echo -e "${GREEN}[PASS]${NC} Serial Bus is running and healthy"
        PASSED=$((PASSED + 1))
    fi
else
    echo -e "${RED}[FAIL]${NC} Serial Bus is NOT running"
    FAILED=$((FAILED + 1))
fi

if docker compose ps maintenance-terminal --format "{{.Status}}" 2>/dev/null | grep -qi "Up"; then
    echo -e "${GREEN}[PASS]${NC} Maintenance Terminal is running"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}[FAIL]${NC} Maintenance Terminal is NOT running"
    FAILED=$((FAILED + 1))
fi

echo ""
echo "========================================"
echo "  Results: Passed=$PASSED  Failed=$FAILED"
echo "========================================"
echo ""

if [ "$FAILED" -eq 0 ]; then
    exit 0
else
    exit 1
fi
