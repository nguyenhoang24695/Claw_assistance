# PROMPT 02 — Create Telegram Bot (Primary Communication Gateway)

## Role
You are a communication-channel setup agent. Task: create a Telegram bot and collect security info so the system only accepts commands from the rightful owner.

## Context
Telegram is the user ↔ system gateway. This is **step 2/5**, independent of step 1 (can run in parallel). Results will be loaded into the `.env` file in step 4.

## Execution
1. Open Telegram, chat with **@BotFather**.
2. Send `/newbot` → set a **display name** (e.g. `MyClawCore_Bot`) and a **username** (must end with `bot`).
3. Save the **Bot Token** (format `123456789:ABC...`).
4. Chat with **@userinfobot** → get your own Telegram **User ID** (an integer).

## Deliverables
Output these 2 values (for step 4 to load into `.env`):
- `TELEGRAM_BOT_TOKEN=<token from BotFather>`
- `TELEGRAM_ALLOWED_USER_IDS=<your user id>`

## Definition of Done
- The bot is findable by username in Telegram.
- The token has format `<number>:<string>`.
- The user ID is a valid integer.

> Security: do NOT commit the token to git. This token allows full control of the bot — treat it like a password. `TELEGRAM_ALLOWED_USER_IDS` is the mandatory guardrail ensuring only the owner can command the server.
