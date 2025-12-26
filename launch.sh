#!/usr/bin/bash

cd "$(dirname "$0")"
readonly project_dir="$PWD"

# Setup bin dir ##################################################
cd "${project_dir}/tools"

# Get last version (without leading v)
github_get_latest_version() {
  local owner="$1"
  local repo="${2:-$1}"
  local i=0
  local version=""
  local releases

  releases=$(curl -sL "https://api.github.com/repos/${owner}/${repo}/releases")

  while true; do
    version=$(echo "$releases" | jq -r ".[$i].name")

    # Si vide, on a atteint la fin
    if [[ -z "$version" || "$version" == "null" ]]; then
      echo "No version found for ${owner}/${repo}"
      return 1
    fi

    # Check if format matchs vX.X.X ou X.X.X
    if [[ "$version" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      if [[ "${version:0:1}" == "v" ]]; then version="${version:1}"; fi
      echo "$version"
      return 0
    fi

    ((i++))
  done
}

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
cluster/launch.sh
#services/launch.sh
