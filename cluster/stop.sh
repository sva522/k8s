#!/usr/bin/bash

clean_input_dir=true
[ -v 1 ] && clean_input_dir=false # --keep

cd "$(dirname "$0")"
readonly input_dir="${PWD}/input"
source "../functions.sh"

tofu apply -destroy -auto-approve

stop_containers(){
    "${tools_dir}/dnsmasq/stop.sh"
    "${tools_dir}/container_registry/stop.sh"
}
stop_containers &

# Clean libvirt current state
#sudo virsh destroy k8s1 2>/dev/null || true
#sudo virsh undefine k8s1 --remove-all-storage 2>/dev/null || true
#sudo rm -f /etc/libvirt/qemu/k8s*.xml
#sudo rm -f /var/lib/libvirt/images/k8s*.qcow2

reset_network(){
    bridgectl remove vm_admin
    bridgectl remove vm_cni
    bridgectl remove vm_vsan
    bridgectl remove vm_svc
}

reset_network &

rm -rf terraform*
rm -rf .terraform*

#virsh undefine k8s1 --remove-all-storage
#virsh undefine k8s2 --remove-all-storage
#virsh undefine k8s3 --remove-all-storage

if $clean_input_dir; then
    rm -rf "$input_dir"
fi
wait
virsh -c qemu:///system  list --all
