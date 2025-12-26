#!/usr/bin/bash

check_ntp_sync() {
    chronyc tracking | grep -q 'Leap status.*Normal'
}

wait_for_sync() {
    local timeout=30
    local start_time=$(date +%s)
    
    until check_ntp_sync; do
        sleep 1
        local now=$(date +%s)
        if (( now - start_time >= timeout )); then
            echo "NTP sync [FAILED] (timeout ${timeout}s)."
            return
        fi
    done

    local end_time=$(date +%s)
    local elapsed=$((end_time - start_time))
    echo "NTP sync completed in ${elapsed}s."
}

if check_ntp_sync; then
    echo 'NTP sync already [OK]'
    
else
    echo 'Waiting for NTP sync...'
    wait_for_sync
fi

# --status
if [ ! -v 1 ]; then exit 0; fi

for service in kubelet ssh; do
    if systemctl is-active --quiet "$service"; then
        echo "$service [STARTED]"
    else
        echo "$service [STOPPED]"
    fi
done
