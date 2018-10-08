.PHONY: build network start stop clean

DOCKER=docker
IMAGE=jlabusch/wrms-dash-frontend
NAME=wrms-dash-frontend
STATIC_VOL=wrms-dash-frontend-vol
CONFIG_VOL=wrms-dash-config-vol
NETWORK=wrms-dash-net

build:
	@mkdir -p ./static/admin
	$(DOCKER) volume ls | grep -q $(STATIC_VOL) || $(DOCKER) volume create $(STATIC_VOL)
	$(DOCKER) build -t $(IMAGE) .
	# collect static files into $(STATIC_VOL) and fix file ownership
	$(DOCKER) run -it --rm -v $$PWD/static:/opt/static -v $(STATIC_VOL):/opt/staticserve $(IMAGE) ./manage.py collectstatic --noinput
	$(DOCKER) run -it --rm -v $$PWD/static:/opt/static -v $(STATIC_VOL):/opt/staticserve $(IMAGE) chown -R $$(id -u):$$(id -g) /opt/static/admin /opt/staticserve
	# If no DB, copy the default one into $(CONFIG_VOL)
	CONTAINER=$$($(DOCKER) run -d -t -v $(CONFIG_VOL):/opt/config -e TERM=xterm --rm $(IMAGE) top) && \
    $(DOCKER) exec -it $$CONTAINER cp -n /opt/db/db.sqlite3 /opt/config/ && \
    $(DOCKER) stop $$CONTAINER

network:
	$(DOCKER) network list | grep -q $(NETWORK) || $(DOCKER) network create $(NETWORK)

start:
	$(DOCKER) run \
        --name $(NAME) \
        --detach  \
        --expose 80 \
        --env DJANGO_DEBUG \
        --env DJANGO_SECRET \
        --env DJANGO_BACKEND_URI=http://wrms-dash-api:80 \
        --network $(NETWORK) \
        --volume /etc/localtime:/etc/localtime:ro \
        --volume $(STATIC_VOL):/opt/staticserve:ro \
        --volume $(CONFIG_VOL):/opt/db \
        --rm \
        $(IMAGE)
	$(DOCKER) logs -f $(NAME) &

stop:
	$(DOCKER) stop $(NAME)

clean:
	$(DOCKER) rmi $(IMAGE) $$($(DOCKER) images --filter dangling=true -q)
	$(DOCKER) volume rm $(STATIC_VOL)

