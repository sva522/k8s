#!/bin/sh

fix_perms(){
    # Wait for log (re)creation
    while [ ! -f /var/log/dnsmasq.log ]; do
        sleep 1
    done
    # Fix permissions
    #chmod g+w /var/log/dhcp.log
    chmod g+w /var/log/dnsmasq.log
    #chmod g+w /var/log/dnsmasq_stdout.log
}

fix_perms &
# Run dnsmasq in foreground (no daemon mode)
/usr/sbin/dnsmasq --no-daemon > /var/log/dnsmasq_stdout.log 2>&1
wait
