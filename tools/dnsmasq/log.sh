#!/bin/sh
line="$(date +'%Y/%m/%d %H:%M:%S')"
event="$1"
mac="$2"
ip="$3"
hostname="$4"
iface="$DNSMASQ_INTERFACE"
#client_id="$DNSMASQ_CLIENT_ID"         # client unique uuid created from mac
#log_enabled="$DNSMASQ_LOG_DHCP"        # Is log enabled: 0 or 1
#missing_field=$DNSMASQ_DATA_MISSING    # 0 or 1 if some field are not emited (ex: option-routeur)
lease_remaining="$DNSMASQ_TIME_REMAINING" # remaining secs
#lease_expire_date="$(date +'%Y/%m/%d %H:%M:%S' -d @${DNSMASQ_LEASE_EXPIRES})"
#vars="$(env | grep '^DNSMASQ_' | tr '\n' ' ')" | sed -i 's/DNSMASQ_//'

if [ -n "$event" ]; then
    line="$line event=$event "
fi
if [ -n "$mac" ]; then
    line="$line mac=$mac "
fi
if [ -n "$ip" ]; then
    line="$line ip=$ip "
fi
if [ -n "$hostname" ]; then
    line="$line hostname=$hostname "
fi
if [ -n "$iface" ]; then
    line="$line iface=$iface "
fi
if [ -n "$lease_remaining" ]; then
    line="$line remaining_secs=$lease_remaining"
fi
echo "$line" >> /var/log/dhcp.log
