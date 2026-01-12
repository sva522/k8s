#!/usr/bin/bash

cd "$(dirname "$0")"

source "../functions.sh"
scripts/start_infra.sh

virsh -c qemu:///system net-start vm_nat
virsh -c qemu:///system start k8s1 &
virsh -c qemu:///system start k8s2 &
virsh -c qemu:///system start k8s3 &
wait

wait_for_ssh k8s1
wait_for_ssh k8s2
wait_for_ssh k8s3
ssh admin@k8s1 wait_for_ntp
ssh admin@k8s2 wait_for_ntp
ssh admin@k8s3 wait_for_ntp
