#!/bin/bash

ln -sf $(pwd)/.bash_aliases $HOME/.bash_aliases
ln -sf $(pwd)/scripts $HOME/scripts
ln -s $(pwd)/.xmonad $HOME/.xmonad
ln -s $(pwd)/Pictures/bg-mandra.jpg $HOME/Pictures/bg-mandra.jpg
ln -s $(pwd)/Pictures/bg-rust.jpg $HOME/Pictures/bg-rust.jpg
sudo mkdir -p /usr/share/X11/xkb/symbols
sudo ln -s $(pwd)/usr/share/X11/xkb/symbols/lv_pok3r_p1 /usr/share/X11/xkb/symbols/lv_pok3r_p1
