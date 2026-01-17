#!/usr/bin/bash

cd "$(dirname "$0")"

source "../functions.sh"
source "scripts/net_conf.sh"
scripts/start_infra.sh

virsh -c qemu:///system net-start vm_nat
virsh -c qemu:///system start k8s1 &
virsh -c qemu:///system start k8s2 &
virsh -c qemu:///system start k8s3 &
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
