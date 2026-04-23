#!/bin/bash
# ============================================================
# 09-melderomer-github.sh
# Upload README + repo files to https://github.com/Drmicalet/melderomer
# ============================================================
set -euo pipefail

REPO_DIR="/casa/0dias/Abril/g03mlai-k3s-v9-melderomer"
REPO_NAME="melderomer"
GH_USER="Drmicalet"
GH_URL="https://github.com/${GH_USER}/${REPO_NAME}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN} melderomer - GitHub Upload${NC}"
echo -e "${GREEN}============================================${NC}"

# 1. Check gh
echo -e "${YELLOW}[1/4] Checking gh CLI...${NC}"
if ! command -v gh &>/dev/null; then
    echo -e "${RED}[ERROR] gh not found. pacman -S github-cli${NC}"
    exit 1
fi

# 2. Auth (skip if GITHUB_TOKEN is set)
echo -e "${YELLOW}[2/4] Auth...${NC}"
if [ -z "${GITHUB_TOKEN:-}" ] && ! gh auth status &>/dev/null; then
    gh auth login
fi
echo -e "${GREEN}  OK${NC}"

# 3. Fix files + setup git
echo -e "${YELLOW}[3/4] Preparing repo...${NC}"
cd "$REPO_DIR"

# Clean build artifacts
rm -f *.tar *.zip build.log melderomer-installer.sh 2>/dev/null
rm -f 08-melderomer.sh 09-diagnose.sh 10-fix.sh 2>/dev/null
rm -f cowrie.cfg requirements-melderomer.txt userdb.txt 2>/dev/null
rm -f deployment-melderomer.yaml melderomer-v4.3.tar melderomer-v4.zip 2>/dev/null

# Fix Containerfile: remove mlai label
sed -i '/LABEL maintainer="mlai/d' Containerfile.melderomer 2>/dev/null || true

# .gitignore
cat > .gitignore << 'GIEOF'
*.tar
*.zip
build.log
*.swp
GIEOF

# safe.directory
git config --global --add safe.directory "$REPO_DIR" 2>/dev/null || true

# Git init
if [ ! -d .git ]; then
    git init -b main
else
    git branch -m main 2>/dev/null || true
fi

echo -e "${GREEN}  Ready${NC}"

# 4. Commit + push
echo -e "${YELLOW}[4/4] Pushing to GitHub...${NC}"
cd "$REPO_DIR"

git add -A
git commit -m "melderomer v5.0 - Arch Linux Honeytrap honeypot (Go)

- Honeytrap static binary on Arch Linux
- SSH simulator, Telnet, HTTP logging
- K3s deployment manifests" \
    || echo "  (nothing new to commit)"

gh repo create "${GH_USER}/${REPO_NAME}" \
    --public \
    --description "melderomer - Arch Linux Honeytrap honeypot (Go) on K3s" \
    --source "$REPO_DIR" \
    --push \
    2>&1 || {
    echo -e "${YELLOW}  Repo exists, pushing...${NC}"
    git remote remove origin 2>/dev/null || true
    git remote add origin "https://github.com/${GH_USER}/${REPO_NAME}.git"
    git push -u origin main --force 2>&1
}

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN} DONE${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "  Repo:  ${GH_URL}"
echo "  Image: ghcr.io/drmicalet/melderomer:5.0"
echo ""
