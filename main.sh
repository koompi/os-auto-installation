#!/bin/bash

get_ram() {
    # Get RAM size                                              B     K      M      G
    echo "RAM: $(lsmem -nb -o SIZE -J | jq '[ .memory[].size ] '| jq 'add / 1024 / 1024 / 1024')"
}

get_disk(){

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
    partitionList=($(echo $InternalDiskOnly | jq '.children[].name' -r));
    partitionCount=$(echo $InternalDiskOnly | jq '.children | length');
     
    # Iterate over disks
    echo "DISK: ${diskName}"
    for((i=0;i<$partitionCount;i++)) {
        echo "/dev/${partitionList[$i]}"
    }

}


prepare() {
    get_disk
    get_ram
}


main() {
    prepare
}

main;