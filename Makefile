ANSIBLE_PLAYBOOK ?= ansible-playbook

.PHONY: deploy
deploy:
	./scripts/deploy.sh

.PHONY: validate
validate:
	./scripts/validate.sh

.PHONY: score
score:
	./scripts/score.sh

.PHONY: demo
demo:
	./scripts/deploy.sh
	./scripts/validate.sh
	./scripts/score.sh

