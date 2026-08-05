FROM alpine:3.20
LABEL description="melderomer — Multiprotocol honeypot (Alpine + honeytrap, 13 protocols)"
LABEL version="v181" maintainer="drmicalet"

# v181: KEEP Alpine (data container — build from source, small footprint)
# Multi-protocol honeypot using honeytrap 5.x
# Ports: 21(FTP) 25(SMTP) 445(SMB) 2222(SSH) 2223(Telnet)
#        3389(RDP) 5900(VNC) 6379(Redis) 8080(Web)
#        8888(HTTP) 9201(ES) 11211(Memcached) 27017(MongoDB)

# Build honeytrap from source, strip, copy binary, clean toolchain
RUN apk add --no-cache git go gcc make ca-certificates tini && \
    mkdir -p /opt/melderomer/bin /opt/melderomer/config /opt/melderomer/data /opt/melderomer/log && \
    git clone --depth 1 https://github.com/honeytrap/honeytrap.git /casa/tmp/ht && \
    cd /casa/tmp/ht && \
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo \
        -ldflags="-s -w -X main.version=5.0-multiprotocol-v181" \
        -o /casa/tmp/ht-bin . && \
    strip /casa/tmp/ht-bin && \
    cp /casa/tmp/ht-bin /opt/melderomer/bin/honeytrap && \
    chmod +x /opt/melderomer/bin/honeytrap && \
    apk del go gcc make && \
    rm -rf /casa/tmp/ht /casa/tmp/ht-bin /var/cache/apk/* /root/.cache/go-build /home/builder/.cache/go-build

COPY config-melderomer.toml /opt/melderomer/config/config.toml
COPY entrypoint-melderomer.sh /opt/melderomer/entrypoint.sh
RUN chmod +x /opt/melderomer/entrypoint.sh

WORKDIR /opt/melderomer

EXPOSE 21 25 445 2222 2223 3389 5900 6379 8080 8888 9201 11211 27017

VOLUME ["/opt/melderomer/data", "/opt/melderomer/log"]

# v181: HEALTHCHECK — honeytrap process running (busybox pgrep)
HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
    CMD pgrep -x honeytrap >/dev/null 2>&1 || exit 1

ENTRYPOINT ["/opt/melderomer/entrypoint.sh"]
CMD ["--config", "config/config.toml", "--data", "data"]
