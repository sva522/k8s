#!/usr/bin/bash

cd "$(dirname "$0")"
readonly project_dir="$PWD"

source 'functions.sh'

# Setup bin dir ##################################################
cd "${project_dir}/tools"

#### Fetch packer ###########################################################################################
packer_last_version=$(github_get_latest_version hashicorp packer)
if [ ! -x packer ] || [ "$(./packer version)" != "Packer v${packer_last_version}" ]; then
    echo "Installing Packer ${packer_last_version}..."
    archive="packer_${packer_last_version}_linux_amd64.zip"
    rm -f packer "${archive}"*
    wget -q "https://releases.hashicorp.com/packer/${packer_last_version}/${archive}"
    unzip -q "$archive"
    rm -f LICENSE* "$archive"
fi

echo "Packer version v${packer_last_version}"
#./packer plugins install github.com/hashicorp/virtualbox
./packer plugins install github.com/hashicorp/qemu

#### Fetch tofu ###########################################################################################

tofu_last_version=$(github_get_latest_version opentofu)
if [ ! -x tofu ] || [ "$(./tofu --version | head -1)" != "OpenTofu v${tofu_last_version}" ]; then
    echo "Installing tofu ${tofu_last_version}..."
    archive="tofu_${tofu_last_version}_linux_amd64.zip"
    rm -f tofu "${archive}"*
    echo "https://github.com/opentofu/opentofu/releases/download/v${tofu_last_version}/${archive}"
    wget -q "https://github.com/opentofu/opentofu/releases/download/v${tofu_last_version}/${archive}"
    unzip -q "$archive"
    rm -f LICENSE* ./*.md "$archive"
fi
echo "OpenTofu v${tofu_last_version}"

# libvirt provider from https://github.com/dmacvicar/terraform-provider-libvirt/releases
# installed to ~/.opentofu.d/plugins/dmacvicar/libvirt/0.8.3/linux_amd64/terraform-provider-libvirt

#### Fetch Ansible ###########################################################################################
#### Fetch portable Ansible from same git repo ###########
#ansible_dir=$(realpath ../portable_ansible)
#if [ ! -x "ansible-playbook" ]; then
#    if [ ! -x "${ansible_dir}/Ansible-x86_64.AppImage" ]; then ansible_dir/build.sh; fi
#    ln -s "${ansible_dir}/Ansible-x86_64.AppImage" ansible-playbook
#fi

cd "$project_dir"

# Launch builds ##################################################
k8s_base/launch.sh
first_node/launch.sh
cluster/install.sh
services/install.sh
