#!/usr/bin/bash

cd "$(dirname "$0")"

img=$1
rm -rf /tmp/*_qemu_debug
tmp_dir=$(mktemp -d --suffix _qemu_debug)
img_name="$(basename $img)"
img_name="${img_name%.*}" # remove .xz
xz -dvc "${img}" > "${tmp_dir}/${img_name}"

create_tap=/opt/create_tap
remove_tap=/opt/remove_tap

echo 'Creating taps...'
sudo "$create_tap" vm_admin 192.168.11.254/24
sudo "$create_tap" vm_cni   192.168.12.254/24
sudo "$create_tap" vm_vsan  192.168.13.254/24
sudo "$create_tap" vm_svc   192.168.14.254/24
echo 'Done.'

../first_node/dnsmasq/launch.sh
xorriso -as mkisofs -quiet -o seed.iso -V cidata -J -r cloud-init/* >/dev/null
ssh-keygen -R '[127.0.0.1]:2222' &>/dev/null
qemu-system-x86_64 -enable-kvm \
  -drive file="${tmp_dir}/${img_name}",format=qcow2 \
  -cdrom seed.iso \
  -smp 4 -m 2048  \
  \
  -netdev user,id=if_nat_net,hostfwd=tcp::2222-:22 \
  -device virtio-net-pci,netdev=if_nat_net \
  \
  -netdev tap,id=if_admin,ifname=vm_admin,script=no,downscript=no \
  -device virtio-net-pci,netdev=if_admin \
  \
  -netdev tap,id=if_cni,ifname=vm_cni,script=no,downscript=no \
  -device virtio-net-pci,netdev=if_cni \
  \
  -netdev tap,id=if_vsan,ifname=vm_vsan,script=no,downscript=no \
  -device virtio-net-pci,netdev=if_vsan \
  \
  -netdev tap,id=if_svc,ifname=vm_svc,script=no,downscript=no \
  -device virtio-net-pci,netdev=if_svc \
  -display gtk \
  -vnc none
  
  # -netdev user,id=net0 \
  # -device virtio-net-pci,netdev=net0 \

rm -rf  /tmp/*_qemu_debug
../first_node/dnsmasq/stop.sh

echo 'Removing taps...'
sudo "$remove_tap" vm_admin
sudo "$remove_tap" vm_cni
sudo "$remove_tap" vm_vsan
sudo "$remove_tap" vm_svc
echo 'Done.'
rm -f seed.iso
