#!/bin/bash
# Minimal desktop environment -> full-fledged machine ready to roll
set -euo pipefail

if [ "$(id -u)" -eq 0 ]; then
    echo "This script must NOT be run as root" >&2
    exit 1
fi

# Docker
sudo apt install ca-certificates curl
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Node
curl -fsSL https://fnm.vercel.app/install | bash
. $HOME/.bashrc
fnm install 24.2.0

# Python
curl -LsSf https://astral.sh/uv/install.sh | sh
uv python install 3.12 

# Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Alacritty
cargo install alacritty
sudo ln -s $HOME/.cargo/bin/alacritty /usr/local/bin/alacritty

# Brave
curl -fsS https://dl.brave.com/install.sh | sh

# Firefox
wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
gpg -n -q --import --import-options import-show /etc/apt/keyrings/packages.mozilla.org.asc | awk '/pub/{getline; gsub(/^ +| +$/,""); if($0 == "35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3") print "\nThe key fingerprint matches ("$0").\n"; else print "\nVerification failed: the fingerprint ("$0") does not match the expected one.\n"}'
echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee -a /etc/apt/sources.list.d/mozilla.list > /dev/null
echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | sudo tee /etc/apt/preferences.d/mozilla
sudo apt update && sudo apt install firefox

# Telegram
wget https://telegram.org/dl/desktop/linux -O /tmp/telegram.tar.xz \
    && cd /tmp/ \
    && tar xvfJ /tmp/telegram.tar.xz \
    && sudo mv /tmp/Telegram/Telegram /usr/bin/Telegram \
    && rm -rf /tmp/{telegram.tar.xz,Telegram}

# LibreOffice
sudo apt install fuse libxslt1.1
wget https://appimages.libreitalia.org/LibreOffice-fresh.basic-x86_64.AppImage \
    -O $HOME/.local/bin/LibreOffice.AppImage \
    && chmod +x $HOME/.local/bin/LibreOffice.AppImage


# Slack
wget https://downloads.slack-edge.com/desktop-releases/linux/x64/4.43.51/slack-desktop-4.43.51-amd64.deb \
    -O /tmp/slack.deb \
    && sudo dpkg -i /tmp/slack.deb
sudo apt --fix-broken install -y # not sure how else to easily get all slack deps

# Gopass
curl https://packages.gopass.pw/repos/gopass/gopass-archive-keyring.gpg | sudo tee /usr/share/keyrings/gopass-archive-keyring.gpg
cat << EOF | sudo tee /etc/apt/sources.list.d/gopass.sources
Types: deb
URIs: https://packages.gopass.pw/repos/gopass
Suites: stable
Architectures: amd64 arm64 armhf
Components: main
Signed-By: /usr/share/keyrings/gopass-archive-keyring.gpg
EOF
sudo apt update
sudo apt install gopass-archive-keyring gopass

