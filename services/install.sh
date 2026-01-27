#!/usr/bin/bash

cd "$(dirname "$0")/rsc"

check_connectivity() {
  local url="$1"
  local caption="$2"
  local timeout=6
  local start=$(date +%s)

  while true; do
    if curl -skL "https://$url" 2>/dev/null | grep -qi "$caption"; then
      echo "$url [OK]"
      return 0
    fi

    # Check timeout
    if (( $(date +%s) - start >= timeout )); then
      echo "$url [NOK]"
      exit 55
    fi

    sleep 2
  done
}

longhorn/install.sh

traefik/install.sh
default-app/install.sh
app1/install.sh
app2/install.sh
admin/install.sh

# kubectl rollout restart deployment -n traefik traefik
echo 'Checking services endpoint...'
check_connectivity svc.lab.ln         'Nginx Default'
check_connectivity app1.svc.lab.ln    'Nginx App1'
check_connectivity svc.lab.ln/app1/   'Nginx App1'
check_connectivity app2.svc.lab.ln    'Nginx App2'
check_connectivity svc.lab.ln/app2/   'Nginx App2'
echo 'Checking admin endpoint...'
check_connectivity k8s.lab.ln         'Nginx Admin'
check_connectivity traefik.k8s.lab.ln 'Traefik Proxy'

simple_app/install.sh
