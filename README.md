# melderomer

> **Base image:** `ghcr.io/drmicalet/xx-xinoxano:latest`
> **Image:** `ghcr.io/drmicalet/melderomer:latest`
> **Port(s):** 21, 25, 445, 2222, 2223, 3389, 5900, 6379, 8080, 8888, 9201, 11211, 27017
> **License:** LGPL-3.0

---

## Overview

### English

Multi-protocol honeypot (FTP, SMTP, SMB, SSH, Telnet, RDP, VNC, Redis, HTTP, MongoDB, Memcached). Logs all attacker activity for analysis. Based on Arch Linux with custom honeypot implementations. Companion to xx-melderomer-logs (fluent-bit collector).

### Castellano

Honeypot multi-protocolo (FTP, SMTP, SMB, SSH, Telnet, RDP, VNC, Redis, HTTP, MongoDB, Memcached). Registra toda la actividad de atacantes para análisis. Basado en Arch Linux con implementaciones custom de honeypot. Compañero de xx-melderomer-logs (collector fluent-bit).

### Català

Honeypot multi-protocol (FTP, SMTP, SMB, SSH, Telnet, RDP, VNC, Redis, HTTP, MongoDB, Memcached). Registra tota l'activitat d'atacants per a anàlisi. Basat en Arch Linux amb implementacions custom de honeypot. Company de xx-melderomer-logs (collector fluent-bit).

---

## Pull

```bash
podman pull ghcr.io/drmicalet/melderomer:latest
# or
docker pull ghcr.io/drmicalet/melderomer:latest
```

## Run

### Podman

```bash
podman run -d \
  --name melderomer \
  ghcr.io/drmicalet/melderomer:latest
```

### Docker

```bash
docker run -d \
  --name melderomer \
  ghcr.io/drmicalet/melderomer:latest
```

### Kubernetes / K3s

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: melderomer
spec:
  containers:
  - name: melderomer
    image: ghcr.io/drmicalet/melderomer:latest
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 8080
```

---

### Files in this repo

| File | Purpose |
|------|---------|
| `Containerfile` | Docker/Podman build definition |
| `entrypoint.sh` | Bash entrypoint script (ENTRYPOINT) |
| `README.md` | This document |
| `LICENSE` | LGPL-3.0 license |
| `.gitignore` | Git ignore rules |

---

## Entrypoint

The container uses `entrypoint.sh` (bash pattern) as ENTRYPOINT, NOT direct binary invocation with `/usr/bin/tini`. This pattern:
- Verifies dependencies before starting
- Uses `case $1 in` for subcommands
- Ends with `exec` to make the main process PID 1

```dockerfile
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["serve"]
```

---

## Build from source

```bash
git clone https://github.com/Drmicalet/melderomer.git
cd melderomer
podman build --network host -t ghcr.io/drmicalet/melderomer:latest -f Containerfile .
```

---

## License

LGPL-3.0 — same as Arch Linux packages.

## Author

drmicalet — https://github.com/Drmicalet
