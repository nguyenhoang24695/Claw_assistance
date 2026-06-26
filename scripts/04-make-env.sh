#!/usr/bin/env bash
# Generate .env (gitignored) for the OpenClaw container. Secrets at runtime only.
#   TELEGRAM_BOT_TOKEN=123:ABC bash scripts/04-make-env.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$ROOT/.env"
: "${TELEGRAM_BOT_TOKEN:?set TELEGRAM_BOT_TOKEN=... when running this script}"

if [ -f "$ENV_FILE" ] && [ "${FORCE:-0}" != "1" ]; then
  echo "  ! .env exists — re-run with FORCE=1 to overwrite"; exit 0
fi
cat > "$ENV_FILE" <<EOF
# OpenClaw container secrets (gitignored). LLM/Telegram routing lives in
# core/openclaw/config/openclaw.json5 — only the bot token is a secret.
TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN
EOF
chmod 600 "$ENV_FILE"
echo "  ✓ wrote $ENV_FILE (mode 600)"
