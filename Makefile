# https://tech.davis-hansson.com/p/make/
# http://agdr.org/2020/05/14/Polyglot-Makefiles.html
ifeq ($(origin .RECIPEPREFIX), undefined)
  $(error This Make does not support .RECIPEPREFIX. Please use GNU Make 4.0 or later)
endif
.RECIPEPREFIX = >
SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

REGISTRY=cell
CONTEXT=$(abspath $(shell pwd))
IMAGE=$(notdir ${CONTEXT})


# Check if everything is commited in git
git-detect:
> git update-index --refresh
> git diff-index --quiet HEAD --

build: $(shell find material -type f) Dockerfile
> docker build -t ${REGISTRY}/${IMAGE} ${CONTEXT}
.PHONY: build

fresh:
> docker build -t ${REGISTRY}/${IMAGE} --pull --no-cache ${CONTEXT}
.PHONY: fresh

use:
> ./material/payload/deploy/czsh
.PHONY: use

push:
> docker push ${REGISTRY}/${IMAGE}
.PHONY: push

publish: build git-detect push
> ssh plic " \
    cd Repos/outer.systems/plic/head.tf/ \
    && git pull \
    && docker stack deploy -c docker-compose.yml --with-registry-auth plic"
.PHONY: publish


