#!/bin/sh
exec "$(dirname "$(readlink -f "$0")")/../apply.sh" --output eDP-1 --primary --mode 1920x1200 --pos 836x1600 --rotate normal --output DP-1-3 --mode 3840x1600 --pos 0x0 --rotate normal
