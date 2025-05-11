DOCKER_COMPOSE           = docker compose
EXEC_APP                 = $(DOCKER_COMPOSE) exec app

## ——————————————————————————————————————————————————————————————
## Project:
## ——————————————————————————————————————————————————————————————

install: app-build up ## Install and run the containers

up: ## Start the containers
	@$(DOCKER_COMPOSE) up --remove-orphans --force-recreate --detach

stop: ## Stop the containers
	@$(DOCKER_COMPOSE) stop

kill: ## Kill the containers
	@$(DOCKER_COMPOSE) kill
	@$(DOCKER_COMPOSE) down --volumes --remove-orphans

clean: kill ## Kill the containers and remove all generated Docker, Composer and Symfony artifacts
	@rm -rf var vendor docker/volumes/*

logs: ## Show real-time the containers logs
	@$(DOCKER_COMPOSE) logs

.PHONY: install build up stop kill clean logs

## ——————————————————————————————————————————————————————————————
## App:
## ——————————————————————————————————————————————————————————————

app-install: app-build app-up ## Install and run the app containers

app-build: ## Build the app container
	@$(DOCKER_COMPOSE) build --pull --no-cache app nginx

app-up: ## Start the app containers
	@$(DOCKER_COMPOSE) -f docker-compose.yml up app nginx --detach

app-up-local: ## Start the app containers for local development
	@$(DOCKER_COMPOSE) -f docker-compose.yml -f docker-compose.local.yml up app nginx --detach

app-bash: ## Connect to the app container
	@$(EXEC_APP) bash

.PHONY: app-install app-build app-up app-up-local app-restart app-bash


## ——————————————————————————————————————————————————————————————
## Help:
## ——————————————————————————————————————————————————————————————

help: ## Outputs this help screen
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-24s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m## /[33m/' && printf "\n"

.PHONY: help

.DEFAULT_GOAL := help