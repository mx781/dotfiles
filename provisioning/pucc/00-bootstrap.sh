#!/bin/bash
# Fresh system -> partitioned and formatted
#
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

if [ ! -b /dev/sda1 ] || [ ! -b /dev/sda2 ]; then
    echo "Disk partitions /dev/sda1 and /dev/sda2 do not exist." >&2
    exit 1
fi

apt install debootstrap cryptsetup cryptsetup-initramfs --no-install-recommends -y

mkfs.vfat -F32 /dev/sda1
cryptsetup luksFormat /dev/sda2
cryptsetup open /dev/sda2 cryptroot
mkfs.ext4 /dev/mapper/cryptroot

debootstrap --arch amd64 stable /mnt http://deb.debian.org/debian

cp -r $(pwd) /mnt/provisioning
mount --types proc /proc /mnt/proc
mount --rbind /sys /mnt/sys
mount --rbind /dev /mnt/dev
chroot /mnt /bin/bash
