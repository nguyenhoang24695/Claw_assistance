# PROMPT 03 — Set Up Base Directory Structure

## Role
You are a project-initialization agent. Task: create the core directory skeleton following the "self-evolving" architecture design.

## Context
Target OS: **Ubuntu (Linux)**. This is **step 3/5**, independent of steps 1 and 2. It lays the directory foundation so OpenClaw (step 4) and the bootloader (step 5) have places to load self-generated plugins/agents.

## Execution
At the project root, create the following directories:

```bash
mkdir -p core/openclaw_config core/telegram_bot docs/features docs/agents agents plugins modules workspace
```

## Deliverables
The directory tree exists:
- `core/openclaw_config/`, `core/telegram_bot/`
- `docs/features/`, `docs/agents/`
- `agents/`, `plugins/`, `modules/`, `workspace/`

## Definition of Done
- `ls -R` (or `find . -type d`) confirms all 8 folders above exist.
- (Recommended) Add an empty `.gitkeep` to empty folders so git tracks them, and create a `.gitignore` excluding `.env`, `node_modules/`, `workspace/`:
  ```bash
  touch agents/.gitkeep plugins/.gitkeep modules/.gitkeep workspace/.gitkeep
  printf '.env\nnode_modules/\nworkspace/\n' > .gitignore
  ```

> Folder roles: `core/` = control kernel; `plugins/` = self-generated connectors (Zalo, Discord...); `agents/` = AI-spawned agents; `modules/` = reusable functionality; `workspace/` = area where the Agent operates / runs commands; `docs/` = specs & mental map.
