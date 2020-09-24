#!/bin/bash

work_dir=$(pwd)

get_ram() {
    # Get RAM size                                                    B     K      M      G
    echo "RAM: $(lsmem -nb -o SIZE -J | jq '[ .memory[].size ] '| jq 'add / 1024 / 1024 / 1024')"
}

get_disk(){
    # install dependencies
    pacman -Sy && pacman -U "${work_dir}"/dep_pkgs/*
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
    for((i=0;i<4;i++)) {
        [[ $i -eq 0 ]] && echo -e "/dev/$diskName => 512M" && parted /dev/$diskName mkpart primary 0% 512M --script;
        [[ $i -eq 1 ]] && echo -e "/dev/$diskName => 30%" && parted /dev/$diskName mkpart primary 512M 30% --script;
        [[ $i -eq 2 ]] && echo -e "/dev/$diskName => 93%" && parted /dev/$diskName mkpart primary 30% 93% --script;
        [[ $i -eq 3 ]] && echo -e "/dev/$diskName => 100%" && parted /dev/$diskName mkpart primary 93% 100% --script;
    }

    partitionList=($(echo $InternalDiskOnly | jq '.children[].name' -r));
    partitionCount=$(echo $InternalDiskOnly | jq '.children | length');

    echo -e "New Partitions information:"
    parted -l;

}


prepare() {
    get_disk
    get_ram
}


main() {
    prepare
}

main;
