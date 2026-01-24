#!/usr/bin/bash

cd "$(dirname "$0")"

kubectl create namespace default-app
kubectl create configmap -n default-app default-app-page --from-file=index.html=./index.html
kubectl apply -f nginx.yaml
kubectl apply -f ingress.yaml
kubectl wait --for=condition=Ready pods --all -n default-app --timeout=120s
