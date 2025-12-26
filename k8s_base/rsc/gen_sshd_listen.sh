#!/usr/bin/bash

echo > /etc/ssh/sshd_config.d/99-listen.conf
_gen_sshd_listen() {
    local dns_ip="$(dig dns.vm_admin +short)"
    if [ -z "$dns_ip" ]; then
        echo "Cannot resolve dns.vm_admin, retry..."
        return 1
    fi
    echo "Resolved dns.vm_admin to $dns_ip"
    local ip="$(dig @"$dns_ip" "$HOSTNAME" +short)"
    if [ -z "$ip" ]; then
        echo "Cannot resolve $HOSTNAME, retry..."
        return 1
    fi
    echo "ListenAddress $ip"
    echo "ListenAddress $ip" >> /etc/ssh/sshd_config.d/99-listen.conf
}

readonly interval=2
readonly timeout=10
elapsed=0

until _gen_sshd_listen; do
  if [ "$elapsed" -ge "$timeout" ]; then
    echo "Timeout reached after $timeout secondes, abandon."
    exit 0
  fi
  sleep "$interval"
  elapsed=$((elapsed + interval))
done
