#!/bin/bash
# COLORS
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${RED}[!] INITIATING EMERGENCY RESTORE PROTOCOL...${NC}"

# 1. Tear down existing containers and delete data volumes
docker compose down -v

# 2. Rebuild and Start
docker compose up -d --build

echo -e "${GREEN}[✔] SYSTEM RESTORED.${NC}"
