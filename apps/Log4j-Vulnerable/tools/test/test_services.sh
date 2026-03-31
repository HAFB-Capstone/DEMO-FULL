#!/usr/bin/env bash
# =============================================================================
# tools/test/test_services.sh
# Verifies all three services are running and reachable.
# Called by: make test
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASSED=0
FAILED=0

check() {
    local label=$1
    local url=$2
    local expected=$3

    response=$(curl -s --connect-timeout 5 "$url" 2>/dev/null)

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
echo "  VULN-Log4Shell Service Health Check"
echo "========================================"
echo ""

# Auth service
check "Auth service is running" \
    "http://localhost:8001/health" \
    "UP"

check "Auth service login endpoint responds" \
    "http://localhost:8001/" \
    "HAFB Auth Service"

# Inventory service
check "Inventory service is running" \
    "http://localhost:8002/health" \
    "UP"

check "Inventory service search endpoint responds" \
    "http://localhost:8002/search" \
    "results"

# Status service
check "Status service is running" \
    "http://localhost:8003/health" \
    "UP"

check "Status service correctly identifies as non-vulnerable" \
    "http://localhost:8003/" \
    "Python"

# Flags
check "Auth flag exists" \
    "file://$(pwd)/flags/auth_flag.txt" \
    "FLAG{"

echo ""
echo "========================================"
echo "  Results: Passed=$PASSED  Failed=$FAILED"
echo "========================================"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All checks passed.${NC}"
    exit 0
else
    echo -e "${RED}$FAILED check(s) failed.${NC}"
    exit 1
fi