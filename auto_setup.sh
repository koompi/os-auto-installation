#!/bin/bash

work_dir=$(pwd)

get_ram() {
    # Get RAM size                                                    B     K      M      G
    echo "RAM: $(lsmem -nb -o SIZE -J | jq '[ .memory[].size ] '| jq 'add / 1024 / 1024 / 1024')"
}

get_disk(){
    # Variables
    local boot_part root_part home_part  swap_part
    # install dependencies
    [[ ! -e /usr/bin/jq ]] && echo "JQ is not installed: Exited!" && exit
    # Get all install disk
    
    InternalDiskOnly=$(lsblk -J -o NAME,RM,SIZE | jq '
    .blockdevices[] | 
        if .rm == false then 
            if .children | length > 0 then
                { name, children: [ .children[] | {name: .name, size: .size} ] } 
            else
                empty
            end
        else 
            empty 
        end
    ');


    diskName=$(echo $InternalDiskOnly | jq '.name' -r);
     
    # Iterate over disks
    echo "Creating GPT partition table on: ${diskName}"
    parted /dev/$diskName mklabel gpt --script
    for((i=1;i<5;i++)) {

        [[ $i -eq 1 ]] &&
            echo -e "/dev/$diskName => 512M" &&
            parted /dev/$diskName mkpart "EFI" fat32 0% 512M --script &&
            parted /dev/$diskName set 1 esp on;

        [[ $i -eq 2 ]] &&
		echo -e "/dev/$diskName => 30%" &&
		parted /dev/$diskName mkpart "ROOT" ext4 512M 30% --script;
        
        [[ $i -eq 3 ]] && 
            echo -e "/dev/$diskName => 93%" &&
            parted /dev/$diskName mkpart "HOME" ext4 30% 93% --script;
            
        [[ $i -eq 4 ]] && 
            echo -e "/dev/$diskName => 100%" &&
            parted /dev/$diskName mkpart "SWAP" linux-swap 93% 100% --script;
    }

    partitionList=($(echo $InternalDiskOnly | jq '.children[].name' -r));
    partitionCount=$(echo $InternalDiskOnly | jq '.children | length');

    echo -e "Formatting file system for each partition..."
    for((i=0;i<${#partitionList[@]};i++)){
        [[ $i -eq 0 ]] &&
            echo -e "/dev/${partitionList[$i]}" &&
            mkfs.fat -F32 "/dev/${partitionList[$i]}" &&
            boot_part="/dev/${partitionList[$i]}";
        [[ $i -eq 1 ]] &&
            echo -e "/dev/${partitionList[$i]}" &&
            mkfs.ext4 -F "/dev/${partitionList[$i]}" &&
            root_part="/dev/${partitionList[$i]}";
        [[ $i -eq 2 ]] &&
            echo -e "/dev/${partitionList[$i]}" &&
            mkfs.ext4 -F "/dev/${partitionList[$i]}" &&
            home_part="/dev/${partitionList[$i]}";
        [[ $i -eq 3 ]] &&
            echo -e "/dev/${partitionList[$i]}" &&
            mkswap "/dev/${partitionList[$i]}" &&
            swapon "/dev/${partitionList[$i]}" &&
            swap_part="/dev/${partitionList[$i]}";
    }

    echo -e "Mounting file system..."
    echo $boot_part $root_part $home_part $swap_part
    
    # Mount root partition
    mount "${root_part}" /mnt
    # Create home directory
    mkdir -p /mnt/home
    # mount home partition
    mount "${home_part}" /mnt/home

    # Mount efi
    mkdir -p /mnt/boot/efi
    mount "${boot_part}" /mnt/boot/efi
    
    unsquashfs -f -d /mnt /run/archiso/bootmnt/arch/x86_64/airootfs.sfs

    genfstab -U -p /mnt >> /mnt/etc/fstab

    arch-chroot /mnt /usr/bin/oem_setup.sh
}


get_disk
echo -e "Unsquashing ROOT system..."

umount -a
reboot