#!/usr/bin/bash

cd "$(dirname "$0")"
readonly pki_dir="${PWD}/../../../tools/pki/gen/"

kubectl create namespace traefik
kubectl create secret tls tls-svc-lab-ln \
  --namespace=traefik \
  --cert="$pki_dir/services/services.chain.crt" \
  --key="$pki_dir/services/services.key"

readonly svc_vip=$(dig +short svc.lab.ln)
[ -z "$svc_vip" ]   && exit 1

cp -f traefik-values.yaml /tmp/traefik-values.yaml
sed -i "s/svc_vip/${svc_vip}/"     /tmp/traefik-values.yaml

# helm repo add traefik https://traefik.github.io/charts; helm repo update &>/dev/null
helm uninstall traefik --namespace=traefik --wait &>/dev/null

# helm upgrade --install ...
echo 'Installing traefik...'
helm install traefik traefik/traefik -n traefik -f /tmp/traefik-values.yaml
kubectl wait --for=condition=available deployment/traefik -n traefik --timeout=300s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=traefik -n traefik --timeout=300s
# rm /tmp/traefik-values.yaml
echo 'Traefik installation finished !'
