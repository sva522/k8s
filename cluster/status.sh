#!/usr/bin/bash

virsh -c qemu:///system net-list --all
virsh -c qemu:///system list     --all
