#!/usr/bin/env bash
# Generate .env (gitignored) for the OpenClaw container. Secrets at runtime only.
#   TELEGRAM_BOT_TOKEN=123:ABC bash scripts/04-make-env.sh
# A random OPENCLAW_GATEWAY_TOKEN is generated if not supplied (the gateway
# refuses to bind in a container without auth).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$ROOT/.env"
: "${TELEGRAM_BOT_TOKEN:?set TELEGRAM_BOT_TOKEN=... when running this script}"
: "${ROUTER9_API_KEY:?set ROUTER9_API_KEY=... (the 9Router access key) when running this script}"

if [ -f "$ENV_FILE" ] && [ "${FORCE:-0}" != "1" ]; then
  echo "  ! .env exists — re-run with FORCE=1 to overwrite"; exit 0
fi

GW_TOKEN="${OPENCLAW_GATEWAY_TOKEN:-$(openssl rand -hex 24)}"
cat > "$ENV_FILE" <<EOF
# OpenClaw container secrets (gitignored). LLM/Telegram routing lives in
# core/openclaw/config/openclaw.json5 — these two are the runtime secrets.
TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN
OPENCLAW_GATEWAY_TOKEN=$GW_TOKEN
ROUTER9_API_KEY=$ROUTER9_API_KEY
EOF
chmod 600 "$ENV_FILE"
echo "  ✓ wrote $ENV_FILE (mode 600)"
echo "  ✓ gateway token (paste into Control UI Settings later):"
echo "      $GW_TOKEN"
