IMAGE_NAME ?= rt-log4j-attacker
COMPOSE ?= docker compose
ATTACKER_CONTAINER ?= attacker
IMAGE_TARBALL ?= rt-log4j-attacker.tar

.PHONY: build makefilebuild up down shell configure save load

build:
	docker build -f docker/attacker/Dockerfile -t $(IMAGE_NAME) .

makefilebuild: build

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

shell:
	docker exec -it $(ATTACKER_CONTAINER) /bin/bash

configure:
	bash setup/configure.sh

save:
	docker save -o $(IMAGE_TARBALL) $(IMAGE_NAME)

load:
	docker load -i $(IMAGE_TARBALL)
