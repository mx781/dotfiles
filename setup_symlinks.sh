#!/bin/bash

ln -sf $(pwd)/.bash_aliases $HOME/.bash_aliases
ln -sf $(pwd)/scripts $HOME/scripts
ln -s $(pwd)/.xmonad $HOME/.xmonad
sudo mkdir -p /usr/share/X11/xkb/symbols
sudo ln -s $(pwd)/usr/share/X11/xkb/symbols/lv_pok3r_p1 /usr/share/X11/xkb/symbols/lv_pok3r_p1
