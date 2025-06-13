#!/bin/bash
# Bootable debian -> configured minimal desktop environment
if [ "$(id -u)" -eq 0 ]; then
    echo "This script must NOT be run as root" >&2
    exit 1
fi

sudo apt update
sudo install -m 0755 -d /etc/apt/keyrings

# X stuff
sudo apt install -y xorg xinit

# Prerequisites
sudo apt install -y build-essential

# Fundamentals
sudo apt install -y git dmenu

# Audio
sudo apt install -y pulseaudio pavucontrol

# Bluetooth
sudo apt install -y bluetooth

# Utils
sudo apt install -y feh xclip maim acpi wget curl bzip2 wmctrl ncdu nnn tmux

## fzf
sudo mkdir -p /opt/fzf
sudo git clone --depth 1 https://github.com/junegunn/fzf.git /opt/fzf
/opt/fzf/install

## ripgrep
curl -LO https://github.com/BurntSushi/ripgrep/releases/download/14.1.0/ripgrep_14.1.1-1_amd64.deb
sudo dpkg -i ripgrep_14.1.1-1_amd64.deb
rm ripgrep_14.1.1-1_amd64.deb

## clipmenu
sudo apt install -y libxfixes-dev
sudo mkdir -p /opt/clipmenu
sudo git clone https://github.com/cdown/clipmenu.git /opt/clipmenu
sudo make -C /opt/clipmenu install
systemctl enable --user clipmenud
systemctl start --user clipmenud

## xsecurelock
sudo apt install -y automake libpam-dev libxcomposite-dev libxmu-dev
sudo git clone https://github.com/google/xsecurelock.git /opt/xsecurelock
cd /opt/xsecurelock 
sudo ./autogen.sh
sudo ./configure --with-pam-service-name=SERVICE-NAME
sudo make
sudo make install
cd -

# GUI Utils
sudo apt install -y arandr

## Neovim
mkdir -p /opt/nvim
wget https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
tar -xzf nvim-linux-x86_64.tar.gz -C /opt/nvim --strip-components=1
ln -s /opt/nvim/bin/nvim /usr/local/bin/nvim
rm nvim-linux-x86_64.tar.gz

# Xmonad stuff
sudo apt install -y libx11-dev libxft-dev libxinerama-dev libxrandr-dev libxss-dev \
    libtinfo-dev libasound2-dev alsa-utils \
    conky dzen2 trayer \
    haskell-stack
stack upgrade

# Configuration
mkdir -p $HOME/hub
git clone https://github.com/mx781/dotfiles $HOME/hub/dotfiles
$HOME/hub/dotfiles/setup_symlinks.sh

ssh-keygen -t ed25519
echo "Your public SSH key is below:"
cat $HOME/.ssh/id_ed25519.pub
read -p "Add it to Github, hit ENTER when ready"

git clone git@github.com:mx781/knowledge.git $HOME/hub/knowledge

## Neovim setup
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

git config --global user.name "mxunknown"
git config --global user.email "mxunknown@gmail.com"
