#!/usr/bin/env bash
# Install the small bootstrap dependency set and run P1 locally.
set -Eeuo pipefail

usage() {
    cat <<'EOF'
Usage: sudo provisioning/p1/bootstrap.sh --user USER [--dotfiles-dir PATH]

Run from a checked-out dotfiles repository on Debian 13 (trixie).
EOF
}

target_user=""
dotfiles_dir=""

while (($#)); do
    case "$1" in
        --user)
            target_user="${2:?missing value for --user}"
            shift 2
            ;;
        --dotfiles-dir)
            dotfiles_dir="${2:?missing value for --dotfiles-dir}"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'Unknown option: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

[[ $EUID -eq 0 ]] || { echo 'Run this script with sudo.' >&2; exit 1; }
[[ -n $target_user ]] || { echo '--user is required.' >&2; exit 2; }
id "$target_user" >/dev/null
target_home=$(getent passwd "$target_user" | cut -d: -f6)
[[ -n $target_home && -d $target_home ]] || {
    printf 'Could not determine a usable home directory for %s.\n' "$target_user" >&2
    exit 1
}

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
dotfiles_dir="${dotfiles_dir:-$(cd -- "$script_dir/../.." && pwd)}"
[[ -f $dotfiles_dir/.git/config ]] || {
    printf 'Not a Git checkout: %s\n' "$dotfiles_dir" >&2
    exit 1
}

# P1 manages this checkout as the principal user.  This also makes a bootstrap
# launched from a root console safe: relocate the already-verified checkout
# rather than leaving the user unable to read or update /root/dotfiles.
target_dotfiles_dir="$target_home/hub/dotfiles"
if [[ $dotfiles_dir != "$target_dotfiles_dir" ]]; then
    if [[ -e $target_dotfiles_dir ]]; then
        printf 'Target checkout already exists: %s\n' "$target_dotfiles_dir" >&2
        printf 'Rerun with --dotfiles-dir %s after reviewing it.\n' "$target_dotfiles_dir" >&2
        exit 1
    fi
    install -d -o "$target_user" -g "$target_user" -m 0755 "$target_home/hub"
    mv "$dotfiles_dir" "$target_dotfiles_dir"
    dotfiles_dir="$target_dotfiles_dir"
fi
chown -R "$target_user:$target_user" "$dotfiles_dir"
script_dir="$dotfiles_dir/provisioning/p1"
[[ -x $script_dir/bootstrap.sh ]] || {
    printf 'Missing bootstrap script after checkout normalisation: %s\n' "$script_dir" >&2
    exit 1
}

. /etc/os-release
[[ ${ID:-} == debian && ${VERSION_CODENAME:-} == trixie ]] || {
    printf 'P1 currently supports Debian 13 (trixie), not %s %s.\n' \
        "${ID:-unknown}" "${VERSION_CODENAME:-unknown}" >&2
    exit 1
}

export DEBIAN_FRONTEND=noninteractive

# A freshly installed full-DVD system may have only a cdrom/file APT source.
# Replace it before the first update; otherwise neither Ansible nor time sync
# can be installed without the installation medium.
rm -f /etc/apt/sources.list /etc/apt/sources.list.d/debian.sources
install -d -m 0755 /etc/apt/sources.list.d
cat >/etc/apt/sources.list.d/debian.sources <<'EOF'
Types: deb
URIs: https://deb.debian.org/debian
Suites: trixie trixie-updates
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: https://security.debian.org/debian-security
Suites: trixie-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF

# If the installer could not set the clock, normal APT rejects repository
# metadata as "not valid yet".  This one bootstrap pass retains Release-file
# signature verification but temporarily skips only timestamp-window checks,
# allowing us to install the clock synchroniser.  Date validation resumes
# before the playbook begins.
apt-get -o Acquire::Check-Date=false update
apt-get -o Acquire::Check-Date=false install --yes --no-install-recommends \
    ansible ca-certificates git systemd-timesyncd

systemctl enable --now systemd-timesyncd.service
for _ in $(seq 1 24); do
    [[ $(timedatectl show --property=NTPSynchronized --value) == yes ]] && break
    sleep 5
done
[[ $(timedatectl show --property=NTPSynchronized --value) == yes ]] || {
    echo 'Clock did not synchronise; check network connectivity before rerunning P1.' >&2
    exit 1
}

apt-get update

exec ansible-playbook \
    -i "$script_dir/inventory/localhost.ini" \
    "$script_dir/site.yml" \
    -e "target_user=$target_user" \
    -e "dotfiles_repo=$dotfiles_dir"
