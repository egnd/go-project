ARG BASE_IMG=golang:1.15-alpine
FROM ${BASE_IMG} as env
ENV TZ Europe/Moscow
ENV GOPROXY https://proxy.golang.org,direct
ENV GOSUMDB off
ENV GOLANGCI_VERSION 1.32.2
RUN apk add -q --no-cache build-base tzdata openssh git make grep ca-certificates && \
    which ssh && git --version && make --version && grep --version && \
    update-ca-certificates && \
    rm -rf /var/cache/apk/*
RUN wget -O- -nv https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b ${GOPATH}/bin v${GOLANGCI_VERSION} && \
    golangci-lint --version
RUN go get -u \
        github.com/vektra/mockery/.../ \
    2>&1 && \
    mockery --version
WORKDIR /src

ARG APP_BUILD_VERSION=devel
FROM env as build
COPY . .
RUN make build BUILD_VERSION=${APP_BUILD_VERSION}

FROM scratch as appimg
ENV TZ Europe/Moscow
WORKDIR /
COPY --from=env /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=env /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /src/configs configs
ENTRYPOINT ["bin/app"]

FROM appimg as linux-amd64
COPY --from=build /src/bin/app-linux-amd64 bin/app
