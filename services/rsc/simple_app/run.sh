#!/usr/bin/bash

cd "$(dirname "$0")"

if ! docker ps --format "{{.Names}}" | grep -q container_registry; then
../../../tools/container_registry/launch.sh
fi

docker run --rm --name simple_app -p 8080:8080 localhost:5000/simple-app:latest
