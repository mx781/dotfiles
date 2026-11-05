#!/bin/sh
exec "$(dirname "$(readlink -f "$0")")/../apply.sh" --output eDP-1 --primary --mode 1920x1200 --pos 0x120 --rotate normal --output HDMI-1 --mode 3440x1440 --pos 1920x0 --rotate normal
