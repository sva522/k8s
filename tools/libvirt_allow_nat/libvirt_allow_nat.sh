#!/bin/bash

readonly default_if_out=$(ip route show default | awk '{print $5}')

iptables_add(){
    echo iptables "$@"
    if [ "$1" == '-I' ]; then
        shift
        iptables -C "$@" 2>/dev/null || iptables -I "$@"
    else
        iptables "$@"
    fi
}

echo "Injecting custom iptables rules for libvirt NAT..."
while [ -v 1 ]; do
    brigde="$1"
    iptables_add -I FORWARD 1 -i "$brigde"         -o "$default_if_out" -j ACCEPT
    iptables_add -I FORWARD 1 -i "$default_if_out" -o "$brigde" -m state --state RELATED,ESTABLISHED -j ACCEPT
    shift
done

echo 'Enable promiscuous mode on interfaces connected to vm_admin bridge:'
for interface in $(bridge link | grep vm_admin | awk -F ': ' '{print $2}'); do
    echo "Enable promiscuous mode on $interface"
    ip link set "$interface" promisc on
done

echo 1 > /host_proc_sys_net_ipv4/ip_forward
nft delete table ip6 libvirt_network &>/dev/null
echo DONE
