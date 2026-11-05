#!/bin/sh
exec "$(dirname "$(readlink -f "$0")")/../apply.sh" --output eDP1 --primary --mode 1920x1080 --pos 0x360 --rotate normal --output HDMI-1-0 --mode 3440x1440 --pos 1920x0 --rotate normal
