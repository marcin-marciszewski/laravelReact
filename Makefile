compose:
	docker compose -f compose.dev.yaml up --build -d --remove-orphans

compose-down:
	docker compose -f compose.dev.yaml down
