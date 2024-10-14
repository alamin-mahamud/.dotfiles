#!/bin/bash

# Exit on error
set -e

# Set up variables
HOSTNAME="archlinux"
USERNAME="user"
PASSWORD="password"
DISK="/dev/sda"

# Update system clock
timedatectl set-ntp true

# Calculate the total disk size
# generate three partition
# 1. EFI System Partition Minimum 1GB
# 2. Swap Partition Minimum the double of RAM
# 3. Root Partition Remaining amount
# Get the total size of the disk in MiB
DISK_SIZE=$(parted $DISK unit MiB print | grep "Disk $DISK" | awk '{print $3}' | sed 's/MiB//')

# Calculate the size of the swap partition (double the RAM size, assuming 2GiB RAM for this example)
SWAP_SIZE=$((2 * 2048))

# Calculate the size of the root partition
ROOT_SIZE=$((DISK_SIZE - 512 - SWAP_SIZE))

# Partition the disk
parted -s $DISK mklabel gpt
parted -s $DISK mkpart primary fat32 1MiB 512MiB
parted -s $DISK set 1 esp on
parted -s $DISK mkpart primary linux-swap 512MiB 4.5GiB
parted -s $DISK mkpart primary ext4 4.5GiB 100%

# Format the partitions
mkfs.fat -F32 ${DISK}1
mkswap ${DISK}2
mkfs.ext4 ${DISK}3

# Mount the file systems
mount ${DISK}3 /mnt
mkdir /mnt/boot
mount ${DISK}1 /mnt/boot
swapon ${DISK}2

# Install essential packages
pacstrap /mnt base linux linux-firmware

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot into the new system
arch-chroot /mnt /bin/bash <<EOF

# Set the time zone
ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
hwclock --systohc

# Localization
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Network configuration
echo $HOSTNAME > /etc/hostname
cat <<EOT > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOT

# Set root password
echo "root:$PASSWORD" | chpasswd

# Create a new user
useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd

# Allow wheel group to use sudo
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

# Install and configure bootloader
pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Enable necessary services
systemctl enable NetworkManager

EOF

# Unmount and reboot
umount -R /mnt
swapoff -a
echo "Installation complete. Rebooting in 5 seconds..."
sleep 5
reboot
