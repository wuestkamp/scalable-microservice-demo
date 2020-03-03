FROM golang:1.12.4 as builder
ENV LIBRDKAFKA_VERSION 1.3.0

RUN apt-get -y update \
        && apt-get install -y --no-install-recommends upx-ucl zip libssl-dev \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*


RUN curl -Lk -o /root/librdkafka-${LIBRDKAFKA_VERSION}.tar.gz https://github.com/edenhill/librdkafka/archive/v${LIBRDKAFKA_VERSION}.tar.gz && \
      tar -xzf /root/librdkafka-${LIBRDKAFKA_VERSION}.tar.gz -C /root && \
      cd /root/librdkafka-${LIBRDKAFKA_VERSION} && \
      ./configure --prefix /usr && make && make install && make clean && ./configure --clean


WORKDIR /app/
COPY . .
ENV GO111MODULE=on
RUN go build -o app main.go
ENTRYPOINT ["/bin/sh", "-c", "./app"]
