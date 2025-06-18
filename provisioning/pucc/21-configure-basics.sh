#!/bin/bash
# Minimal desktop environment -> configured desktop environment
set -euo pipefail

if [ "$(id -u)" -eq 0 ]; then
    echo "This script must NOT be run as root" >&2
    exit 1
fi

# Configuration
mkdir -p $HOME/hub
git clone https://github.com/mx781/dotfiles $HOME/hub/dotfiles
cd $HOME/hub/dotfiles
git submodule update --init --recursive
$HOME/hub/dotfiles/setup_symlinks.sh

# Xmonad
cd $HOME/.xmonad
stack install

# SSH
ssh-keygen -t ed25519
echo "Your public SSH key is below:"
cat $HOME/.ssh/id_ed25519.pub
read -p "Add it to Github, hit ENTER when ready (goto new tty, startx, login, use Brave): "

# Core repos
git clone git@github.com:mx781/knowledge.git $HOME/hub/knowledge

# Neovim setup
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# Git
git config --global user.name "mxunknown"
git config --global user.email "mxunknown@gmail.com"

# Fonts
fonts_dir="${HOME}/.local/share/fonts"
if [ ! -d "${fonts_dir}" ]; then
    echo "mkdir -p $fonts_dir"
    mkdir -p "${fonts_dir}"
else
    echo "Found fonts dir $fonts_dir"
fi

version=v3.4.0
curl --fail --location --show-error https://github.com/ryanoasis/nerd-fonts/releases/download/${version}/FiraCode.zip --output FiraCode.zip
unzip -o -q -d ${fonts_dir} FiraCode.zip
rm FiraCode.zip

echo "fc-cache -f"
fc-cache -f

# GPG
gpg --full-generate-key
