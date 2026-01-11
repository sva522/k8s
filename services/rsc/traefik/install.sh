#!/usr/bin/bash

cd "$(dirname "$0")"

readonly svc_vip=$(dig +short svc.lab.ln)
readonly admin_vip=$(dig +short k8s.lab.ln)

cp traefik-values.yaml /tmp/traefik-values.yaml
sed -i "s/svc_vip/${svc_vip}/"     /tmp/traefik-values.yaml
sed -i "s/admin_vip/${admin_vip}/" /tmp/traefik-values.yaml

helm repo add traefik https://traefik.github.io/charts; helm repo update &>/dev/null
helm uninstall traefik --namespace=traefik --wait &>/dev/null

# helm upgrade --install ...
helm install traefik traefik/traefik -n traefik -f /tmp/traefik-values.yaml
#sleep 5 && kubectl logs -n traefik $(kubectl get pods -n traefik -o custom-columns=:metadata.name --no-headers | head -1)
kubectl wait --for=condition=available deployment/traefik -n traefik --timeout=300s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=traefik -n traefik --timeout=300s

kubectl apply -f dashboard-ingress.yaml

# rm /tmp/traefik-values.yaml
