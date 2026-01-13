#!/usr/bin/bash

cd "$(dirname "$0")"

virsh -c qemu:///system managedsave k8s1 &
virsh -c qemu:///system managedsave k8s2 &
virsh -c qemu:///system managedsave k8s3 &
wait
virsh -c qemu:///system net-destroy vm_nat &
scripts/stop_infra.sh &
wait

./status.sh
