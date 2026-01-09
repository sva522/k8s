FROM alpine:3.23.2

# Install dnsmasq
RUN apk add --no-cache dnsmasq

COPY rsc/hostname     /etc/hostname
COPY rsc/hosts        /etc/hosts
# Can be override on launch with -v ./dnsmasq.conf:/etc/dnsmasq.conf:ro
COPY rsc/dnsmasq.conf /etc/dnsmasq.conf
COPY rsc/log.sh       /opt/log.sh
COPY rsc/launch.sh    /opt/launch.sh

# Expose DNS and DHCP ports
EXPOSE 53/tcp 53/udp 67/udp

# Run dnsmasq in foreground (no daemon mode)
ENTRYPOINT ["/opt/launch.sh"]
