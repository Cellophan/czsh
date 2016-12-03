#!/bin/bash
set -eEuo pipefail

stacktrace () {
	echo "FAIL: unhandled error. stacktrace:"
	i=0
	while caller $i; do
		i=$((i+1))
	done
}

init() {
	trap "stacktrace" ERR
	registry="cell"
	context="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
	dirname="$(basename ${context})"
	image="${registry:+${registry}/}${dirname}"
}

build() {
	local action=${1:-}
	local tag=${2:-latest}
	local status=0

	echo "Building ${image}:${tag} ..."
	if [ "${action}" == "release" ]; then
		docker tag ${image}:n ${image}:n-1 &>/dev/null || true
		docker rmi ${image}:latest ${image}:n &>/dev/null || true
	fi

	out=$(docker build -t ${image}:n ${context} 2>&1 || status=$?)
	if [ ${status} -ne 0 ]; then
		echo -e ${out} >&2
		exit $status
	fi

	docker tag ${image}:n ${image}:latest

	if [ "${action}" == "release" ]; then
		docker tag ${image}:n ${image}:${tag}
	fi
}

all() {
	local githash=
	if [ $(cd ${context} && git diff-index  HEAD -- | wc -l) -eq 0 ]; then
		githash="$(cd ${context} && git rev-parse --verify HEAD)"
	fi

	if [ -n "${githash}" ]; then
		local already=0
		docker inspect ${image}:${githash} &>/dev/null || already=$?
		if [ $already -eq 0 ]; then
			echo "Already built: ${image}:${githash}"
			exit 1
		fi

		echo "Release"
		build release $githash
	else
		echo "Snapshot"
		build snapshot
	fi
}

main() {

	if [ -n "${1:-}" -a "$(type -t ${1:-})" != "function" ]; then
		echo -e "Invalid action!\n" >&2
		exit 1
	fi

	init
	${@:-all}
}

main $@
