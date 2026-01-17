#!/usr/bin/bash

cd "$(dirname "$0")"
readonly services_dir="$PWD"
readonly rsc_dir="${services_dir}/rsc"
readonly simple_app_dir="${services_dir}/simple_app"
readonly pki_dir="${services_dir}/../tools/pki/gen/"


cd "$rsc_dir"

check_connectivity(){
  local url="$1"
  local caption="$2"
  if curl -sk "https://$url" | grep -qi "$caption"; then
    echo "$url [OK]"
  else
    echo "$url [NOK]"
  fi
}

traefik/install.sh
default-app.sh
check_connectivity svc.lab.ln 'Nginx Default'
app1/install.sh
check_connectivity app1.svc.lab.ln  'Nginx App1'
check_connectivity svc.lab.ln/app1/ 'Nginx App1'
app2/install.sh
check_connectivity app2.svc.lab.ln  'Nginx App2'
check_connectivity svc.lab.ln/app2/ 'Nginx App2'
read -rp 'Press [ENTER] to continue' </dev/tty
admin/install.sh
check_connectivity admin.lab.ln 'Nginx Admin'
check_connectivity traefik.svc.lab.ln 'Traefik Dashboard'
exit 0

echo 'Checking connectivity...'

check_connectivity app2.svc.lab.ln  'Nginx App2'
check_connectivity svc.lab.ln/app2  'Nginx App2'
check_connectivity admin.lab.ln 'Nginx Admin'

readonly dns_on_vsan=$(dig dns.vm_vsan.lab.ln +short)
network_get_prefix(){
    awk -F '.' '{print $1 "." $2 "." $3}' <<< "$1"
}
readonly vsan_net_prefix=$(network_get_prefix "$dns_on_vsan")
vsan_if=$(ip -brief a | grep "$vsan_net_prefix.*/" | awk '{print $1}')
sed "s|^  defaultReplicaNetwork: .*|  defaultReplicaNetwork: $vsan_if|" longhorn-values.yaml > /tmp/longhorn-values.yaml

kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.32/deploy/local-path-storage.yaml
helm repo add longhorn https://charts.longhorn.io; helm repo update &>/dev/null
helm install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace -f /tmp/longhorn-values.yaml
rm /tmp/longhorn-values.yaml
kubectl -n longhorn-system wait --for=condition=Available --timeout=600s deployment --all
echo 'Longhorn installed !'
kubectl get storageclass

echo 'Installing simple_app_dir...'
cd "$simple_app_dir"
kubectl create --save-config -f pvc.yaml
kubectl create --save-config -f deploy.yaml
kubectl create --save-config -f ingress.yaml
kubectl wait --for=condition=ready pod -l app=simple-app -n simple-app --timeout=300s
kubectl get pods -n longhorn-system --watch

cd "$rsc_dir"

helm repo add gitlab https://charts.gitlab.io/; helm repo update &>/dev/null
# helm upgrade --install gitlab gitlab/gitlab \
#   --timeout 600s \
#   -f gitlab-values.yaml \
#   --namespace gitlab \
#   --create-namespace

#kubectl port-forward svc/longhorn-frontend -n longhorn-system 8080:80 # http://localhost:8080
#kubectl port-forward -n calico-system service/whisker 8080:8081
#kubectl port-forward -n traefik svc/traefik 8080:9000

# helm install my-postgres oci://registry-1.docker.io/cloudpirates/postgres
# helm install my-valkey   oci://registry-1.docker.io/cloudpirates/valkey
