#!/usr/bin/bash

network_get_prefix(){
    awk -F '.' '{print $1 "." $2 "." $3}' <<< "$1"
}

readonly ip="$1"
readonly network_prefix=$(network_get_prefix "$ip")
ip -brief a | grep "$network_prefix" | awk '{print $1}'
