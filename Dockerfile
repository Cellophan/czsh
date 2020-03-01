#golang env
FROM ubuntu:rolling as golang-tools

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends curl git ca-certificates
RUN curl -sSL https://dl.google.com/go/go1.13.1.linux-amd64.tar.gz >/tmp/go.tgz &&\
  tar -C /usr/local -xz -f /tmp/go.tgz &&\
  chown -R root:root /usr/local/go
ENV GOPATH=/tmp/go GOBIN=/usr/local/go/bin PATH=${PATH}:/usr/local/go/bin

RUN go get golang.org/x/tools/cmd/godoc
RUN go get golang.org/x/tools/cmd/goimports
RUN go get golang.org/x/tools/cmd/gorename
RUN go get github.com/nsf/gocode
RUN go get github.com/rogpeppe/godef
#RUN go get github.com/golang/lint/golint
RUN go get github.com/kisielk/errcheck
RUN go get github.com/jstemmer/gotags

RUN go get github.com/Originate/git-town
#RUN go get github.com/interesse/git-town
RUN go get github.com/erning/gorun
RUN go get mvdan.cc/sh/cmd/shfmt
##RUN go get github.com/gruntwork-io/terragrunt
RUN go get github.com/containous/yaegi/cmd/yaegi
RUN go get github.com/digitalocean/doctl/cmd/doctl
RUN go get github.com/charmbracelet/glow

#download tools
FROM ubuntu:rolling as downloaded-tools
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends curl ca-certificates unzip
#container-diff
#from http://opensource.googleblog.com/2018/01/container-structure-tests-unit-tests.html
WORKDIR /usr/local/bin
#terraform
RUN curl -sSL https://releases.hashicorp.com/terraform/0.12.18/terraform_0.12.18_linux_amd64.zip >/tmp/terraform.zip &&\
  unzip /tmp/terraform.zip

RUN curl -sSL https://storage.googleapis.com/container-diff/latest/container-diff-linux-amd64 >/usr/local/bin/container-diff
RUN curl -sSLO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN curl -sSL https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m) > /usr/local/bin/docker-compose
RUN curl -sSL https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-latest >/usr/local/bin/ecs-cli
RUN curl -sSL https://github.com/drone/drone-cli/releases/download/v1.0.7/drone_linux_amd64.tar.gz | tar zx
RUN curl -sSL https://github.com/concourse/concourse/releases/download/3.14.1/fly_linux_amd64 >/usr/local/bin/fly

RUN chmod +x /usr/local/bin/*

#build tools
FROM ubuntu:rolling as built-tools

# Skopeo
# From https://github.com/containers/skopeo
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends wget git ca-certificates curl
RUN DEBIAN_FRONTEND=noninteractive apt-get install -qy libgpgme-dev libassuan-dev libbtrfs-dev libdevmapper-dev libostree-dev
RUN curl -sSL https://dl.google.com/go/go1.13.1.linux-amd64.tar.gz >/tmp/go.tgz &&\
  tar -C /usr/local -xz -f /tmp/go.tgz &&\
  chown -R root:root /usr/local/go
ENV GOPATH=/tmp/go GOBIN=/usr/local/go/bin PATH=${PATH}:/usr/local/go/bin

RUN git clone --depth 1 https://github.com/containers/skopeo $GOPATH/src/github.com/containers/skopeo
RUN cd $GOPATH/src/github.com/containers/skopeo &&\
  make binary-local DISABLE_CGO=1 &&\
  mv skopeo /usr/local/bin/

# gh cli
# From https://github.com/cli/cli/blob/master/source.md
RUN git clone https://github.com/cli/cli.git $GOPATH/githubcli
RUN cd $GOPATH/githubcli &&\
  make
RUN mv $GOPATH/githubcli/bin/* /usr/local/bin/

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
  ln -s /etc/skel/.zshrc /root

#agnoster
RUN git clone --depth 1 https://github.com/Cellophan/agnoster-zsh-theme /etc/skel/.oh-my-zsh/custom/themes/agnoster-zsh-theme &&\
  ln -s /etc/skel/.oh-my-zsh/custom/themes/agnoster-zsh-theme/agnoster.zsh-theme /etc/skel/.oh-my-zsh/custom/themes
#zsh-autosuggestions
RUN git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions /etc/skel/.oh-my-zsh/custom/plugins/zsh-autosuggestions
#zsh-autosuggestions
RUN git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git /etc/skel/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
#terragrunt.plugin.zsh
RUN git clone --depth 1 https://github.com/Cellophan/terragrunt.plugin.zsh.git /etc/skel/.oh-my-zsh/custom/plugins/terragrunt
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
  git clone --depth 1 https://github.com/Treri/fzf-zsh.git /etc/skel/.oh-my-zsh/custom/plugins/fzf-zsh

#powerline
RUN apt-get update &&\
  apt-get install -qy --no-install-recommends wget dconf-cli &&\
  apt-get clean -y && rm -rf /var/lib/apt/lists/* &&\
  mkdir -p /etc/skel/.fonts /etc/skel.config/fontconfig/conf.d &&\
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
  DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends pass gnupg2 qrencode xclip &&\
  apt-get clean -y && rm -rf /var/lib/apt/lists/*

#aws-cli
RUN apt-get update &&\
  DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends python3 python3-pip groff &&\
  pip3 install --system setuptools &&\
  pip3 install --system awscli &&\
  apt-get clean -y && rm -rf /var/lib/apt/lists/*
#awsudo
#RUN pip3 install --system git+https://github.com/makethunder/awsudo.git
RUN pip3 install --system git+https://github.com/outersystems/awsudo.git

#pwgen
RUN apt-get update &&\
  DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends pwgen &&\
  apt-get clean -y && rm -rf /var/lib/apt/lists/*

#socat (used in material/scripts/xdg-open)
RUN apt-get update &&\
  DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends socat &&\
  apt-get clean -y && rm -rf /var/lib/apt/lists/*

#Completion for bash for colleagues
#RUN apt-get update &&\
#  apt-get install -qy --no-install-recommends bash-completion &&\
#  apt-get clean -y && rm -rf /var/lib/apt/lists/* &&\
#  kubectl completion bash >> /etc/skel/.bashrc
#  echo "complete -C /usr/local/bin/aws_completer" >>/etc/skel/.bashrc

#crystal
#From https://crystal-lang.org/reference/installation/on_debian_and_ubuntu.html
RUN apt update &&\
  apt install -qy gnupg &&\
  curl -sL "https://keybase.io/crystal/pgp_keys.asc" | sudo apt-key add - &&\
  echo "deb https://dist.crystal-lang.org/apt crystal main" | sudo tee /etc/apt/sources.list.d/crystal.list &&\
  apt-get update &&\
  apt install -qy crystal libssl-dev libxml2-dev libyaml-dev libgmp-dev libreadline-dev libz-dev &&\
  apt-get clean -y && rm -rf /var/lib/apt/lists/

#Imports
#COPY --from=dc           /usr/local/bin/*  /usr/local/bin/
COPY --from=golang-tools /usr/local/go     /usr/local/go
COPY --from=downloaded-tools /usr/local/bin/*  /usr/local/bin/
COPY --from=built-tools /usr/local/bin/*  /usr/local/bin/

#tools
RUN apt-get update &&\
  apt-get install -qy --no-install-recommends make ncdu apt-file &&\
  apt-get clean -y && rm -rf /var/lib/apt/lists/*

#pass
RUN apt-get update &&\
  apt-get install -qy --no-install-recommends pass gnupg2 &&\
  apt-get clean -y && rm -rf /var/lib/apt/lists/*

COPY material/payload /opt/payload/
COPY material/scripts /usr/local/bin/
COPY material/profile.d /etc/profile.d/
COPY material/virtualenv.sudoers /etc/sudoers.d/virtualenv
COPY material/skel  /etc/skel
