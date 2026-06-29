# Overlay image: OpenClaw gateway + runtimes Cua needs to run cloned projects
# "by hand" (Mô hình B). We do NOT install runtimes at runtime via dpkg/elevated
# (that failed: missing deps + lost on rebuild). Baking them here is durable,
# version-controlled, and lets apt resolve dependencies properly.
#
# Provides: .NET SDK 8, Node 20, tmux (long-running dotnet run / npm start live
# in tmux sessions because exec has timeoutSec:120 and can't hold a process).
# Redis/DB still run as SIBLING containers via the mounted docker socket (DooD).
FROM ghcr.io/openclaw/openclaw:latest

USER root

# Microsoft .NET 8 + NodeSource Node 20 + tmux/git. Base is Debian bookworm
# (OpenClaw runs as user `node` under /home/node, same family as node:20).
# If the base ever turns out to be Alpine (musl), this RUN fails loudly and we
# switch to: apk add dotnet8-sdk nodejs npm tmux git
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl ca-certificates gnupg tmux git \
 && install -m 0755 -d /etc/apt/keyrings \
 && curl -fsSL https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -o /tmp/ms.deb \
 && dpkg -i /tmp/ms.deb && rm /tmp/ms.deb \
 && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
 && apt-get update && apt-get install -y --no-install-recommends \
      dotnet-sdk-8.0 nodejs \
 && rm -rf /var/lib/apt/lists/* /tmp/* \
 && dotnet --version && node --version && tmux -V

USER node
