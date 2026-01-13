#!/usr/bin/bash

cd "$(dirname "$0")"

# Gracefull stop VM
virsh -c qemu:///system shutdown k8s1 &
virsh -c qemu:///system shutdown k8s2 &
virsh -c qemu:///system shutdown k8s3 &
# Force shutdown: virsh destroy k8s1
wait

# Stop net
virsh -c qemu:///system net-destroy vm_nat &
scripts/stop_infra.sh &
wait

# Final status
./status.sh

# Check if VM autostart on launch
# virsh -c qemu:///system dominfo k8s1 | grep Autostart
