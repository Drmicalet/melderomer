#!/bin/sh
# entrypoint-melderomer.sh — POSIX sh (compatible Alpine + Arch)
# Inicia honeytrap en foreground amb la config multiprotocol (13 protocols)
set -eu

CONFIG="${MELDEROMER_CONFIG:-/opt/melderomer/config/config.toml}"
DATA="${MELDEROMER_DATA:-/opt/melderomer/data}"
LOG="${MELDEROMER_LOG:-/opt/melderomer/log}"

mkdir -p "$DATA" "$LOG"

echo "[melderomer] Iniciant honeytrap multiprotocol (13 protocols)"
echo "[melderomer] Config: $CONFIG"
echo "[melderomer] Data:   $DATA"
echo "[melderomer] Log:    $LOG"
echo "[melderomer] Ports:  21(FTP) 25(SMTP) 445(SMB) 2222(SSH) 2223(Telnet)"
echo "[melderomer]         3389(RDP) 5900(VNC) 6379(Redis) 8080(Web)"
echo "[melderomer]         8888(HTTP) 9201(ES) 11211(Memcached) 27017(MongoDB)"

exec /opt/melderomer/bin/honeytrap \
    --config "$CONFIG" \
    --data "$DATA"
