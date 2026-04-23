#!/bin/bash
# ============================================================
# 08-melderomer-deploy.sh v5.0
# Build + Save + Import + Deploy — Honeytrap en Arch Linux
# Ejecutar en 192.168.1.247 (CachyOS, K3s master)
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

IMAGE_NAME="melderomer"
IMAGE_TAG="5.0"
IMAGE_FULL="${IMAGE_NAME}:${IMAGE_TAG}"
TAR_FILE="${IMAGE_NAME}-${IMAGE_TAG}.tar"
CONTAINERFILE="Containerfile.melderomer"
K8S_MANIFEST="melderomer-k8s.yaml"
NAMESPACE="mlai"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN} melderomer v5.0 — Deploy${NC}"
echo -e "${GREEN} Honeytrap (Go) on Arch Linux${NC}"
echo -e "${GREEN}============================================${NC}"

# ----------------------------------------------------------
# 1. LIMPIEZA
# ----------------------------------------------------------
echo -e "${YELLOW}[1/5] Cleaning old builds...${NC}"
rm -f "${TAR_FILE}"
podman rm -f "${IMAGE_NAME}-build" 2>/dev/null || true
podman rmi -f "localhost/${IMAGE_FULL}" 2>/dev/null || true
echo "  Clean."

# ----------------------------------------------------------
# 2. BUILD (podman con --network=host para pacman/git)
# ----------------------------------------------------------
echo -e "${YELLOW}[2/5] Building image (this takes a while)...${NC}"
podman build \
    --no-cache \
    --network=host \
    -t "localhost/${IMAGE_FULL}" \
    -f "${CONTAINERFILE}" \
    --label "version=${IMAGE_TAG}" \
    . 2>&1 | tee build.log

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo -e "${RED}[FAIL] Build failed. Check build.log${NC}"
    exit 1
fi
echo -e "${GREEN}  Build OK.${NC}"

# ----------------------------------------------------------
# 3. SAVE (docker-archive para importar en containerd)
# ----------------------------------------------------------
echo -e "${YELLOW}[3/5] Saving image...${NC}"
podman save "localhost/${IMAGE_FULL}" -o "${TAR_FILE}" 2>&1
TAR_SIZE=$(du -h "${TAR_FILE}" | cut -f1)
echo -e "${GREEN}  Saved: ${TAR_FILE} (${TAR_SIZE})${NC}"

# ----------------------------------------------------------
# 4. IMPORT a K3s containerd
# ----------------------------------------------------------
echo -e "${YELLOW}[4/5] Importing to K3s containerd...${NC}"
sudo k3s ctr images import "${TAR_FILE}" 2>&1
echo -e "${GREEN}  Imported.${NC}"

# ----------------------------------------------------------
# 5. DEPLOY
# ----------------------------------------------------------
echo -e "${YELLOW}[5/5] Deploying to K3s...${NC}"

# Crear namespace si no existe
kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1 || \
    kubectl create namespace "${NAMESPACE}"

# Crear PVC si no existe
kubectl get pvc -n "${NAMESPACE}" melderomer-data >/dev/null 2>&1 || {
    echo "  Creating PVC melderomer-data..."
    # El PVC ya está definido en melderomer-k8s.yaml, pero si existe el
    # storageclass local-path, se creará automáticamente con kubectl apply
}

kubectl apply -f "${K8S_MANIFEST}" 2>&1

# Esperar a que el pod arranque
echo "  Waiting for pod to start (60s timeout)..."
kubectl wait --for=condition=Ready pod -l app=melderomer -n "${NAMESPACE}" --timeout=60s 2>&1 || {
    echo -e "${YELLOW}[WARN] Pod not Ready yet. Check status:${NC}"
    kubectl get pods -n "${NAMESPACE}" -l app=melderomer
    echo ""
    echo "  Logs:"
    kubectl logs -n "${NAMESPACE}" -l app=melderomer --tail=30 2>&1 || true
}

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN} DEPLOY COMPLETE${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "  SSH:    192.168.1.247:30222"
echo "  Telnet: 192.168.1.247:30223"
echo "  HTTP:   192.168.1.247:30888"
echo ""
echo "  Check:  kubectl logs -n mlai -l app=melderomer -f"
echo "  Status: kubectl get pods -n mlai -l app=melderomer"
