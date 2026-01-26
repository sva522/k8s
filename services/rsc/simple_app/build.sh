#!/usr/bin/bash

cd "$(dirname "$0")"

echo 'Installing simple_app_dir...'
cd "$simple_app_dir"
kubectl create --save-config -f pvc.yaml
kubectl create --save-config -f deploy.yaml
kubectl create --save-config -f ingress.yaml
kubectl wait --for=condition=ready pod -l app=simple-app -n simple-app --timeout=300s
kubectl get pods -n longhorn-system --watch

cd "$rsc_dir"


docker rmi simple-app
docker build -t simple-app .

if ! docker ps --format "{{.Names}}" | grep -q container_registry; then
../../tools/container_registry/launch.sh
fi

# Allow usage of this "insecure" registry
# /etc/docker/daemon.json
#  "insecure-registries": ["localhost:5000"]
# sudo systemctl restart docker

docker tag simple-app localhost:5000/simple-app:latest
docker tag simple-app localhost:5000/simple-app:1.0
docker push localhost:5000/simple-app:latest
docker push localhost:5000/simple-app:1.0
