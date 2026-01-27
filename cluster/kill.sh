#!/usr/bin/bash

node="k8s3"
[ -v 1 ] && node="$1"
virsh -c qemu:///system destroy "$node"
