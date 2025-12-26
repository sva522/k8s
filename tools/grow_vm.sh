#!/usr/bin/bash

readonly vm_disk_path="$1"
readonly new_size="$2"

#### GROW ROOT PART ####
# virt-filesystems --filesystems -l --no-title    Get all info of filesystems in image (no title line)
#   sort -k5 -n                                   Sort by 5th column e.g. size (not human readable, because no -h on virt-filesystems)
#   tail -1                                       Get biggest partion size (sort is acsending)
#   awk '{print $1}'                              Get device name on first column
root_part=$(
    virt-filesystems -l --no-title -a "$vm_disk_path" \
    | sort -k5 -n      \
    | tail -1          \
    | awk '{print $1}'
)

#### GROW ROOT PART ####
mv "$vm_disk_path" "${vm_disk_path}.small"
qemu-img create -f qcow2 "$vm_disk_path" "$new_size"
virt-resize --expand "$root_part" "${vm_disk_path}.small" "$vm_disk_path"
rm "${vm_disk_path}.small" 
