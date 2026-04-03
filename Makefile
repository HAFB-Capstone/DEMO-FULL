# HAFB DEMO-FULL — Management Makefile
COMPOSE ?= $(shell if docker compose version >/dev/null 2>&1; then echo "docker compose"; elif docker-compose --version >/dev/null 2>&1; then echo "docker-compose"; else echo "docker compose"; fi)
SHELL := /bin/bash

.PHONY: help setup build up down restart logs ps logs-splunk validate urls test shell

help:
	@echo "HAFB DEMO-FULL Management"
	@echo "  make setup      — Initial environment setup (.env and Splunk payloads)"
	@echo "  make build      — Build all docker images"
	@echo "  make up         — Start the entire stack (including forwarders)"
	@echo "  make down       — Stop all containers and remove volumes"
	@echo "  make restart    — Full restart of the stack"
	@echo "  make logs       — Follow logs from all application services"
	@echo "  make logs-splunk — Follow Splunk server logs"
	@echo "  make ps         — Show status of all containers"
	@echo "  make validate   — Validate Splunk and application health"
	@echo "  make urls       — Print all service access URLs"
	@echo "  make test       — Run all tests (or use TEST_APP=<name>)"
	@echo "  make shell      — Open shell in service (use SERVICE=<name>)"

setup:
	@if [ ! -f .env ]; then cp .env.example .env && echo "[*] Created .env — edit if needed."; fi
	@cd apps/splunk && export SKIP_SERVE=1 && bash setup_host.sh
	@echo "[*] Setup complete."

build:
	$(COMPOSE) --profile forwarders build

up:
	$(COMPOSE) --profile forwarders up -d
	@echo ""
	@$(MAKE) urls

down:
	$(COMPOSE) --profile forwarders down -v --remove-orphans

restart: down up

logs:
	@services="$$( $(COMPOSE) config --services | grep -vE '^splunk$$|^splunk-payloads$$|^uf-|^sbom-' )"; \
	$(COMPOSE) logs -f $$services

logs-splunk:
	$(COMPOSE) logs -f splunk

ps:
	$(COMPOSE) ps

validate:
	@echo "[*] Validating Splunk API..."
	@$(COMPOSE) exec -T splunk sh -c 'curl -sk -u "admin:$$SPLUNK_PASSWORD" "https://localhost:8089/services/server/info?output_mode=json" | grep -q "\"version\"" && echo "[OK] Splunk API responding" || echo "[FAIL] Splunk API check failed"'
	@echo "[*] Validating Scoring Ops..."
	@curl -sf http://localhost:8090/healthz | grep -q '"status":"ok"' && echo "[OK] Scoring dashboard /healthz" || echo "[FAIL] Scoring dashboard unreachable"
	@echo "[*] Validating Log4j Services..."
	@chmod +x apps/Log4j-Vulnerable/tools/test/test_services.sh
	@bash apps/Log4j-Vulnerable/tools/test/test_services.sh | grep -E "PASS|FAIL"
	@echo "[*] Validating MIL-STD-1553 Services..."
	@chmod +x apps/MIL-STD-1553-Vulnerable/tools/test/test_services.sh
	@bash apps/MIL-STD-1553-Vulnerable/tools/test/test_services.sh | grep -E "PASS|FAIL"

urls:
	@echo "==============================================================="
	@echo "  BLUE TEAM (DEFENSE)"
	@echo "==============================================================="
	@echo "  Splunk Web UI:     http://localhost:8000 (admin / Changeme1!)"
	@echo "  Splunk Management: https://localhost:9089"
	@echo "  UF Payload Server: http://localhost:8001"
	@echo ""
	@echo "==============================================================="
	@echo "  RED TEAM (ATTACK)"
	@echo "==============================================================="
	@echo "  Logistics Portal:  http://localhost:9080"
	@echo "  Log4j Lab Entry:   http://localhost:8180"
	@echo "  Training UI:       http://localhost:8020"
	@echo ""
	@echo "==============================================================="
	@echo "  SBOM / SUPPLY CHAIN LAB (CLI only — no web URL)"
	@echo "==============================================================="
	@echo "  Enter the lab container (repo bind-mounted at /lab):"
	@echo "    make shell SERVICE=sbom-xray-lab"
	@echo "    $(COMPOSE) exec sbom-xray-lab bash"
	@echo "  First-time setup inside the container:"
	@echo "    $(COMPOSE) exec sbom-xray-lab bash -c 'SBOM_XRAY_CONTAINER=1 bash /lab/install-module1-offline.sh --lab-dir /lab'"
	@echo "  Docs: apps/SBOM-XRay/student/sbom-xray-lab-student-guide.md"
	@echo ""
	@echo "==============================================================="
	@echo "  SERVICES"
	@echo "==============================================================="
	@echo "  Auth Service:      http://localhost:8101"
	@echo "  Inventory Service: http://localhost:8102"
	@echo "  Status Service:    http://localhost:8103"
	@echo "  Scoring Dashboard: http://localhost:8090"
	@echo "==============================================================="

test:
	@if [ "$(TEST_APP)" == "log4j" ]; then \
		chmod +x apps/Log4j-Vulnerable/tools/test/test_services.sh && bash apps/Log4j-Vulnerable/tools/test/test_services.sh; \
	elif [ "$(TEST_APP)" == "mil1553" ]; then \
		$(MAKE) down && chmod +x apps/MIL-STD-1553-Vulnerable/tools/test/test_attack_chain.sh && bash apps/MIL-STD-1553-Vulnerable/tools/test/test_attack_chain.sh; \
	elif [ "$(TEST_APP)" == "sbom" ]; then \
		$(COMPOSE) run --rm sbom-xray-lab bash /lab/validate-module1-offline.sh --lab-dir /lab; \
	else \
		echo "[*] Running all tests..."; \
		chmod +x apps/Log4j-Vulnerable/tools/test/test_services.sh && bash apps/Log4j-Vulnerable/tools/test/test_services.sh; \
		chmod +x apps/MIL-STD-1553-Vulnerable/tools/test/test_attack_chain.sh && bash apps/MIL-STD-1553-Vulnerable/tools/test/test_attack_chain.sh; \
		$(COMPOSE) run --rm sbom-xray-lab bash /lab/validate-module1-offline.sh --lab-dir /lab; \
	fi

shell:
	@if [ -z "$(SERVICE)" ]; then \
		echo "[FAIL] Please specify a service: make shell SERVICE=<name>"; \
		echo "Available: $$( $(COMPOSE) config --services | xargs )"; \
		exit 1; \
	fi; \
	$(COMPOSE) exec $(SERVICE) /bin/bash || $(COMPOSE) exec $(SERVICE) /bin/sh || $(COMPOSE) exec $(SERVICE) sh
