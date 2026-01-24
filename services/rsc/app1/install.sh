#!/usr/bin/bash

cd "$(dirname "$0")"

kubectl create namespace app1
kubectl create configmap -n app1 app1-page --from-file=index.html=./index.html
kubectl apply -f nginx.yaml
kubectl apply -f ingress.yaml
kubectl wait --for=condition=Ready pods --all -n app1 --timeout=120s
