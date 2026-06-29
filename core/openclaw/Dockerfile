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

# Base is Debian bookworm (OpenClaw runs as user `node` under /home/node).
#
# .NET: we do NOT use the Microsoft apt feed — on Debian its packages-microsoft-prod
# package pins dotnet* to Pin-Priority -10, so `apt install dotnet-sdk-8.0` fails with
# "Unable to locate package". Instead use the official dotnet-install.sh (distro-agnostic,
# no package names/pinning) into /usr/share/dotnet, plus the DEB runtime deps MS lists
# (libicu72 is the bookworm ICU). Node 20 via NodeSource is unaffected, kept as-is.
#
# If the base ever turns out to be Alpine (musl), this RUN fails loudly — switch to
# apk add and dotnet-install.sh.
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl ca-certificates gnupg tmux git \
      libc6 libgcc-s1 libgssapi-krb5-2 libicu72 libssl3 libstdc++6 zlib1g \
 && curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh \
 && bash /tmp/dotnet-install.sh --channel 8.0 --install-dir /usr/share/dotnet \
 && ln -s /usr/share/dotnet/dotnet /usr/local/bin/dotnet \
 && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
 && apt-get update && apt-get install -y --no-install-recommends nodejs \
 && rm -rf /var/lib/apt/lists/* /tmp/* \
 && dotnet --version && node --version && tmux -V

# .NET telemetry off + tell the SDK where it lives (symlink alone doesn't set DOTNET_ROOT).
ENV DOTNET_ROOT=/usr/share/dotnet \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=1

USER node
