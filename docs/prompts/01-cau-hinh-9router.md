# PROMPT 01 — Configure LLM Infrastructure on 9Router

## Role
You are an infrastructure deployment agent. Task: configure **9Router** as the aggregation & routing layer for free LLM API keys, so later steps call LLMs through a single endpoint.

## Context
Target OS: **Ubuntu (Linux)** (step 0 prerequisites already installed). 9Router is a provider/model management dashboard. This is **step 1/5** — no prior dependencies beyond step 0.

IMPORTANT — the server already runs ANOTHER 9Router (`automation-agent-9router-1` on port 20128). Do NOT touch it. This project runs its OWN isolated instance: container `claw-9router`, port **20138**, separate data dir → keys/combos are fully separate.

## Execution
1. Start this project's dedicated 9Router instance (from repo root):
   ```bash
   bash scripts/01-start-9router.sh
   ```
   The script is idempotent: it brings up `claw-9router` on port 20138, waits
   for the dashboard, and confirms the existing instance is untouched.
   Then open `http://localhost:20138` (or `http://<server-ip>:20138`).
2. Go to **Providers** → add the free API keys you have (Kiro AI, OpenCode Free, iFlow, ...).
3. Go to **Combos** → create exactly 2 routing combos:
   - `combo-reasoning` → prioritize model `nemotron-3-ultra-free` (logic breakdown, planning, writing specs).
   - `combo-coding` → prioritize `qwen3.6-plus-free` and `north-mini-code-free` (writing code, running terminal, syntax review).

## Deliverables
- 9Router reachable at `http://localhost:20138`.
- Two combos exist: `combo-reasoning`, `combo-coding`, each with at least one active model.
- Record the endpoint for later steps: `http://localhost:20138/v1`.

## Definition of Done
- Send a test request to `http://localhost:20138/v1/chat/completions` with `model: combo-coding` → receive a valid response.
- The dashboard shows the log of that request.

> Note: model names may change depending on the actual key source. If a model is unavailable, replace it with one in the same functional group and document the name used.
