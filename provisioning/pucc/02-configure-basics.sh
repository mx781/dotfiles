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
