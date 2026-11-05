#!/bin/sh
exec "$(dirname "$(readlink -f "$0")")/../apply.sh" --output eDP-1 --primary --mode 1920x1080 --pos 3840x1080 --rotate normal --output DP-1-1 --mode 3840x2160 --pos 0x0 --rotate normal
