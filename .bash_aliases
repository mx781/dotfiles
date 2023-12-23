# constants
DOTFILES=/home/maksis/hub/dotfiles

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
alias config-keyb-old="setxkbmap lv -variant apostrophe"
alias config-keyb="setxkbmap lv_pok3r_p1" 

# screen
alias single="$HOME/.screenlayout/single.sh"
alias dual="$HOME/.screenlayout/dual-ultrawide.sh"

alias lockscreen="gnome-screensaver-command -l"
alias screensaver-on="xset s off -dpms"
alias screensaver-off="xset s on +dpms" 

alias xorg-intel="sudo ln -sf $DOTFILES/etc/X11/xorg_intel.conf /etc/X11/xorg.conf && echo 'xorg.conf updated, run reset-xserver to kill session and apply'"
alias xorg-dual="sudo ln -sf $DOTFILES/etc/X11/xorg_dual.conf /etc/X11/xorg.conf && echo 'xorg.conf updated, run reset-xserver to kill session and apply'"

# wifi
alias rescan="nmcli device wifi rescan"

# reset things
alias reset-sound="pulseaudio -k && sudo alsa force-reload"
alias reset-bt="rfkill block bluetooth && rfkill unblock bluetooth"
alias reset-gpu="sudo rmmod nvidia_uvm && sudo modprobe nvidia_uvm"
alias reset-wine="wineserver -k"
alias reset-bg="feh --bg-fill $HOME/Pictures/bg-mandra.jpg"
alias reset-xserver="sudo systemctl restart display-manager"

# project-specific
## vivacity
# alias vpn="/home/maksis/hub/vivacity/atrocity/office-openvpn/connect.sh"
# alias tfinit="terraform init -backend-config="encryption_key=$(cat /home/maksis/secrets/tfstate_secret.key)""
# alias tfinit132="terraform132 init -backend-config="encryption_key=$(cat /home/maksis/secrets/tfstate_secret.key)""
# alias tfinit135="terraform135 init -backend-config="encryption_key=$(cat /home/maksis/secrets/tfstate_secret.key)""
# alias prod="gcloud container clusters get-credentials main-cluster --zone europe-west1-b --project vivacity-infrastructure && export VAULT_ADDR=https://vault.vivacitylabs.com && kubectl get pods > /dev/null && export TF_VAR_kubectl_auth_token_prod=$(cat ~/.kube/config | yq e '.users[] | select(.name == "gke_vivacity-infrastructure_europe-west1-b_main-cluster") | .user["auth-provider"] | .config["access-token"]' -)"
# alias staging="gcloud container clusters get-credentials staging-cluster --zone europe-west1-b --project vivacity-infrastructure && export VAULT_ADDR=https://vault.staging.vivacitylabs.com  && kubectl get pods > /dev/null && export TF_VAR_kubectl_auth_token_staging=$(cat ~/.kube/config | yq e '.users[] | select(.name == "gke_vivacity-infrastructure_europe-west1-b_staging-cluster") | .user["auth-provider"] | .config["access-token"]' -)"
# alias dev="gcloud container clusters get-credentials dev-cluster --zone europe-west1-b --project vivacity-infrastructure && export VAULT_ADDR=https://vault.dev.vivacitylabs.com  && kubectl get pods > /dev/null && export TF_VAR_kubectl_auth_token_dev=$(cat ~/.kube/config | yq e '.users[] | select(.name == "gke_vivacity-infrastructure_europe-west1-b_dev-cluster") | .user["auth-provider"] | .config["access-token"]' -)"

## mandratek
alias manifold="cd /home/maksis/hub/maxtor/manifold && source venv/bin/activate"
alias mandra="cd /home/maksis/hub/maxtor/mandragora && source env/bin/activate"

## imbue
alias imbue="cd /home/maksis/hub/testgrounds/generally_intelligent && source venv/311/bin/activate && source science/secrets/environment_vars/controller_vars.sh && source science/secrets/environment_vars/bashenv_secrets.sh"

# misc
alias olafa-nets="nmcli -p con up id olafs"
