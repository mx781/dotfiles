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

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
dotfiles_dir="${dotfiles_dir:-$(cd -- "$script_dir/../.." && pwd)}"
[[ -f $dotfiles_dir/.git/config ]] || {
    printf 'Not a Git checkout: %s\n' "$dotfiles_dir" >&2
    exit 1
}

. /etc/os-release
[[ ${ID:-} == debian && ${VERSION_CODENAME:-} == trixie ]] || {
    printf 'P1 currently supports Debian 13 (trixie), not %s %s.\n' \
        "${ID:-unknown}" "${VERSION_CODENAME:-unknown}" >&2
    exit 1
}

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install --yes --no-install-recommends ansible ca-certificates git

exec ansible-playbook \
    -i "$script_dir/inventory/localhost.ini" \
    "$script_dir/site.yml" \
    -e "target_user=$target_user" \
    -e "dotfiles_repo=$dotfiles_dir"

