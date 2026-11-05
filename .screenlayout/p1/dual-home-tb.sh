#!/bin/sh
exec "$(dirname "$(readlink -f "$0")")/../apply.sh" --output DP-1.3 --mode 1920x1080 --pos 1920x0 --rotate normal --output eDP-1-1 --mode 1920x1080 --pos 0x0 --rotate normal
