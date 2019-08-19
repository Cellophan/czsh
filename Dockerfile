#golang env
FROM ubuntu:rolling as golang-tools

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends wget git ca-certificates
RUN DEBIAN_FRONTEND=noninteractive apt-get install -qy golang-go

ENV GOPATH=/tmp/go GOBIN=/usr/local/go/bin PATH=${PATH}:/usr/local/go/bin
RUN go get golang.org/x/tools/cmd/godoc
RUN go get golang.org/x/tools/cmd/goimports
RUN go get golang.org/x/tools/cmd/gorename
RUN go get github.com/nsf/gocode
RUN go get github.com/rogpeppe/godef
RUN go get github.com/golang/lint/golint
RUN go get github.com/kisielk/errcheck
RUN go get github.com/jstemmer/gotags
RUN go get github.com/golang/dep/cmd/dep

RUN go get github.com/Originate/git-town
#RUN go get github.com/interesse/git-town
RUN go get github.com/erning/gorun
RUN go get mvdan.cc/sh/cmd/shfmt
##RUN go get github.com/gruntwork-io/terragrunt
##RUN go get github.com/kubernetes-sigs/aws-iam-authenticator/cmd/aws-iam-authenticator
#RUN go get github.com/containous/yaegi/cmd/yaegi

#download tools
FROM ubuntu:rolling as downloaded-tools
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends curl ca-certificates unzip
#container-diff
#from http://opensource.googleblog.com/2018/01/container-structure-tests-unit-tests.html
RUN curl -L https://storage.googleapis.com/container-diff/latest/container-diff-linux-amd64 >/usr/local/bin/container-diff
WORKDIR /usr/local/bin
#terraform
RUN curl -sSL https://releases.hashicorp.com/terraform/0.11.11/terraform_0.11.11_linux_amd64.zip >/tmp/terraform.zip &&\
  unzip /tmp/terraform.zip
#kubectl
RUN curl -sSLO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
#minikube
#RUN curl -sSL https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 >/usr/local/bin/minikube
#docker-compose
RUN curl -sSL https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m) > /usr/local/bin/docker-compose
RUN curl -sSL https://github.com/drone/drone-cli/releases/download/v1.0.7/drone_linux_amd64.tar.gz | tar zx
RUN chmod +x /usr/local/bin/*

#build tools
FROM ubuntu:rolling as built-tools

# Skopeo
# From https://github.com/containers/skopeo
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends wget git ca-certificates
RUN DEBIAN_FRONTEND=noninteractive apt-get install -qy golang-go libgpgme-dev libassuan-dev libbtrfs-dev libdevmapper-dev libostree-dev

ENV GOPATH=/tmp/go GOBIN=/usr/local/go/bin PATH=${PATH}:/usr/local/go/bin
RUN git clone --depth 1 https://github.com/containers/skopeo $GOPATH/src/github.com/containers/skopeo
RUN cd $GOPATH/src/github.com/containers/skopeo &&\
  make binary-local DISABLE_CGO=1 &&\
  mv skopeo /usr/local/bin/

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
  apt-get remove -y wget

RUN apt-get update &&\
  apt-get install -qy --no-install-recommends fontconfig locales &&\
  apt-get clean -y && rm -rf /var/lib/apt/lists/* &&\
  locale-gen en_US.UTF-8 en_US &&\
  DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales &&\
  /usr/sbin/update-locale LANG=C.UTF-8 &&\
  chsh -s /bin/zsh

#golan-go
RUN apt-get update &&\
  DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends wget git ca-certificates golang-go &&\
  apt-get remove -y wget &&\
  apt-get clean -y && rm -rf /var/lib/apt/lists/*

#nnn
# https://github.com/jarun/nnn
# TODO: make a link for czsh instead of an extra layer?
COPY material/payload/deploy/czsh /usr/local/bin/
# TODO: Use NNN_MULTISCRIPT instead of EDITOR and NNN_USE_EDITOR for starting cvim?
RUN apt-get update &&\
  DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends nnn &&\
  apt-get clean -y && rm -rf /var/lib/apt/lists/*

#aws-cli
RUN apt-get update &&\
  DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends python3 python3-pip groff &&\
  pip3 install --system setuptools &&\
  pip3 install --system awscli &&\
  apt-get clean -y && rm -rf /var/lib/apt/lists/*

#Completion for bash for colleagues
#RUN apt-get update &&\
#  apt-get install -qy --no-install-recommends bash-completion &&\
#  apt-get clean -y && rm -rf /var/lib/apt/lists/* &&\
#  kubectl completion bash >> /etc/skel/.bashrc
#  echo "complete -C /usr/local/bin/aws_completer" >>/etc/skel/.bashrc

#Imports
#COPY --from=dc           /usr/local/bin/*  /usr/local/bin/
COPY --from=golang-tools /usr/local/go     /usr/local/go
COPY --from=downloaded-tools /usr/local/bin/*  /usr/local/bin/
COPY --from=built-tools /usr/local/bin/*  /usr/local/bin/

#make
RUN apt-get update &&\
  apt-get install -qy --no-install-recommends make &&\
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
