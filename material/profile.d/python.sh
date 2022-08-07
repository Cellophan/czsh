# default pip needs
PATH="${HOME}/.local/bin:${PATH}"
export PATH

# pyenv
PYENV_ROOT="${HOME}/.pyenv"
PATH="${PYENV_ROOT}/bin:${PYENV_ROOT}/shims:${PATH}"
export PYENV_ROOT PATH

chmod a+w \
    ${PYENV_ROOT} ${PYENV_ROOT}/shims \
    ${PYENV_ROOT}/versions ${PYENV_ROOT}/version

if [ ! -d ${HOME}/.local/lib ]; then
    mkdir -p ${HOME}/.local/lib
    chown ${USER}. ${HOME}/.local/lib
fi

#debugger
export PYTHONBREAKPOINT="pudb.set_trace"

# poetry
export POETRY_VIRTUALENVS_IN_PROJECT=true
