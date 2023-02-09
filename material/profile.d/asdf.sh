: "${ASDF_DIR:="/etc/skel/.asdf"}"
: "${ASDF_DATA_DIR:="${WORKDIR}/.asdf"}"

PATH="/etc/skel/.asdf/bin:${PATH}"

if [ -d "${WORKDIR}/.asdf/shims" ]; then
    PATH="${WORKDIR}/.asdf/shims:${PATH}"
fi
