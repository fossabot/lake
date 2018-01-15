VERSION = $$(git rev-parse --abbrev-ref HEAD 2> /dev/null | rev | cut -d/ -f1 | rev)
CORES := $$(getconf _NPROCESSORS_ONLN)
MACOSX_DEPLOYMENT_TARGET := $$(sw_vers -productVersion)

.PHONY: all
all: bootstrap bundle test bbtest

.PHONY: bootstrap
bootstrap:
	docker-compose build go

.PHONY: fetch
fetch:
	docker-compose run fetch

.PHONY: build-lint
build-lint:
	docker-compose build lint

.PHONY: build-sync
build-sync:
	docker-compose build sync

.PHONY: build-package
build-package:
	docker-compose build package

.PHONY: lint
lint:
	docker-compose run --rm lint || :

.PHONY: sync
sync:
	docker-compose run --rm sync

.PHONY: test
test:
	docker-compose run --rm test

.PHONY: package
package:
	VERSION=$(VERSION) \
	MACOSX_DEPLOYMENT_TARGET=$(MACOSX_DEPLOYMENT_TARGET) \
	docker-compose run --rm package
	docker-compose build service

.PHONY: run
run:
	docker-compose run --rm --service-ports service run

.PHONY: version
version:
	docker-compose run --rm service version

.PHONY: perf
perf: build-perf
	./dev/lifecycle/performance
