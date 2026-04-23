#!/bin/bash
# ============================================================
# 09-melderomer-github.sh
# Upload README + container image to GitHub (Drmicalet)
# ============================================================
set -euo pipefail

REPO_DIR="/casa/0dias/Abril/g03mlai-k3s-v9-melderomer"
GH_USER="Drmicalet"
REPO_NAME="melderomer"
GHCR_IMAGE="ghcr.io/${GH_USER,,}/${REPO_NAME}:5.0"
LOCAL_IMAGE="localhost/melderomer:5.0"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN} melderomer - GitHub Upload${NC}"
echo -e "${GREEN}============================================${NC}"

# ----------------------------------------------------------
# 1. Verificar herramientas
# ----------------------------------------------------------
echo -e "${YELLOW}[1/6] Checking prerequisites...${NC}"
for cmd in gh podman kubectl; do
    if ! command -v $cmd &>/dev/null; then
        echo -e "${RED}[ERROR] $cmd not found${NC}"
        exit 1
    fi
done
echo -e "${GREEN}  gh, podman, kubectl: OK${NC}"

# ----------------------------------------------------------
# 2. Auth GitHub (saltar si GITHUB_TOKEN existe)
# ----------------------------------------------------------
echo -e "${YELLOW}[2/6] Checking GitHub auth...${NC}"
if [ -z "${GITHUB_TOKEN:-}" ] && ! gh auth status &>/dev/null; then
    echo -e "${YELLOW}  Run: gh auth login${NC}"
    gh auth login
fi
echo -e "${GREEN}  Authenticated as: $(gh auth status 2>&1 | head -1)${NC}"

# ----------------------------------------------------------
# 3. Auth GitHub Container Registry
# ----------------------------------------------------------
echo -e "${YELLOW}[3/6] Checking GitHub Container Registry auth...${NC}"
GHCR_USER="${GH_USER,,}"
if ! podman login ghcr.io --get-login 2>/dev/null | grep -q "$GHCR_USER"; then
    echo -e "${YELLOW}  Need a GitHub Personal Access Token (PAT) with write:packages${NC}"
    echo -e "${YELLOW}  Create one at: https://github.com/settings/tokens${NC}"
    echo -e "${YELLOW}  Select scopes: write:packages, read:packages${NC}"
    echo ""
    read -rp "  Paste your GitHub PAT: " GH_TOKEN
    echo "$GH_TOKEN" | podman login ghcr.io -u "$GHCR_USER" --password-stdin
else
    echo -e "${GREEN}  ghcr.io: logged in as $GHCR_USER${NC}"
fi

# ----------------------------------------------------------
# 4. Tag + Push container image to ghcr.io
# ----------------------------------------------------------
echo -e "${YELLOW}[4/6] Pushing container image to ghcr.io...${NC}"
podman tag "$LOCAL_IMAGE" "$GHCR_IMAGE" 2>/dev/null || true
podman push "$GHCR_IMAGE" 2>&1
echo -e "${GREEN}  Image pushed: ${GHCR_IMAGE}${NC}"

# ----------------------------------------------------------
# 5. Limpiar + preparar repo
# ----------------------------------------------------------
echo -e "${YELLOW}[5/6] Preparing repo files...${NC}"
cd "$REPO_DIR"

# Limpiar artefactos de build (NO borrar este script)
rm -f *.tar *.zip build.log melderomer-installer.sh 2>/dev/null
rm -f 08-melderomer.sh 09-diagnose.sh 10-fix.sh 2>/dev/null
rm -f cowrie.cfg requirements-melderomer.txt userdb.txt 2>/dev/null
rm -f deployment-melderomer.yaml melderomer-v4.3.tar melderomer-v4.zip 2>/dev/null

# .gitignore
cat > .gitignore << 'EOF'
*.tar
*.zip
build.log
.DS_Store
*.swp
.vscode/
.idea/
EOF

# safe.directory
git config --global --add safe.directory "$REPO_DIR" 2>/dev/null || true

# Git init
if [ ! -d .git ]; then
    git init
    git checkout -b main
else
    git branch -m main 2>/dev/null || true
fi

echo -e "${GREEN}  Ready: $(ls -1 *.sh *.yaml *.toml README.md .gitignore 2>/dev/null | tr '\n' ' ')${NC}"

# ----------------------------------------------------------
# 6. Commit + Create repo + Push
# ----------------------------------------------------------
echo -e "${YELLOW}[6/6] Pushing to GitHub...${NC}"

cd "$REPO_DIR"
git add -A
git commit -m "melderomer v5.0 - Arch Linux Honeytrap honeypot (Go)

- Honeytrap compiled from source as static Go binary on Arch Linux
- SSH simulator (Ubuntu 16.04), Telnet (Huawei), HTTP logging
- K3s deployment with ConfigMap, PVC, NodePort services
- Container image on ghcr.io
- Zero runtime dependencies" || echo "  (nothing new to commit)"

gh repo create "${GH_USER}/${REPO_NAME}" \
    --public \
    --description "melderomer - Arch Linux Honeytrap honeypot (Go) on K3s" \
    --source "$REPO_DIR" \
    --push 2>&1 || {
    echo "  Repo exists, pushing..."
    git remote remove origin 2>/dev/null || true
    git remote add origin "https://github.com/${GH_USER}/${REPO_NAME}.git"
    git push -u origin main --force 2>&1
}

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN} UPLOAD COMPLETE${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "  Repo:  ${GREEN}https://github.com/${GH_USER}/${REPO_NAME}${NC}"
echo -e "  Image: ${GREEN}${GHCR_IMAGE}${NC}"
echo ""
echo "  Pull image:  podman pull ${GHCR_IMAGE}"
echo "  View repo:   gh repo view ${GH_USER}/${REPO_NAME}"
