#!/usr/bin/bash

cd "$(dirname "$0")"

source "../functions.sh"

if [ ! -v 1 ]; then
    echo 'Missing snapthot name' && exit 1
fi

virsh destroy k8s1 2>/dev/null
virsh destroy k8s2 2>/dev/null
virsh destroy k8s3 2>/dev/null

restore_snapshot(){
    vm_name="$1"
    snapshot_name="$2"
    virsh -c qemu:///system restore "/var/lib/libvirt/qemu/save/${vm_name}_${snapshot_name}.mem"
}
restore_snapshot k8s1 "$1" &
restore_snapshot k8s2 "$1" &
restore_snapshot k8s3 "$1" & 
wait

wait_for_ssh k8s1
wait_for_ssh k8s2
wait_for_ssh k8s3
ssh admin@k8s1 wait_for_ntp
ssh admin@k8s2 wait_for_ntp
ssh admin@k8s3 wait_for_ntp
