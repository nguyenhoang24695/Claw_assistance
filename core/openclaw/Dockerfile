# Slim overlay: OpenClaw gateway + git + docker compose plugin.
#
# claw-openclaw is an ORCHESTRATOR, not a build host. It clones repos,
# commits/pushes code, and drives the HOST docker daemon (DooD, see
# docker-compose.yml). Per-project runtimes (.NET, Node, Python, Go…) live in
# EACH PROJECT'S OWN container — never baked in here. That keeps this image
# small, avoids version conflicts across projects, and isolates project builds.
#
# Tooling baked in (NOT language runtimes): git for clone/commit/push, and the
# `docker compose` v2 plugin so Cua can `docker compose up` per-project stacks.
# The docker CLI itself is bind-mounted from the host, but its compose plugin is
# NOT, so we install the plugin here. The base image is Debian bookworm.
FROM ghcr.io/openclaw/openclaw:latest

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
      git ca-certificates curl \
 && rm -rf /var/lib/apt/lists/* \
 # docker compose v2 plugin (system-wide cli-plugins dir). latest/download +
 # uname keeps it correct across architectures. Docker skipped v3/v4, so the
 # current series is v5.x — invoked as `docker compose`, not `docker-compose`.
 && mkdir -p /usr/local/lib/docker/cli-plugins \
 && curl -fsSL "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
      -o /usr/local/lib/docker/cli-plugins/docker-compose \
 && chmod +x /usr/local/lib/docker/cli-plugins/docker-compose \
 && git --version \
 && /usr/local/lib/docker/cli-plugins/docker-compose version
USER node
