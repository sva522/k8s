FROM alpine:3.22.2

RUN apk add --no-cache bash iproute2 nftables

WORKDIR /tmp
COPY tapctl.sh /usr/local/bin/tapctl.sh
RUN bash -n /usr/local/bin/tapctl.sh chmod +x /usr/local/bin/tapctl.sh
ENTRYPOINT ["/usr/local/bin/tapctl.sh"]
