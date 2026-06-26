#!/usr/bin/env bash
# PROMPT 04 — Install OpenClaw + generate .env (idempotent).
# Secrets are passed at RUNTIME via env vars, never hardcoded in the repo.
#
# Run from repo root, supplying the Telegram secrets inline:
#   TELEGRAM_BOT_TOKEN=123:ABC \
#   TELEGRAM_ALLOWED_USER_IDS=6302853216 \
#   bash scripts/04-install-openclaw.sh
#
# Re-running is safe: it won't overwrite an existing .env unless FORCE=1.

set -euo pipefail

log()  { printf '\n\033[1;36m[04]\033[0m %s\n' "$*"; }
ok()   { printf '  \033[1;32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[1;33m!\033[0m %s\n' "$*"; }
die()  { printf '  \033[1;31m✗\033[0m %s\n' "$*"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$ROOT/.env"

# Load nvm so npm -g works without sudo (installed in step 00).
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" || true
command -v npm >/dev/null 2>&1 || die "npm not found — run step 00 first (nvm/node)."

# 1. Install OpenClaw globally (skip if present) ------------------------------
if command -v openclaw >/dev/null 2>&1; then
  ok "openclaw already installed ($(openclaw --version 2>/dev/null || echo '?'))"
else
  log "Installing openclaw globally…"
  npm install -g openclaw
  ok "openclaw installed ($(openclaw --version 2>/dev/null || echo '?'))"
fi

# 2. Generate .env ------------------------------------------------------------
: "${TELEGRAM_BOT_TOKEN:?set TELEGRAM_BOT_TOKEN=... when running this script}"
: "${TELEGRAM_ALLOWED_USER_IDS:?set TELEGRAM_ALLOWED_USER_IDS=... when running this script}"

# Overridable, with sane defaults matching the rest of the project.
OPENAI_API_BASE="${OPENAI_API_BASE:-http://localhost:20138/v1}"
OPENAI_API_KEY="${OPENAI_API_KEY:-9router_local_secret}"
OPENAI_MODEL="${OPENAI_MODEL:-combo-coding}"

if [ -f "$ENV_FILE" ] && [ "${FORCE:-0}" != "1" ]; then
  warn ".env already exists — leaving it untouched (re-run with FORCE=1 to overwrite)."
else
  log "Writing $ENV_FILE …"
  cat > "$ENV_FILE" <<EOF
# --- ROUTING THROUGH 9ROUTER ---
OPENAI_API_BASE=$OPENAI_API_BASE
OPENAI_API_KEY=$OPENAI_API_KEY
OPENAI_MODEL=$OPENAI_MODEL

# --- SECURITY & TELEGRAM CHANNEL ---
TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN
TELEGRAM_ALLOWED_USER_IDS=$TELEGRAM_ALLOWED_USER_IDS

# --- LINUX TERMINAL EXECUTION PERMISSION ---
WORKSPACE_DIR=./workspace
ENABLE_TERMINAL_EXECUTION=true
EXECUTION_MODE=docker
EOF
  ok ".env written"
fi

chmod 600 "$ENV_FILE"
ok ".env locked to mode 600"

# 3. Verify -------------------------------------------------------------------
log "Verify (Definition of Done):"
openclaw --version >/dev/null 2>&1 && ok "openclaw --version works" || warn "openclaw --version failed"
if grep -q '<.*>' "$ENV_FILE"; then
  die ".env still has <placeholder> values — check inputs."
else
  ok ".env has no leftover placeholders"
fi
grep -qx ".env" "$ROOT/.gitignore" && ok ".env is gitignored" || warn ".env NOT in .gitignore!"

log "Done. Next: step 05 (bootloader + smoke test)."
