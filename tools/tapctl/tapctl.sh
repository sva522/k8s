#!/bin/bash

set -euo pipefail
cd "$(dirname "$(realpath "$0")")"

usage() {
    echo "Usage:"
    echo "  $0 create <interface_name> <ip_address/mask> [-nat]"
    echo "  $0 remove <interface_name>"
    exit 1
}

main(){
     # $1 must be action
    if [[ ! -v 1 ]]; then usage; fi
    local -r action="$1" && shift # consume arg

    case "$action" in
        create)
            if [[ ! -v 1 ]]; then
                echo "Action create: Interface name must be provided" >&2 && usage
            fi
            local -r iface="$1" && validate_interface "$iface" && shift 

            if [[ ! -v 1 ]]; then
                echo "Action create: ip address must be provide" >&2 && usage
            fi
            local -r ipaddr="$1" && validate_ip "$ipaddr" && shift
            
            local nat_enabled=false
            if [[ -v 1 ]]; then
                if [[ "$1" == '-nat' ]]; then 
                    nat_enabled=true && shift
                else
                    echo "Action create: unknow option $1" >&2 && usage
                fi
            fi
            readonly nat_enabled

            if [[ -v 1 ]]; then
                echo "Action create: too much args provided" >&2 && usage
            fi
            
            create_tap "$iface" "$ipaddr"
            if $nat_enabled; then setup_nat "$ipaddr"; fi
            ;;
        remove)
            if [[ ! -v 1 ]]; then
                echo "Action remove: Interface name must be provided" >&2 && usage
            fi
            iface="$1" && validate_interface "$iface" && shift
            if [[ -v 1 ]]; then
                echo "Action remove: too much args provided" >&2 && usage
            fi

            remove_tap "$iface"
            ;;
        *)
            echo "Error: Unknown action '$action'." >&2
            usage
            ;;
    esac
}

validate_interface() {
    local iface="$1"
    if ! [[ "$iface" =~ ^[a-z0-9_-]{1,15}$ ]]; then
        echo "Error: Invalid interface name '$iface'." >&2
        exit 1
    fi
}

validate_ip() {
    local ip="$1"
    if ! [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]]; then
        echo "Error: Invalid IP address format. Expected format: 192.168.1.1/24" >&2
        exit 1
    fi
}

remove_tap() {
    local iface="$1"

    if ip link show "$iface" &>/dev/null; then
        echo "Bringing down interface: $iface"
        ip link set "$iface" down || true
    else
        echo "Warning: Interface '$iface' does not exist."
    fi

    echo "Deleting TAP interface: $iface"
    ip tuntap del dev "$iface" mode tap 2>/dev/null || \
        echo "Note: TAP interface '$iface' may not exist or is already removed."
}

create_tap() {
    local iface="$1"
    local ipaddr="$2"

    remove_tap "$iface" &>/dev/null || true

    echo "Creating TAP interface: $iface"
    ip tuntap add dev "$iface" mode tap

    echo "Assigning IP address $ipaddr to $iface"
    ip addr add "$ipaddr" dev "$iface"

    echo "Bringing up interface: $iface"
    ip link set "$iface" up
}

setup_nat(){
    local ipaddr="$1"
    local -r default_if_out=$(ip route show default | awk '{print $5}')

    echo 1 > /host_proc_sys_net_ipv4/ip_forward
    nft add table ip vm_nat
    nft add chain ip vm_nat postrouting { type nat hook postrouting priority 100 \; }
    nft add rule  ip vm_nat postrouting oifname "$default_if_out" ip saddr "$ipaddr"/24 masquerade
}

main "$@"
