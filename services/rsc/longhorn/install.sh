#!/usr/bin/bash

cd "$(dirname "$0")"
source "${PWD}/../../../functions.sh"

readonly dns_on_vsan=$(dig dns.vm_vsan.lab.ln +short)
network_get_prefix(){
    awk -F '.' '{print $1 "." $2 "." $3}' <<< "$1"
}
readonly vsan_net_prefix=$(network_get_prefix "$dns_on_vsan")

node_net_conf(){
    ssh admin@k8s1 'ip -brief a'
}
vsan_if=$(node_net_conf | grep "$vsan_net_prefix.*/" | awk '{print $1}')
sed "s|^  defaultReplicaNetwork: .*|  defaultReplicaNetwork: $vsan_if|" longhorn-values.yaml > /tmp/longhorn-values.yaml

readonly version="v$(github_get_latest_version rancher local-path-provisioner)"
echo "Installing ${version}..."
kubectl apply -f "https://raw.githubusercontent.com/rancher/local-path-provisioner/${version}/deploy/local-path-storage.yaml"
helm repo add longhorn https://charts.longhorn.io; helm repo update &>/dev/null
helm install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace -f /tmp/longhorn-values.yaml
# rm /tmp/longhorn-values.yaml
kubectl -n longhorn-system wait --for=condition=Available --timeout=600s deployment --all
echo 'Longhorn installed !'
kubectl get storageclass

#kubectl port-forward svc/longhorn-frontend -n longhorn-system 8080:80 # http://localhost:8080
