# P1: Debian 13 workstation provisioning

P1 replaces the historical `provisioning/pucc` scripts without removing them.
It separates destructive installer choices from repeatable post-install setup.

1. Debian Installer owns disks, boot, encryption, hostname, and the first user.
2. This local Ansible playbook owns packages and dotfile links, and can be rerun.

## Storage profiles — not automated yet

| Profile | Layout |
| --- | --- |
| `mirror` | Two ESPs, RAID1 `/boot`, RAID1 data, then one LUKS2 container with a single ext4 root filesystem and swapfile (no LVM). |
| `separate` | Primary disk: ESP, `/boot`, LUKS2; second disk: independent LUKS2 data disk. |
| `custom` | Debian Installer manual partitioner. |

P1 has no partitioning command yet. Those profiles will be tested in a disposable
UEFI VM before an installer USB is built. Never use `pucc/00-bootstrap.sh` on
this machine: its hard-coded `/dev/sda` layout is unrelated to either profile.

The normal P1 run creates and enables an 8 GiB `/swapfile`. It lives within the
encrypted root filesystem; this default is for suspend, not hibernation. Override
its size with `-e p1_swapfile_size_mb=VALUE` when needed.

## First run after Debian 13 installation

Install a minimal Debian 13 system with an administrative user and network
access.  During Debian Installer:

- allow firmware detection and installation;
- configure the network; and
- network access is sufficient; the full DVD is useful offline installation
  media, but P1 replaces any DVD-only APT source with the standard Debian
  archives before its first package update.

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

Bootstrap normalises the checked-out repository to the `--user` account's
`~/hub/dotfiles`. If it was launched from a root-console checkout such as
`/root/dotfiles`, it relocates that verified checkout and fixes its ownership
before applying P1. The principal user—not root—therefore owns all dotfiles
and user-level tooling.

The bootstrapper installs Ansible from Debian and applies this playbook locally.
P1 covers the desktop, the NVIDIA driver, Docker, Node 24.2.0, uv/Python 3.12, Rust, Blender,
Brave, Chromium, Firefox, Gopass, LibreOffice, PCManFM, Telegram, and Slack.
It uses the vendors' signed APT repositories where available and versioned
upstream archives for Blender, Telegram, Fira Code Nerd Font, and Slack.

## NVIDIA driver and PRIME render offload

The `nvidia` stage is a no-op on machines without an NVIDIA display
controller. Where one is present it installs Debian's packaged
`nvidia-driver` (550.163.01 in trixie) together with `linux-headers-amd64`,
so DKMS rebuilds the module for every future kernel.

The GPU is configured for PRIME render offload rather than as the primary
display device. The Intel iGPU keeps driving every screen through the
`modesetting` driver; the discrete GPU is added as a secondary Xorg screen and
stays in RTD3 runtime suspend until something asks for it:

```sh
prime-run glxinfo | grep 'OpenGL renderer'
prime-run blender
```

CUDA and `nvidia-smi` work without the wrapper. Waking the GPU from D3cold
costs roughly a second on the first offloaded frame.

`nvidia-persistenced` is deliberately not installed: persistence mode holds
the GPU awake and defeats runtime power management. If the machine misbehaves
on resume, set `options nvidia NVreg_DynamicPowerManagement=0x00` in
`/etc/modprobe.d/p1-nvidia.conf` and rerun `update-initramfs -u -k all`.

Displays wired to the discrete GPU (on this chassis, HDMI) need a one-time
provider hookup per X session before `xrandr` will list their outputs:

```sh
xrandr --setprovideroutputsource NVIDIA-G0 modesetting
```

Re-run only this stage with:

```sh
ansible-playbook site.yml --ask-become-pass --tags nvidia
```

Changing the module options requires a reboot, because `nouveau` is
blacklisted from the initramfs at install time.

`startx` reads `~/.xinitrc`; P1 links that file to the repository's
`.xsession`, which starts XMonad.  P1 installs the packaged XMonad dependencies
and builds the pinned Stack project.  Re-run only that stage with:

```sh
ansible-playbook site.yml --ask-become-pass --tags xmonad
```

## Remote bootstrap from a newly installed host

Run this once at the new machine's local console. It makes the host reachable
for the regular P1 bootstrap; choose a port appropriate for the local network.

```sh
SSH_PORT=2222
sudo apt-get update
sudo apt-get install --yes openssh-server git ca-certificates
printf 'Port %s\n' "$SSH_PORT" | sudo tee /etc/ssh/sshd_config.d/90-p1-port.conf
sudo sshd -t
sudo systemctl enable --now ssh
sudo systemctl restart ssh
```

From an existing machine, clone and provision the new host over SSH:

```sh
HOST=host-or-ip-address
SSH_PORT=2222
TARGET_USER=maksis
ssh -p "$SSH_PORT" "$TARGET_USER@$HOST" \
  "git clone --recurse-submodules https://github.com/mx781/dotfiles \"\$HOME/hub/dotfiles\" && \
   cd \"\$HOME/hub/dotfiles\" && \
   sudo ./provisioning/p1/bootstrap.sh --user \"$TARGET_USER\""
```

If the host uses a firewall, allow the chosen TCP port before disconnecting from
its local console. The SSH bootstrap is intentionally a small one-time step;
the normal P1 playbook does not choose or replace an SSH port.

## Secondary ESP boot copy (mirrored installs only)

After the first successful UEFI boot of the `mirror` layout, run this separate
playbook once to install GRUB on the second disk's EFI System Partition. It
does not format either ESP and does not update UEFI NVRAM. Use the spare ESP's
stable UUID path, never a volatile `/dev/sdX` name:

```sh
lsblk -o PATH,FSTYPE,PARTTYPE,UUID,MOUNTPOINTS
cd "$HOME/hub/dotfiles/provisioning/p1"
sudo ansible-playbook mirror-esp.yml \
  -e p1_secondary_esp_device=/dev/disk/by-uuid/PASTE-THE-SPARE-ESP-UUID
```

The role writes both Debian's normal GRUB EFI path and the standard fallback
path, then unmounts the spare ESP. Re-run it after a GRUB package update if you
want to refresh that redundant copy.

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
