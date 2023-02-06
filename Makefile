include .env

REGISTRY           ?= ghcr.io
TAG_VERSION        ?= $(shell git describe --tags --abbrev=0)

IMAGE_NAME         := goreleaser/goreleaser-osxcross:$(TAG_VERSION)

ifneq ($(REGISTRY),)
	IMAGE_NAME     := $(REGISTRY)/$(IMAGE_NAME)
endif

OSX_SDK            := MacOSX12.0.sdk
OSX_SDK_SUM        := ac07f28c09e6a3b09a1c01f1535ee71abe8017beaedd09181c8f08936a510ffd
OSX_VERSION_MIN    := 10.9
OSX_CROSS_COMMIT   := e59a63461da2cbc20cb0a5bbfc954730e50a5472
DEBIAN_FRONTEND    := noninteractive

DOCKER_BUILD=docker build

SUBIMAGES ?= amd64 \
arm64

.PHONY: gen-changelog
gen-changelog:
	@echo "generating changelog to changelog"
	./scripts/genchangelog.sh $(shell git describe --tags --abbrev=0) changelog.md

.PHONY: osxcross-%
osxcross-%:
	@echo "building $(IMAGE_NAME)-$(@:osxcross-%=%)"
	$(DOCKER_BUILD) --platform=linux/$(@:osxcross-%=%) -t $(IMAGE_NAME)-$(@:osxcross-%=%) \
		--build-arg OSX_SDK=$(OSX_SDK) \
		--build-arg OSX_SDK_SUM=$(OSX_SDK_SUM) \
		--build-arg OSX_VERSION_MIN=$(OSX_VERSION_MIN) \
		--build-arg OSX_CROSS_COMMIT=$(OSX_CROSS_COMMIT) \
		--build-arg DEBIAN_FRONTEND=$(DEBIAN_FRONTEND) \
		-f Dockerfile .

.PHONY: osxcross
osxcross: $(patsubst %, osxcross-%,$(SUBIMAGES))

.PHONY: docker-push-%
docker-push-%:
	docker push $(IMAGE_NAME)-$(@:docker-push-%=%)

.PHONY: docker-push
docker-push: $(patsubst %, docker-push-%,$(SUBIMAGES))

.PHONY: manifest-create
manifest-create:
	@echo "creating manifest $(IMAGE_NAME)"
	docker manifest create $(IMAGE_NAME) $(foreach arch,$(SUBIMAGES), --amend $(IMAGE_NAME)-$(arch))

.PHONY: manifest-push
manifest-push:
	@echo "pushing manifest $(IMAGE_NAME)"
	docker manifest push $(IMAGE_NAME)

.PHONY: tags
tags:
	@echo $(IMAGE_NAME) $(foreach arch,$(SUBIMAGES), $(IMAGE_NAME)-$(arch))

.PHONY: tag
tag:
	@echo $(TAG_VERSION)
