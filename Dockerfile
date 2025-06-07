# Download tools
# hadolint ignore=DL3007
FROM ubuntu:latest AS downloaded-tools
RUN apt-get update
# hadolint ignore=DL3059,DL3008
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
RUN curl -sSL https://github.com/derailed/k9s/releases/download/v0.25.18/k9s_Linux_arm.tar.gz \
    | tar --directory=/usr/local/bin -xvz k9s
# hadolint ignore=DL3059,DL4006
RUN curl -sSL https://github.com/mithrandie/csvq/releases/download/v1.17.10/csvq-v1.17.10-linux-amd64.tar.gz \
    | tar --directory=/usr/local/bin -xvz csvq-v1.17.10-linux-amd64/csvq
# hadolint ignore=DL3059,DL4006
RUN curl -sSL https://dl.gitea.io/tea/0.9/tea-0.9-linux-amd64 >/usr/local/bin/tea
# hadolint ignore=DL3059,DL4006
RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh \
    | sh -s -- -b /usr/local/bin v1.55.2
# hadolint ignore=DL3059,DL4006
RUN curl -sSL https://github.com/Wilfred/difftastic/releases/download/0.56.1/difft-x86_64-unknown-linux-gnu.tar.gz \
    | tar --directory=/usr/local/bin -xvz difft
# hadolint ignore=DL3059,DL4006
RUN curl -o /usr/local/bin/jd -sSL https://github.com/josephburnett/jd/releases/download/v1.9.1/jd-amd64-linux
# hadolint ignore=DL3059,DL4006
RUN curl -sSL https://github.com/asdf-vm/asdf/releases/download/v0.16.2/asdf-v0.16.2-linux-amd64.tar.gz \
    | tar --directory=/usr/local/bin -xvz asdf


# hadolint ignore=DL3059
RUN chmod +x /usr/local/bin/*

#Main
# hadolint ignore=DL3007
FROM cell/playground:latest AS final
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
    find /etc/skel -name .git -type d -exec echo rm -rf {} \;

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
# RUN git clone --depth 1 https://github.com/outersystems/awsudo2.git /tmp/awsudo2 &&\
#     mkdir /etc/skel/.oh-my-zsh/custom/plugins/awsudo2 &&\
#     cp /tmp/awsudo2/completion/zsh/awsudo2.plugin.zsh /etc/skel/.oh-my-zsh/custom/plugins/awsudo2/ &&\
#     rm -rf /tmp/awsudo2
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

#pass
# hadolint ignore=DL3008
RUN apt-get update &&\
    DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends pass gnupg2 qrencode xclip pass-extension-otp oathtool &&\
    apt-get clean -y && rm -rf /var/lib/apt/lists/*

# # dependencies to install python (with asdf install python latest)
# # Based on https://github.com/pyenv/pyenv/wiki#suggested-build-environment
# # hadolint ignore=DL3008
# RUN apt-get update &&\
#     DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends \
#         ca-certificates make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev git &&\
#     apt-get clean -y && rm -rf /var/lib/apt/lists/*
# # pyenv, python. poetry
# # # hadolint ignore=DL4006,DL3013
# # RUN export PYTHON_VERSION="3.9.6" &&\
# #     export HOME="/etc/skel" &&\
# #     export PYENV_ROOT="${HOME}/.pyenv" &&\
# #     export PATH="${PYENV_ROOT}/bin:${PATH}" &&\
# #     curl https://pyenv.run | bash &&\
# #     eval "$(pyenv init -)" &&\
# #     eval "$(pyenv virtualenv-init -)" &&\
# #     eval "$(pyenv init --path)" &&\
# #     pyenv install ${PYTHON_VERSION} &&\
# #     ln -s "${PYENV_ROOT}/versions/${PYTHON_VERSION}" "${PYENV_ROOT}/versions/${PYTHON_VERSION%.*}" &&\
# #     pyenv global ${PYTHON_VERSION%.*} &&\
# #     python --version &&\
# #     pip install wheel &&\
# #     pip install --no-cache-dir poetry pudb
#
# #python distrib
# # hadolint ignore=DL3008
# RUN apt-get update &&\
#     DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends python3 python3-pip &&\
#     apt-get clean -y && rm -rf /var/lib/apt/lists/*
#
# # git-filter-repo
# # hadolint ignore=DL3013,DL3059
# # RUN pip install --quiet --no-cache-dir git-filter-repo

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
# RUN curl -sSL https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb >/tmp/tmp.deb &&\
#     dpkg -i /tmp/tmp.deb &&\
#     rm /tmp/tmp.deb
#awsudo 1&2
# # hadolint ignore=DL3013
# RUN pip install --no-cache-dir git+https://github.com/makethunder/awsudo.git
# # hadolint ignore=DL3013,DL3059
# RUN pip install --no-cache-dir git+https://github.com/outersystems/awsudo2.git@interate-profile-handling

#github.com/cli/cli
RUN curl -sSL https://github.com/cli/cli/releases/download/v2.59.0/gh_2.59.0_linux_amd64.deb >/tmp/tmp.deb &&\
  dpkg -i /tmp/tmp.deb &&\
  rm /tmp/tmp.deb &&\
  chmod -R a+w /etc/skel/.oh-my-zsh/plugins/gh

#github.com/grafana/k6
RUN curl -sSL https://github.com/grafana/k6/releases/download/v0.54.0/k6-v0.54.0-linux-amd64.deb >/tmp/tmp.deb &&\
  dpkg -i /tmp/tmp.deb &&\
  rm /tmp/tmp.deb &&\
  chmod -R a+w /etc/skel/.oh-my-zsh/plugins/gh

#glow
RUN curl -sSL https://github.com/charmbracelet/glow/releases/download/v1.1.0/glow_1.1.0_linux_amd64.deb >/tmp/tmp.deb &&\
    dpkg -i /tmp/tmp.deb &&\
    rm /tmp/tmp.deb

#gum
RUN curl -sSL https://github.com/charmbracelet/gum/releases/download/v0.8.0/gum_0.8.0_linux_amd64.deb >/tmp/tmp.deb &&\
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

# ntfy
# https://docs.ntfy.sh/install/
# hadolint ignore=SC2046,DL3003
RUN curl -sSL https://github.com/binwiederhier/ntfy/releases/download/v2.10.0/ntfy_2.10.0_linux_amd64.tar.gz >/tmp/tmp.tgz &&\
    cd /tmp &&\
    tar zxvf /tmp/tmp.tgz &&\
    cp -a ntfy_*_linux_amd64/ntfy /usr/local/bin/ntfy &&\
    mkdir /etc/ntfy &&\
    cp ntfy_*_linux_amd64/client/*.yml /etc/ntfy/ &&\
    cp ntfy_*_linux_amd64/server/*.yml /etc/ntfy/ &&\
    rm -rf /tmp/*

# nvm, nodejs version manager
# hadolint ignore=SC2046,DL3003
# RUN git clone https://github.com/nvm-sh/nvm.git "/etc/skel/.nvm" &&\
#     cd /etc/skel/.nvm &&\
#     git checkout $(git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1))

#tools
# openssh-client: to permit ssh mount while build:
#   DOCKER_BUILDKIT=1 docker build --ssh default -t ...
#   RUN --mount=type=ssh mkdir -p -m 0600 ~/.ssh &&\
#      ssh-keyscan <host to know> >> ~/.ssh/known_hosts
# hadolint ignore=DL3008
RUN apt-get update &&\
    apt-get install -qy --no-install-recommends make ncdu entr apt-file less netcat-openbsd iputils-ping time bsdextrautils btop libnotify-bin openssh-client &&\
    apt-get clean -y && rm -rf /var/lib/apt/lists/*

#Imports
# COPY --from=golang-tools /usr/local/go     /usr/local/go
COPY --from=downloaded-tools /usr/local/bin/*  /usr/local/bin/
# COPY --from=built-tools /usr/local/bin/*  /usr/local/bin/

#Completions
#kubectl
RUN mkdir -p /etc/skel/.oh-my-zsh/custom/plugins/kubectl &&\
    kubectl completion zsh >/etc/skel/.oh-my-zsh/custom/plugins/kubectl/kubectl.plugin.zsh

COPY material/payload /opt/payload/
COPY material/scripts /usr/local/bin/
COPY material/profile.d /etc/profile.d/
COPY material/virtualenv.sudoers /etc/sudoers.d/virtualenv
COPY material/skel  /etc/skel

