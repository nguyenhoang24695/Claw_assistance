#!/usr/bin/env bash
# PROMPT 04 (Docker) — Start the OpenClaw gateway, wired to our 9Router.
# Replaces the old npm/.env/bootloader approach. Idempotent.
#
# Prereqs: .env exists at repo root with at least TELEGRAM_BOT_TOKEN
# (generate it via scripts/04-make-env.sh). 9Router (step 01) must be running.
#
# Run from repo root:  bash scripts/04-start-openclaw.sh

set -euo pipefail

log()  { printf '\n\033[1;36m[04]\033[0m %s\n' "$*"; }
ok()   { printf '  \033[1;32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[1;33m!\033[0m %s\n' "$*"; }
die()  { printf '  \033[1;31m✗\033[0m %s\n' "$*"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OC="$ROOT/core/openclaw"
COMPOSE="$OC/docker-compose.yml"
PORT=18789

[ -f "$COMPOSE" ] || die "compose not found: $COMPOSE (git pull?)"
[ -f "$ROOT/.env" ] || die ".env missing — run: bash scripts/04-make-env.sh"
grep -q '^TELEGRAM_BOT_TOKEN=.\+' "$ROOT/.env" || die "TELEGRAM_BOT_TOKEN empty in .env"

DC="docker compose"; docker compose version >/dev/null 2>&1 || DC="docker-compose"

# Port guard (server runs other projects).
if ss -ltn 2>/dev/null | grep -q ":$PORT "; then
  docker ps --format '{{.Names}} {{.Ports}}' | grep -q "claw-openclaw.*:$PORT->" \
    && ok "port $PORT already served by our own claw-openclaw" \
    || die "port $PORT in use by something else — change it in $COMPOSE"
fi

# Prep bind-mount dirs and drop our config in. Container runs as uid 1000.
log "Preparing data dirs + config…"
mkdir -p "$OC/openclaw-data/config" "$OC/openclaw-data/secrets" "$OC/openclaw-data/config/workspace"
cp "$OC/config/openclaw.json5" "$OC/openclaw-data/config/openclaw.json5"
# Workspace bootstrap files (SOUL/AGENTS/USER...) — source of truth in repo,
# copied into the mounted workspace. -n: don't clobber agent-edited files (memory, skills).
if [ -d "$OC/workspace" ]; then
  cp -rn "$OC/workspace/." "$OC/openclaw-data/config/workspace/" 2>/dev/null || true
  cp "$OC/workspace/"*.md "$OC/openclaw-data/config/workspace/" 2>/dev/null || true  # always refresh top-level docs
  ok "workspace bootstrap files synced"
fi
sudo chown -R 1000:1000 "$OC/openclaw-data" 2>/dev/null \
  && ok "data dirs owned by uid 1000" \
  || warn "could not chown to 1000:1000 (may cause permission warnings)"

# Docker-out-of-Docker wiring: the compose file mounts the host docker socket +
# CLI into the container so Cua can spawn sibling containers. Both values are
# host-specific, so resolve them here and export for compose interpolation.
DOCKER_BIN="$(command -v docker || echo /usr/bin/docker)"
# GID that owns the docker socket — this is what the container must join.
if [ -S /var/run/docker.sock ]; then
  DOCKER_GID="$(stat -c '%g' /var/run/docker.sock 2>/dev/null || echo 999)"
else
  DOCKER_GID="$(getent group docker | cut -d: -f3 2>/dev/null || echo 999)"
  warn "/var/run/docker.sock not found — using docker group GID $DOCKER_GID"
fi
export DOCKER_BIN DOCKER_GID
ok "DooD wiring: DOCKER_BIN=$DOCKER_BIN  DOCKER_GID=$DOCKER_GID"

log "Pulling image + starting gateway…"
$DC -f "$COMPOSE" pull openclaw-gateway
$DC -f "$COMPOSE" up -d openclaw-gateway

log "Container status:"
docker ps --filter "name=claw-openclaw" --format '  {{.Names}}  {{.Status}}  {{.Ports}}'

log "Waiting for gateway health at :$PORT …"
code=000
for _ in $(seq 1 60); do
  code="$(curl -sS -o /dev/null -w '%{http_code}' "http://localhost:$PORT/healthz" 2>/dev/null || echo 000)"
  case "$code" in 2*) break;; esac
  sleep 1
done
case "$code" in
  2*) ok "gateway healthy (HTTP $code)" ;;
  *)  warn "no healthy response yet ($code). Check: docker logs claw-openclaw --tail 60" ;;
esac

# Verify Docker-out-of-Docker actually works from inside the container.
log "Verifying DooD (docker access from inside the container)…"
if docker exec claw-openclaw docker version --format '{{.Server.Version}}' >/dev/null 2>&1; then
  ok "Cua can reach the host docker daemon (sibling containers OK)"
else
  warn "docker not usable inside claw-openclaw. Common causes:"
  warn "  - docker CLI missing/incompatible: docker exec claw-openclaw docker --version"
  warn "  - socket perms: container must join GID $DOCKER_GID (group_add in compose)"
  warn "  - check: docker exec claw-openclaw ls -l /var/run/docker.sock"
fi

cat <<EOF

[04] Next:
  1. Verify the model wiring:
       $DC -f $COMPOSE --profile cli run --rm openclaw-cli models list
  2. DM your bot on Telegram, then approve the pairing (allowlist already set):
       docker logs claw-openclaw --tail 30   # find the from.id / pairing code
  3. Open Control UI: http://<server-ip>:$PORT
EOF
