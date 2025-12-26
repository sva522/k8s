#!/usr/bin/bash

cd "$(dirname "$0")"

launch_container_registry(){
    human_name=$1
    container_name=$2
    volume_name="$container_name"
    config_filename=$3
    host_port=$4

    echo "Launch ${human_name}..."
    # Create Volume if not exists
    if ! docker volume inspect "${volume_name}" &> /dev/null; then
        docker volume create "${volume_name}"
    fi

    docker run -d --rm --name "${container_name}" \
        -v "../pki/gen/container_registry":/certs \
        -p "${host_port}:5000" \
        -v "${volume_name}:/var/lib/registry" \
        -v "$(pwd)/config/${config_filename}:/etc/docker/registry/config.yml" registry:2
}

./stop.sh 2>/dev/null
launch_container_registry 'container registry'                            'container_registry' 'container_registry.yaml' 5000 &
launch_container_registry 'Kubernetes official container registry mirror' 'registry_k8s_io'    'registry.k8s.io.yaml'    5001 &
launch_container_registry 'Github container registry mirror'              'ghcr_io'            'ghcr.io.yaml'            5002 &
launch_container_registry 'Docker Hub  mirror'                            'docker_hub'         'docker.io.yaml'          5003 &
launch_container_registry 'Redhat container registry mirror'              'quay_io'            'quay.io.yaml'            5004 &
wait
