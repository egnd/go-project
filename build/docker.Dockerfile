ARG BASE_IMG=docker
FROM ${BASE_IMG}

ENV DOCKER_DRIVER=overlay2
ENV DOCKER_HOST=tcp://docker:2375
ENV DOCKER_TLS_CERTDIR=

RUN apk add --quiet --no-cache py3-pip && \
    pip3 --version

RUN apk add --quiet --no-cache --virtual .compose-deps python3-dev libffi-dev openssl-dev gcc libc-dev && \
        pip3 install --quiet --upgrade --no-cache-dir pip docker docker-compose && \
        apk del --quiet .compose-deps && \
    docker --version && docker-compose --version