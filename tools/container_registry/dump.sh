#!/usr/bin/bash

cd "$(dirname "$0")"/..
mkdir -p output && cd output

docker run --rm \
-v container_registry:/container_registry \
-v $(pwd):/dump \
alpine \
tar -cf /dump/container_registry.tar -C /volume .
xz -v -T0 -9 container_registry.tar
du -h container_registry.tar.xz

