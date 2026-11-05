#!/bin/sh
exec "$(dirname "$(readlink -f "$0")")/../apply.sh" --output eDP-1 --primary --mode 1920x1080 --pos 0x0 --rotate normal
