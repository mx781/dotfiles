#!/usr/bin/env bash
# Smoke-test a completed P1 workstation provisioning.
#
# Run on the target as root:
#   sudo provisioning/p1/smoke-test.sh --user "$USER"
#
# The test deliberately never reads Gopass entries, clipboard contents, private
# keys, or browser profiles.  GUI checks use the running X session only.
set -uo pipefail

usage() {
    cat <<'EOF'
Usage: sudo provisioning/p1/smoke-test.sh --user USER [--display DISPLAY] [--screenshots]

Writes logs and a PASS/FAIL/SKIP summary to ~/p1-smoke-artifacts/<timestamp>.
--screenshots captures the active desktop and may include sensitive content; it
is deliberately opt-in.
EOF
}

target_user=""
display=":0"
take_screenshots=0

while (($#)); do
    case "$1" in
        --user) target_user="${2:?missing user}"; shift 2 ;;
        --display) display="${2:?missing display}"; shift 2 ;;
        --screenshots) take_screenshots=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done

[[ ${EUID} -eq 0 ]] || { echo 'Run this script with sudo.' >&2; exit 2; }
[[ -n $target_user ]] || { echo '--user is required.' >&2; exit 2; }
id "$target_user" >/dev/null

target_home=$(getent passwd "$target_user" | cut -d: -f6)
repo="$target_home/hub/dotfiles"
timestamp=$(date +%Y%m%d-%H%M%S)
artifacts="$target_home/p1-smoke-artifacts/$timestamp"
mkdir -p "$artifacts"
chown "$target_user:$target_user" "$target_home/p1-smoke-artifacts" "$artifacts"
log="$artifacts/smoke-test.log"
summary="$artifacts/summary.tsv"
checklist="$artifacts/human-checklist.md"
touch "$log" "$summary"
chown "$target_user:$target_user" "$log" "$summary"

cat >"$checklist" <<EOF
# P1 human smoke-test checklist

Review this after the machine checks pass.  Do not capture or paste secrets.

- Open a new Alacritty: it uses the default terminal palette, a Fira Code Nerd
  Font glyph renders correctly, and no configuration warning appears.
- Press Super+V: Clipmenu opens, contains a harmless newly copied value, and
  remains populated after restarting X/startx.
- Check the Dzen bar: icons and focused workspace use the selected theme,
  geometry fits the active monitor, and no literal backslashes are visible.
- Open a terminal, browser, LibreOffice, Telegram, Slack, and VLC once.

Hardware validation is intentionally out of scope for this P1 smoke test.
EOF
chown "$target_user:$target_user" "$checklist"

passes=0
failures=0
skips=0

record() {
    local state=$1 name=$2 detail=${3:-}
    printf '%s\t%s\t%s\n' "$state" "$name" "$detail" | tee -a "$summary" "$log"
    case "$state" in
        PASS) ((passes += 1)) ;;
        FAIL) ((failures += 1)) ;;
        SKIP) ((skips += 1)) ;;
    esac
}

pass() { record PASS "$1" "${2:-}"; }
fail() { record FAIL "$1" "${2:-}"; }
skip() { record SKIP "$1" "${2:-}"; }

run_user() {
    runuser -u "$target_user" -- env \
        HOME="$target_home" DISPLAY="$display" XAUTHORITY="$target_home/.Xauthority" \
        PATH="/usr/local/bin:/usr/bin:/bin:$target_home/.local/bin:$target_home/.cargo/bin" "$@"
}

check_command() {
    local command=$1
    if run_user bash -lc "command -v '$command'" >>"$log" 2>&1; then
        pass "command:$command"
    else
        fail "command:$command" 'not in target user PATH'
    fi
}

check_link() {
    local path=$1
    if [[ -L $path && -e $path ]]; then
        pass "link:${path#$target_home/}"
    else
        fail "link:${path#$target_home/}" 'missing or dangling'
    fi
}

check_apt() {
    if apt-get update >>"$log" 2>&1; then
        pass apt-update
    else
        fail apt-update 'repository update or signature verification failed'
    fi
    if [[ -e /etc/apt/sources.list.d/slack.list ]]; then
        fail slack-source 'obsolete Slack Packagecloud source is present'
    else
        pass slack-source 'obsolete source absent'
    fi
}

check_base() {
    local commands=(
        acpi alacritty amixer arandr cmake conky curl dmenu_run ffmpeg feh fc-match
        fzf git htop maim ncdu nnn pavucontrol powertop killall rg rsync scrot tmux
        unzip vlc wget wmctrl xclip xdg-open xinit xsecurelock
    )
    local command
    for command in "${commands[@]}"; do check_command "$command"; done

    if run_user fc-match -f '%{family}\n' 'Fira Code Nerd Font' 2>>"$log" |
        grep -Eqi 'Fira ?Code.*Nerd|FiraCodeNerd'; then
        pass nerd-font
    else
        fail nerd-font 'Fira Code Nerd Font was not selected by fontconfig'
    fi
    if [[ $(timedatectl show --property=NTPSynchronized --value) == yes ]]; then
        pass ntp-sync
    else
        fail ntp-sync 'timedatectl does not report synchronization'
    fi
    systemctl is-enabled --quiet systemd-timesyncd.service && pass timesync-enabled || fail timesync-enabled
    systemctl is-enabled --quiet bluetooth.service && pass bluetooth-enabled || fail bluetooth-enabled
}

check_dotfiles() {
    [[ -d $repo/.git ]] && pass dotfiles-checkout || { fail dotfiles-checkout; return; }
    local links=(
        .vimrc .bashrc .bash_aliases .xsession .xinitrc scripts .xmonad
        .config/alacritty/alacritty.toml .config/shell/theme-prompt.sh .config/nvim/init.lua
    )
    local link
    for link in "${links[@]}"; do check_link "$target_home/$link"; done

    if run_user bash -ic 'true' >>"$log" 2>&1; then
        pass bash-startup
    else
        fail bash-startup 'interactive Bash returned non-zero; see log'
    fi
    if [[ -x $repo/scripts/theme ]] && run_user "$repo/scripts/theme" apply >>"$log" 2>&1; then
        pass theme-generation
    else
        fail theme-generation
    fi
    if python3 - "$repo/themes" >>"$log" 2>&1 <<'PY'; then
import pathlib
import sys
import tomllib

required = {
    'wallpaper', 'background', 'foreground', 'accent', 'status_accent', 'muted',
    'border_normal', 'border_focused', 'urgent', 'status_foreground',
    'battery_urgent', 'battery_warning',
}
for path in pathlib.Path(sys.argv[1]).glob('*.toml'):
    colors = tomllib.loads(path.read_text())['colors']
    missing = required - set(colors)
    if missing:
        raise SystemExit(f'{path}: missing {sorted(missing)}')
print('theme schemas valid')
PY
        pass theme-schemas
    else
        fail theme-schemas
    fi
}

check_developer() {
    local commands=(docker node npm npx corepack tree-sitter claude codex uv cargo rustc)
    local command
    for command in "${commands[@]}"; do check_command "$command"; done
    for command in node npm tree-sitter claude codex uv cargo rustc; do
        if run_user "$command" --version >>"$log" 2>&1; then
            pass "version:$command"
        else
            fail "version:$command"
        fi
    done
    if id -nG "$target_user" | tr ' ' '\n' | grep -qx docker; then
        pass docker-group
    else
        fail docker-group "${target_user} is not in docker group"
    fi
    if run_user docker version >>"$log" 2>&1; then
        pass docker-daemon
    else
        fail docker-daemon 'may require a fresh login after group membership change'
    fi
}

check_desktop_apps() {
    local commands=(brave-browser firefox gopass libreoffice Telegram slack nvim)
    local command
    for command in "${commands[@]}"; do check_command "$command"; done
    if run_user nvim --headless '+lua assert(pcall(require, "nvim-treesitter"))' '+qall' >>"$log" 2>&1; then
        pass nvim-treesitter
    else
        fail nvim-treesitter
    fi
    if run_user nvim --headless '+qall' >>"$log" 2>&1; then
        pass nvim-startup
    else
        fail nvim-startup
    fi
    if run_user gopass version >>"$log" 2>&1; then
        pass gopass-cli
    else
        fail gopass-cli
    fi
}

check_x_session() {
    if ! run_user wmctrl -m >>"$log" 2>&1; then
        skip x-session 'no reachable X display; rerun with --display DISPLAY'
        return
    fi
    pass x-session "DISPLAY=$display"

    local alacritty_log="$artifacts/alacritty.log"
    if run_user alacritty -vv -e true >"$alacritty_log" 2>&1; then
        if grep -Eiq 'unused config key|deprecated.*config|config.*error' "$alacritty_log"; then
            fail alacritty-config 'see configuration warnings in log'
        else
            pass alacritty-config
        fi
    else
        fail alacritty-launch
    fi

    local conky_before conky_pid
    conky_before=$(pgrep -u "$target_user" -x conky 2>/dev/null | tr '\n' ' ' || true)
    if timeout 4s runuser -u "$target_user" -- env \
        HOME="$target_home" DISPLAY="$display" XAUTHORITY="$target_home/.Xauthority" \
        PATH="/usr/local/bin:/usr/bin:/bin:$target_home/.local/bin:$target_home/.cargo/bin" \
        conky -c "$target_home/.xmonad/.conky_dzen" >"$artifacts/conky-dzen.txt" 2>>"$log"; then :; fi
    # The configuration daemonizes Conky, so give its child a short window to
    # flush the first Dzen status line into the artifact before inspecting it.
    local attempt
    for attempt in {1..20}; do
        grep -Eq '\^fg\(#[[:xdigit:]]{6}\)' "$artifacts/conky-dzen.txt" && break
        sleep 0.2
    done
    # Do not leave the temporary Conky instance behind; preserve any bar
    # instance that predated this test.
    for conky_pid in $(pgrep -u "$target_user" -x conky 2>/dev/null || true); do
        case " $conky_before " in
            *" $conky_pid "*) ;;
            *) kill "$conky_pid" 2>>"$log" || true ;;
        esac
    done
    if grep -Fq '^fg()' "$artifacts/conky-dzen.txt"; then
        fail conky-theme 'empty Dzen foreground directive'
    elif grep -Eq '\^fg\(#[[:xdigit:]]{6}\)' "$artifacts/conky-dzen.txt"; then
        pass conky-theme
    else
        fail conky-theme 'no concrete Dzen colour directive emitted'
    fi

    if run_user setxkbmap lv_pok3r_p1 >>"$log" 2>&1 && run_user xkbcomp -xkb "$display" - >>"$artifacts/xkb-map.txt" 2>>"$log"; then
        pass keyboard-layout
    else
        fail keyboard-layout
    fi
    if [[ -d $target_home/.cache/clipmenu ]] && [[ $(stat -c %a "$target_home/.cache/clipmenu") == 700 ]]; then
        pass clipmenu-cache-permissions
    else
        fail clipmenu-cache-permissions
    fi
    if ps -u "$target_user" -o args= | grep -q '[c]lipmenud'; then
        pass clipmenu-daemon
    else
        fail clipmenu-daemon 'start a new X session or inspect .xsession'
    fi
    if run_user bash -c 'cd "$HOME/.xmonad" && ./build "$1"' _ \
        "$artifacts/xmonad-smoke" >>"$log" 2>&1; then
        pass xmonad-build
    else
        fail xmonad-build
    fi
    if run_user "$target_home/scripts/dzen-geometry" workspace >>"$artifacts/dzen-workspace.txt" 2>>"$log" &&
       run_user "$target_home/scripts/dzen-geometry" status >>"$artifacts/dzen-status.txt" 2>>"$log"; then
        pass dzen-geometry
    else
        fail dzen-geometry
    fi

    if ((take_screenshots)); then
        if run_user maim "$artifacts/desktop.png" >>"$log" 2>&1; then
            pass desktop-screenshot "$artifacts/desktop.png"
        else
            fail desktop-screenshot
        fi
    else
        skip desktop-screenshot 'use --screenshots only when the desktop has no sensitive content'
    fi
}

check_apt
check_base
check_dotfiles
check_developer
check_desktop_apps
check_x_session

printf '\nSummary: %d passed, %d failed, %d skipped\nArtifacts: %s\n' \
    "$passes" "$failures" "$skips" "$artifacts" | tee -a "$log"
((failures == 0))
