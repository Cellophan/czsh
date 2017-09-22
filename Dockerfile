#fly: the cli tool for concourse
FROM ubuntu as fly

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -qy wget git direnv

RUN wget -O /tmp/go.tar.gz --quiet https://storage.googleapis.com/golang/go1.8.3.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf /tmp/go.tar.gz

ENV GOPATH=/app GOBIN=/usr/local/go/bin PATH=${PATH}:/usr/local/go/bin
RUN mkdir /app
WORKDIR /app
RUN git clone --recursive https://github.com/concourse/fly.git /app
RUN go get
RUN go build
RUN mv /usr/local/go/bin/app /usr/local/go/fly

#docker-compose and dc
FROM ubuntu as dc
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends sudo curl git ca-certificates
RUN git clone https://github.com/Cellophan/scripts.git /tmp/scripts
RUN find /tmp/scripts -maxdepth 1 -type f -executable -exec cp {} /usr/local/bin/ \; &&\
    /usr/local/bin/dc install
RUN curl -sSL \
		https://github.com/docker/compose/releases/download/1.13.0/docker-compose-$(uname -s)-$(uname -m) \
		>> /usr/local/bin/docker-compose
RUN chmod +x /usr/local/bin/docker-compose

#git-town
FROM ubuntu as git-town
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt install -qy --no-install-recommends wget ca-certificates
RUN wget --no-verbose -O /usr/local/bin/git-town https://github.com/Originate/git-town/releases/download/v4.0.1/git-town-linux-amd64
RUN chmod a+x /usr/local/bin/git-town

#jid
FROM ubuntu as jid
RUN	apt update
RUN DEBIAN_FRONTEND=noninteractive apt install -qy --no-install-recommends unzip wget ca-certificates
RUN wget --no-verbose -O /tmp/jid.zip  https://github.com/simeji/jid/releases/download/0.6.1/jid_linux_amd64.zip
RUN unzip -d /tmp /tmp/jid.zip
RUN mv /tmp/jid_linux_amd64 /usr/local/bin/jid

#vault
FROM ubuntu as vault
RUN apt update
RUN DEBIAN_FRONTEND=noninteractive apt install -qy --no-install-recommends unzip wget ca-certificates
RUN wget --no-verbose -O /tmp/vault.zip 'https://releases.hashicorp.com/vault/0.7.3/vault_0.7.3_linux_amd64.zip'
RUN unzip -d /tmp /tmp/vault.zip
RUN mv /tmp/vault /usr/local/bin/vault

#Main
FROM cell/playground
ENV DOCKER_IMAGE="cell/czsh"

#zsh and oh-my-zsh and my theme
#https://hub.docker.com/r/nacyot/ubuntu/~/dockerfile/
RUN apt update &&\
	apt install -qy --no-install-recommends zsh dconf-cli wget &&\
	apt clean -y && rm -rf /var/lib/apt/lists/* &&\
	git clone https://github.com/robbyrussell/oh-my-zsh.git /etc/skel/.oh-my-zsh &&\
	git clone https://github.com/Cellophan/agnoster-zsh-theme.git /etc/skel/.agnoster-zsh-theme &&\
	ln -s /etc/skel/.agnoster-zsh-theme/agnoster.zsh-theme /etc/skel/.oh-my-zsh/themes/agnoster-real.zsh-theme &&\
	ln -s /etc/skel/.oh-my-zsh /root &&\
	ln -s /etc/skel/.zshrc /root &&\
	mkdir -p /etc/skel/.fonts /etc/skel.config/fontconfig/conf.d &&\
	wget -q -P /etc/skel/.fonts/ https://github.com/powerline/powerline/raw/develop/font/PowerlineSymbols.otf &&\
	wget -q -P /etc/skel/.config/fontconfig/conf.d https://github.com/powerline/powerline/raw/develop/font/10-powerline-symbols.conf &&\
	apt remove -y wget

RUN apt update &&\
	apt install -qy --no-install-recommends fontconfig locales &&\
	apt clean -y && rm -rf /var/lib/apt/lists/* &&\
	locale-gen en_US.UTF-8 en_US &&\
	DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales &&\
	/usr/sbin/update-locale LANG=C.UTF-8 &&\
	chsh -s /bin/zsh

#Imports
COPY --from=fly      /usr/local/go/fly /usr/local/bin/
COPY --from=dc       /usr/local/bin/* /usr/local/bin/
COPY --from=git-town /usr/local/bin/* /usr/local/bin/
COPY --from=jid      /usr/local/bin/* /usr/local/bin/
COPY --from=vault  /usr/local/bin/* /usr/local/bin/

#make icdiff sshpass
RUN apt update &&\
	apt install -qy --no-install-recommends make icdiff sshpass &&\
	apt clean -y && rm -rf /var/lib/apt/lists/*

COPY material/payload	/opt/payload/
COPY material/scripts	/usr/local/bin/
COPY material/profile.d	/etc/profile.d/
COPY material/virtualenv.sudoers /etc/sudoers.d/virtualenv
COPY material/skel/*	/etc/skel/

