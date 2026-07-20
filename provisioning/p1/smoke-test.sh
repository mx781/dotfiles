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
Usage: sudo provisioning/p1/smoke-test.sh --user USER [--display DISPLAY] [--no-screenshots]

Writes logs and a PASS/FAIL/SKIP summary to ~/p1-smoke-artifacts/<timestamp>.
Visual screenshots are captured by default.  They may include sensitive content
from an already-active desktop; use --no-screenshots to omit them.
EOF
}

target_user=""
display=":0"
take_screenshots=1

while (($#)); do
    case "$1" in
        --user) target_user="${2:?missing user}"; shift 2 ;;
        --display) display="${2:?missing display}"; shift 2 ;;
        --screenshots) take_screenshots=1; shift ;;
        --no-screenshots) take_screenshots=0; shift ;;
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
report="$artifacts/report.md"
screenshots="$artifacts/screenshots"
mkdir -p "$screenshots"
chown "$target_user:$target_user" "$screenshots"
touch "$log" "$summary"
chown "$target_user:$target_user" "$log" "$summary"

cat >"$checklist" <<EOF
# P1 human smoke-test checklist

Review this after the machine checks pass.  Do not capture or paste secrets.

- Review every PNG in this artifact directory.  They cover the default desktop,
  Alacritty + Neovim glyph fixture, Firefox, Brave, LibreOffice, PCManFM,
  Telegram, Slack, VLC, and ARandR.  Confirm the rendered UI is legible and
  appropriate.
- Press Super+V: Clipmenu opens, contains a harmless newly copied value, and
  remains populated after restarting X/startx.  This deliberately avoids
  capturing clipboard contents.
- Lock and unlock once with XSecureLock.  The automated test does not lock a
  live X session.

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

window_id_for() {
    local pattern=$1 excluded_ids=${2:-} max_attempts=${3:-120} window_id attempt
    for ((attempt = 1; attempt <= max_attempts; attempt++)); do
        window_id=$(run_user wmctrl -lx 2>>"$log" |
            awk -v pattern="$pattern" -v excluded=" $excluded_ids " '
                index(tolower($0), tolower(pattern)) && index(excluded, " " $1 " ") == 0 {
                    print $1; exit
                }
            ')
        [[ -n $window_id ]] && { printf '%s\n' "$window_id"; return 0; }
        sleep 0.25
    done
    return 1
}

capture_window() {
    local name=$1 pattern=$2 window_id window_id_decimal existing_ids
    shift 2
    existing_ids=$(run_user wmctrl -lx 2>>"$log" |
        awk -v pattern="$pattern" 'index(tolower($0), tolower(pattern)) { printf "%s ", $1 }')
    run_user "$@" >>"$log" 2>&1 &
    # Prefer the window this invocation created.  Single-instance applications
    # may reuse an existing window, so fall back to that after a short wait.
    if ! window_id=$(window_id_for "$pattern" "$existing_ids" 12); then
        window_id=$(window_id_for "$pattern") || true
    fi
    if [[ -n ${window_id:-} ]]; then
        # wmctrl reports hexadecimal XIDs, whereas maim interprets its input
        # as decimal.  Convert explicitly or maim silently captures the root.
        window_id_decimal=$((window_id))
    fi
    if [[ -n ${window_id_decimal:-} ]] &&
        run_user maim -i "$window_id_decimal" "$screenshots/$name.png" >>"$log" 2>&1; then
        pass "screenshot:$name" "screenshots/$name.png"
    else
        fail "screenshot:$name" "did not find a $pattern window"
    fi
}

capture_visuals() {
    local fixture="$artifacts/p1-visual-fixture.txt"
    cat >"$fixture" <<'EOF'
P1 visual smoke-test fixture

ASCII: ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789
Nerd Font glyphs: 󰍛 󰘚 󰖩 󰂯 󰄛 󰅐
Unicode: → ✓ ★ λ 日本語
EOF
    chown "$target_user:$target_user" "$fixture"

    local original_workspace
    original_workspace=$(run_user wmctrl -d 2>>"$log" | awk '$2 == "*" { print $1; exit }')
    # Workspace 9 is reserved for the clean desktop fixture.  Switch back
    # immediately after capturing so a test does not leave the user elsewhere.
    run_user wmctrl -s 8 >>"$log" 2>&1 || true
    sleep 0.5
    if run_user maim "$screenshots/desktop.png" >>"$log" 2>&1; then
        pass screenshot:desktop 'screenshots/desktop.png'
    else
        fail screenshot:desktop
    fi
    [[ -n $original_workspace ]] && run_user wmctrl -s "$original_workspace" >>"$log" 2>&1 || true
    capture_window alacritty-nvim p1-smoke-alacritty \
        alacritty --class p1-smoke-alacritty,p1-smoke-alacritty -e nvim "$fixture"
    capture_window firefox firefox firefox --new-window about:blank
    capture_window brave brave brave-browser --new-window about:blank
    capture_window libreoffice libreoffice libreoffice --writer "$fixture"
    capture_window pcmanfm pcmanfm pcmanfm "$target_home"
    capture_window telegram telegram Telegram
    capture_window slack slack slack
    capture_window vlc vlc vlc
    capture_window arandr arandr arandr
}

report_checks() {
    local title=$1 pattern=$2
    printf '## %s\n\n| Status | Check | Detail |\n| --- | --- | --- |\n' "$title"
    awk -F '\t' -v pattern="$pattern" '
        $2 ~ pattern {
            gsub(/\|/, "\\\\|", $3)
            printf "| %s | `%s` | %s |\n", $1, $2, $3
            found = 1
        }
        END { if (!found) print "| — | _No checks recorded_ | — |" }
    ' "$summary"
    printf '\n'
}

report_screenshot() {
    local filename=$1 title=$2
    printf '### %s\n\n' "$title"
    if [[ -e $screenshots/$filename.png ]]; then
        printf '[Open PNG](screenshots/%s.png)\n\n![](screenshots/%s.png)\n\n' "$filename" "$filename"
    else
        printf '_No screenshot was captured; inspect the associated check result above._\n\n'
    fi
}

write_report() {
    {
        cat <<EOF
# P1 provisioning smoke-test report

Generated: $(date --iso-8601=seconds)
Target user: \`$target_user\`
Display: \`$display\`

This is the human-review entry point.  Raw supporting evidence is available in
[smoke-test.log](smoke-test.log), [summary.tsv](summary.tsv), and
[screenshots/](screenshots/).

EOF
        report_checks 'System and dotfiles' '^(apt-|slack-source|command:(acpi|amixer|cmake|curl|ffmpeg|git|htop|killall|ncdu|powertop|rg|rsync|tmux|unzip|wget)|nerd-font|ntp-|timesync-|bluetooth-|dotfiles-|link:|bash-startup|theme-)'
        report_checks 'Developer tooling' '^(command:(docker|node|npm|npx|corepack|tree-sitter|claude|codex|uv|cargo|rustc)|version:|docker-)'
        report_checks 'Desktop integration' '^(x-session|alacritty-|conky-|keyboard-|clipmenu-|xmonad-|dzen-|command:(arandr|conky|dmenu_run|feh|maim|nnn|pavucontrol|scrot|wmctrl|xclip|xdg-open|xinit|xsecurelock))'
        report_checks 'Desktop applications' '^(command:(brave-browser|firefox|gopass|libreoffice|pcmanfm|Telegram|slack|vlc|nvim)|nvim-|gopass-cli|screenshot:)'
        printf '## Visual review\n\n'
        report_screenshot desktop 'Default desktop, Dzen, and Conky'
        report_screenshot alacritty-nvim 'Alacritty + Neovim glyph fixture'
        report_screenshot firefox 'Firefox'
        report_screenshot brave 'Brave'
        report_screenshot libreoffice 'LibreOffice'
        report_screenshot pcmanfm 'PCManFM'
        report_screenshot telegram 'Telegram'
        report_screenshot slack 'Slack'
        report_screenshot vlc 'VLC'
        report_screenshot arandr 'ARandR'
        printf '## Manual checks\n\n'
        sed '1,4d' "$checklist"
    } >"$report"
    chown "$target_user:$target_user" "$report"
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
    local commands=(brave-browser firefox gopass libreoffice pcmanfm Telegram slack nvim)
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
        capture_visuals
    else
        skip screenshots 'disabled with --no-screenshots'
    fi
}

check_apt
check_base
check_dotfiles
check_developer
check_desktop_apps
check_x_session
write_report

printf '\nSummary: %d passed, %d failed, %d skipped\nArtifacts: %s\nReport: %s\n' \
    "$passes" "$failures" "$skips" "$artifacts" "$report" | tee -a "$log"
((failures == 0))
