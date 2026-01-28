#!/usr/bin/bash

name="$(date +%Y-%m-%d_%H-%M-%S)"
if [ -v 1 ]; then
    name="$1"
fi

create_snapshot(){
    vm_name="$1"
    snapshot_name="$2"
    virsh -c qemu:///system snapshot-create-as --domain "$vm_name" --name "$snapshot_name" # --description 'Before update'
}

create_snapshot k8s1 "$name" --live &
create_snapshot k8s2 "$name" --live &
create_snapshot k8s3 "$name" --live &
wait
