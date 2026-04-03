INVENTORY ?=
LIMIT ?=
PLAYBOOK ?=

.PHONY: help
help:
	@echo "Usage:"
	@echo "  make deploy INVENTORY=inventories/localhost.yml"
	@echo "  make validate INVENTORY=inventories/localhost.yml"
	@echo "  make deploy-validate INVENTORY=inventories/localhost.yml"
	@echo "  make deploy INVENTORY=inventories/proxmox-lab.yml LIMIT=ubuntuBlue"
	@echo "  make playbook PLAYBOOK=playbooks/<name>.yml INVENTORY=inventories/proxmox-lab.yml LIMIT=<target>"

.PHONY: deploy
deploy:
	@if [ -z "$(INVENTORY)" ]; then echo "Set INVENTORY=... Example: make deploy INVENTORY=inventories/localhost.yml"; exit 2; fi
	./scripts/deploy.sh -i "$(INVENTORY)" $(if $(LIMIT),--limit "$(LIMIT)")

.PHONY: validate
validate:
	@if [ -z "$(INVENTORY)" ]; then echo "Set INVENTORY=... Example: make validate INVENTORY=inventories/localhost.yml"; exit 2; fi
	./scripts/validate.sh -i "$(INVENTORY)" $(if $(LIMIT),--limit "$(LIMIT)")

.PHONY: deploy-validate
deploy-validate:
	@if [ -z "$(INVENTORY)" ]; then echo "Set INVENTORY=... Example: make deploy-validate INVENTORY=inventories/localhost.yml"; exit 2; fi
	./scripts/deploy.sh -i "$(INVENTORY)" $(if $(LIMIT),--limit "$(LIMIT)")
	./scripts/validate.sh -i "$(INVENTORY)" $(if $(LIMIT),--limit "$(LIMIT)")

.PHONY: playbook
playbook:
	@if [ -z "$(PLAYBOOK)" ]; then echo "Set PLAYBOOK=... Example: make playbook PLAYBOOK=playbooks/check_connectivity.yml INVENTORY=inventories/proxmox-lab.yml"; exit 2; fi
	@if [ -z "$(INVENTORY)" ]; then echo "Set INVENTORY=... Example: make playbook PLAYBOOK=playbooks/check_connectivity.yml INVENTORY=inventories/proxmox-lab.yml"; exit 2; fi
	./scripts/run_playbook.sh "$(PLAYBOOK)" -i "$(INVENTORY)" $(if $(LIMIT),--limit "$(LIMIT)")
