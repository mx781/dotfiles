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

# Screen aliases come from this computer's provisioned layout directory.
for screenlayout in "$HOME"/.screenlayout/*.sh; do
    [ -f "$screenlayout" ] || continue
    screenlayout_name=${screenlayout##*/}
    alias "${screenlayout_name%.sh}=\"$screenlayout\""
done
unset screenlayout screenlayout_name

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
# power-source change; these wrap it for manual overrides. The discrete GPU
# has its own whole-session switch, because keeping it in X means pinning it
# awake (each RTD3 resume freezes the X server for ~1.5s):
#   pmode           source, tlp profile, gpu state and draw
#   ac / battery    force one profile until the next power change
#   dgpu on         GPU in X: external monitors, prime-run; ~10W (default)
#   dgpu off        GPU out of X, sleeping; built-in panel only. Restarts X
#   dgpu measure    what `on` actually costs, in watts
pmode() {
    "$DOTFILES/scripts/power-mode" "$@"
}

dgpu() {
    "$DOTFILES/scripts/dgpu-power" "$@"
}

# startx that honours `dgpu off` and restarts X when dgpu asks it to. Plain
# `startx` only, so explicit arguments still pass straight through. A no-op
# difference on machines without the off-mode config (Pucc).
startx() {
    local restart="${XDG_RUNTIME_DIR:-/run/user/$UID}/p1-x-restart" off started
    while :; do
        rm -f "$restart"
        off=
        if [ $# -eq 0 ] && [ -e /run/p1-dgpu-manual-auto ] \
            && [ -f /etc/X11/p1-dgpu-off.conf ]; then
            off=1
        fi
        started=$SECONDS
        if [ -n "$off" ]; then
            command startx -- -nolisten tcp -config p1-dgpu-off.conf
        else
            command startx "$@"
        fi
        [ -e "$restart" ] && continue
        if [ -n "$off" ] && [ $((SECONDS - started)) -lt 10 ]; then
            echo "X exited right away in dgpu-off mode; \`dgpu on\` then \`startx\` to go back" >&2
        fi
        return
    done
}

# Shadows the rarely-used `ac` from the acct package, which is not installed.
alias ac="pmode ac"
alias battery="pmode battery"

## provisioning
# Runs from the playbook directory so ansible.cfg and inventory resolve, in a
# subshell so the caller's cwd survives. Extra args pass straight through:
#   provision p1 --tags base
#   provision pucc --tags base,dotfiles --check
provision() {
    local profile="${1:-}"
    case "$profile" in
        p1|pucc) shift ;;
        *) printf 'Usage: provision {p1|pucc} [ansible-playbook arguments]\n' >&2; return 2 ;;
    esac
    (cd "$DOTFILES/provisioning" && ansible-playbook site.yml --ask-become-pass \
        -e "workstation_profile=$profile" "$@")
}

## mandratek
alias manifold="cd /home/maksis/hub/maxtor/manifold && source venv/bin/activate"
alias mandra="cd /home/maksis/hub/maxtor/mandragora && source 311/bin/activate && source .env"
alias knowledge="cd /home/maksis/hub/knowledge && nvim"

# misc
alias olafa-nets="nmcli -p con up id olafs"
alias ppp="PYTHONPATH=$(pwd) python"
alias awake="dual && config-keyb && reset-bt"

## machine-local
# Aliases that should not be committed: internal hostnames, per-machine paths,
# anything credential-shaped. Gitignored, and sourced last so it can override
# anything above. Missing on a fresh checkout, which is fine.
if [ -f "$DOTFILES/.bash_aliases.private" ]; then
    . "$DOTFILES/.bash_aliases.private"
fi
