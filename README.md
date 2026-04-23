# melderomer

> *Mel de romer* — a Catalan idiom meaning **"rosemary honey"**, but also **"the very best"**, **"the cream of the crop"**. The finest honey from wild rosemary in the Mediterranean hills. This honeypot aspires to be just that: the sweetest trap and the best of the best.

---

## What is it?

**melderomer** is a high-interaction honeypot built on [Honeytrap](https://github.com/honeytrap/honeytrap), compiled from source as a static Go binary on **Arch Linux**, and deployed to a **K3s** cluster. It emulates SSH, Telnet, and HTTP services to deceive attackers and capture their credentials, commands, and behavioral patterns.

A custom, from-scratch container image — not a repackaged upstream Docker image — with full control over the build chain from the base OS to the running binary.

## Quick Start

### Option A: Pull the pre-built image

The image is available on GitHub Container Registry:

**Podman:**
```bash
podman pull ghcr.io/drmicalet/melderomer:5.0
podman run -d --name melderomer -p 2222:2222 -p 2223:2223 -p 8888:8888 ghcr.io/drmicalet/melderomer:5.0
```

**K3s (import from tar):**
```bash
podman pull ghcr.io/drmicalet/melderomer:5.0
podman save ghcr.io/drmicalet/melderomer:5.0 -o melderomer-5.0.tar
sudo k3s ctr images import melderomer-5.0.tar
kubectl apply -f melderomer-k8s.yaml
```

### Option B: Build from source

```bash
git clone https://github.com/Drmicalet/melderomer.git
cd melderomer
chmod +x 08-melderomer-deploy.sh
./08-melderomer-deploy.sh
```

Handles: `podman build` then `podman save` then `k3s ctr images import` then `kubectl apply`

## Architecture

```
                    Internet
                       |
                       v
              +------------------+
              |   K3s Cluster    |
              +--------+---------+
                       |
           +-----------+-----------+
           v           v           v
     NodePort     NodePort     NodePort
     :30222       :30223       :30888
     SSH          Telnet       HTTP
           |           |           |
           v           v           v
    +-------------------------------+
    |  melderomer container        |
    |  +-------------------------+  |
    |  | Honeytrap (Go static)   |  |
    |  | Zero runtime deps       |  |
    |  +-------------------------+  |
    |  Arch Linux base image       |
    +-------------------------------+
```

## Services

| Service | Container Port | NodePort | Emulation |
|---------|---------------|----------|-----------|
| SSH Simulator | 2222 | 30222 | Ubuntu 16.04.1 LTS, credential harvesting |
| Telnet | 2223 | 30223 | Huawei network switch banner |
| HTTP | 8888 | 30888 | Web server, request logging |

## What it captures

- Source/destination IP and port, timestamp (UTC)
- Usernames, passwords, SSH keys, HTTP headers, URLs
- Session IDs, sensor IDs for multi-deployment correlation

```
services > ssh > ssh.username=root, ssh.password=admin, type=password-authentication
```

## Configuration

```toml
[service.ssh]
type = "ssh-simulator"
credentials = ["root:root", "admin:password", ...]

[channel.file]
type = "file"
filename = "/opt/melderomer/log/melderomer.json"
```

## Files

```
Containerfile.melderomer   - Build definition (Go on Arch)
config.toml                 - Honeytrap service configuration
entrypoint-melderomer.sh    - Container entrypoint
melderomer-k8s.yaml         - K8s manifests (Deployment, Services, ConfigMap, PVC)
08-melderomer-deploy.sh     - Build + deploy pipeline
```

## License

[Honeytrap](https://github.com/honeytrap/honeytrap) (Apache 2.0). Custom config and build scripts provided as-is.
