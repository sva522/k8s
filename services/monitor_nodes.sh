#!/usr/bin/bash

while true; do
    reset
    kubecolor get nodes
    kubecolor get pods -n simple-app -o wide
    sleep 1
done
