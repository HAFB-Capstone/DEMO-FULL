PYTHON ?= python3

.PHONY: run
run:
	uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload

.PHONY: dashboard
dashboard:
	HOST=0.0.0.0 PORT=8080 RELOAD=0 ./scripts/run_dashboard.sh

.PHONY: bootstrap
bootstrap:
	./scripts/setup_demo.sh

.PHONY: dashboard-setup
dashboard-setup:
	./scripts/setup_dashboard.sh

.PHONY: demo
demo: run

.PHONY: validate
validate:
	$(PYTHON) -m py_compile app/*.py app/services/*.py
