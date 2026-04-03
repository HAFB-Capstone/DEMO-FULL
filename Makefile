INVENTORY ?=
LIMIT ?=

.PHONY: help
help:
	@echo "Usage:"
	@echo "  make deploy INVENTORY=inventories/localhost.yml"
	@echo "  make validate INVENTORY=inventories/localhost.yml"
	@echo "  make demo INVENTORY=inventories/localhost.yml"
	@echo "  make deploy INVENTORY=inventories/proxmox-lab.yml LIMIT=ubuntuBlue"

.PHONY: deploy
deploy:
	@if [ -z "$(INVENTORY)" ]; then echo "Set INVENTORY=... Example: make deploy INVENTORY=inventories/localhost.yml"; exit 2; fi
	./scripts/deploy.sh -i "$(INVENTORY)" $(if $(LIMIT),--limit "$(LIMIT)")

.PHONY: validate
validate:
	@if [ -z "$(INVENTORY)" ]; then echo "Set INVENTORY=... Example: make validate INVENTORY=inventories/localhost.yml"; exit 2; fi
	./scripts/validate.sh -i "$(INVENTORY)" $(if $(LIMIT),--limit "$(LIMIT)")

.PHONY: demo
demo:
	@if [ -z "$(INVENTORY)" ]; then echo "Set INVENTORY=... Example: make demo INVENTORY=inventories/localhost.yml"; exit 2; fi
	./scripts/deploy.sh -i "$(INVENTORY)" $(if $(LIMIT),--limit "$(LIMIT)")
	./scripts/validate.sh -i "$(INVENTORY)" $(if $(LIMIT),--limit "$(LIMIT)")
