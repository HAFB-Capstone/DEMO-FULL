#!/usr/bin/env bash
# Health checks for Log4j lab (expects root compose port map). Run: make test-log4j
# Standalone (cd apps/Log4j-Vulnerable && docker compose up): set LOG4J_AUTH_PORT=8001 etc.
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

: "${LOG4J_AUTH_PORT:=8101}"
: "${LOG4J_INVENTORY_PORT:=8102}"
: "${LOG4J_STATUS_PORT:=8103}"
: "${LOG4J_VULN_APP_PORT:=8180}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

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
echo "  Log4j lab service health check"
echo "========================================"
echo ""

check "Auth service is running" \
    "http://localhost:${LOG4J_AUTH_PORT}/health" \
    "UP"

check "Auth service login endpoint responds" \
    "http://localhost:${LOG4J_AUTH_PORT}/" \
    "HAFB Auth Service"

check "Inventory service is running" \
    "http://localhost:${LOG4J_INVENTORY_PORT}/health" \
    "UP"

check "Inventory service search endpoint responds" \
    "http://localhost:${LOG4J_INVENTORY_PORT}/search" \
    "results"

check "Status service is running" \
    "http://localhost:${LOG4J_STATUS_PORT}/health" \
    "UP"

check "Status service identifies as non-vulnerable (Python)" \
    "http://localhost:${LOG4J_STATUS_PORT}/" \
    "Python"

# christophetd/log4shell-vulnerable-app — controller requires X-Api-Version on GET /
vuln_body=$(curl -s --connect-timeout 5 -H "X-Api-Version: healthcheck" "http://localhost:${LOG4J_VULN_APP_PORT}/" 2>/dev/null || true)
if echo "$vuln_body" | grep -q "Hello, world!"; then
    echo -e "${GREEN}[PASS]${NC} Vulnerable app (christophetd) responds"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}[FAIL]${NC} Vulnerable app (christophetd) — expected body from GET / with X-Api-Version"
    echo "       Got: $vuln_body"
    FAILED=$((FAILED + 1))
fi

if [ -f "$APP_ROOT/flags/auth_flag.txt" ] && grep -q "FLAG{" "$APP_ROOT/flags/auth_flag.txt" 2>/dev/null; then
    echo -e "${GREEN}[PASS]${NC} Auth flag file present on host"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}[FAIL]${NC} Auth flag missing or invalid at flags/auth_flag.txt"
    FAILED=$((FAILED + 1))
fi

if [ -f "$APP_ROOT/flags/app_flag.txt" ] && grep -q "FLAG{" "$APP_ROOT/flags/app_flag.txt" 2>/dev/null; then
    echo -e "${GREEN}[PASS]${NC} App flag file present on host"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}[FAIL]${NC} App flag missing or invalid at flags/app_flag.txt"
    FAILED=$((FAILED + 1))
fi

echo ""
echo "========================================"
echo "  Results: Passed=$PASSED  Failed=$FAILED"
echo "========================================"
echo ""

if [ "$FAILED" -eq 0 ]; then
    echo -e "${GREEN}All checks passed.${NC}"
    exit 0
else
    echo -e "${RED}$FAILED check(s) failed.${NC}"
    exit 1
fi
