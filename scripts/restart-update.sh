#!/usr/bin/env bash
# Restart + update the whole Core stack (9Router + OpenClaw) with the latest
# images and current .env / config. Idempotent. Data in the bind mounts
# (9router-data, openclaw-data) survives — only containers are recreated.
#
# Run from repo root:  bash scripts/restart-update.sh
#
# It reuses the per-service start scripts (which already pull, copy config,
# and health-check), so there is one source of truth per service.

set -euo pipefail

log()  { printf '\n\033[1;35m[restart]\033[0m %s\n' "$*"; }
ok()   { printf '  \033[1;32m✓\033[0m %s\n' "$*"; }
die()  { printf '  \033[1;31m✗\033[0m %s\n' "$*"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

[ -f "$ROOT/.env" ] || die ".env missing — run: TELEGRAM_BOT_TOKEN=... ROUTER9_API_KEY=... bash scripts/04-make-env.sh"

DC="docker compose"; docker compose version >/dev/null 2>&1 || DC="docker-compose"
OC_COMPOSE="$ROOT/core/openclaw/docker-compose.yml"

# 1. 9Router — the start script already pulls :latest + recreates + waits.
log "Updating 9Router…"
bash "$SCRIPT_DIR/01-start-9router.sh"

# 2. OpenClaw — bring it DOWN first so it re-reads .env on the way up, then
#    the start script pulls latest, re-copies config, and health-checks.
log "Recreating OpenClaw (so it re-reads .env + config)…"
$DC -f "$OC_COMPOSE" down
bash "$SCRIPT_DIR/04-start-openclaw.sh"

# 3. End-to-end sanity: can the container actually reach 9Router with the key?
log "Verifying OpenClaw → 9Router auth…"
status="$(docker exec claw-openclaw node -e \
  "fetch('http://host.docker.internal:20138/v1/models',{headers:{Authorization:'Bearer '+(process.env.ROUTER9_API_KEY||'')}}).then(r=>console.log(r.status)).catch(e=>console.log('ERR:'+e.message))" \
  2>/dev/null || echo "ERR")"
case "$status" in
  200) ok "OpenClaw can reach 9Router /v1/models (HTTP 200) — auth OK" ;;
  401|403) die "9Router rejected the key (HTTP $status) — check ROUTER9_API_KEY in .env" ;;
  *) printf '  \033[1;33m!\033[0m unexpected response: %s (check: docker logs claw-openclaw)\n' "$status" ;;
esac

log "Stack restarted on latest images. Running containers:"
docker ps --filter name=claw-9router --filter name=claw-openclaw \
  --format '  {{.Names}}  {{.Status}}  {{.Ports}}'

echo
ok "Done. DM your Telegram bot to confirm end-to-end."
