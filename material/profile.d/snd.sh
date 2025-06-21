if [[ -n ${XDG_RUNTIME_DIR} ]]; then
    if [[ ${USER} != "root" ]]; then
        usermod -aG audio ${USER}
    fi

    PULSE_SERVER=unix:${XDG_RUNTIME_DIR}/pulse/native
fi
