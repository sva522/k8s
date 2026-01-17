#!/usr/bin/bash

cd $(dirname "$0")
readonly pki_dir="${PWD}/../../tools/pki/gen/"

kubectl create namespace admin
kubectl create secret tls tls-admin-lab-ln \
  --namespace=traefik \
  --cert="$pki_dir/admin/admin.chain.crt" \
  --key="$pki_dir/admin/admin.key"
kubectl create configmap -n admin admin-page --from-file=index.html=./index.html

kubectl apply -f traefik-admin.yaml
kubectl apply -f dashboard-ingress.yaml

kubectl apply -f nginx.yaml
kubectl apply -f ingress.yaml
