if [[ ${USER} != "root" ]]; then
    usermod -aG audio ${USER}
fi
