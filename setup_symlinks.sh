#!/bin/bash

mkdir -p $HOME/.config/nvim
ln -s $(pwd)/.vimrc $HOME/.vimrc
ln -s $(pwd)/nvim/init.lua $HOME/.config/nvim/init.lua

ln -sf $(pwd)/.bash_aliases $HOME/.bash_aliases
ln -sf $(pwd)/.xsession $HOME/.xsession
ln -sf $(pwd)/scripts $HOME/scripts
ln -s $(pwd)/.xmonad $HOME/.xmonad

mkdir -p $HOME/Pictures
ln -s $(pwd)/Pictures/bg-mandra.jpg $HOME/Pictures/bg-mandra.jpg
ln -s $(pwd)/Pictures/bg-rust.jpg $HOME/Pictures/bg-rust.jpg
ln -s $(pwd)/Pictures/bg-kristaps-ungurs.jpg $HOME/Pictures/bg-kristaps-ungurs.jpg
ln -s $(pwd)/Pictures/bg-karina-skrypnik.jpg $HOME/Pictures/bg-karina-skrypnik.jpg

sudo mkdir -p /usr/share/X11/xkb/symbols
sudo ln -s $(pwd)/usr/share/X11/xkb/symbols/lv_pok3r_p1 /usr/share/X11/xkb/symbols/lv_pok3r_p1
