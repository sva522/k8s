#!/usr/bin/bash

readonly join_token=$(kubeadm token create)
get_discovery_token(){
    openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt \
        | openssl rsa -pubin -outform der 2>/dev/null \
        | openssl dgst -sha256 -hex | sed 's/^.* //'
}
readonly dicovery_token=$(get_discovery_token)
readonly certificate_key=$(kubeadm init phase upload-certs --upload-certs | tail -1)
echo "$join_token $dicovery_token $certificate_key"
