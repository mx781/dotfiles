# P1: Debian 13 workstation provisioning

P1 replaces the historical `provisioning/pucc` scripts without removing them.
It separates destructive installer choices from repeatable post-install setup.

1. Debian Installer owns disks, boot, encryption, hostname, and the first user.
2. This local Ansible playbook owns packages and dotfile links, and can be rerun.

## Storage profiles — not automated yet

| Profile | Layout |
| --- | --- |
| `mirror` | Two ESPs, RAID1 `/boot`, RAID1 data, then one LUKS2 container and LVM. |
| `separate` | Primary disk: ESP, `/boot`, LUKS2; second disk: independent LUKS2 data disk. |
| `custom` | Debian Installer manual partitioner. |

P1 has no partitioning command yet. Those profiles will be tested in a disposable
UEFI VM before an installer USB is built. Never use `pucc/00-bootstrap.sh` on
this machine: its hard-coded `/dev/sda` layout is unrelated to either profile.

## First run after Debian 13 installation

Install a minimal Debian 13 system with an administrative user and network
access.  During Debian Installer:

- allow firmware detection and installation;
- configure the network; and
- answer **Yes** to **Use a network mirror** when it is offered.  The full DVD
  is useful offline installation media, but P1 will replace any DVD-only APT
  source with the standard Debian archives.

P1 enables network time synchronisation, waits for NTP, writes the signed
`trixie`, `trixie-updates`, and `trixie-security` archive configuration (with
`main contrib non-free non-free-firmware`), then runs its APT work.  The
installer only needs working network connectivity.

Then clone this repository:

```sh
git clone --recurse-submodules https://github.com/mx781/dotfiles "$HOME/hub/dotfiles"
cd "$HOME/hub/dotfiles"
sudo provisioning/p1/bootstrap.sh --user "$USER"
```

The bootstrapper installs Ansible from Debian and applies this playbook locally.
P1 covers the desktop, Docker, Node 24.2.0, uv/Python 3.12, Rust, Brave,
Firefox, Gopass, LibreOffice, PCManFM, Telegram, and Slack. It uses the vendors'
signed APT repositories where available and versioned upstream archives for
Telegram, Fira Code Nerd Font, and Slack.

`startx` reads `~/.xinitrc`; P1 links that file to the repository's
`.xsession`, which starts XMonad.  P1 installs the packaged XMonad dependencies
and builds the pinned Stack project.  Re-run only that stage with:

```sh
ansible-playbook site.yml --ask-become-pass --tags xmonad
```

## Smoke test

After provisioning and starting X, run the target-side validation script:

```sh
sudo provisioning/p1/smoke-test.sh --user "$USER"
```

It stages command logs, a PASS/FAIL summary, and visual PNG fixtures in
`~/p1-smoke-artifacts/<timestamp>/`; the human-review entry point is
`report.md`. Screenshots are enabled by default; use `--no-screenshots` if the
current desktop contains sensitive content. When testing remotely, copy the
complete artifact directory back to the host before reviewing the report.

## Re-run selected stages

```sh
cd "$HOME/hub/dotfiles/provisioning/p1"
ansible-playbook site.yml --ask-become-pass --tags base
ansible-playbook site.yml --ask-become-pass --tags dotfiles
ansible-playbook site.yml --ask-become-pass --tags xmonad
```

Override the target only for an account/repository restoration:

```sh
ansible-playbook site.yml --ask-become-pass \
  -e target_user=maksis -e dotfiles_repo=/home/maksis/hub/dotfiles
```

## One-time identity setup

The `personal` stage creates an ED25519 SSH key only when one is absent and sets
the historical Git identity. Add the resulting public key to GitHub before cloning
the private knowledge repository. GPG key creation remains intentionally manual:
the passphrase and any identity choices must never be placed in the playbook.
