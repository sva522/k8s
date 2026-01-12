#!/usr/bin/bash

cd "$(dirname "$0")"

virsh -c qemu:///system managedsave k8s1 &
virsh -c qemu:///system managedsave k8s2 &
virsh -c qemu:///system managedsave k8s3 &
wait
scripts/stop_infra.sh

virsh -c qemu:///system net-list --all
virsh -c qemu:///system list --all
