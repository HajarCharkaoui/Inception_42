NAME = inception
COMPOSE_FILE = srcs/docker-compose.yml
DATA_DIR = /home/hacharka/data

all: up

up: build
	@mkdir -p $(DATA_DIR)/wordpress
	@mkdir -p $(DATA_DIR)/mariadb
	docker compose -f $(COMPOSE_FILE) up -d

build:
	docker compose -f $(COMPOSE_FILE) build

down:
	docker compose -f $(COMPOSE_FILE) down

clean: down
	docker system prune -a --force

fclean: clean
	@sudo rm -rf $(DATA_DIR)/wordpress/* $(DATA_DIR)/mariadb/*
	@docker volume prune -f

re: fclean all

.PHONY: all up build down clean fclean re