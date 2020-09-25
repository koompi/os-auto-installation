#!/bin/bash

# setup locale
sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
locale-gen

# setup timezone
ln -sf /usr/share/zoneinfo/Asia/Phnom_Penh /etc/localtime

# setup machine clock
hwclock --systoch --localtime

# setup hostname
echo "koompi_os" > /etc/hostname

# enable wheel group
sed -i 's/^#\s*\(%wheel\s\+ALL=(ALL)\s\+ALL\)/\1/' /etc/sudoers
sed -i 's/^#\s*\(%sudo\s\+ALL=(ALL)\s\+ALL\)/\1/' /etc/sudoers

# create live user
useradd -mg users -G wheel,power,storage,input -s /bin/bash --password 123 OEM

# clean up initcpio config
rm -rf /etc/mkinitcpio*

# install packages
yes | pacman -U /packages/* ;
yes | pacman -Rdd openbox obconf-qt noto-fonts;

# systemd services
systemctl set-default graphical.target
systemctl enable NetworkManager sddm org.cups.cupsd.socket

# prepare boot partition

# regenerate initramfs image
mkinitcpio -p linux

# install bootloader
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=KOOMPI-OS --recheck
grub-mkconfig -o /boot/grub/grub.cfg

rm -rf /packages
exit
