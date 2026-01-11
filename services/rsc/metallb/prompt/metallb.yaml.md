apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: traefik-svc
  namespace: metallb-system
spec:
  addresses:
    - 192.168.14.1/32
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: traefik-svc
  namespace: metallb-system
spec:
  ipAddressPools:
    - traefik-svc
  interfaces:
    - ens7
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: traefik-admin
  namespace: metallb-system
spec:
  addresses:
    - 192.168.11.100/32
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: traefik-admin
  namespace: metallb-system
spec:
  ipAddressPools:
    - traefik-admin
  interfaces:
    - ens4
