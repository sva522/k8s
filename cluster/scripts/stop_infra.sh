#!/usr/bin/bash

cd $(dirname $0)
source "../../functions.sh"

stop_containers(){
    "${tools_dir}/dnsmasq/stop.sh"
    "${tools_dir}/container_registry/stop.sh"
}

reset_network(){
    bridgectl remove vm_admin &
    bridgectl remove vm_cni   &
    bridgectl remove vm_vsan  &
    bridgectl remove vm_svc   &
    wait
}

stop_containers &
reset_network &
wait
