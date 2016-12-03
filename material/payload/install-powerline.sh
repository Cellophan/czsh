#!/bin/bash

set -e

mkdir -p /etc/skel/.fonts /etc/skel.config/fontconfig/conf.d
wget -q -P /etc/skel/.fonts/ https://github.com/powerline/powerline/raw/develop/font/PowerlineSymbols.otf
wget -q -P /etc/skel/.config/fontconfig/conf.d https://github.com/powerline/powerline/raw/develop/font/10-powerline-symbols.conf

# https://hub.docker.com/r/nacyot/ubuntu/~/dockerfile/
apt-get update
apt-get install -qy fontconfig locales
apt-get clean -y && rm -rf /var/lib/apt/lists/*
locale-gen en_US.UTF-8 en_us
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales
/usr/sbin/update-locale LANG=C.UTF-8
chsh -s /bin/zsh


