#!/bin/bash

selected_boot=$(cat selected_boot)
selected_disk=$(cat selected_disk) 
selected_home=$(cat selected_home)
hostname=E11
username=koompi
password=123

echo "$selected_home    /home    ext4    rw,relatime    0 1" >> /etc/fstab
mount -a

id_system() {
	
    # Apple System Detection
    if [[ "$(cat /sys/class/dmi/id/sys_vendor)" == 'Apple Inc.' ]] || [[ "$(cat /sys/class/dmi/id/sys_vendor)" == 'Apple Computer, Inc.' ]]; then
    	modprobe -r -q efivars || true  # if MAC
    else
    	modprobe -q efivarfs            # all others
    fi
    
    # BIOS or UEFI Detection
    if [[ -d "/sys/firmware/efi/" ]]; 
	then
      # Mount efivarfs if it is not already mounted
    	if [[ -z $(mount | grep /sys/firmware/efi/efivars) ]]; 
		then
    		mount -t efivarfs efivarfs /sys/firmware/efi/efivars
    	fi

    	SYSTEM="UEFI"
		
	else
    	SYSTEM="BIOS"
    fi
         
	echo $SYSTEM

}

timedatectl set-timezone Asia/Phnom_Penh
echo LANG=en_US.UTF-8 > /etc/locale.conf
export LANG=en_US.UTF-8

echo "$hostname" > /etc/hostname
echo "127.0.0.1	localhost" >> /etc/hosts
echo "::1		localhost" >> /etc/hosts
echo "127.0.1.1	$hostname" >> /etc/hosts

system=$(id_system)

if [[ "$system" == "UEFI" ]];
then
	mkdir /boot/efi && 
	mount $selected_boot /boot/efi && 
	grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi && 
	grub-mkconfig -o /boot/grub/grub.cfg
else
	parted $selected_disk set 1 bios_grub on &&
	grub-install $selected_disk && 
	grub-mkconfig -o /boot/grub/grub.cfg
fi

check="false"

while read -r line;
do
	
	if [[ "$check" == "true" ]];
	then
		echo "$line" | sed 's/^#\(.*\)/\1/' | sed 's/^ \(.*\)/\1/' >> /etc/sudoers-new
        check="false"
    else
		echo "$line" >> /etc/sudoers-new
	fi

	if [[ "$line" == "## Uncomment to allow members of group wheel to execute any command" ]];
	then
		check="true"
	fi
	
done <<< $(cat /etc/sudoers)

rm -rf /etc/sudoers
mv /etc/sudoers-new /etc/sudoers

systemctl enable NetworkManager
systemctl enable sshd

username=$(echo $username | tr '[:upper:]' '[:lower:]')

useradd -mg users -G wheel,power,storage,network -s /bin/bash $username
echo -e "$password\n$password" | passwd $username
echo -e "$password\n$password" | passwd



systemctl disable installer.service

exit