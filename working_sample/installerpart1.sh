#!/bin/bash 

print_all_disk(){

        fdiskOUTPUT=$(fdisk -l)
        rm -rf /tmp/ReadDisk
        while read -r line;
        do

        #find out whether the line at character 5th to 10th which is being read start with /dev/
        if [[ "${line:5:10}" == /dev/* ]] ;
        then

                #filter the line by looking for commas and take the pre-line number 1 and change all spaces that output into underscore and put it into file at /tmp/ReadDisk
                var=$(echo "$line" | awk -F' ' '{printf $2}' | sed s/.$//)
                echo $var >> /tmp/ReadDisk

        fi
        done <<< "$fdiskOUTPUT" 

}

print_all_part(){

        fdiskOUTPUT=$(fdisk -l)
        rm -rf /tmp/ReadPart
        while read -r line;
        do

        #find out whether the line at character 5th to 10th which is being read start with /dev/
        if [[ "$line" == $1* ]] ;
        then
                var=$(echo "$line" | awk -F' ' '{printf $1}')
                echo $var >> /tmp/ReadPart
        fi
        done <<< "$fdiskOUTPUT" 

}

print_all_disk

unit='M'
findram=$(grep MemTotal /proc/meminfo | awk '{print $2}' | xargs -I {} echo "scale=0; {}/1024" | bc)
findram=$(echo $(( $findram+538 )))
findram="$findram$unit"

selected_disk=$(sed -n "$1{p;q}" /tmp/ReadDisk)

selected_disk=$(echo $selected_disk)
parted $selected_disk mklabel gpt --script
parted $selected_disk mkpart primary 0% 538M --script
parted $selected_disk mkpart primary 538M $findram --script
parted $selected_disk mkpart primary $findram 75% --script
parted $selected_disk mkpart primary 75% 100% --script

print_all_part $selected_disk

selected_boot=$(sed -n "1{p;q}" /tmp/ReadPart)
selected_swap=$(sed -n "2{p;q}" /tmp/ReadPart)
selected_home=$(sed -n "3{p;q}" /tmp/ReadPart)
selected_root=$(sed -n "4{p;q}" /tmp/ReadPart)


echo "$selected_boot $selected_swap $selected_home $selected_root"


echo $selected_boot >> /tmp/selected_boot
echo $selected_disk >> /tmp/selected_disk
echo $selected_home >> /tmp/selected_home

mkfs.fat -F32 $selected_boot
mkswap $selected_swap
swapon $selected_swap
mkfs.ext4 $selected_root
mkfs.ext4 $selected_home

pacman -Sy
mount $selected_root /mnt

pacstrap /mnt base base-devel linux linux-firmware vim nano man-db man-pages \
networkmanager dhclient libnewt bash-completion grub efibootmgr parted openssh wget;
genfstab -U /mnt >> /mnt/etc/fstab
cp installerpart2.sh /mnt
cp /tmp/selected_disk /mnt
cp /tmp/selected_boot /mnt
cp /tmp/selected_home /mnt


arch-chroot /mnt ./installerpart2.sh
arch-chroot /mnt rm -rf selected_disk selected_boot installerpart2.sh

shutdown now