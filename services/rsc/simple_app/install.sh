#!/usr/bin/bash

cd "$(dirname "$0")"

./build.sh

echo 'Installing simple_app...'
kubectl apply -f pvc.yaml
kubectl apply -f deployment.yaml
kubectl apply -f ingress.yaml
kubectl wait --for=condition=ready pod -l app=simple-app -n simple-app --timeout=300s
