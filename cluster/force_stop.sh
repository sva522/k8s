#!/usr/bin/bash

virsh -c qemu:///system destroy k8s1 &
virsh -c qemu:///system destroy k8s2 &
virsh -c qemu:///system destroy k8s3 &
wait
