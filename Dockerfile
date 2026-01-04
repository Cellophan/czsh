# Download tools
# hadolint ignore=DL3007
FROM ubuntu:latest AS downloaded-tools
# https://docs.docker.com/build/building/multi-platform/
# ${TARGETARCH}: amd64 or arm64
# $(uname -m): x86_64 or aarch64
ARG TARGETARCH
# RUN echo $TARGETARCH; echo $(uname -m);exit 1

RUN apt-get update
# hadolint ignore=DL3059,DL3008
RUN DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends curl ca-certificates unzip git
WORKDIR /usr/local/bin

RUN curl -sSL "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" >/usr/local/bin/docker-compose
# hadolint ignore=DL3059
RUN curl -sSLO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/${TARGETARCH}/kubectl"
# hadolint ignore=DL3059
RUN git clone -b v1.4 --depth 1 https://github.com/gdraheim/docker-systemctl-replacement.git /tmp/docker-systemctl-replacement &&\
    cp /tmp/docker-systemctl-replacement/files/docker/systemctl3.py /usr/local/bin/systemctl
# hadolint ignore=DL3059
RUN curl -sSL https://releases.hashicorp.com/terraform/0.13.5/terraform_0.13.5_linux_${TARGETARCH}.zip >/tmp/terraform.zip &&\
    unzip /tmp/terraform.zip
# hadolint ignore=DL3059,DL4006
RUN curl -sSL https://github.com/derailed/k9s/releases/download/v0.50.15/k9s_Linux_${TARGETARCH}.tar.gz \
    | tar --directory=/usr/local/bin -xvz k9s
# hadolint ignore=DL3059,DL4006
RUN curl -sSL https://github.com/mithrandie/csvq/releases/download/v1.17.10/csvq-v1.17.10-linux-${TARGETARCH}.tar.gz \
    | tar --directory=/usr/local/bin -xvz csvq-v1.17.10-linux-${TARGETARCH}/csvq
# hadolint ignore=DL3059,DL4006
RUN curl -sSL https://dl.gitea.io/tea/0.9/tea-0.9-linux-${TARGETARCH} >/usr/local/bin/tea
# hadolint ignore=DL3059,DL4006
RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh \
    | sh -s -- -b /usr/local/bin v1.64.5
# hadolint ignore=DL3059,DL4006
RUN curl -sSL https://github.com/Wilfred/difftastic/releases/download/0.56.1/difft-$(uname -m)-unknown-linux-gnu.tar.gz \
    | tar --directory=/usr/local/bin -xvz difft
# hadolint ignore=DL3059,DL4006
RUN curl -o /usr/local/bin/jd -sSL https://github.com/josephburnett/jd/releases/download/v1.9.1/jd-${TARGETARCH}-linux
# hadolint ignore=DL3059,DL4006
RUN curl -sSL https://github.com/asdf-vm/asdf/releases/download/v0.16.2/asdf-v0.16.2-linux-${TARGETARCH}.tar.gz \
    | tar --directory=/usr/local/bin -xvz asdf
# hadolint ignore=DL3059
RUN curl -sSL  https://github.com/astral-sh/uv/releases/download/0.9.16/uv-$(uname -m)-unknown-linux-gnu.tar.gz >/tmp/tmp.tgz &&\
    tar -C /tmp -xz -f /tmp/tmp.tgz &&\
    mv /tmp/*/uv* /usr/local/bin/

# hadolint ignore=DL3059
RUN chmod +x /usr/local/bin/*

#Main
# hadolint ignore=DL3007
FROM cell/playground:latest AS final
ARG TARGETARCH
ENV DOCKER_IMAGE="cell/czsh"

# hadolint ignore=DL3008
RUN --mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt/lists \
    apt-get update

#zsh and oh-my-zsh
# hadolint ignore=DL3008
RUN --mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt/lists \
    apt-get update &&\
    apt-get install -qy --no-install-recommends zsh &&\
    git clone --depth 1 https://github.com/robbyrussell/oh-my-zsh.git /etc/skel/.oh-my-zsh &&\
    ln -s /etc/skel/.oh-my-zsh /root &&\
    ln -s /etc/skel/.zshrc /root &&\
    find /etc/skel -name .git -type d -exec echo rm -rf {} \;

#zsh-autosuggestions
RUN git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions /etc/skel/.oh-my-zsh/custom/plugins/zsh-autosuggestions &&\
    find /etc/skel/.oh-my-zsh/custom/plugins/zsh-autosuggestions -name .git -type d -exec echo rm -rf {} \;
#zsh-autosuggestions
RUN git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git /etc/skel/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting &&\
    find /etc/skel/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting -name .git -type d -exec echo rm -rf {} \;
RUN --mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt/lists \
    apt-get update &&\
    apt-get install -qy --no-install-recommends zsh

# hadolint ignore=DL3008
RUN --mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt/lists \
    apt-get update &&\
    apt-get install -qy --no-install-recommends fontconfig locales &&\
    locale-gen en_US.UTF-8 en_US &&\
    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales &&\
    /usr/sbin/update-locale LANG=C.UTF-8 &&\
    chsh -s /bin/zsh

#pass
# hadolint ignore=DL3008
RUN --mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt/lists \
    apt-get update &&\
    DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends pass gnupg2 qrencode xclip pass-extension-otp oathtool

#github.com/cli/cli
RUN curl -sSL https://github.com/cli/cli/releases/download/v2.59.0/gh_2.59.0_linux_${TARGETARCH}.deb >/tmp/tmp.deb &&\
  dpkg -i /tmp/tmp.deb &&\
  rm /tmp/tmp.deb

#glow
RUN curl -sSL https://github.com/charmbracelet/glow/releases/download/v1.1.0/glow_1.1.0_linux_${TARGETARCH}.deb >/tmp/tmp.deb &&\
    dpkg -i /tmp/tmp.deb &&\
    rm /tmp/tmp.deb

#gum
RUN curl -sSL https://github.com/charmbracelet/gum/releases/download/v0.8.0/gum_0.8.0_linux_${TARGETARCH}.deb >/tmp/tmp.deb &&\
    dpkg -i /tmp/tmp.deb &&\
    rm /tmp/tmp.deb

#pwgen
# hadolint ignore=DL3008
RUN --mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt/lists \
    apt-get update &&\
    DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends pwgen

#socat (used in material/scripts/xdg-open)
# hadolint ignore=DL3008
RUN --mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt/lists \
    apt-get update &&\
    DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends socat

# #icdiff (used in material/scripts/git-icdiff)
# # hadolint ignore=DL3008
# RUN --mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt/lists \
#     apt-get update &&\
#     DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends icdiff

#dive
RUN curl -sSL https://github.com/wagoodman/dive/releases/download/v0.13.1/dive_0.13.1_linux_${TARGETARCH}.deb >/tmp/tmp.deb &&\
    dpkg -i /tmp/tmp.deb &&\
    rm /tmp/tmp.deb

# ntfy
# https://docs.ntfy.sh/install/
# hadolint ignore=SC2046,DL3003
RUN curl -sSL https://github.com/binwiederhier/ntfy/releases/download/v2.10.0/ntfy_2.10.0_linux_${TARGETARCH}.tar.gz >/tmp/tmp.tgz &&\
    cd /tmp &&\
    tar zxvf /tmp/tmp.tgz &&\
    cp -a */ntfy /usr/local/bin/ntfy &&\
    mkdir /etc/ntfy &&\
    cp */client/*.yml /etc/ntfy/ &&\
    cp */server/*.yml /etc/ntfy/ &&\
    rm -rf /tmp/*

#tools
# openssh-client: to permit ssh mount while build:
#   DOCKER_BUILDKIT=1 docker build --ssh default -t ...
#   RUN --mount=type=ssh mkdir -p -m 0600 ~/.ssh &&\
#      ssh-keyscan <host to know> >> ~/.ssh/known_hosts
# hadolint ignore=DL3008
RUN --mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt/lists \
    apt-get update &&\
    apt-get install -qy --no-install-recommends make ncdu entr apt-file less netcat-openbsd iputils-ping time bsdextrautils btop libnotify-bin openssh-client openssh-server

#Imports
# COPY --from=golang-tools /usr/local/go     /usr/local/go
COPY --from=downloaded-tools /usr/local/bin/*  /usr/local/bin/
# COPY --from=built-tools /usr/local/bin/*  /usr/local/bin/


# ZSH
RUN --mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt/lists \
    apt-get install -qy wget gawk fzf
RUN mkdir -p /opt/local/zsh/fzf &&\
    wget --quiet --directory-prefix=/opt/local/zsh/ \
      https://raw.githubusercontent.com/git/git/refs/heads/master/contrib/completion/git-completion.zsh \
      https://raw.githubusercontent.com/zsh-users/zsh-autosuggestions/refs/heads/master/zsh-autosuggestions.zsh &&\
    wget --quiet --directory-prefix=/opt/local/zsh/fzf/ \
      https://raw.githubusercontent.com/junegunn/fzf/refs/heads/master/shell/completion.zsh \
      https://raw.githubusercontent.com/junegunn/fzf/refs/heads/master/shell/key-bindings.zsh
RUN mkdir -p /etc/skel/.zsh &&\
    wget --quiet --directory-prefix=/etc/skel/.zsh/ \
      https://raw.githubusercontent.com/zsh-users/zsh-autosuggestions/refs/heads/master/zsh-autosuggestions.zsh
# Completions
RUN docker completion zsh >/opt/local/zsh/docker.zsh
RUN kubectl completion zsh >/opt/local/zsh/kubectl.zsh
RUN asdf completion zsh >/opt/local/zsh/asdf.zsh

COPY material/*.zsh-theme /etc/skel/.oh-my-zsh/custom/themes/
COPY material/payload /opt/payload/
COPY material/scripts /usr/local/bin/
COPY material/profile.d /etc/profile.d/
COPY material/virtualenv.sudoers /etc/sudoers.d/virtualenv
COPY material/skel  /etc/skel

