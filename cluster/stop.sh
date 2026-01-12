#!/usr/bin/bash

cd "$(dirname "$0")"

# Gracefull stop VM
virsh -c qemu:///system shutdown k8s1 &
virsh -c qemu:///system shutdown k8s2 &
virsh -c qemu:///system shutdown k8s3 &
# Force shutdown: virsh destroy k8s1
wait

# Stop net
virsh net-destroy vm_nat &
scripts/stop_infra.sh &
wait

# Final status
virsh -c qemu:///system net-list --all
virsh -c qemu:///system list --all

# Check if VM autostart on launch
# virsh -c qemu:///system dominfo k8s1 | grep Autostart
