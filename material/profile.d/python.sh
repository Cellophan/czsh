# pyenv
PYENV_ROOT="${HOME}/.pyenv"
chmod a+w ${PYENV_ROOT} ${PYENV_ROOT}/shims ${PYENV_ROOT}/versions

if [ ! -d ${HOME}/.local/lib ]; then
  mkdir -p ${HOME}/.local/lib
  chown ${USER}. ${HOME}/.local/lib
fi

# poetry
export POETRY_VIRTUALENVS_IN_PROJECT=true

