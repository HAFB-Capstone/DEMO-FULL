setup:
	docker compose build

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f

reset:
	@chmod +x restore.sh
	@./restore.sh

test:
	@chmod +x tools/test/*.sh
	@./tools/test/test_attack_chain.sh
	@./tools/test/test_tools.sh

test-chain:
	@chmod +x tools/test/*.sh
	@./tools/test/test_attack_chain.sh
	
test-tools:
	@chmod +x tools/test/*.sh
	@./tools/test/test_tools.sh

