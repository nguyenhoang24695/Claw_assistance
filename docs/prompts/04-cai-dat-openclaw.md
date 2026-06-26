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
1. Install OpenClaw globally (nvm-managed Node → no `sudo` needed):
   ```bash
   npm install -g openclaw
   ```
2. Create the `.env` file at the **project root** with the following (replace with real values from steps 1 & 2):

   ```env
   # --- ROUTING THROUGH 9ROUTER ---
   OPENAI_API_BASE=http://localhost:20138/v1
   OPENAI_API_KEY=9router_local_secret
   OPENAI_MODEL=combo-coding

   # --- SECURITY & TELEGRAM CHANNEL ---
   TELEGRAM_BOT_TOKEN=<token_from_botfather>
   TELEGRAM_ALLOWED_USER_IDS=<your_telegram_user_id>

   # --- LINUX TERMINAL EXECUTION PERMISSION ---
   WORKSPACE_DIR=./workspace
   ENABLE_TERMINAL_EXECUTION=true
   EXECUTION_MODE=docker   # Force terminal commands to run inside a Docker container for safety
   ```
3. Lock down `.env` permissions (it holds secret tokens):
   ```bash
   chmod 600 .env
   ```

## Deliverables
- OpenClaw installed successfully (`openclaw --version` works).
- `.env` file exists at the project root with all 3 config groups above.
- `.env` is listed in `.gitignore` and has mode `600`.

## Definition of Done
- `openclaw --version` returns a version.
- All variables in `.env` are readable, with no remaining `<...>` placeholders.
- `EXECUTION_MODE=docker` and `docker ps` works without `sudo` (daemon running).

> Security: `.env` holds secret tokens → never commit it, keep mode `600`. `EXECUTION_MODE=docker` ensures terminal commands run isolated in a container, never touching the host.
