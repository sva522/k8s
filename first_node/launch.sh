#!/usr/bin/bash
set -euo pipefail

cd "$(dirname "$0")"
source "../functions.sh"

#### IMPORT BASE IMAGE ####
input_dir="${PWD}/input"
rm -rf "$input_dir"  && mkdir -p "$input_dir"
trap "rm -rf '$input_dir'" EXIT
readonly input_img_path="${project_dir}/k8s_base/output/k8s_base.qcow2.xz"
readonly vm_disk_path="${input_dir}/disk.qcow2"

readonly vm_name=$(jq -r '.builders[] | .vm_name' packer.json)
readonly output_dir="${PWD}/$(jq -r '.builders[] | .output_directory' packer.json)"
readonly output_img_path="${output_dir}/${vm_name}.qcow2.xz"
readonly output_qcow2_path="${output_img_path%.xz}" # remove .xz
rm -rf "$output_dir"

setup_network(){
    #### CREATE TAPS ####
    #tapctl create vm_nat   192.168.10.254/24
    tapctl create vm_admin 192.168.11.254/24
    tapctl create vm_cni   192.168.12.254/24
    tapctl create vm_vsan  192.168.13.254/24
    tapctl create vm_svc   192.168.14.254/24
    "${tools_dir}/dnsmasq/launch.sh"
    "${tools_dir}/container_registry/launch.sh"
    ssh-keygen -R '[127.0.0.1]:2222' &>/dev/null
}

setup_network &
xorriso -as mkisofs -quiet -o seed.iso -V cidata -J -r cloud-init/* >/dev/null
unxz -c -v "$input_img_path" > "$vm_disk_path"

"${tools_dir}/grow_vm.sh" "$vm_disk_path" "$node_disk_size"
wait

#### LAUNCH BUILD ####

netcat_script_stdout
export PACKER_LOG=0
#packer hcl2_upgrade -with-annotations -output-file=first_node.pkr.hcl packer.json
packer build                \
    -var "nc_ip=$nc_ip"     \
    -var "nc_port=$nc_port" \
    packer.json # first_node.pkr.hcl
wait_netcat

rm -f "${output_dir}/${vm_name}"* # Ignore packer output (Empty disk created)
mv "$vm_disk_path" "$output_qcow2_path" # Set vm_disk as output
rm -rf input

#### CLEANUP ####

"${tools_dir}/dnsmasq/stop.sh"  
"${tools_dir}/container_registry/stop.sh"

tapctl remove vm_admin
tapctl remove vm_cni
tapctl remove vm_vsan
tapctl remove vm_svc
rm -f seed.iso

#### COMPRESS IMAGE ####
# virt-sparsify tmp_dir
export TMPDIR="${output_dir}/tmp" && mkdir -p "$TMPDIR"
trap "rm -rf '$TMPDIR'" EXIT

mv "$output_qcow2_path" "${output_qcow2_path}.nsp"
virt-sparsify "${output_qcow2_path}.nsp" "$output_qcow2_path"
rm -rf "${output_qcow2_path}.nsp" "$TMPDIR"
xz -T0 -v -${xz_level} "$output_qcow2_path"
du -h "$output_img_path"

# Setup kubectl
cp -f "${output_dir}/gen/kube_config.conf" ~/.kube/config 
if [ ! -d final ]; then cp -r output final; fi
