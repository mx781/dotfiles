# Local workstation provisioning

This directory is an Ansible role library applied to localhost through one of
two profiles:

| Profile | Debian | Theme | Storage role | NVIDIA PRIME role |
| --- | --- | --- | --- | --- |
| `p1` | 13 (`trixie`) | teal | enabled | enabled |
| `pucc` | 12 (`bookworm`) | orange | disabled | enabled (RTX 2000) |

Debian Installer owns disks, boot, encryption, hostname, and the first user.
The provisioning library owns repeatable post-install configuration.
Bootstrap configures APT for the Debian codename reported by the installed
system; the playbook then refuses to apply a profile whose expected release does
not match. A future Pucc release bump therefore lives primarily in
`profiles/pucc.yml`, rather than being baked into shared roles.

## Bootstrap a fresh installation

```sh
sudo provisioning/bootstrap.sh --profile p1 --user "$USER"
sudo provisioning/bootstrap.sh --profile pucc --user "$USER"
```

Optionally restrict the first run to selected role tags:

```sh
sudo provisioning/bootstrap.sh --profile pucc --user "$USER" \
  --tags base,nvidia,drivers
```

## Rerun Ansible directly

Run commands from this directory so `ansible.cfg` resolves the localhost
inventory and role library:

```sh
cd "$HOME/hub/dotfiles/provisioning"
ansible-playbook site.yml --ask-become-pass \
  -e workstation_profile=pucc --tags base,nvidia
```

The profile is always required. Tags choose stages within that profile; they do
not change its OS or hardware capability flags. Profile variables live in
`profiles/`, and reusable implementation lives in `roles/`.

Bootstrap installs Ansible for both profiles. The `developer` role installs
AWS CLI from Debian's `awscli` package. To install only AWS CLI on Pucc, run
from this directory:

```sh
ansible-playbook site.yml --ask-become-pass \
  -e workstation_profile=pucc --tags aws-cli
```

The dotfiles role preserves an existing `~/.screenlayout` directory. It links
repository layouts only when the destination filename is absent, so local
machine-specific layouts and same-name overrides are not replaced.

The `backlight` role installs a profile-specific udev permission rule, adds the
target user to `video`, and verifies write access. After its first run, log out
and back in so the XMonad session inherits the new group membership.

P1's mirrored-ESP helper and graphical smoke test remain under `p1/` because
they are machine-specific rather than reusable provisioning roles.
