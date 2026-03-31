#!/usr/bin/env bash
# =============================================================================
# restore.sh — Game State Reset
# Wipes containers and rebuilds from scratch.
# Called by: make reset
# =============================================================================

set -e

echo "[*] Resetting VULN-Log4Shell environment..."

# Stop and remove containers
docker compose down --remove-orphans

# Rebuild images fresh
docker compose build --no-cache

# Start services
docker compose up -d

echo ""
echo "[+] Reset complete. Services are back to original state."
echo "    Auth Service      -> http://localhost:8001"
echo "    Inventory Service -> http://localhost:8002"
echo "    Status Service    -> http://localhost:8003"
echo ""
