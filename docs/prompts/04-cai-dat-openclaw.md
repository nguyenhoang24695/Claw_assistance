# PROMPT 04 — Run OpenClaw (Docker), wired to 9Router

## Role
You are the processing-brain deployment agent. Task: run the OpenClaw gateway as an isolated Docker container, route its LLM calls through this project's 9Router (step 1), and connect Telegram (step 2).

## Context
Target OS: **Ubuntu (Linux)**. This is **step 4/5**. DEPENDS ON:
- Step 0: Docker usable without `sudo`.
- Step 1: 9Router running on the host at `http://localhost:20138/v1` with combos `combo-coding` / `combo-reasoning`.
- Step 2: `TELEGRAM_BOT_TOKEN` + your Telegram user id.

OpenClaw is NOT configured via a flat `.env` like the original plan assumed. It is a **gateway daemon** (Control UI on port `18789`) configured via `openclaw.json5`. LLM routing is a **custom OpenAI-compatible provider** (`router9` → `http://host.docker.internal:20138/v1`). Telegram is a built-in **channel** locked to your user id via `dmPolicy: allowlist`.

Files in the repo:
- `core/openclaw/docker-compose.yml` — gateway + cli sidecar.
- `core/openclaw/config/openclaw.json5` — provider `router9` + Telegram allowlist (set your user id in `allowFrom`).

## Execution
1. Create `.env` with the bot token (secret, gitignored):
   ```bash
   TELEGRAM_BOT_TOKEN='<token_from_botfather>' bash scripts/04-make-env.sh
   ```
2. Confirm your Telegram user id is in `core/openclaw/config/openclaw.json5` → `channels.telegram.allowFrom`.
3. Start the gateway (handles uid-1000 mount ownership, waits for health):
   ```bash
   bash scripts/04-start-openclaw.sh
   ```

## Deliverables
- Container `claw-openclaw` running, Control UI reachable at `http://<server-ip>:18789`.
- `.env` present (mode 600, gitignored) with the bot token.
- Provider `router9` resolves models `combo-coding` / `combo-reasoning`.

## Definition of Done
- `docker compose -f core/openclaw/docker-compose.yml --profile cli run --rm openclaw-cli models list`
  lists `router9/combo-coding` and `router9/combo-reasoning`.
- `curl -s http://localhost:18789/healthz` returns 2xx.

> Security: only `.env` (token) is secret and never committed. `host.docker.internal` lets the container reach 9Router on the host; on Linux this is provided by `extra_hosts: host-gateway` in the compose file.
