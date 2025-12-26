#!/bin/bash
REGISTRY="localhost:5000"

# Liste tous les repositories
repos=$(curl -s http://${REGISTRY}/v2/_catalog | jq -r '.repositories[]')

for repo in $repos; do
  # Liste les tags du repo
  tags=$(curl -s http://${REGISTRY}/v2/${repo}/tags/list | jq -r '.tags[]?')

  for tag in $tags; do
    if [ "$tag" == "latest" ]; then
      echo "Suppression du tag latest pour $repo"

      # Récupère le digest du manifest latest
      digest=$(curl -sI -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
        http://${REGISTRY}/v2/${repo}/manifests/latest | \
        grep Docker-Content-Digest | awk '{print $2}' | tr -d $'\r')

      if [ -n "$digest" ]; then
        # Supprime le manifest
        curl -s -X DELETE http://${REGISTRY}/v2/${repo}/manifests/${digest}
        echo "Digest $digest supprimé pour $repo:latest"
      fi
    fi
  done
done