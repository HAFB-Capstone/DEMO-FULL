# Standard Blue Team Control Plane
include .env
export

SHELL := /bin/bash
.phony: setup up down clean rebuild logs status test

setup:
	@echo "Running Host Setup..."
	@bash setup_host.sh

up:
	@echo "Starting Splunk container..."
	@docker compose up -d
	@echo "Waiting for Splunk to initialize (this may take as much as 3-5 minutes)..."
	@echo "Press 'l' to view logs"
	@# Spinner animation while waiting for Splunk
	@trap 'echo ""; echo "Stopping Splunk..."; docker compose down; stty sane; exit 1' INT; \
	spinner="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"; \
	i=0; \
	elapsed=0; \
	timeout=330; \
	start_time=$$(date +%s); \
	stty -echo -icanon time 0 min 0; \
	while ! docker logs $$(docker compose ps -q splunk) 2>&1 | grep -q "Ansible playbook complete"; do \
		elapsed=$$(( $$(date +%s) - start_time )); \
		if [ $$elapsed -ge $$timeout ]; then \
			stty sane; \
			printf "\r  ✗ TIMEOUT: Splunk did not start after %d seconds\n" $$timeout; \
			echo ""; \
			echo "There may be a problem with your setup. Try:"; \
			echo "  - Check logs: docker logs $$(docker compose ps -q splunk)"; \
			echo "  - Restart: make down && make up"; \
			echo "  - Check Docker resources (CPU/Memory)"; \
			exit 1; \
		fi; \
		key=$$(dd bs=1 count=1 2>/dev/null); \
		if [ "$$key" = "l" ]; then \
			stty sane; \
			printf "\n"; \
			docker logs $$(docker compose ps -q splunk) 2>&1 | less -R +G; \
			printf "\033[1A\033[K"; \
			stty -echo -icanon time 0 min 0; \
		fi; \
		if [ $$elapsed -gt 59 ]; then \
			minutes=$$(( elapsed / 60 )); \
			seconds=$$(( elapsed % 60 )); \
			time_str=$$(printf "%dm %02ds" $$minutes $$seconds); \
		else \
			time_str=$$(printf "%ds" $$elapsed); \
		fi; \
		printf "\r %s Initializing Splunk... (%s) [Press 'l' for logs]" "$${spinner:$$i:1}" "$$time_str"; \
		i=$$(( (i + 1) % 10 )); \
		sleep 0.07; \
	done; \
	stty sane
	@printf "\r \033[32m✔\033[0m SUCCESS: Splunk is up and running!                              \n"
	@echo "URL: http://localhost:8002"

down:
	docker compose down

clean:
	docker compose down -v

rebuild:
	docker compose down -v && docker compose build --no-cache

logs:
	docker compose logs -f

status:
	docker compose ps

test:
	@chmod +x validation/*.py
	@python3 validation/validate_splunk.py

