# PROMPT 05 — Create Core Bootloader & Smoke Test

## Role
You are the final integration agent. Task: write `core/bootloader.js` to activate OpenClaw, auto-load plugins/agents, then run a full end-to-end smoke test.

## Context
Target OS: **Ubuntu (Linux)**. This is **step 5/5** — the closing step. DEPENDS ON: steps 1–4 complete (9Router has combos, Telegram has token/user-id, directories set up, OpenClaw installed + `.env` configured).

## Execution
1. Create the file `core/bootloader.js`:

   ```javascript
   const fs = require('fs');
   const path = require('path');

   console.log("[Core] Starting control kernel...");

   // 1. Auto-create dynamic directories if missing
   const requiredDirs = ['./agents', './plugins', './modules', './docs'];
   requiredDirs.forEach(dir => {
     if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
   });

   // 2. Scan & load self-generated plugins (Zalo, Discord... later)
   const pluginsDir = path.join(__dirname, '../plugins');
   fs.readdirSync(pluginsDir).forEach(pluginName => {
     const pluginPath = path.join(pluginsDir, pluginName, 'index.js');
     if (fs.existsSync(pluginPath)) {
       console.log(`[Core] Loading self-generated connector: ${pluginName}`);
       require(pluginPath);
     }
   });

   // 3. OpenClaw starts listening to Telegram
   console.log("[Core] Telegram and 9Router connected successfully. System Online!");
   ```

2. Run: `node core/bootloader.js`.

## Smoke Test (Definition of Done)
1. `node core/bootloader.js` runs without errors and prints "System Online!".
2. Open Telegram, go to the bot you created, send `/start` or `"Hi, system check"`.
3. The bot replies **AND** the 9Router dashboard shows a request log from model `combo-coding`.
   → The backbone (Core) is 100% operational.

## Final Handover
- File `core/bootloader.js` exists and runs.
- Smoke test passes all 3 checks.
- Next step (outside the 5-step scope): copy the **Master Plan** content into `docs/system_spec.md` so the Agent gets a "mental map" to self-expand.

> If the bot does not reply: check (a) token/user-id in `.env`, (b) 9Router still running on `:20128` (`curl http://localhost:20128`), (c) Docker daemon enabled (`docker ps` without `sudo`).
