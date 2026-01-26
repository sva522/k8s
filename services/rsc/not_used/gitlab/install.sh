#!/usr/bin/bash

helm repo add gitlab https://charts.gitlab.io/; helm repo update &>/dev/null
# helm upgrade --install gitlab gitlab/gitlab \
#   --timeout 600s \
#   -f gitlab-values.yaml \
#   --namespace gitlab \
#   --create-namespace

