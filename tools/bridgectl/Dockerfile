FROM alpine:3.22.2

RUN apk add --no-cache bash iproute2 nftables

WORKDIR /tmp
COPY bridgectl.sh /usr/local/bin/bridgectl.sh
RUN bash -n /usr/local/bin/bridgectl.sh && chmod +x /usr/local/bin/bridgectl.sh
ENTRYPOINT ["/usr/local/bin/bridgectl.sh"]
