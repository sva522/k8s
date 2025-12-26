#!/usr/bin/bash

docker stop container_registry &
docker stop registry_k8s_io &
docker stop ghcr_io &
docker stop docker_hub &
docker stop quay_io &
sleep 1
wait
