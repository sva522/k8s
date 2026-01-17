#!/usr/bin/bash

cd "$(dirname "$0")"

kubectl create namespace app2
kubectl create configmap -n app2 app2-page --from-file=index.html=./index.html
kubectl apply -f nginx.yaml
kubectl apply -f ingress.yaml
