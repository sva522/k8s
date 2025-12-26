#!/usr/bin/bash

cd "$(dirname "$0")"

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
