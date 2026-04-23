#!/bin/bash
set -e
HONEYTRAP_HOME="/opt/melderomer"
mkdir -p ${HONEYTRAP_HOME}/{data,log}
chown -R 1000:1000 ${HONEYTRAP_HOME}/{data,log,config} 2>/dev/null || true
echo "=========================================="
echo " melderomer v5.0 - Arch Linux Honeytrap"
echo " Honeypot (Go) - Sin Python"
echo "=========================================="
echo "SSH    :2222 (simulator)"
echo "Telnet :2223"
echo "HTTP   :8888"
echo "Logs   : stdout + /opt/melderomer/log/"
echo "=========================================="
exec ${HONEYTRAP_HOME}/bin/honeytrap "$@"
