# PROMPT 00 — Prerequisites (Ubuntu)

## Role
You are an environment-provisioning agent. Task: install the base infrastructure on **Ubuntu** so steps 1–5 can run.

## Context
Target OS: **Ubuntu (Linux)**. This is **step 0/5** — runs before everything else. All later steps assume these tools exist.

## Execution
1. Update packages:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```
2. Install Git + build essentials:
   ```bash
   sudo apt install -y git curl build-essential
   ```
3. Install Node.js 18+ LTS via **nvm** (avoids global-npm `EACCES` issues):
   ```bash
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
   source ~/.bashrc
   nvm install --lts
   ```
4. Install Docker Engine + Compose plugin:
   ```bash
   sudo apt install -y docker.io docker-compose-plugin
   sudo systemctl enable --now docker
   ```
5. Allow running Docker without `sudo` (required for `EXECUTION_MODE=docker`):
   ```bash
   sudo usermod -aG docker $USER
   ```
   Then **log out and back in** (or run `newgrp docker`) for the group to take effect.

## Deliverables
- `git`, `node`, `npm`, `docker` all installed and on `PATH`.
- Docker daemon running and usable without `sudo`.

## Definition of Done
```bash
git --version          # any version
node --version         # v18.x or higher
npm --version          # works
docker run hello-world # runs WITHOUT sudo and prints success
```
All four commands succeed.

> Note: if `docker run hello-world` still needs `sudo`, the group change has not applied yet — re-login or run `newgrp docker`.
