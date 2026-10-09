# constants
DOTFILES=/home/maksis/hub/dotfiles

alias ll="ls -lash"

# git
alias gs="git status"
alias gps="git push"
alias gpl="git pull"
alias gsuir="git submodule update --init --recursive"
alias gsl="git stash list"
alias gsp="git stash pop"

alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'

# keeb
alias config-keyb="setxkbmap lv_pok3r_p1" 

# cmds to launch on login
alias config-startup="gnome-session-properties"

# screen
alias single="$HOME/.screenlayout/single.sh"
alias docked="$HOME/.screenlayout/docked.sh"
alias home="$HOME/.screenlayout/home.sh"

alias lockscreen="gnome-screensaver-command -l"
alias screensaver-on="xset s off -dpms"
alias screensaver-off="xset s on +dpms" 

alias xorg-intel="sudo ln -sf $DOTFILES/etc/X11/xorg_intel.conf /etc/X11/xorg.conf && echo 'xorg.conf updated, run reset-xserver to kill session and apply'"
alias xorg-dual="sudo ln -sf $DOTFILES/etc/X11/xorg_dual.conf /etc/X11/xorg.conf && echo 'xorg.conf updated, run reset-xserver to kill session and apply'"

# wifi
alias rescan="nmcli device wifi rescan"

# reset things
alias reset-sound="pulseaudio -k && sudo alsa force-reload"
alias reset-bt="sudo rfkill block bluetooth && sudo rfkill unblock bluetooth"
alias reset-gpu="sudo rmmod nvidia_uvm && sudo modprobe nvidia_uvm"
alias reset-wine="wineserver -k"
alias reset-bg="feh --bg-fill $HOME/Pictures/bg-mandra.jpg"
alias reset-xserver="sudo systemctl restart display-manager"


## brightness
brightness() {
    echo $1 > /sys/class/backlight/intel_backlight/brightness
}

## power
# TLP owns the battery/AC profile and switches it automatically on every
# power-source change; these wrap it for manual overrides and keep the
# discrete GPU pinned awake in both modes. The GPU is pinned because every
# D3cold resume blocks the X server for ~1.5s, which reads as the whole
# desktop freezing for a second about once a minute.
#   pmode           source, tlp profile, gpu state and draw
#   ac / battery    force one profile until the next power change
#   dgpu auto       hand the watts back, freezes and all (manual override)
#   dgpu measure    what pinning actually costs, in watts
pmode() {
    "$DOTFILES/scripts/power-mode" "$@"
}

dgpu() {
    "$DOTFILES/scripts/dgpu-power" "$@"
}

# Shadows the rarely-used `ac` from the acct package, which is not installed.
alias ac="pmode ac"
alias battery="pmode battery"

## mandratek
alias manifold="cd /home/maksis/hub/maxtor/manifold && source venv/bin/activate"
alias mandra="cd /home/maksis/hub/maxtor/mandragora && source 311/bin/activate && source .env"
alias knowledge="cd /home/maksis/hub/knowledge && nvim"

# misc
alias olafa-nets="nmcli -p con up id olafs"
alias ppp="PYTHONPATH=$(pwd) python"
alias awake="dual && config-keyb && reset-bt"
