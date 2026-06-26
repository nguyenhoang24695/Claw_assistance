# PROMPT 05 — Pair Telegram & Smoke Test

## Role
You are the final integration agent. Task: pair your Telegram account with the OpenClaw bot and verify the full backbone (Telegram → OpenClaw → 9Router → LLM) end to end.

## Context
Target OS: **Ubuntu (Linux)**. This is **step 5/5** — the closing step. DEPENDS ON steps 1–4 complete (9Router up on 20138; OpenClaw gateway `claw-openclaw` running on 18789 with the `router9` provider and Telegram allowlist).

> NOTE: the original plan's `core/bootloader.js` is OBSOLETE. OpenClaw ships its own gateway daemon — there is nothing to bootstrap. This step is pairing + verification only.

## Execution
1. Open Telegram, find your bot (the one whose token is in `.env`), send `/start` or any DM.
2. Approve the pairing (the allowlist already restricts to your user id):
   ```bash
   # find the pairing code / from.id in the gateway logs:
   docker logs claw-openclaw --tail 40
   # if a code is shown, approve it via the cli sidecar:
   docker compose -f core/openclaw/docker-compose.yml --profile cli run --rm \
     openclaw-cli pairing approve telegram <CODE>
   ```
3. Send a real message to the bot, e.g. `"Hi, system check"`.

## Smoke Test (Definition of Done)
1. `curl -s http://localhost:18789/healthz` → 2xx.
2. The bot replies in Telegram to your message.
3. The **9Router dashboard** (`http://<server-ip>:20138`) shows a fresh request log routed via `combo-coding`.
   → Backbone (Telegram → OpenClaw → 9Router → LLM) is 100% operational.

## Final Handover
- `claw-openclaw` + `claw-9router` both running, isolated from other server projects.
- Smoke test passes all 3 checks.
- Next (outside the 5-step scope): copy the **Master Plan** into `docs/system_spec.md` so the agent can self-expand.

> If the bot does not reply: check (a) token in `.env` + your id in `allowFrom`, (b) `docker logs claw-openclaw --tail 60`, (c) 9Router reachable from the container: `docker exec claw-openclaw node -e "fetch('http://host.docker.internal:20138/v1/models').then(r=>console.log(r.status))"`.
