#!/usr/bin/bash

cd "$(dirname "$0")"
./stop.sh 2>/dev/null 

./build.sh &>/dev/null
echo>dnsmasq.log
echo>dhcp.log
echo>stdout.log

# Launced with "--network host" to bind tap interfaces
docker run -d --rm \
  --name dnsmasq-infra \
  --network host \
  --cap-add=NET_ADMIN \
  --cap-add=NET_BIND_SERVICE \
  -v $(pwd)/rsc/dnsmasq.conf:/etc/dnsmasq.conf:ro \
  -v $(pwd)/stdout.log:/var/log/dnsmasq_stdout.log \
  -v $(pwd)/dnsmasq.log:/var/log/dnsmasq.log \
  -v $(pwd)/dhcp.log:/var/log/dhcp.log \
  dnsmasq-infra
