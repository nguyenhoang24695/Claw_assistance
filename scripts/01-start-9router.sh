#!/usr/bin/env bash
# PROMPT 01 — Start this project's DEDICATED 9Router instance (port 20138).
# Isolated from the existing `automation-agent-9router-1` (port 20128): own
# container name, own port, own data dir. That container is never touched.
# Idempotent: safe to re-run.
#
# Run from the repo root:  bash scripts/01-start-9router.sh

set -euo pipefail

log()  { printf '\n\033[1;36m[01]\033[0m %s\n' "$*"; }
ok()   { printf '  \033[1;32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[1;33m!\033[0m %s\n' "$*"; }
die()  { printf '  \033[1;31m✗\033[0m %s\n' "$*"; exit 1; }

# Resolve repo root from this script's location, so it works from anywhere.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COMPOSE="$ROOT/core/9router/docker-compose.yml"
PORT=20138
NAME=claw-9router

[ -f "$COMPOSE" ] || die "compose file not found: $COMPOSE (did you 'git pull'?)"

# Pick the compose command available on this host.
if docker compose version >/dev/null 2>&1; then
  DC="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  DC="docker-compose"
else
  die "neither 'docker compose' nor 'docker-compose' is available"
fi

# Guard: port already used by something OTHER than our own container?
if ss -ltn 2>/dev/null | grep -q ":$PORT "; then
  if docker ps --format '{{.Names}} {{.Ports}}' | grep -q "$NAME.*:$PORT->"; then
    ok "port $PORT already served by our own '$NAME' — fine"
  else
    die "port $PORT is in use by something else. Free it or change PORT in $COMPOSE (and the prompts)."
  fi
fi

log "Starting '$NAME' on port $PORT…"
$DC -f "$COMPOSE" up -d

log "Container status:"
docker ps --filter "name=$NAME" --format '  {{.Names}}  {{.Status}}  {{.Ports}}'

# Wait for the dashboard to answer (up to ~30s).
log "Waiting for dashboard at http://localhost:$PORT …"
code=000
for _ in $(seq 1 30); do
  code="$(curl -sS -o /dev/null -w '%{http_code}' "http://localhost:$PORT" 2>/dev/null || echo 000)"
  case "$code" in 2*|3*) break;; esac
  sleep 1
done
case "$code" in
  2*|3*) ok "9Router responding (HTTP $code) at http://localhost:$PORT" ;;
  *)     warn "no healthy HTTP response yet (last: $code). Check: docker logs $NAME --tail 50" ;;
esac

# Confirm the other instance is untouched (informational).
if docker ps --format '{{.Names}}' | grep -qx automation-agent-9router-1; then
  ok "existing 'automation-agent-9router-1' still running (untouched)"
fi

log "Done. Next: open http://<server-ip>:$PORT → add Providers + create combos."
echo "  Endpoint for later steps:  http://localhost:$PORT/v1"
