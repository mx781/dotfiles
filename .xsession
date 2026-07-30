#!/bin/bash

# clipmenud defaults to the runtime directory, which disappears at logout.
# Keep its clipboard history in a private user cache directory instead.  The
# packaged user unit cannot see DISPLAY when started by systemd, so launch it
# from this X session where the display is available.
export CM_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/clipmenu"
mkdir -p "$CM_DIR"
chmod 700 "$CM_DIR"
clipmenud &

# Notification daemon behind notify-send, which the P1 storage alerts use.
# D-Bus would activate it through the systemd user manager, which cannot see
# DISPLAY here for the same reason as clipmenud, so start it from the session.
dunst &

exec xmonad
