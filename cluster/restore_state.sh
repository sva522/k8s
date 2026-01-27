#!/usr/bin/bash

cd "$(dirname "$0")"

source "../functions.sh"
source "scripts/net_conf.sh"

snapshot_name="$1"
if [ ! -v 1 ]; then
    # Use last snapshot
    snapshot_name=$(virsh -c qemu:///system snapshot-list k8s1 --name | sort -r | head -1)
    #echo 'Missing snapthot name' && exit 1
fi

./force_stop.sh 2>/dev/null

restore_snapshot(){
    vm_name="$1"
    snapshot_name="$2"
    virsh -c qemu:///system restore snapshot-revert --domain "$vm_name" --snapshotname "$snapshot_name"
}

echo "Restoring ${snapshot_name}..."
restore_snapshot k8s1 "$snapshot_name" &
restore_snapshot k8s2 "$snapshot_name" &
restore_snapshot k8s3 "$snapshot_name" & 
wait

readonly k8s1_ip=$(dig k8s1 +short "@$dns_vm_admin")
readonly k8s2_ip=$(dig k8s2 +short "@$dns_vm_admin")
readonly k8s3_ip=$(dig k8s3 +short "@$dns_vm_admin")

wait_for_ssh k8s1 "$k8s1_ip"
wait_for_ssh k8s2 "$k8s2_ip"
wait_for_ssh k8s3 "$k8s3_ip"
ssh admin@k8s1 wait_for_ntp
ssh admin@k8s2 wait_for_ntp
ssh admin@k8s3 wait_for_ntp
kubectl get nodes -o wide
