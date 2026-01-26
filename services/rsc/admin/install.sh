#!/usr/bin/bash

cd $(dirname "$0")
readonly pki_dir="${PWD}/../../../tools/pki/gen/"

kubectl create namespace admin
kubectl create secret tls tls-admin-lab-ln \
  --namespace=admin \
  --cert="$pki_dir/admin/admin.chain.crt" \
  --key="$pki_dir/admin/admin.key"
kubectl create configmap -n admin admin-page --from-file=index.html=./index.html

admin_ip=$(dig k8s.lab.ln +short)
[ -z "$admin_ip" ] && exit 88

kubectl apply -f admin-app.yaml
kubectl apply -f ingress-admin-app.yaml
sed "s/<admin_ip>/$admin_ip/" service-admin.yaml | kubectl apply -f -
kubectl apply -f ingress-traefik-dashboard.yaml
kubectl apply -f ingress-whisker-ui.yaml
kubectl get namespace longhorn-system &>/dev/null && kubectl apply -f ingress-longhorn.yaml
kubectl wait --for=condition=Ready pods --all -n admin --timeout=120s
kubectl wait --for=condition=Ready pods --all -n traefik --timeout=120s

# See cert Subject in secret
# kubectl get secret -n admin tls-admin-lab-ln -o jsonpath="{.data['tls\.crt']}" | base64 -d | openssl x509 -noout -text | grep -E "Subject:|DNS:"
