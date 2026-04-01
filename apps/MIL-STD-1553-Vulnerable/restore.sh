#!/bin/bash
# Recreate MIL-STD-1553 stack services only (does not stop Splunk / Log4j / payloads).
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
COMPOSE_FILE="$REPO_ROOT/docker-compose.yaml"

echo -e "${RED}[!] Recreating MIL-STD-1553 containers (root compose)...${NC}"

docker compose -f "$COMPOSE_FILE" up -d --build --force-recreate \
    logistics-portal maintenance-terminal serial-bus

echo -e "${GREEN}[✔] MIL-STD-1553 services refreshed. Logistics portal: http://localhost:9080${NC}"
