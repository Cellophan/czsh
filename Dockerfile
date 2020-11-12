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
RUN go get github.com/digitalocean/doctl/cmd/doctl
#RUN go get github.com/charmbracelet/glow
RUN go get github.com/wagoodman/dive
RUN GO111MODULE=on go get github.com/mikefarah/yq/v3

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
FROM ubuntu:rolling as downloaded-tools
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends curl ca-certificates unzip git
WORKDIR /usr/local/bin

RUN curl -sSL https://storage.googleapis.com/container-diff/latest/container-diff-linux-amd64 >/usr/local/bin/container-diff
RUN curl -sSL https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m) >/usr/local/bin/docker-compose
RUN curl -sSL https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-latest >/usr/local/bin/ecs-cli
RUN curl -sSL https://github.com/concourse/concourse/releases/download/v3.14.1/fly_linux_amd64 >/usr/local/bin/fly
RUN curl -sSLO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN git clone -b v1.4 --depth 1 https://github.com/gdraheim/docker-systemctl-replacement.git /tmp/docker-systemctl-replacement &&\
  cp /tmp/docker-systemctl-replacement/files/docker/systemctl3.py /usr/local/bin/systemctl
RUN curl -sSL https://releases.hashicorp.com/terraform/0.13.5/terraform_0.13.5_linux_amd64.zip >/tmp/terraform.zip &&\
  unzip /tmp/terraform.zip

RUN chmod +x /usr/local/bin/*

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
  DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends pass gnupg2 qrencode xclip pass-extension-otp oathtool &&\
  apt-get clean -y && rm -rf /var/lib/apt/lists/*

#python3
RUN apt-get update &&\
  DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends python3 python3-pip &&\
  DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends python3-wheel &&\
  pip3 install --system setuptools &&\
  pip3 install --system pytest &&\
  apt-get clean -y && rm -rf /var/lib/apt/lists/*

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
RUN pip3 install --system git+https://github.com/makethunder/awsudo.git
RUN pip3 install --system git+https://github.com/outersystems/awsudo2.git

##github.com/cli/cli
#RUN curl -sSL https://github.com/cli/cli/releases/download/v0.10.1/gh_0.10.1_linux_amd64.deb >/tmp/tmp.deb &&\
#  dpkg -i /tmp/tmp.deb &&\
#  rm /tmp/tmp.deb

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
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 379CE192D401AB61 &&\
  echo "deb https://dl.bintray.com/loadimpact/deb stable main" | tee -a /etc/apt/sources.list &&\
  apt-get update &&\
  apt-get install k6 &&\
  apt-get clean -y && rm -rf /var/lib/apt/lists/

#dive
#RUN curl -sSL https://github.com/wagoodman/dive/releases/download/v0.9.2/dive_0.9.2_linux_amd64.deb >/tmp/tmp.deb &&\
#  dpkg -i /tmp/tmp.deb &&\
#  rm /tmp/tmp.deb

#Imports
#COPY --from=dc           /usr/local/bin/*  /usr/local/bin/
COPY --from=golang-tools /usr/local/go     /usr/local/go
COPY --from=downloaded-tools /usr/local/bin/*  /usr/local/bin/
#COPY --from=built-tools /usr/local/bin/*  /usr/local/bin/

#tools
RUN apt-get update &&\
  apt-get install -qy --no-install-recommends make ncdu apt-file &&\
  apt-get clean -y && rm -rf /var/lib/apt/lists/*

COPY material/payload /opt/payload/
COPY material/scripts /usr/local/bin/
COPY material/profile.d /etc/profile.d/
COPY material/virtualenv.sudoers /etc/sudoers.d/virtualenv
COPY material/skel  /etc/skel

