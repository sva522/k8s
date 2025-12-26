#!/usr/bin/bash


cd "$(dirname "$0")"
cert='../pki/gen/root_ca.crt'

host='container-registry.lab.ln'
#host='127.0.0.1'
echo -n 'container_registry: '
curl --cacert "$cert" -s "https://${host}:5000/v2/_catalog" | jq .
echo -n 'registry_k8s_io: '
curl --cacert "$cert" -s "https://${host}:5001/v2/_catalog" | jq .
echo -n 'ghcr_io: '
curl --cacert "$cert" -s "https://${host}:5002/v2/_catalog" | jq .
echo -n 'docker_hub: '
curl --cacert "$cert" -s "https://${host}:5003/v2/_catalog" | jq .
echo -n 'quay_io: '
curl --cacert "$cert" -s "https://${host}:5004/v2/_catalog" | jq .

volume_size(){
    local volume_name="$1"
    echo -n "${volume_name} size: "
    docker system df -v | awk '/VOLUME/{show=1; next} show && NF==3' | grep "${volume_name}" | awk '{print $3}' # Volume size
}

volume_size container_registry
volume_size registry_k8s_io
volume_size ghcr_io
volume_size docker_hub
volume_size quay_io

# ctr images rm container-registry.lab.ln:5000/simple-app:latest; ctr images pull container-registry.lab.ln:5000/simple-app:latest
# crictl rmi docker.io/library/busybox:latest; crictl pull docker.io/library/busybox:latest
