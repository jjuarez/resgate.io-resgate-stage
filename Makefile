#!/usr/bin/env make

CONFIG ?= .envrc

-include $(CONFIG)

NATS_VERSION      ?= 2.1.7-alpine3.11
RESGATE_VERSION   ?= latest
NATS_NETWORK_NAME ?= resgate

NATS_DOCKER_IMAGE      := nats:$(NATS_VERSION)
RESGATE_DOCKER_IMAGE   := resgateio/resgate:$(RESGATE_VERSION)
NATS_CONTAINER_NAME    := nats
RESGATE_CONTAINER_NAME := resgate

.DEFAULT_GOAL := help


.PHONY: help
help:
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)


.PHONY: .docker-pull
.docker-pull:
	@docker pull $(NATS_DOCKER_IMAGE)
	@docker pull $(RESGATE_DOCKER_IMAGE)


.PHONY: .docker-network
.docker-network:
	@docker network create $(NATS_NETWORK_NAME)


.PHONY: setup
setup: .docker-pull .docker-network  ## Setup all stuff, docker images, docker network, etc


.PHONY: run 
run:  ## Start all the stuff NATS.io server and resgate API gateway
	@docker run --name $(NATS_CONTAINER_NAME)    --rm -d -p $(NATS_PORT):4222    --net $(NATS_NETWORK_NAME) $(NATS_DOCKER_IMAGE)
	@docker run --name $(RESGATE_CONTAINER_NAME) --rm -d -p $(RESGATE_PORT):8080 --net $(NATS_NETWORK_NAME) $(RESGATE_DOCKER_IMAGE) --nats nats://nats:$(NATS_PORT)

.PHONY: test
test:
	@docker network list --filter "name=$(NATS_NETWORK_NAME)"
	@docker container list --filter "name=$(NATS_CONTAINER_NAME)|$(RESGATE_CONTAINER_NAME)"

.PHONY: inspect
inspect:  ## Show the current status of the docker containers and network
	@docker container inspect $(NATS_CONTAINER_NAME)
	@docker container inspect $(RESGATE_CONTAINER_NAME)
	@docker network inspect $(NATS_NETWORK_NAME)

