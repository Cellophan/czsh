FROM cell/debsandbox
MAINTAINER Cell <maintainer.docker.cell@outer.systems>
ENV	DOCKER_IMAGE="cell/czsh"

ADD material/payload	/opt/payload/
ADD material/scripts	/usr/local/bin/
ADD material/profile.d	/etc/profile.d/
ADD material/zshrc		/etc/skel/.zshrc
ADD material/virtualenv.sudoers /etc/sudoers.d/virtualenv

# https://hub.docker.com/r/nacyot/ubuntu/~/dockerfile/
RUN apt-get update &&\
	apt-get install -qy zsh dconf-cli &&\
	apt-get clean -y && rm -rf /var/lib/apt/lists/* &&\
	git clone git://github.com/robbyrussell/oh-my-zsh.git /etc/skel/.oh-my-zsh &&\
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

#Import tools
RUN	git clone https://github.com/Cellophan/scripts.git /tmp/scripts &&\
	find /tmp/scripts -maxdepth 1 -type f -executable -exec cp {} /usr/local/bin/ \; &&\
	rm -rf /tmp/scripts &&\
	dc install &&\
	curl -sSL \
		https://github.com/docker/compose/releases/download/1.9.0/docker-compose-$(uname -s)-$(uname -m) \
		>> /usr/local/bin/docker-compose &&\
	chmod +x /usr/local/bin/docker-compose
