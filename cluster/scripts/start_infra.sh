#!/usr/bin/bash

cd $(dirname $0)
source "../../functions.sh"

echo 'Resetting infra...'
./stop_infra.sh &>/dev/null # Stop best effort (removes old bridges)

echo 'Starting setup...'
source ./net_conf.sh

bridgectl create vm_admin "$dns_vm_admin/24"
bridgectl create vm_cni   "$dns_vm_cni/24"
bridgectl create vm_vsan  "$dns_vm_vsan/24"
bridgectl create vm_svc   "$dn_vm_svc/24"

"${tools_dir}/dnsmasq/launch.sh"
"${tools_dir}/container_registry/launch.sh"
