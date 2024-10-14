## TODO

- Start i3 when arch login

## OS Installation

### Arch Linux Installation

This script automates the installation of Arch Linux on a system. It partitions the disk, installs essential packages, configures the system, and sets up a new user.

#### Prerequisites

- A fresh Arch Linux system
- Internet connection
- The script assumes the disk to be `/dev/sda` and the RAM size to be `2GiB`. Adjust these values as needed.

#### Script Overview

The script performs the following steps:

- Set up variables: Define hostname, username, password, and disk.
- Update system clock: Ensure the system clock is accurate.
- Partition the disk: Create EFI, swap, and root partitions.
- Format the partitions: Format the created partitions.
- Mount the file systems: Mount the partitions.
- Install essential packages: Install base system packages.
- Generate fstab: Generate the file system table.
- Chroot into the new system: Configure the new system.
- Set up the system: Configure timezone, localization, network, and users.
- Install and configure bootloader: Install GRUB bootloader.
- Enable necessary services: Enable essential services.
- Reboot the system: Unmount partitions and reboot.

#### Script

```bash
#!/bin/bash

# Exit on error
set -e

# Set up variables
HOSTNAME="archlinux"
USERNAME="user"
PASSWORD="password"
DISK="/dev/sda"
RAM_SIZE=$(free -m | awk '/^Mem:/{print $2}') # Get RAM size in MiB

# Update system clock
timedatectl set-ntp true

# Calculate the total disk size in MiB
DISK_SIZE=$(parted $DISK unit MiB print | grep "Disk $DISK" | awk '{print $3}' | sed 's/MiB//')

# Calculate partition sizes
EFI_SIZE=$((DISK_SIZE / 100)) # 1% of DISK_SIZE
[ $EFI_SIZE -lt 1024 ] && EFI_SIZE=1024 # Minimum 1GB

SWAP_SIZE=$((RAM_SIZE <= 4096 ? RAM_SIZE : 4096)) # Minimum 4GB or RAM_SIZE
[ $SWAP_SIZE -lt $EFI_SIZE ] && SWAP_SIZE=$EFI_SIZE # Ensure SWAP_SIZE is at least 1% of DISK_SIZE

ROOT_SIZE=$((DISK_SIZE - EFI_SIZE - SWAP_SIZE)) # Remaining amount

# Check if the system is booted in UEFI mode
if [ -d /sys/firmware/efi ]; then
    echo "UEFI mode detected. Partitioning for UEFI."

    # Partition the disk for UEFI
    parted -s $DISK mklabel gpt
    parted -s $DISK mkpart primary fat32 1MiB ${EFI_SIZE}MiB
    parted -s $DISK set 1 esp on
    parted -s $DISK mkpart primary linux-swap ${EFI_SIZE}MiB $((${EFI_SIZE} + ${SWAP_SIZE}))MiB
    parted -s $DISK mkpart primary ext4 $((${EFI_SIZE} + ${SWAP_SIZE}))MiB 100%

    # Format the partitions
    mkfs.fat -F32 ${DISK}1
    mkswap ${DISK}2
    mkfs.ext4 ${DISK}3

    # Mount the file systems
    mount ${DISK}3 /mnt
    mkdir /mnt/boot
    mount ${DISK}1 /mnt/boot
    swapon ${DISK}2

else
    echo "BIOS mode detected. Partitioning for BIOS."

    # Partition the disk for BIOS
    parted -s $DISK mklabel msdos
    parted -s $DISK mkpart primary ext4 1MiB 100%
    parted -s $DISK set 1 boot on

    # Format the partitions
    mkfs.ext4 ${DISK}1

    # Mount the file systems
    mount ${DISK}1 /mnt
fi

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
if [ -d /sys/firmware/efi ]; then
    pacman -S --noconfirm grub efibootmgr
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
else
    pacman -S --noconfirm grub
    grub-install --target=i386-pc $DISK
fi
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
```

#### Usage

- Save the script to a file, e.g., `arch_os_install.sh`.
- Make the script executable: `chmod +x ./arch_os_install.sh`.

#### Run the script:

```bash
./arch_os_install.sh
```

Notes
Adjust the HOSTNAME, USERNAME, PASSWORD, and DISK variables as needed.
Ensure the Region/City in the timezone configuration is set correctly for your location.
The script assumes a RAM size of 2GiB for the swap partition calculation. Adjust this value if your system has a different amount of RAM.

## Dotfile Installation

### Linux

Constants

- DOTFILE_LOCATION

```
sudo apt update
sudo apt upgrade
sudo apt install -y curl git
```

clone `.dotfiles` in $DOTFILE_LOCATION

## Python Workflow:

Here’s how you can use this setup with best practices in mind:

### Install & Manage Python Versions with `pyenv`:

Use `pyenv` to install & manage the desired Python version for your project.

```bash
pyenv install 3.11.0
pyenv global 3.11.0

# setting a python version for only a specific project
pyenv local 3.11.0
```

### Project dependencies with `pipenv`:

Navigate to your project directory and start using `pipenv` to manage dependencies and virtual environments.

```bash
# This will use the version of Python managed by pyenv and
# create a virtual environment specific to your project.
pipenv install --python $(pyenv which python)

# install a package for that specific venv
pipenv install requests

# Activate venv by running
pipenv shell

# lock the exact versions of all installed packages
pipenv lock
```

### Install & manage global python tools with pipx

```bash
# install tools
pipx install black
pipx install httpie

# list all tools installed by pipx
pipx list

# Once installed with pipx, you can use the tools as if they were installed globally
black myfile.py
http httpbin.org/get

# upgrade / uninstall tools
pipx upgrade black
pipx uninstall httpie
```
