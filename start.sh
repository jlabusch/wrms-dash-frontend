#!/bin/bash

until ./manage.py makemigrations
do
    sleep 3
done
./manage.py migrate

gunicorn -w 4 --error-logfile - --log-level info -b 0.0.0.0:80 --env DJANGO_SETTINGS_MODULE=dashboard.settings dashboard.wsgi

