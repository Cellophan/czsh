REGISTRY=cell
CONTEXT=$(abspath $(shell pwd))
IMAGE=$(notdir ${CONTEXT})
BLAH=${CONTEXT}

.PHONY: build

build:
	docker build -t ${REGISTRY}/${IMAGE} ${CONTEXT}

fresh:
	docker build -t ${REGISTRY}/${IMAGE} --pull --no-cache ${CONTEXT}
