# Pucc: Debian 12 workstation provisioning

Pucc uses the same post-install model as P1:

1. Debian Installer owns disks, boot, encryption, hostname, and the first user.
2. This local Ansible playbook owns packages and dotfile links, and can be rerun.

The old Pucc scripts formatted hard-coded `/dev/sda` partitions, entered a
chroot, and split the rest of setup across root and user shells. They have been
replaced by one bootstrap entry point and a rerunnable playbook. Use Debian
Installer's manual partitioner if you want to reproduce Pucc's former layout of
an EFI System Partition plus one encrypted root partition; this repository no
longer guesses or formats a disk.

Pucc selects the reusable roles in `../roles`, so package versions and dotfile
setup do not drift between the two machines. It also enables the NVIDIA role
for its RTX 2000 and PRIME render offload. Its profile omits only P1's
mirrored-storage role.

## First run after Debian 12 installation

Install a minimal Debian 12 (bookworm) system with an administrative user and
working network access, then clone this repository:

Provisioning configures `bookworm`, `bookworm-updates`, and
`bookworm-backports`, with `main contrib non-free non-free-firmware`, plus the
separate `bookworm-security` archive.

```sh
git clone --recurse-submodules https://github.com/mx781/dotfiles "$HOME/hub/dotfiles"
cd "$HOME/hub/dotfiles"
sudo provisioning/bootstrap.sh --profile pucc --user "$USER"
```

The bootstrapper normalises the checkout to the selected user's
`~/hub/dotfiles`, installs Ansible from Debian, synchronises the clock, and
applies `site.yml` locally. It is also safe to launch from a root-console
checkout: after validating the checkout it moves it into the principal user's
home and fixes ownership before provisioning.

The playbook installs the shared base desktop, Bluetooth support, NVIDIA driver
and PRIME wrapper, development tools, dotfiles, XMonad, desktop applications,
and personal identity setup. It applies the orange theme and Rust wallpaper. It
also creates an 8 GiB swapfile by default, encrypted at rest when Debian
Installer placed the root filesystem in LUKS. Override its size at playbook invocation with
`-e workstation_swapfile_size_mb=VALUE` when needed.

Verify render offload after rebooting into the installed driver:

```sh
prime-run glxinfo | grep 'OpenGL renderer'
nvidia-smi
```

## Re-run selected stages

Run Ansible from the provisioning directory so it loads the localhost inventory
and role library:

```sh
cd "$HOME/hub/dotfiles/provisioning"
ansible-playbook site.yml --ask-become-pass -e workstation_profile=pucc --tags base
ansible-playbook site.yml --ask-become-pass -e workstation_profile=pucc --tags dotfiles
ansible-playbook site.yml --ask-become-pass -e workstation_profile=pucc --tags apps
```

Override the target only when restoring a checkout for a different account:

```sh
ansible-playbook site.yml --ask-become-pass \
  -e workstation_profile=pucc \
  -e target_user=maksis -e dotfiles_repo=/home/maksis/hub/dotfiles
```

The `personal` stage creates an ED25519 SSH key only if one is absent and sets
the historical Git identity. Authorising that key, generating a GPG key, and
cloning private repositories remain manual follow-up steps.
