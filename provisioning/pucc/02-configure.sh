#!/bin/bash
# Bootable debian -> configured desktop environment

if [ "$(id -u)" -eq 0 ]; then
    echo "This script must NOT be run as root" >&2
    exit 1
fi

apt update

# X stuff
apt install xorg xinit \
    libx11-dev libxft-dev libxinerama-dev libxrandr-dev libxss-dev libtinfo-dev # for Xmonad

# Prerequisites
apt install build-essential

# Utils
apt install feh xclip maim acpi wget curl bzip2

# GUI Utils
apt install arandr

# Fundamentals
apt install git alacritty dmenu

## Vim
mkdir -p /opt/nvim
wget https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
tar -xzf nvim-linux-x86_64.tar.gz -C /opt/nvim --strip-components=1
ln -s /opt/nvim/bin/nvim /usr/local/bin/nvim
rm nvim-linux-x86_64.tar.gz

# Audio
apt install pulseaudio pavucontrol \
    libasound2-dev alsa-utils  # for Xmonad

# Xmonad stuff
apt install haskell-stack conky dzen2 trayer
stack upgrade

# Configuration
mkdir -p /home/$USER/hub/dotfiles
# clone dotfiles repo, install it

## Neovim setup
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

git config --global user.name "mxunknown"
git config --global user.email "mxunknown@gmail.com"
