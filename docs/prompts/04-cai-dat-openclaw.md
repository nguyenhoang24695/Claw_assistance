# PROMPT 04 — Install & Configure OpenClaw

## Role
You are a processing-brain configuration agent. Task: install OpenClaw and create the `.env` file wiring OpenClaw to 9Router (step 1) and Telegram (step 2).

## Context
Target OS: **Ubuntu (Linux)**. This is **step 4/5**. DEPENDS ON:
- Step 0: Node.js (via nvm) and Docker installed & usable without `sudo`.
- Step 1: 9Router endpoint `http://localhost:20138/v1` + combo `combo-coding`.
- Step 2: `TELEGRAM_BOT_TOKEN` and `TELEGRAM_ALLOWED_USER_IDS`.
- Step 3: directory tree set up (including `workspace/`).

## Execution
Run the script from repo root, passing the Telegram secrets inline (they are
NOT stored in the repo — only written into the gitignored `.env`):

```bash
TELEGRAM_BOT_TOKEN=<token_from_botfather> \
TELEGRAM_ALLOWED_USER_IDS=<your_telegram_user_id> \
bash scripts/04-install-openclaw.sh
```

The script: installs `openclaw` globally (via nvm Node, no `sudo`), generates
`.env` (endpoint `http://localhost:20138/v1`, `combo-coding`), `chmod 600`s it,
and verifies. See `.env.example` for the full template.
Re-run with `FORCE=1` to overwrite an existing `.env`.

## Deliverables
- OpenClaw installed successfully (`openclaw --version` works).
- `.env` file exists at the project root with all 3 config groups above.
- `.env` is listed in `.gitignore` and has mode `600`.

## Definition of Done
- `openclaw --version` returns a version.
- All variables in `.env` are readable, with no remaining `<...>` placeholders.
- `EXECUTION_MODE=docker` and `docker ps` works without `sudo` (daemon running).

> Security: `.env` holds secret tokens → never commit it, keep mode `600`. `EXECUTION_MODE=docker` ensures terminal commands run isolated in a container, never touching the host.
