#!/usr/bin/env bash
# PROMPT 00 — Prerequisites (Ubuntu) — idempotent, non-destructive.
# Server already runs Docker + other projects: this script NEVER reinstalls or
# restarts an existing Docker, never touches firewall/ports. It only installs
# what is missing and verifies the Definition of Done.
#
# Usage (on the server):
#   bash 00-prerequisites-ubuntu.sh
# It will ask for the sudo password ONCE (via `sudo -v`) if anything needs sudo.

set -euo pipefail

log()  { printf '\n\033[1;36m[00]\033[0m %s\n' "$*"; }
ok()   { printf '  \033[1;32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[1;33m!\033[0m %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

# Cache sudo creds up front only if we actually need sudo this run.
need_sudo=0
have git || need_sudo=1
have docker || need_sudo=1
if [ "$need_sudo" = 1 ]; then
  log "Some packages are missing — caching sudo (password asked once)…"
  sudo -v
fi

# 1. git + build essentials ---------------------------------------------------
if have git && dpkg -s build-essential >/dev/null 2>&1; then
  ok "git + build-essential already present ($(git --version))"
else
  log "Installing git, curl, build-essential…"
  sudo apt update
  sudo apt install -y git curl build-essential
  ok "installed git + build tools"
fi

# 2. Node.js 18+ via nvm -------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
load_nvm() { [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; }

node_major() { have node && node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0; }

if [ "$(node_major)" -ge 18 ] 2>/dev/null; then
  ok "Node $(node --version) already satisfies >=18"
else
  if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    log "Installing nvm…"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  fi
  load_nvm
  log "Installing Node LTS via nvm…"
  nvm install --lts
  nvm alias default 'lts/*' >/dev/null 2>&1 || true
  ok "Node $(node --version) installed"
fi
load_nvm || true

# 3. Docker — DO NOT reinstall/restart if already there -----------------------
if have docker; then
  ok "Docker already installed ($(docker --version)) — leaving it untouched"
else
  log "Docker not found — installing docker.io + compose plugin…"
  sudo apt install -y docker.io docker-compose-plugin
  sudo systemctl enable --now docker
  ok "Docker installed and enabled"
fi

# 4. docker group (run without sudo) — only if not already a member -----------
if id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
  ok "$USER already in 'docker' group"
else
  log "Adding $USER to 'docker' group…"
  sudo usermod -aG docker "$USER"
  warn "Group change needs a NEW login session. Run 'newgrp docker' or re-SSH, then re-run verify."
fi

# 5. Port awareness (server runs other projects) ------------------------------
# Prompt 00 binds nothing, but later steps need these. Report what's taken now.
log "Checking ports needed by later steps (informational only)…"
check_port() {
  local p="$1" label="$2"
  if have ss && ss -ltn 2>/dev/null | grep -q ":$p "; then
    warn "port $p ($label) is ALREADY IN USE — pick another in the relevant step"
  else
    ok "port $p ($label) is free"
  fi
}
check_port 20138 "9Router dashboard"

# --- Definition of Done ------------------------------------------------------
log "Verify (Definition of Done):"
git --version
node --version
npm --version
if docker run --rm hello-world >/dev/null 2>&1; then
  ok "docker run hello-world OK (no sudo)"
else
  warn "docker run hello-world failed without sudo."
  warn "→ likely the 'docker' group hasn't applied to this session yet."
  warn "  Fix: run 'newgrp docker' (or log out/in), then re-run this script."
  exit 1
fi

log "All prerequisites satisfied. ✅"
