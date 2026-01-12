#!/usr/bin/bash

name="$(date +%Y-%m-%d_%H-%M-%S)"
if [ -v 1 ]; then
    name="$1"
fi

create_snapshot(){
    vm_name="$1"
    snapshot_name="$2"
    virsh -c qemu:///system snapshot-create-as "$vm_name" "$snapshot_name" \
    --live --atomic \
    --memspec file="/var/lib/libvirt/qemu/save/${vm_name}_${snapshot_name}.mem" \
    --diskspec vda,file="/var/lib/libvirt/images/${vm_name}_${snapshot_name}.qcow2",snapshot=external \
    --diskspec hdd,snapshot=no
}

create_snapshot k8s1 "$name" --live &
create_snapshot k8s2 "$name" --live &
create_snapshot k8s3 "$name" --live &
wait
