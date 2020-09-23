#!/bin/bash

get_disk(){

    # Get all install disk
    InternalDiskOnly=$(lsblk -J -o NAME,RM,SIZE | jq '
    .blockdevices[] | 
        if .rm == false then 
            { name, children: [ .children[] | {name: .name, size: .size} ] } 
        else 
            empty 
        end
    ');

    PartitionList=($(echo $InternalDiskOnly | jq '.children[].name' -r))

    for((i=0;i<${#PartitionList[@]};i++)){
        echo "/dev/${PartitionList[$i]}"
    }
}

get_ram() {
    #                                                           B     K      M      G
    echo $(lsmem -nb -o SIZE -J | jq '[ .memory[].size ] '| jq 'add / 1024 / 1024 / 1024')
}

prepare() {
    echo "Preparing Installation"
    get_disk
    get_ram
}



main() {
    prepare
}

main;