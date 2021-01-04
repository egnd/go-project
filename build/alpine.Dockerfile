ARG BASE_IMG=alpine
FROM ${BASE_IMG}

ENV DOCKER_DRIVER=overlay2
ENV DOCKER_HOST=tcp://docker:2375
ENV DOCKER_TLS_CERTDIR=

RUN apk add --quiet --no-cache git grep make
