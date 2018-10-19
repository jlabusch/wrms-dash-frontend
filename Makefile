.PHONY: deps build network start stop clean

DOCKER=docker
IMAGE=jlabusch/wrms-dash-frontend
NAME=wrms-dash-frontend
NETWORK=wrms-dash-net
BUILD=$(shell ls ./wrms-dash-build-funcs/build.sh 2>/dev/null || ls ../wrms-dash-build-funcs/build.sh 2>/dev/null)
SHELL:=/bin/bash

deps:
	@test -n "$(BUILD)" || (echo 'wrms-dash-build-funcs not found; do you need "git submodule update --init"?'; false)
	@echo "Using $(BUILD)"

build: deps
	@mkdir -p ./static/admin
	$(BUILD) build $(IMAGE)

network:
	$(BUILD) network create $(NETWORK)

start: network
	test -n "$$DB_PASS" || (echo 'DB_PASS not set - try "export DB_PASS=`cat ../wrms-dash-frontend-db/pgpass`"'; false)
	$(DOCKER) run \
        --name $(NAME) \
        --detach  \
        --expose 80 \
        --env DJANGO_DEBUG \
        --env DJANGO_SECRET \
        --env DJANGO_BACKEND_URI=http://wrms-dash-api:80 \
        --env DB_PASS \
        --network $(NETWORK) \
        --volume /etc/localtime:/etc/localtime:ro \
        --rm \
        $(IMAGE)
	$(DOCKER) logs -f $(NAME) &

stop:
	$(DOCKER) stop $(NAME)

clean:
	$(BUILD) image delete $(IMAGE) || :

