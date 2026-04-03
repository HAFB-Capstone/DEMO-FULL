.PHONY: setup up down reset logs test

setup:
	docker compose build

up:
	docker compose up -d
	@echo ""
	@echo "Services running:"
	@echo "  Auth Service      -> http://localhost:8001  (VULNERABLE)"
	@echo "  Inventory Service -> http://localhost:8002  (VULNERABLE)"
	@echo "  Status Service    -> http://localhost:8003  (NOT vulnerable)"
	@echo "  Vulnerable App    -> http://localhost:8080  (VULNERABLE; christophetd image)"
	@echo ""

down:
	docker compose down

reset:
	bash restore.sh

logs:
	docker compose logs -f

test:
	bash tools/test/test_services.sh
