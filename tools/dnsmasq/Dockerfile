FROM alpine:3.23.2

# Install dnsmasq
RUN apk add --no-cache dnsmasq

COPY hostname /etc/hostname
COPY hosts    /etc/hosts
# Can be override on launch with -v ./dnsmasq.conf:/etc/dnsmasq.conf:ro
COPY dnsmasq.conf /etc/dnsmasq.conf
COPY log.sh /opt/log.sh

# Expose DNS and DHCP ports
EXPOSE 53/tcp 53/udp 67/udp

# Run dnsmasq in foreground (no daemon mode)
ENTRYPOINT ["/usr/sbin/dnsmasq", "--no-daemon"]
