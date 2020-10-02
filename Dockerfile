FROM python:3.8-buster

WORKDIR /opt

COPY requirements.txt /opt/

RUN pip install -r requirements.txt

COPY . /opt/

RUN ./manage.py collectstatic --noinput

CMD [ "/opt/start.sh" ]
