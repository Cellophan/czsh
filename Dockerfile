FROM cell/debsandbox
MAINTAINER Cell <maintainer.docker.cell@outer.systems>
ENV	DOCKER_IMAGE="cell/czsh"

#Tools
#  make
RUN apt-get update &&\
	apt-get install -qy make &&\
	apt-get clean -y && rm -rf /var/lib/apt/lists/*

#  docker-compose
RUN	git clone https://github.com/Cellophan/scripts.git /tmp/scripts &&\
	find /tmp/scripts -maxdepth 1 -type f -executable -exec cp {} /usr/local/bin/ \; &&\
	rm -rf /tmp/scripts &&\
	dc install &&\
	curl -sSL \
		https://github.com/docker/compose/releases/download/1.11.1/docker-compose-$(uname -s)-$(uname -m) \
		>> /usr/local/bin/docker-compose &&\
	chmod +x /usr/local/bin/docker-compose

#  jid
RUN	apt-get update &&\
	DEBIAN_FRONTEND=noninteractive apt-get install -qy unzip &&\
	wget -O /tmp/jid.zip  https://github.com/simeji/jid/releases/download/0.6.1/jid_linux_amd64.zip &&\
	unzip -d /tmp /tmp/jid.zip &&\
	mv /tmp/jid_linux_amd64 /usr/local/bin/jid &&\
	apt-get remove -y unzip

COPY material/payload	/opt/payload/
COPY material/scripts	/usr/local/bin/
COPY material/profile.d	/etc/profile.d/
COPY material/zshrc		/etc/skel/.zshrc
COPY material/virtualenv.sudoers /etc/sudoers.d/virtualenv

#zsh and oh-my-zsh and my theme
#https://hub.docker.com/r/nacyot/ubuntu/~/dockerfile/
RUN apt-get update &&\
	apt-get install -qy zsh dconf-cli &&\
	apt-get clean -y && rm -rf /var/lib/apt/lists/* &&\
	git clone https://github.com/robbyrussell/oh-my-zsh.git /etc/skel/.oh-my-zsh &&\
	git clone https://github.com/Cellophan/agnoster-zsh-theme.git /etc/skel/.agnoster-zsh-theme &&\
	ln -s /etc/skel/.agnoster-zsh-theme/agnoster.zsh-theme /etc/skel/.oh-my-zsh/themes/agnoster-real.zsh-theme &&\
	ln -s /etc/skel/.oh-my-zsh /root &&\
	ln -s /etc/skel/.zshrc /root

RUN	mkdir -p /etc/skel/.fonts /etc/skel.config/fontconfig/conf.d &&\
	wget -q -P /etc/skel/.fonts/ https://github.com/powerline/powerline/raw/develop/font/PowerlineSymbols.otf &&\
	wget -q -P /etc/skel/.config/fontconfig/conf.d https://github.com/powerline/powerline/raw/develop/font/10-powerline-symbols.conf

RUN apt-get update &&\
	apt-get install -qy fontconfig locales &&\
	apt-get clean -y && rm -rf /var/lib/apt/lists/* &&\
	locale-gen en_US.UTF-8 en_us &&\
	DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales &&\
	/usr/sbin/update-locale LANG=C.UTF-8 &&\
	chsh -s /bin/zsh

