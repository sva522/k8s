#!/usr/bin/bash

cd $(dirname "$0")

readonly svc_vip=$(dig +short svc.lab.ln)
readonly admin_vip=$(dig +short admin.lab.ln)

readonly admin_if=$(cat ../get_if_from_ip.sh | ssh "admin@k8s1" "bash -s -- $admin_vip")
readonly svc_if=$(cat   ../get_if_from_ip.sh | ssh "admin@k8s1" "bash -s -- $svc_vip")

# Install MetalLB -----------------------------------------------------------------------------------------
readonly metallb_version=$(curl -sL "https://api.github.com/repos/metallb/metallb/releases" \
  | jq -r '.[0].name' | grep 'Release ' | head -1 | awk -F 'Release ' '{print $2}')
#kubectl apply -f metallb/allow-metallb-memberlist.yaml
kubectl apply -f "https://raw.githubusercontent.com/metallb/metallb/$metallb_version/config/manifests/metallb-native.yaml"
kubectl wait --namespace metallb-system --for=condition=Ready pods --all --timeout=120s

# Setup metallb
cp metallb.yaml /tmp/metallb.yaml
sed -i "s/admin_if/${admin_if}/"   /tmp/metallb.yaml
sed -i "s/svc_if/${svc_if}/"       /tmp/metallb.yaml
sed -i "s/svc_vip/${svc_vip}/"     /tmp/metallb.yaml
sed -i "s/admin_vip/${admin_vip}/" /tmp/metallb.yaml
kubectl apply -f /tmp/metallb.yaml
echo 'Metallb configuration:'
cat /tmp/metallb.yaml
rm /tmp/metallb.yaml

# Test
kubectl apply -f ServicesTest.yaml
kubectl wait --for=condition=ready pod -l app=vip-svc --timeout=60s
kubectl wait --for=condition=ready pod -l app=vip-admin --timeout=60s
k get svc
curl -L http://admin.lab.ln | grep title
curl -L http://svc.lab.ln | grep title
kubectl delete -f ServicesTest.yaml
