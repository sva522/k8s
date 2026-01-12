#!/usr/bin/bash

clean_input_dir=true
[ -v 1 ] && clean_input_dir=false # --keep

cd "$(dirname "$0")"
readonly input_dir="${PWD}/input"

tofu apply -destroy -auto-approve

scripts/stop_infra.sh &

# Clean libvirt current state
ls /etc/libvirt/qemu/k8s*.xml         2>/dev/null
ls /var/lib/libvirt/images/k8s*.qcow2 2>/dev/null
ls /var/lib/libvirt/images/k8s*.iso   2>/dev/null
#sudo rm -f /etc/libvirt/qemu/k8s*.xml
#sudo rm -f /var/lib/libvirt/images/k8s*.qcow2
#sudo rm -f /var/lib/libvirt/images/k8s*.iso

rm -rf terraform*
rm -rf .terraform*

virsh -c qemu:///system destroy k8s1
virsh -c qemu:///system destroy k8s2
virsh -c qemu:///system destroy k8s3
virsh -c qemu:///system undefine k8s1 --remove-all-storage
virsh -c qemu:///system undefine k8s2 --remove-all-storage
virsh -c qemu:///system undefine k8s3 --remove-all-storage
#virsh -c qemu:///system net-destroy default
#virsh -c qemu:///system net-undefine default
virsh -c qemu:///system net-destroy vm_nat
virsh -c qemu:///system net-undefine vm_nat

if $clean_input_dir; then
    rm -rf "$input_dir"
fi
wait
virsh -c qemu:///system net-list --all
virsh -c qemu:///system list --all
