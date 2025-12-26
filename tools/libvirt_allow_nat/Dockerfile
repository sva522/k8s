FROM alpine:3.22.2

# On alpine linux iptables is iptables-nft by default (see iptables --version)
RUN apk add --no-cache bash iproute2 iptables

WORKDIR /tmp
COPY libvirt_allow_nat.sh /usr/local/bin/libvirt_allow_nat.sh
RUN bash -n /usr/local/bin/libvirt_allow_nat.sh chmod +x /usr/local/bin/libvirt_allow_nat.sh
ENTRYPOINT ["/usr/local/bin/libvirt_allow_nat.sh"]
