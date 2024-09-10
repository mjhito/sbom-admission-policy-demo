# APP INFO
BUILD_DIR         := $(shell mktemp -d)
DOCKER_REGISTRY   ?= docker.io
IMAGE_PREFIX      ?= 
IMAGE_NAME        ?= 
IMAGE_TAG         ?= latest
PROXY             ?= http://proxy.foo.com:8000
NO_PROXY          ?= localhost,127.0.0.1,.svc.cluster.local
USE_PROXY         ?= false
PUSH_IMAGE        ?= false
# use this variable for image labels added in internal build process
LABEL             ?= 
COMMIT            ?= $(shell git rev-parse HEAD)
PYTHON            = python3
CHARTS            := $(filter-out deps, $(patsubst charts/%/.,%,$(wildcard charts/*/.)))
DISTRO            ?= ubuntu_focal
IMAGE             := ${DOCKER_REGISTRY}/${IMAGE_PREFIX}/${IMAGE_NAME}:${IMAGE_TAG}-${DISTRO}
UBUNTU_BASE_IMAGE ?=

# VERSION INFO
GIT_COMMIT = $(shell git rev-parse HEAD)
GIT_SHA    = $(shell git rev-parse --short HEAD)
GIT_TAG    = $(shell git describe --tags --abbrev=0 --exact-match 2>/dev/null)
GIT_DIRTY  = $(shell test -n "`git status --porcelain`" && echo "dirty" || echo "clean")

ifdef VERSION
	DOCKER_VERSION = $(VERSION)
endif

SHELL = /bin/bash

info:
	@echo "Version:           ${VERSION}"
	@echo "Git Tag:           ${GIT_TAG}"
	@echo "Git Commit:        ${GIT_COMMIT}"
	@echo "Git Tree State:    ${GIT_DIRTY}"
	@echo "Docker Version:    ${DOCKER_VERSION}"
	@echo "Registry:          ${DOCKER_REGISTRY}"
# Image URL to use all building/pushing image targets
IMG ?= docker.io/iuriikogan/

# Get the currently used golang install path (in GOPATH/bin, unless GOBIN is set)
ifeq (,$(shell go env GOBIN))
GOBIN=$(shell go env GOPATH)/bin
else
GOBIN=$(shell go env GOBIN)
endif


_BASE_IMAGE_ARG := $(if $(UBUNTU_BASE_IMAGE),--build-arg FROM="${UBUNTU_BASE_IMAGE}" ,)

MAKE_TARGET := build

# CONTAINER_TOOL defines the container tool to be used for building images.
# Be aware that the target commands are only tested with Docker which is
# scaffolded by default. However, you might want to replace it to use other
# tools. (i.e. podman)
CONTAINER_TOOL ?= docker

# Setting SHELL to bash allows bash commands to be executed by recipes.
# Options are set to exit when a recipe line exits non-zero or a piped command fails.
SHELL = /usr/bin/env bash -o pipefail
.SHELLFLAGS = -ec

# linting
LINTER_CMD          := "github.com/golangci/golangci-lint/cmd/golangci-lint" run
LINTER_CONFIG       := .golangci.yaml


PKG                 := ./...
TESTS               := .

.PHONY: clean
clean:
	@./scripts/destroy.sh