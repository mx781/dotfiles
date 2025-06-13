#!/bin/bash
# Bare system (chrooted into /mnt) -> bootable debian
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

read -p "Enter the hostname for the system: " hostname
echo $hostname > /etc/hostname
sed -i "1i127.0.1.1 $hostname" /etc/hosts

read -p "Enter the principal user name: " username
adduser $username
usermod -aG sudo $username
passwd -l root # drop root login

# needed for firmware-iwlwifi
sed -i '/^deb / s/main.*/main contrib non-free non-free-firmware/' /etc/apt/sources.list

apt update
apt install -y linux-image-amd64 grub-efi-amd64 cryptsetup initramfs-tools systemd-sysv sudo firmware-iwlwifi network-manager locales

dpkg-reconfigure locales

echo "cryptroot UUID=$(blkid -s UUID -o value /dev/sda2) none luks,discard" > /etc/crypttab

cat <<EOF > /etc/fstab
UUID=$(blkid -s UUID -o value /dev/mapper/cryptroot) / ext4 defaults 0 1
UUID=$(blkid -s UUID -o value /dev/sda1) /boot vfat umask=0077 0 2
EOF

echo "Check /etc/fstab to ensure it is correct before proceeding:"
echo ">cat /etc/fstab"
cat /etc/fstab
read -p "Press Enter to continue or Ctrl+C to abort..."

update-initramfs -u
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=debian
update-grub
