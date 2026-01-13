#!/usr/bin/bash

cd "$(dirname "$0")"

virsh -c qemu:///system managedsave k8s1 &
virsh -c qemu:///system managedsave k8s2 &
virsh -c qemu:///system managedsave k8s3 &
wait
scripts/stop_infra.sh

./status.sh
