#!/bin/bash

# clipmenud defaults to the runtime directory, which disappears at logout.
# Keep its clipboard history in a private user cache directory instead.  The
# packaged user unit cannot see DISPLAY when started by systemd, so launch it
# from this X session where the display is available.
export CM_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/clipmenu"
mkdir -p "$CM_DIR"
chmod 700 "$CM_DIR"
clipmenud &

exec xmonad
