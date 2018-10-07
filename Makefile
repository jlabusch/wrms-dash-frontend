.PHONY: build network start stop clean

DOCKER=docker
IMAGE=jlabusch/wrms-dash-frontend
NAME=wrms-dash-frontend
STATIC_VOL=wrms-dash-frontend-vol
NETWORK=wrms-dash-net

build:
	@mkdir -p ./static/admin
	$(DOCKER) volume ls | grep -q $(STATIC_VOL) || $(DOCKER) volume create $(STATIC_VOL)
	$(DOCKER) build -t $(IMAGE) .
	$(DOCKER) run -it --rm -v $$PWD/static:/opt/static -v $(STATIC_VOL):/opt/staticserve $(IMAGE) ./manage.py collectstatic --noinput
	$(DOCKER) run -it --rm -v $$PWD/static:/opt/static -v $(STATIC_VOL):/opt/staticserve $(IMAGE) chown -R $$(id -u):$$(id -g) /opt/static/admin /opt/staticserve

network:
	$(DOCKER) network list | grep -q $(NETWORK) || $(DOCKER) network create $(NETWORK)

# If no DB, copy the default one out of the django image
db.sqlite3:
	CONTAINER=$$($(DOCKER) run -d -t -e TERM=xterm --rm jlabusch/wrms-dash-frontend top) && \
    $(DOCKER) cp $$CONTAINER:/opt/db.sqlite3 ./ && \
    $(DOCKER) stop $$CONTAINER

start: db.sqlite3
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
        --volume $$PWD/db.sqlite3:/opt/db.sqlite3 \
        --rm \
        $(IMAGE)
	$(DOCKER) logs -f $(NAME) &

stop:
	$(DOCKER) stop $(NAME)

clean:
	$(DOCKER) rmi $(IMAGE) $$($(DOCKER) images --filter dangling=true -q)
	$(DOCKER) volume rm $(STATIC_VOL)

