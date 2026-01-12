#!/usr/bin/bash

virsh -c qemu:///system snapshot-list k8s1
if [ -v 1 ]; then # --all
    virsh -c qemu:///system snapshot-list k8s2
    virsh -c qemu:///system snapshot-list k8s3
fi
