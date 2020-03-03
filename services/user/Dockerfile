FROM python:3.8.1-alpine
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

RUN apk add --no-cache gcc musl-dev librdkafka-dev \
    && pip install -U pymongo==3.10.1 PyPubSub==4.0.3 avro-python3==1.9.2.1 crcmod requests==2.22.0 confluent_kafka==1.3.0

COPY . /usr/src/app

ENTRYPOINT ["python3", "-u", "app.py"]
