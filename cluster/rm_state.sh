#!/usr/bin/bash

if [ ! -v 1 ]; then
    echo 'Missing snapthot name' && exit 1
fi

# sudo chown root:libvirt /var/lib/libvirt/qemu/save/
# sudo chmod 770 /var/lib/libvirt/qemu/save/

rm_snapshot(){
    vm_name="$1"
    snapshot_name="$2"
    virsh snapshot-delete "$vm_name" "$snapshot_name" --metadata
    rm /var/lib/libvirt/qemu/save/"$vm_name"_"$snapshot_name".mem
}

rm_snapshot k8s1 "$1"
rm_snapshot k8s2 "$1"
rm_snapshot k8s3 "$1"
