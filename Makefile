# HAFB DEMO-FULL — Docker Compose shortcuts (POSIX; use Git Bash or WSL on Windows if needed)
COMPOSE ?= docker compose
SHELL := /bin/bash

.PHONY: help setup build up down restart logs ps clean forwarders-up forwarders-down validate urls \
	test-log4j test-mil1553-chain test-mil1553-tools reset-log4j reset-mil1553

help:
	@echo "HAFB DEMO-FULL"
	@echo "  make setup              — create .env, download Splunk UF payloads (no blocking HTTP server)"
	@echo "  make build              — docker compose build (images only)"
	@echo "  make up                 — docker compose up -d --build"
	@echo "  make down               — stop stack"
	@echo "  make restart            — down then up"
	@echo "  make logs               — follow all container logs"
	@echo "  make logs-splunk        — follow Splunk only"
	@echo "  make ps                 — docker compose ps"
	@echo "  make clean              — down and remove volumes (Splunk data reset)"
	@echo "  make forwarders-up      — start profile forwarders (UF containers → Splunk)"
	@echo "  make forwarders-down    — stop forwarder profile containers"
	@echo "  make validate           — quick Splunk API check inside splunk container"
	@echo "  make urls               — print service URLs"
	@echo "  make test-log4j         — health checks (ports 8101–8103)"
	@echo "  make test-mil1553-chain — ephemeral MIL upload → bridge → bus chain"
	@echo "  make test-mil1553-tools — ephemeral serial-bus + attacker image tests"
	@echo "  make reset-log4j        — recreate Log4j lab containers only"
	@echo "  make reset-mil1553      — recreate MIL-STD-1553 containers only"
	@echo "See README.md for demo walkthrough, architecture, and attack routes."

setup:
	@if [ ! -f .env ]; then cp .env.example .env && echo "[*] Created .env — edit SPLUNK_PASSWORD if needed."; fi
	@cd apps/splunk && export SKIP_SERVE=1 && bash setup_host.sh

build:
	$(COMPOSE) build

up:
	$(COMPOSE) up -d --build
	@echo ""
	@$(MAKE) urls

down:
	$(COMPOSE) down

restart: down up

logs:
	$(COMPOSE) logs -f

logs-splunk:
	$(COMPOSE) logs -f splunk

ps:
	$(COMPOSE) ps

clean:
	$(COMPOSE) down -v --remove-orphans

forwarders-up:
	$(COMPOSE) --profile forwarders up -d

forwarders-down:
	-$(COMPOSE) --profile forwarders stop uf-mil1553 uf-log4j uf-scenario

validate:
	@echo "[*] Checking Splunk management API from inside container..."
	@$(COMPOSE) exec -T splunk sh -c 'curl -sk -u "admin:$$SPLUNK_PASSWORD" "https://localhost:8089/services/server/info?output_mode=json" | grep -q "\"version\"" && echo "[OK] Splunk API responding" || (echo "[FAIL] Splunk API check failed"; exit 1)'

urls:
	@echo "Splunk web UI:     http://localhost:9000  (admin / SPLUNK_PASSWORD in .env)"
	@echo "Splunk mgmt (host): https://localhost:9089"
	@echo "UF payload server: http://localhost:8001   (forwarder packages + deploy script)"
	@echo "MIL logistics:     http://localhost:9080"
	@echo "Log4j auth:        http://localhost:8101"
	@echo "Log4j inventory:   http://localhost:8102"
	@echo "Log4j status:      http://localhost:8103"
	@echo "MIL serial bus UDP: localhost:5001"

test-log4j:
	@chmod +x apps/Log4j-Vulnerable/tools/test/test_services.sh
	@bash apps/Log4j-Vulnerable/tools/test/test_services.sh

test-mil1553-chain:
	@chmod +x apps/MIL-STD-1553-Vulnerable/tools/test/test_attack_chain.sh
	@bash apps/MIL-STD-1553-Vulnerable/tools/test/test_attack_chain.sh

test-mil1553-tools:
	@chmod +x apps/MIL-STD-1553-Vulnerable/tools/test/test_tools.sh
	@bash apps/MIL-STD-1553-Vulnerable/tools/test/test_tools.sh

reset-log4j:
	@chmod +x apps/Log4j-Vulnerable/restore.sh
	@bash apps/Log4j-Vulnerable/restore.sh

reset-mil1553:
	@chmod +x apps/MIL-STD-1553-Vulnerable/restore.sh
	@bash apps/MIL-STD-1553-Vulnerable/restore.sh
