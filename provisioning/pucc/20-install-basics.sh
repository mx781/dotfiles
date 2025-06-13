#!/bin/bash
# Bootable debian -> minimal desktop environment
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

apt update
install -m 0755 -d /etc/apt/keyrings

# X stuff
apt install -y xorg xinit

# Prerequisites
apt install -y build-essential

# Fundamentals
apt install -y git dmenu

# Audio
apt install -y pulseaudio pavucontrol

# Bluetooth
apt install -y bluetooth

# Utils
apt install -y feh xclip maim acpi wget curl bzip2 wmctrl ncdu nnn tmux

## fzf
mkdir -p /opt/fzf
git clone --depth 1 https://github.com/junegunn/fzf.git /opt/fzf
/opt/fzf/install

## ripgrep
curl -LO https://github.com/BurntSushi/ripgrep/releases/download/14.1.1/ripgrep_14.1.1-1_amd64.deb
dpkg -i ripgrep_14.1.1-1_amd64.deb
rm ripgrep_14.1.1-1_amd64.deb

## clipmenu
apt install -y libxfixes-dev
mkdir -p /opt/clipmenu
git clone https://github.com/cdown/clipmenu.git /opt/clipmenu
make -C /opt/clipmenu install
systemctl enable --user clipmenud
systemctl start --user clipmenud

## xsecurelock
apt install -y automake pkg-config libpam-dev libxcomposite-dev libxmu-dev
git clone https://github.com/google/xsecurelock.git /opt/xsecurelock
cd /opt/xsecurelock 
./autogen.sh
./configure --with-pam-service-name=common-auth
make
make install
cd -

# GUI Utils
apt install -y arandr

## Neovim
mkdir -p /opt/nvim
wget https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
tar -xzf nvim-linux-x86_64.tar.gz -C /opt/nvim --strip-components=1
ln -s /opt/nvim/bin/nvim /usr/local/bin/nvim
rm nvim-linux-x86_64.tar.gz

# Xmonad stuff
apt install -y libx11-dev libxft-dev libxinerama-dev libxrandr-dev libxss-dev \
    libtinfo-dev libasound2-dev alsa-utils \
    conky dzen2 trayer \
    haskell-stack
stack upgrade

# Brave (technically not basics, but needed for configure step)
curl -fsS https://dl.brave.com/install.sh | sh
