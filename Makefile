#!make

include .env
export

MAKEFLAGS += --always-make

PACKAGES=./internal/... ./pkg/...
BUILD_VERSION=devel
REGISTRY_IMAGE_PREFIX=egnd/goproject

.PHONY: help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' Makefile | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

%:
	@:

########################################################################################################################

build: vendor ## Build application
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -mod=readonly -ldflags "-X 'main.appVersion=$(BUILD_VERSION)-linux-amd64'" -o bin/app-linux-amd64 *.go
	chmod +x bin/app-*
	@ls -lah bin

docker-build:
	docker run --rm -t --volume $$(pwd):/src:rw $(DC_APP_ENV_IMAGE) make build
	@echo "Success"

image: ## Build app docker image
	docker build --build-arg BASE_IMG=${DC_APP_BASE_IMAGE} --tag=$(DC_APP_IMAGE) .

image-env: ## Build docker image for app debug
	docker build --build-arg BASE_IMG=${DC_APP_BASE_IMAGE} --tag=$(DC_APP_ENV_IMAGE) --target=env .

lint: ## Lint source code
	golangci-lint run --color=always --config=.golangci.yml $(PACKAGES)

docker-lint:
	docker run --rm -t --volume $$(pwd):/src:rw $(DC_APP_ENV_IMAGE) make lint
	@echo "Success"

test: mocks ## Test source code
	go test -mod=readonly -cover -covermode=count -coverprofile=coverage.out $(PACKAGES)
	go tool cover -html=coverage.out -o coverage.html
	go tool cover -func=coverage.out

docker-test:
	docker run --rm -t --volume $$(pwd):/src:rw $(DC_APP_ENV_IMAGE) make test
	@echo "Success, read report at file://$$(pwd)/coverage.html"

mocks: ## Generate mocks
	@rm -rf gen/mocks && mkdir -p gen/mocks
	mockery --all --case=underscore --recursive --outpkg=mocks --output=gen/mocks --dir=internal
	mockery --all --case=underscore --recursive --outpkg=mocks --output=gen/mocks --dir=pkg

docker-mocks:
	docker run --rm -t --volume $$(pwd):/src:rw $(DC_APP_ENV_IMAGE) make mocks
	@echo "Success"

vendor: ## Resolve dependencies
	go mod tidy

docker-vendor:
	docker run --rm -t --volume $$(pwd):/src:rw $(DC_APP_ENV_IMAGE) make vendor
	@echo "Success"

owner: ## Reset folder owner
	sudo chown -R $$(id -u):$$(id -u) ./
	@echo "Success"

check-conflicts: ## Find git conflicts
	@if grep -rn '^<<<\<<<< ' .; then exit 1; fi
	@if grep -rn '^===\====$$' .; then exit 1; fi
	@if grep -rn '^>>>\>>>> ' .; then exit 1; fi
	@echo "All is OK"

check-todos: ## Find TODO's
	@if grep -rn '@TO\DO:' .; then exit 1; fi
	@echo "All is OK"

check-master: ## Check for latest master in current branch
	@git remote update
	@if ! git log --pretty=format:'%H' | grep $$(git log --pretty=format:'%H' -n 1 origin/master) > /dev/null; then exit 1; fi
	@echo "All is OK"

codecov: mocks
	CGO_ENABLED=1 go test -race -coverprofile=coverage.txt -covermode=atomic ./pkg/...

release: ## Create release archive
	zip -9 -roTj release-$(BUILD_VERSION).zip README.md
	@ls -lah release-$(BUILD_VERSION).zip
