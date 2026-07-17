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
    echo $1 | sudo tee /sys/class/backlight/intel_backlight/brightness
}

## mandratek
alias manifold="cd /home/maksis/hub/maxtor/manifold && source venv/bin/activate"
alias mandra="cd /home/maksis/hub/maxtor/mandragora && source 311/bin/activate && source .env"
alias knowledge="cd /home/maksis/hub/knowledge && nvim"

# misc
alias olafa-nets="nmcli -p con up id olafs"
alias ppp="PYTHONPATH=$(pwd) python"
alias awake="dual && config-keyb && reset-bt"
