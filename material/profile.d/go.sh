set -o allexport

# https://go.dev/doc/code
# go env -w GOBIN=$PWD/bin
# go env -u GOBIN
: "${GOBIN:="$WORKDIR/bin"}"

# : "${GOROOT:="/usr/local/go"}"
# # : "${GOPRIVATE:=""}"
# PATH=$PATH:${GOROOT}/bin:${GOBIN}
set +o allexport
