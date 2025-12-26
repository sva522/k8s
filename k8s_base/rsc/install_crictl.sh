#!/usr/bin/bash

cd "$(dirname "$0")"

mv crictl.yaml /etc/crictl.yaml
readonly last_version=$(curl -sL https://api.github.com/repos/kubernetes-sigs/cri-tools/releases | jq -r '.[0].name')
readonly url="https://github.com/kubernetes-sigs/cri-tools/releases/download/${last_version}/crictl-${last_version}-linux-amd64.tar.gz"
curl -sL "$url" | tar -xz -C /usr/local/bin/ 
