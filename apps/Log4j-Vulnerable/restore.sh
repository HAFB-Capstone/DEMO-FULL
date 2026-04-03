#!/usr/bin/env bash
# Recreate Log4j lab services only (does not stop Splunk / MIL / payloads).
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
COMPOSE_FILE="$REPO_ROOT/docker-compose.yaml"

echo "[*] Recreating Log4j lab containers (root compose)..."

docker compose -f "$COMPOSE_FILE" up -d --build --force-recreate \
    log4j-auth-service log4j-inventory-service log4j-status-service log4j-vulnerable-app \
    rt-log4j-attacker rt-log4j-training-ui

echo ""
echo "[+] Reset complete."
echo "    Auth           -> http://localhost:8101"
echo "    Inventory      -> http://localhost:8102"
echo "    Status         -> http://localhost:8103"
echo "    Vulnerable app -> http://localhost:8180"
echo ""
