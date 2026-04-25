FROM alpine:latest

WORKDIR /root

RUN apk --no-cache add curl jq bash
SHELL ["/bin/bash", "-c"]

COPY dns-sync.sh /root/dns-sync.sh
RUN chmod +x /root/dns-sync.sh

RUN echo "* * * * * /root/dns-sync.sh >> /proc/1/fd/1 2>&1" >> /etc/crontabs/root

# dns.config must be mounted at /root/dns.config at runtime (contains secrets).
CMD ["/bin/bash", "-c", "/root/dns-sync.sh && crond -f -l 2"]
