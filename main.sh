#!/bin/bash

print_all_disk(){

    
    InternalDiskOnly=$(lsblk -J -o NAME,RM,SIZE | jq '
    .blockdevices[] | 
        if .rm == false then 
            { name, children: [ .children[] | {name: .name, size: .size} ] } 
        else 
            empty 
        end
    ' -r);
    echo -e $InternalDiskOnly

}

prepare() {
    echo "Preparing Installation"
    print_all_disk
}



main() {
    prepare
}

main;