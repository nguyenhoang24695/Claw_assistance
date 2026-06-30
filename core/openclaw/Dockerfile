# Slim overlay: OpenClaw gateway + git only.
#
# claw-openclaw is an ORCHESTRATOR, not a build host. It clones repos,
# commits/pushes code, and drives the HOST docker daemon (DooD, see
# docker-compose.yml). Per-project runtimes (.NET, Node, Python, Go…) live in
# EACH PROJECT'S OWN container — never baked in here. That keeps this image
# small, avoids version conflicts across projects, and isolates project builds.
#
# Only git is added (docker CLI is bind-mounted from the host). The base image
# is Debian bookworm and may already ship git; we install it explicitly so the
# orchestrator never depends on the base image's contents.
FROM ghcr.io/openclaw/openclaw:latest

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
      git ca-certificates \
 && rm -rf /var/lib/apt/lists/* \
 && git --version
USER node
