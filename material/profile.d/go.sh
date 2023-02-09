# https://go.dev/doc/code
# go env
# go env -w GOBIN=$PWD/bin
# go env -u GOBIN
# go list -f '{{.Target}}' .
# go mod tidy
: ${GOBIN:="${WORKDIR}/bin"}
: ${GOCACHE:="${WORKDIR}/.gocache"}

# : "${GOROOT:="/usr/local/go"}"
# # : "${GOPRIVATE:=""}"
