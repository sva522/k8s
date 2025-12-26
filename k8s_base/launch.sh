#!/usr/bin/bash
set -euo pipefail

cd "$(dirname "$0")"
source "../functions.sh"

# Image is imported from net then :
# img_xz -mc debian-13-nocloud-amd64.qcow2

readonly input_img_path=input/debian-13-nocloud-amd64.qcow2.xz
readonly output_img_path=output/k8s_base.qcow2.xz
readonly output_qcow2_path="${output_img_path%.xz}" # remove .xz

rm -rf output && mkdir -p output
unxz -c -v "$input_img_path" > "$output_qcow2_path"

netcat_script_stdout

cat "$tools_dir/pki/gen/root_ca.crt" > rsc/root_ca.crt

#export LIBGUESTFS_DEBUG=1 LIBGUESTFS_TRACE=1
opt=; #opt='-x -v'
virt-customize $opt \
  -a "$output_qcow2_path" \
  --copy-in rsc:/root \
  --run-command "/root/rsc/setup.sh $nc_ip $nc_port"
wait_netcat

## This is an alternative using multiple low level libguestfs tools (strangley much much slower)
# virt-copy-in -a   ""$output_img_path" rsc /root/
# guestfish --rw --network -a ""$output_img_path" -i <<< 'sh /root/rsc/setup.sh'
# virt-cat -a       ""$output_img_path" /root/setup.log

mv "$output_qcow2_path" "${output_qcow2_path}.nsp"
virt-sparsify "${output_qcow2_path}.nsp" "$output_qcow2_path"
rm "${output_qcow2_path}.nsp"
xz -v -${xz_level} "$output_qcow2_path"
du -h "$output_img_path"
if [ ! -d final ]; then cp -r output final; fi
