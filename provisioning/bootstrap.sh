#!/usr/bin/env bash
# Install bootstrap dependencies and apply one local workstation profile.
set -Eeuo pipefail

usage() {
    cat <<'EOF'
Usage: sudo provisioning/bootstrap.sh --profile p1|pucc --user USER \
       [--dotfiles-dir PATH] [--tags TAG1,TAG2]

Profiles: p1, pucc
EOF
}

workstation_profile=""
target_user=""
dotfiles_dir=""
requested_tags=""

while (($#)); do
    case "$1" in
        --profile)
            workstation_profile="${2:?missing value for --profile}"
            shift 2
            ;;
        --user)
            target_user="${2:?missing value for --user}"
            shift 2
            ;;
        --dotfiles-dir)
            dotfiles_dir="${2:?missing value for --dotfiles-dir}"
            shift 2
            ;;
        --tags)
            requested_tags="${2:?missing value for --tags}"
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

case "$workstation_profile" in
    p1|pucc) ;;
    *)
        echo '--profile must be p1 or pucc.' >&2
        exit 2
        ;;
esac

id "$target_user" >/dev/null
target_home=$(getent passwd "$target_user" | cut -d: -f6)
[[ -n $target_home && -d $target_home ]] || {
    printf 'Could not determine a usable home directory for %s.\n' "$target_user" >&2
    exit 1
}

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
dotfiles_dir="${dotfiles_dir:-$(cd -- "$script_dir/.." && pwd)}"
[[ -f $dotfiles_dir/.git/config ]] || {
    printf 'Not a Git checkout: %s\n' "$dotfiles_dir" >&2
    exit 1
}

# The selected workstation profile manages this checkout as the principal user.
# A bootstrap launched from a root console relocates the verified checkout
# rather than leaving the principal user unable to update /root/dotfiles.
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
script_dir="$dotfiles_dir/provisioning"
[[ -x $script_dir/bootstrap.sh ]] || {
    printf 'Missing bootstrap script after checkout normalisation: %s\n' "$script_dir" >&2
    exit 1
}

. /etc/os-release
[[ ${ID:-} == debian && -n ${VERSION_CODENAME:-} ]] || {
    printf 'Bootstrap requires Debian with a release codename, not %s %s.\n' \
        "${ID:-unknown}" "${VERSION_CODENAME:-unknown}" >&2
    exit 1
}
debian_release=$VERSION_CODENAME
debian_suites="${debian_release} ${debian_release}-updates"
if [[ $workstation_profile == pucc ]]; then
    debian_suites+=" ${debian_release}-backports"
fi

export DEBIAN_FRONTEND=noninteractive

# A full-DVD install may have only a cdrom/file source. Replace it before the
# first update so Ansible and time synchronisation can be installed online.
rm -f /etc/apt/sources.list /etc/apt/sources.list.d/debian.sources
install -d -m 0755 /etc/apt/sources.list.d
cat >/etc/apt/sources.list.d/debian.sources <<EOF
Types: deb
URIs: https://deb.debian.org/debian
Suites: ${debian_suites}
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: https://security.debian.org/debian-security
Suites: ${debian_release}-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF

# Permit this first update with an incorrect installer clock, install the clock
# synchroniser, then restore normal APT date validation before Ansible runs.
apt-get -o Acquire::Check-Date=false update
apt-get -o Acquire::Check-Date=false install --yes --no-install-recommends \
    ansible ca-certificates git systemd-timesyncd

systemctl enable --now systemd-timesyncd.service
for _ in $(seq 1 24); do
    [[ $(timedatectl show --property=NTPSynchronized --value) == yes ]] && break
    sleep 5
done
[[ $(timedatectl show --property=NTPSynchronized --value) == yes ]] || {
    echo 'Clock did not synchronise; check network connectivity before rerunning.' >&2
    exit 1
}

apt-get update

playbook_args=(
    -i inventory/localhost.ini
    site.yml
    -e "workstation_profile=$workstation_profile"
    -e "target_user=$target_user"
    -e "dotfiles_repo=$dotfiles_dir"
)
if [[ -n $requested_tags ]]; then
    playbook_args+=(--tags "$requested_tags")
fi

cd "$script_dir"
exec ansible-playbook "${playbook_args[@]}"
