FROM python:3.6-stretch

WORKDIR /opt

COPY requirements.txt /opt/

RUN pip install -r requirements.txt

COPY . /opt/

CMD [ "/opt/start.sh" ]
