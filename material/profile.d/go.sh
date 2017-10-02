: "${GOPATH:="$WORKDIR"}"
: "${GOBIN:="${GOPATH}/bin"}"
PATH=${PATH}:/usr/local/go/bin:${GOBIN}
export GOPATH GOBIN PATH

