#!/usr/bin/bash

cd $(dirname "$0")

readonly admin_vip=$(dig +short admin.lab.ln)
ssh "admin@k8s1" "date" &>/dev/null # Sometimes ssh on k8s1 fail the first time WTF ?
readonly admin_if=$(cat ../get_if_from_ip.sh | ssh "admin@k8s1" "bash -s -- $admin_vip")
if [ -z "$admin_if" ]; then
    echo "Cannot determine interface for VIP $admin_vip"
    exit 1
fi

readonly last_version=$(curl -sL https://api.github.com/repos/kube-vip/kube-vip/releases | jq -r '.[0].name')
readonly last_image="ghcr.io/kube-vip/kube-vip:${last_version}"

kube-vip(){
    docker run --rm --name kube-vip "$last_image" "$@"
}

kube-vip manifest daemonset \
    --serviceInterface "${admin_if}" \
    --services \
    --servicesElection \
    --lbClassNameLegacyHandling false \
    --lbClassName "kube-vip-admin-lb" \
    --lbClassOnly \
    --inCluster \
    --arp \
    > /tmp/kube-vip-lb.yaml

./configureKubeVip.py /tmp/kube-vip-lb.yaml
#cat /tmp/kube-vip-lb.yaml && exit
kubectl apply -f /tmp/kube-vip-lb.yaml
kubectl rollout status daemonset/kube-vip-ds-admin-lb -n kube-system --timeout=120s

kubectl create deployment test-nginx --image=nginx
kubectl rollout status deployment/test-nginx --timeout=30s
kubectl apply -f ServiceTest.yaml
sleep 4
kubectl get svc test-service -o wide

#kubectl logs -n kube-system -l app.kubernetes.io/name=kube-vip-ds-admin-lb
curl -s http://192.168.11.100 | grep title

kubectl delete svc test-service
kubectl delete deployment test-nginx
#kubectl delete -f /tmp/kube-vip-lb.yaml

#rm /tmp/kube-vip-lb.yaml
