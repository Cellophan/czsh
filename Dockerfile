#golang env
FROM ubuntu:latest as golang-tools

RUN apt-get update
# hadolint ignore=DL3008
RUN DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends curl git ca-certificates gcc libc6-dev
# hadolint ignore=DL3059
RUN curl -sSL https://go.dev/dl/go1.16.13.linux-amd64.tar.gz >/tmp/go.tgz &&\
    tar -C /usr/local -xz -f /tmp/go.tgz &&\
    chown -R root:root /usr/local/go
ENV GOPATH=/tmp/go GOBIN=/usr/local/go/bin PATH=${PATH}:/usr/local/go/bin

RUN go get github.com/Originate/git-town
# RUN go get mvdan.cc/sh/cmd/shfmt
RUN GO111MODULE=on go get github.com/mikefarah/yq/v3
# hadolint ignore=DL3059
RUN GO111MODULE=on go get github.com/go-delve/delve/cmd/dlv
# hadolint ignore=DL3059
RUN GO111MODULE=on go get github.com/pitr/fj
# hadolint ignore=DL3059
# RUN GO111MODULE=on go get github.com/mithrandie/csvq

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
# hadolint ignore=DL3008
RUN DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends curl ca-certificates unzip git
WORKDIR /usr/local/bin

RUN curl -sSL "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" >/usr/local/bin/docker-compose
# hadolint ignore=DL3059
RUN curl -sSLO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
# hadolint ignore=DL3059
RUN git clone -b v1.4 --depth 1 https://github.com/gdraheim/docker-systemctl-replacement.git /tmp/docker-systemctl-replacement &&\
    cp /tmp/docker-systemctl-replacement/files/docker/systemctl3.py /usr/local/bin/systemctl
# hadolint ignore=DL3059
RUN curl -sSL https://releases.hashicorp.com/terraform/0.13.5/terraform_0.13.5_linux_amd64.zip >/tmp/terraform.zip &&\
    unzip /tmp/terraform.zip
# hadolint ignore=DL3059,DL4006
RUN curl -sSL https://github.com/exercism/cli/releases/download/v3.0.13/exercism-3.0.13-linux-x86_64.tar.gz \
    | tar --directory=/usr/local/bin -xvz exercism
# hadolint ignore=DL3059,DL4006
RUN curl -sSL https://raw.github.com/xwmx/nb/master/nb >/usr/local/bin/nb
# sudo nb completions install
# hadolint ignore=DL3059,DL4006
RUN curl -sSL https://github.com/derailed/k9s/releases/download/v0.25.18/k9s_Linux_arm.tar.gz \
    | tar --directory=/usr/local/bin -xvz k9s

# hadolint ignore=DL3059
RUN chmod +x /usr/local/bin/*

#Main
# hadolint ignore=DL3007
FROM cell/playground:latest
ENV DOCKER_IMAGE="cell/czsh"

#zsh and oh-my-zsh
#https://hub.docker.com/r/nacyot/ubuntu/~/dockerfile/
# hadolint ignore=DL3008
RUN apt-get update &&\
    apt-get install -qy --no-install-recommends zsh &&\
    apt-get clean -y && rm -rf /var/lib/apt/lists/* &&\
    git clone --depth 1 https://github.com/robbyrussell/oh-my-zsh.git /etc/skel/.oh-my-zsh &&\
    ln -s /etc/skel/.oh-my-zsh /root &&\
    ln -s /etc/skel/.zshrc /root &&\
    find . -name .git -type d -exec echo rm -rf {} \;

#agnoster
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
# hadolint ignore=DL3008
RUN apt-get update &&\
    apt-get install -qy --no-install-recommends silversearcher-ag &&\
    apt-get clean -y && rm -rf /var/lib/apt/lists/* &&\
    git clone --depth 1 https://github.com/junegunn/fzf.git /etc/skel/.oh-my-zsh/custom/plugins/fzf &&\
    /etc/skel/.oh-my-zsh/custom/plugins/fzf/install --bin &&\
    git clone --depth 1 https://github.com/Treri/fzf-zsh.git /etc/skel/.oh-my-zsh/custom/plugins/fzf-zsh &&\
    find /etc/skel/.oh-my-zsh/custom/plugins -name .git -type d -exec echo rm -rf {} \;

#powerline
# hadolint ignore=DL3008
RUN apt-get update &&\
    apt-get install -qy --no-install-recommends curl ca-certificates dconf-cli &&\
    apt-get clean -y && rm -rf /var/lib/apt/lists/* &&\
    mkdir -p /etc/skel/.fonts /etc/skel/.config/fontconfig/conf.d &&\
    curl -sSL --output /etc/skel/.fonts/PowerlineSymbols.otf https://github.com/powerline/powerline/raw/develop/font/PowerlineSymbols.otf &&\
    curl -sSL --output /etc/skel/.config/fontconfig/conf.d/10-powerline-symbols.conf https://github.com/powerline/powerline/raw/develop/font/10-powerline-symbols.conf &&\
    apt-get remove -y dconf-cli

# hadolint ignore=DL3008
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
# hadolint ignore=DL3008
RUN apt-get update &&\
    DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends nnn &&\
    apt-get clean -y && rm -rf /var/lib/apt/lists/*

#pass
# hadolint ignore=DL3008
RUN apt-get update &&\
    DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends pass gnupg2 qrencode xclip pass-extension-otp oathtool &&\
    apt-get clean -y && rm -rf /var/lib/apt/lists/*

# pyenv, python. poetry
# Based on https://github.com/pyenv/pyenv/wiki#suggested-build-environment
# hadolint ignore=DL3008
RUN apt-get update &&\
    DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends \
        ca-certificates make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev git &&\
    apt-get clean -y && rm -rf /var/lib/apt/lists/*

# hadolint ignore=DL4006,DL3013
RUN export PYTHON_VERSION="3.9.6" &&\
    export HOME="/etc/skel" &&\
    export PYENV_ROOT="${HOME}/.pyenv" &&\
    export PATH="${PYENV_ROOT}/bin:${PATH}" &&\
    curl https://pyenv.run | bash &&\
    eval "$(pyenv init -)" &&\
    eval "$(pyenv virtualenv-init -)" &&\
    eval "$(pyenv init --path)" &&\
    pyenv install ${PYTHON_VERSION} &&\
    ln -s "${PYENV_ROOT}/versions/${PYTHON_VERSION}" "${PYENV_ROOT}/versions/${PYTHON_VERSION%.*}" &&\
    pyenv global ${PYTHON_VERSION%.*} &&\
    python --version &&\
    pip install wheel &&\
    pip install --no-cache-dir poetry pudb

#python distrib
# hadolint ignore=DL3008
RUN apt-get update &&\
    DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends python3 python3-pip &&\
    apt-get clean -y && rm -rf /var/lib/apt/lists/*

# bpytop
# hadolint ignore=DL3013
RUN pip install --quiet --no-cache-dir bpytop

# git-filter-repo
# hadolint ignore=DL3013
RUN pip install --quiet --no-cache-dir git-filter-repo

#aws-cli
#RUN apt-get update &&\
#  DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends groff &&\
#  apt-get clean -y && rm -rf /var/lib/apt/lists/* &&\
#  pip3 install --system awscli
# hadolint ignore=DL3003,DL3008
RUN apt-get update &&\
    DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends unzip groff &&\
    apt-get clean -y && rm -rf /var/lib/apt/lists/* &&\
    cd /tmp &&\
    curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" >/tmp/awscliv2.zip &&\
    unzip -q /tmp/awscliv2.zip &&\
    /tmp/aws/install &&\
    rm -rf /tmp/aws*
#aws cli session-manager-plugin
RUN curl -sSL https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb >/tmp/tmp.deb &&\
    dpkg -i /tmp/tmp.deb &&\
    rm /tmp/tmp.deb
#awsudo 1&2
# hadolint ignore=DL3013
RUN pip install --no-cache-dir git+https://github.com/makethunder/awsudo.git
# hadolint ignore=DL3013
RUN pip install --no-cache-dir git+https://github.com/outersystems/awsudo2.git@interate-profile-handling

#github.com/cli/cli
RUN curl -sSL https://github.com/cli/cli/releases/download/v2.14.3/gh_2.14.3_linux_amd64.deb >/tmp/tmp.deb &&\
  dpkg -i /tmp/tmp.deb &&\
  rm /tmp/tmp.deb &&\
  chmod -R a+w /etc/skel/.oh-my-zsh/plugins/gh

#glow
RUN curl -sSL https://github.com/charmbracelet/glow/releases/download/v1.1.0/glow_1.1.0_linux_amd64.deb >/tmp/tmp.deb &&\
    dpkg -i /tmp/tmp.deb &&\
    rm /tmp/tmp.deb

#pwgen
# hadolint ignore=DL3008
RUN apt-get update &&\
    DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends pwgen &&\
    apt-get clean -y && rm -rf /var/lib/apt/lists/*

#socat (used in material/scripts/xdg-open)
# hadolint ignore=DL3008
RUN apt-get update &&\
    DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends socat &&\
    apt-get clean -y && rm -rf /var/lib/apt/lists/*

#icdiff (used in material/scripts/git-icdiff)
# hadolint ignore=DL3008
RUN apt-get update &&\
    DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends icdiff &&\
    apt-get clean -y && rm -rf /var/lib/apt/lists/*

#Completion for bash for colleagues
#RUN apt-get update &&\
#  apt-get install -qy --no-install-recommends bash-completion &&\
#  apt-get clean -y && rm -rf /var/lib/apt/lists/* &&\
#  kubectl completion bash >> /etc/skel/.bashrc
#  echo "complete -C /usr/local/bin/aws_completer" >>/etc/skel/.bashrc

#dive
RUN curl -sSL https://github.com/wagoodman/dive/releases/download/v0.9.2/dive_0.9.2_linux_amd64.deb >/tmp/tmp.deb &&\
    dpkg -i /tmp/tmp.deb &&\
    rm /tmp/tmp.deb

#Imports
COPY --from=golang-tools /usr/local/go     /usr/local/go
COPY --from=downloaded-tools /usr/local/bin/*  /usr/local/bin/
#COPY --from=built-tools /usr/local/bin/*  /usr/local/bin/

#tools
# hadolint ignore=DL3008
RUN apt-get update &&\
    apt-get install -qy --no-install-recommends make ncdu entr apt-file less netcat iputils-ping time &&\
    apt-get clean -y && rm -rf /var/lib/apt/lists/*

COPY material/payload /opt/payload/
COPY material/scripts /usr/local/bin/
COPY material/profile.d /etc/profile.d/
COPY material/virtualenv.sudoers /etc/sudoers.d/virtualenv
COPY material/skel  /etc/skel

