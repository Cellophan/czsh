#golang env
FROM ubuntu:latest as golang-tools

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends curl git ca-certificates
RUN curl -sSL https://dl.google.com/go/go1.13.1.linux-amd64.tar.gz >/tmp/go.tgz &&\
  tar -C /usr/local -xz -f /tmp/go.tgz &&\
  chown -R root:root /usr/local/go
ENV GOPATH=/tmp/go GOBIN=/usr/local/go/bin PATH=${PATH}:/usr/local/go/bin

# RUN go get golang.org/x/tools/cmd/godoc
# RUN go get golang.org/x/tools/cmd/goimports
# RUN go get golang.org/x/tools/cmd/gorename
# RUN go get github.com/nsf/gocode
# RUN go get github.com/rogpeppe/godef
# # RUN go get github.com/golang/lint/golint
# RUN go get github.com/kisielk/errcheck
# RUN go get github.com/jstemmer/gotags

RUN go get github.com/Originate/git-town
# RUN go get github.com/interesse/git-town
RUN go get github.com/erning/gorun
RUN go get mvdan.cc/sh/cmd/shfmt
RUN go get github.com/digitalocean/doctl/cmd/doctl
RUN GO111MODULE=on go get github.com/mikefarah/yq/v3
#RUN GO111MODULE=on go get github.com/bazelbuild/bazelisk

##build tools
#FROM ubuntu:rolling as built-tools
#RUN apt-get update
#RUN DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends wget git ca-certificates curl make gcc
#
### Skopeo
### From https://github.com/containers/skopeo
##RUN apt-get update
##RUN DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends wget git ca-certificates curl
##RUN DEBIAN_FRONTEND=noninteractive apt-get install -qy libgpgme-dev libassuan-dev libbtrfs-dev libdevmapper-dev libostree-dev
##RUN curl -sSL https://dl.google.com/go/go1.13.1.linux-amd64.tar.gz >/tmp/go.tgz &&\
##  tar -C /usr/local -xz -f /tmp/go.tgz &&\
##  chown -R root:root /usr/local/go
##ENV GOPATH=/tmp/go GOBIN=/usr/local/go/bin PATH=${PATH}:/usr/local/go/bin
##
##RUN git clone --depth 1 https://github.com/containers/skopeo $GOPATH/src/github.com/containers/skopeo
##RUN cd $GOPATH/src/github.com/containers/skopeo &&\
##  make binary-local DISABLE_CGO=1 &&\
##  mv skopeo /usr/local/bin/
#
### gh cli
### From https://github.com/cli/cli/blob/master/source.md
##RUN git clone --depth 1 https://github.com/cli/cli.git $GOPATH/githubcli
##RUN cd $GOPATH/githubcli &&\
##  make
##RUN mv $GOPATH/githubcli/bin/* /usr/local/bin/

#download tools
FROM ubuntu:latest as downloaded-tools
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends curl ca-certificates unzip git
WORKDIR /usr/local/bin

#RUN curl -sSL https://storage.googleapis.com/container-diff/latest/container-diff-linux-amd64 >/usr/local/bin/container-diff
RUN curl -sSL https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m) >/usr/local/bin/docker-compose
#RUN curl -sSL https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-latest >/usr/local/bin/ecs-cli
#RUN curl -sSL https://github.com/concourse/concourse/releases/download/v3.14.1/fly_linux_amd64 >/usr/local/bin/fly
RUN curl -sSLO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN git clone -b v1.4 --depth 1 https://github.com/gdraheim/docker-systemctl-replacement.git /tmp/docker-systemctl-replacement &&\
  cp /tmp/docker-systemctl-replacement/files/docker/systemctl3.py /usr/local/bin/systemctl
RUN curl -sSL https://releases.hashicorp.com/terraform/0.13.5/terraform_0.13.5_linux_amd64.zip >/tmp/terraform.zip &&\
  unzip /tmp/terraform.zip
RUN curl -sSL https://github.com/exercism/cli/releases/download/v3.0.13/exercism-3.0.13-linux-x86_64.tar.gz \
  | tar --directory=/usr/local/bin -xvz exercism

RUN chmod +x /usr/local/bin/*

#Python
#FROM ubuntu:latest as python
#
#ENV PYTHON_VERSION="3.9.4"
#RUN echo Install build dependencies &&\
#  apt-get update &&\
#  DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends \
#    ca-certificates make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev git &&\
#  apt-get clean -y && rm -rf /var/lib/apt/lists/* &&\
#  echo Get/Compile python &&\
#  cd /tmp &&\
#  wget -q -O python.tar.xz https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz &&\
#  tar -xJf python.tar.xz &&\
#  cd Python* &&\
#  ./configure --enable-optimizations &&\
#  make &&\
#  make install &&\
#  make clean &&\
#  rm -rf /tmp/* &&\
#  apt remove -qy build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev llvm libncurses5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev &&\
#  apt autoremove -qy &&\
#  ln -s /usr/local/bin/python3 /usr/local/bin/python &&\
#  ln -s /usr/local/bin/pip3 /usr/local/bin/pip &&\
#  ln -s /usr/local/bin/pydoc3 /usr/local/bin/pydoc

#Main
FROM cell/playground
ENV DOCKER_IMAGE="cell/czsh"

#zsh and oh-my-zsh
#https://hub.docker.com/r/nacyot/ubuntu/~/dockerfile/
RUN apt-get update &&\
  apt-get install -qy --no-install-recommends zsh &&\
  apt-get clean -y && rm -rf /var/lib/apt/lists/* &&\
  git clone --depth 1 https://github.com/robbyrussell/oh-my-zsh.git /etc/skel/.oh-my-zsh &&\
  ln -s /etc/skel/.oh-my-zsh /root &&\
  ln -s /etc/skel/.zshrc /root &&\
  find . -name .git -type d -exec echo rm -rf {} \;

#agnoster
#RUN git clone --depth 1 https://github.com/Cellophan/agnoster-zsh-theme /etc/skel/.oh-my-zsh/custom/themes/agnoster-zsh-theme &&\
RUN git clone --depth 1 https://github.com/agnoster/agnoster-zsh-theme /etc/skel/.oh-my-zsh/custom/themes/agnoster-zsh-theme &&\
  ln -s /etc/skel/.oh-my-zsh/custom/themes/agnoster-zsh-theme/agnoster.zsh-theme /etc/skel/.oh-my-zsh/custom/themes &&\
  find /etc/skel/.oh-my-zsh/custom/themes -name .git -type d -exec echo rm -rf {} \;
#zsh-autosuggestions
RUN git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions /etc/skel/.oh-my-zsh/custom/plugins/zsh-autosuggestions &&\
  find /etc/skel/.oh-my-zsh/custom/plugins/zsh-autosuggestions -name .git -type d -exec echo rm -rf {} \;
#zsh-autosuggestions
RUN git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git /etc/skel/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting &&\
  find /etc/skel/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting -name .git -type d -exec echo rm -rf {} \;
#awsudo
RUN git clone --depth 1 https://github.com/outersystems/awsudo2.git /tmp/awsudo2 &&\
  mkdir /etc/skel/.oh-my-zsh/custom/plugins/awsudo2 &&\
  cp /tmp/awsudo2/completion/zsh/awsudo2.plugin.zsh /etc/skel/.oh-my-zsh/custom/plugins/awsudo2/ &&\
  rm -rf /tmp/awsudo2
#kubectl
COPY --from=downloaded-tools /usr/local/bin/kubectl  /usr/local/bin/kubectl
RUN mkdir -p /etc/skel/.oh-my-zsh/custom/plugins/kubectl &&\
  kubectl completion zsh > /etc/skel/.oh-my-zsh/custom/plugins/kubectl/kubectl.plugin.zsh

#fzf
RUN apt-get update &&\
  apt-get install -qy --no-install-recommends silversearcher-ag &&\
  apt-get clean -y && rm -rf /var/lib/apt/lists/* &&\
  git clone --depth 1 https://github.com/junegunn/fzf.git /etc/skel/.oh-my-zsh/custom/plugins/fzf &&\
  /etc/skel/.oh-my-zsh/custom/plugins/fzf/install --bin &&\
  git clone --depth 1 https://github.com/Treri/fzf-zsh.git /etc/skel/.oh-my-zsh/custom/plugins/fzf-zsh &&\
  find /etc/skel/.oh-my-zsh/custom/plugins -name .git -type d -exec echo rm -rf {} \;

#powerline
RUN apt-get update &&\
  apt-get install -qy --no-install-recommends wget dconf-cli &&\
  apt-get clean -y && rm -rf /var/lib/apt/lists/* &&\
  mkdir -p /etc/skel/.fonts /etc/skel/.config/fontconfig/conf.d &&\
  wget -q -P /etc/skel/.fonts/ https://github.com/powerline/powerline/raw/develop/font/PowerlineSymbols.otf &&\
  wget -q -P /etc/skel/.config/fontconfig/conf.d https://github.com/powerline/powerline/raw/develop/font/10-powerline-symbols.conf &&\
  apt-get remove -y wget dconf-cli

RUN apt-get update &&\
  apt-get install -qy --no-install-recommends fontconfig locales &&\
  apt-get clean -y && rm -rf /var/lib/apt/lists/* &&\
  locale-gen en_US.UTF-8 en_US &&\
  DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales &&\
  /usr/sbin/update-locale LANG=C.UTF-8 &&\
  chsh -s /bin/zsh

#nnn
# https://github.com/jarun/nnn
# TODO: make a link for czsh instead of an extra layer?
COPY material/payload/deploy/czsh /usr/local/bin/
# TODO: Use NNN_MULTISCRIPT instead of EDITOR and NNN_USE_EDITOR for starting cvim?
RUN apt-get update &&\
  DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends nnn &&\
  apt-get clean -y && rm -rf /var/lib/apt/lists/*

#pass
RUN apt-get update &&\
  DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends pass gnupg2 qrencode xclip pass-extension-otp oathtool &&\
  apt-get clean -y && rm -rf /var/lib/apt/lists/*

#python3
# RUN apt-get update &&\
#   DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends python3 python3-pip &&\
#   DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends python3-wheel &&\
#   pip3 install --system setuptools &&\
#   pip3 install --system pytest &&\
#   apt-get clean -y && rm -rf /var/lib/apt/lists/*

#python
#FROM ubuntu:rolling as python-stuff
#RUN apt-get update &&\
#  apt-get install -qy --no-install-recommends curl ca-certificates xz-utils &&\
#  apt-get clean -y && rm -rf /var/lib/apt/lists/*
#RUN mkdir -p /usr/src/python &&\
#  curl -sSL https://www.python.org/ftp/python/3.9.4/Python-3.9.4.tar.xz \
#  | tar -xJ -C /usr/src/python --strip-components=1

# Based on https://github.com/pyenv/pyenv/wiki#suggested-build-environment
#ENV PYTHON_VERSION="3.9.2" \
#  PYENV_ROOT="/opt/python" \
#  PYENV_ROOT="/opt/python" \
#  POETRY_HOME="/opt/poetry"
#ENV PATH="/opt/python/versions/${PYTHON_VERSION}/bin:/opt/python/bin:$PATH"
#RUN apt-get update &&\
#  DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends \
#    ca-certificates make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev git &&\
#  apt-get clean -y && rm -rf /var/lib/apt/lists/*
## export PYENV_ROOT="/opt/python"
#RUN curl https://pyenv.run \
#    | bash &&\
#  pyenv init - >/etc/profile.d/pyenv-init.sh &&\
#  pyenv virtualenv-init - >/etc/profile.d/pyenv-virtualenv-init.sh
#RUN pyenv install ${PYTHON_VERSION}
#RUN curl -sSL https://bootstrap.pypa.io/get-pip.py \
#  | python -
#RUN curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py \
#  | python -

ENV PYTHON_VERSION="3.9.4"
# RUN echo Install build dependencies &&\
#   apt-get update &&\
#   DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends \
#     ca-certificates make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev git &&\
#   apt-get clean -y && rm -rf /var/lib/apt/lists/* &&\
#   echo Get/Compile python &&\
#   cd /tmp &&\
#   wget -q -O python.tar.xz https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz &&\
#   tar -xJf python.tar.xz &&\
#   cd Python* &&\
#   ./configure --enable-optimizations &&\
#   make &&\
#   make install &&\
#   make clean &&\
#   cd / &&\
#   rm -rf /tmp/* &&\
#   apt remove -qy build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev llvm libncurses5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev &&\
#   apt autoremove -qy &&\
#   ln -s /usr/local/bin/python3 /usr/local/bin/python &&\
#   ln -s /usr/local/bin/pip3 /usr/local/bin/pip &&\
#   ln -s /usr/local/bin/pydoc3 /usr/local/bin/pydoc
# #COPY --from=python /usr/local /usr/local

#ENV PYENV_ROOT="/etc/skel/.pyenv"
# ENV PATH="${PYENV_ROOT}/bin:${PATH}"
RUN apt update &&\
  DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends \
    ca-certificates make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev git &&\
  apt-get clean -y && rm -rf /var/lib/apt/lists/*
# RUN echo Install Python &&\
#   curl https://pyenv.run \
#     | bash &&\
#   pyenv init - >/etc/profile.d/pyenv-init.sh &&\
#   pyenv virtualenv-init - >/etc/profile.d/pyenv-virtualenv-init.sh &&\
#   pyenv install ${PYTHON_VERSION}
# pyenv
RUN export HOME="/etc/skel" &&\
  export PYENV_ROOT="${HOME}/.pyenv" &&\
  export PATH="${PYENV_ROOT}/bin:${PATH}" &&\
  eval "$(pyenv init --path)" &&\
  curl https://pyenv.run | bash &&\
  ls -al ${PYENV_ROOT} &&\
  cd ${PYENV_ROOT} && pwd && cd - &&\
  eval "$(pyenv init -)" &&\
  eval "$(pyenv virtualenv-init -)" &&\
  eval "$(pyenv init --path)" &&\
  pyenv install ${PYTHON_VERSION} &&\
  pyenv global ${PYTHON_VERSION} &&\
  python --version &&\
  curl -sSL https://bootstrap.pypa.io/get-pip.py | ${PYENV_ROOT}/versions/*/bin/python - &&\
  ${PYENV_ROOT}/versions/*/bin/pip install poetry
#RUN \
#  pyenv init - &&\
#  . /etc/profile.d/pyenv-init.sh &&\
#  . /etc/profile.d/pyenv-virtualenv-init.sh &&\
#  curl -sSL https://bootstrap.pypa.io/get-pip.py \
#    | python - &&\
#  curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py \
#   | python -
# RUN export HOME="/etc/skel" PYENV_ROOT="~/.pyenv" &&\
#   curl -sSL https://bootstrap.pypa.io/get-pip.py \
#     | ${PYENV_ROOT}/versions/*/bin/python -
# RUN export HOME="/etc/skel" PYENV_ROOT="~/.pyenv" &&\
#   ${PYENV_ROOT}/versions/*/bin/pip install poetry

#python distrib and xonsh
RUN apt-get update &&\
  DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends python3 python3-pip xonsh &&\
  apt-get clean -y && rm -rf /var/lib/apt/lists/*

# bpytop
RUN pip install --quiet --no-cache-dir bpytop

#xonsh
RUN apt-get update &&\
  DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends xonsh &&\
  apt-get clean -y && rm -rf /var/lib/apt/lists/*

#aws-cli
#RUN apt-get update &&\
#  DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends groff &&\
#  apt-get clean -y && rm -rf /var/lib/apt/lists/* &&\
#  pip3 install --system awscli
RUN apt-get update &&\
  DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends unzip groff &&\
  apt-get clean -y && rm -rf /var/lib/apt/lists/* &&\
  cd /tmp &&\
  curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" >/tmp/awscliv2.zip &&\
  unzip /tmp/awscliv2.zip &&\
  /tmp/aws/install &&\
  rm -rf /tmp/aws*
#aws cli session-manager-plugin
RUN curl -sSL https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb >/tmp/tmp.deb &&\
  dpkg -i /tmp/tmp.deb &&\
  rm /tmp/tmp.deb
#awsudo 1&2
RUN pip install --no-cache-dir git+https://github.com/makethunder/awsudo.git
RUN pip install --no-cache-dir git+https://github.com/outersystems/awsudo2.git@interate-profile-handling

##github.com/cli/cli
#RUN curl -sSL https://github.com/cli/cli/releases/download/v0.10.1/gh_0.10.1_linux_amd64.deb >/tmp/tmp.deb &&\
#  dpkg -i /tmp/tmp.deb &&\
#  rm /tmp/tmp.deb

#glow
RUN curl -sSL https://github.com/charmbracelet/glow/releases/download/v1.1.0/glow_1.1.0_linux_amd64.deb >/tmp/tmp.deb &&\
  dpkg -i /tmp/tmp.deb &&\
  rm /tmp/tmp.deb

#pwgen
RUN apt-get update &&\
  DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends pwgen &&\
  apt-get clean -y && rm -rf /var/lib/apt/lists/*

#socat (used in material/scripts/xdg-open)
RUN apt-get update &&\
  DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends socat &&\
  apt-get clean -y && rm -rf /var/lib/apt/lists/*

#icdiff (used in material/scripts/git-icdiff)
RUN apt-get update &&\
  DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends icdiff &&\
  apt-get clean -y && rm -rf /var/lib/apt/lists/*

#Completion for bash for colleagues
#RUN apt-get update &&\
#  apt-get install -qy --no-install-recommends bash-completion &&\
#  apt-get clean -y && rm -rf /var/lib/apt/lists/* &&\
#  kubectl completion bash >> /etc/skel/.bashrc
#  echo "complete -C /usr/local/bin/aws_completer" >>/etc/skel/.bashrc

#k6
#RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 379CE192D401AB61 &&\
#  echo "deb https://dl.bintray.com/loadimpact/deb stable main" | tee -a /etc/apt/sources.list &&\
#  apt-get update &&\
#  apt-get install k6 &&\
#  apt-get clean -y && rm -rf /var/lib/apt/lists/

#dive
RUN curl -sSL https://github.com/wagoodman/dive/releases/download/v0.9.2/dive_0.9.2_linux_amd64.deb >/tmp/tmp.deb &&\
  dpkg -i /tmp/tmp.deb &&\
  rm /tmp/tmp.deb

#Imports
#COPY --from=dc           /usr/local/bin/*  /usr/local/bin/
COPY --from=golang-tools /usr/local/go     /usr/local/go
COPY --from=downloaded-tools /usr/local/bin/*  /usr/local/bin/
#COPY --from=built-tools /usr/local/bin/*  /usr/local/bin/

#tools
RUN apt-get update &&\
  apt-get install -qy --no-install-recommends make ncdu entr apt-file &&\
  apt-get clean -y && rm -rf /var/lib/apt/lists/*

COPY material/payload /opt/payload/
COPY material/scripts /usr/local/bin/
COPY material/profile.d /etc/profile.d/
COPY material/virtualenv.sudoers /etc/sudoers.d/virtualenv
COPY material/skel  /etc/skel

