FROM ghcr.io/actions/actions-runner:latest

ARG GO_VERSION=1.27.3
ARG NODE_VERSION=22

USER root

# Базовые пакеты. Docker CLI с buildx, группа docker, curl, git, jq, unzip и python3 уже есть
# в базовом образе. build-essential — сборка с CGO (esign) и нативных модулей node-gyp,
# zip — showcase_wails_app.
# libvips-dev не ставим: sharp у mechta-site тогда скачивает свою готовую libvips, а не
# собирается из исходников против системной (~80 с на каждую сборку сайта).
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      make \
      unzip \
      zip \
      jq \
      sudo \
      build-essential \
      python3 \
      && rm -rf /var/lib/apt/lists/*

# Go
RUN curl -fsSL https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz | tar -C /usr/local -xz
ENV PATH="/usr/local/go/bin:${PATH}"

# Node через fnm. chown — в том же слое: отдельным RUN папка fnm легла бы в образ второй копией
ENV FNM_DIR="/usr/local/fnm"
ENV PATH="$FNM_DIR/aliases/default/bin:$FNM_DIR:$PATH"
RUN curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir $FNM_DIR && \
    bash -c "eval \"\$(fnm env)\" && fnm install $NODE_VERSION && fnm default $NODE_VERSION" && \
    corepack enable && \
    chown -R runner:runner $FNM_DIR

# Архивы действий из go-service.yml (закреплены там по sha): раннер берёт их с диска, а не с GitHub.
# Токен (секрет github_token, если передан) — чтобы не упереться в лимит анонимных запросов к API.
ENV ACTIONS_RUNNER_ACTION_ARCHIVE_CACHE=/opt/action-archive-cache
COPY .github/workflows/go-service.yml /tmp/go-service.yml
RUN --mount=type=secret,id=github_token \
    TOKEN=$(cat /run/secrets/github_token 2>/dev/null || true) && \
    grep -oE '[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+@[0-9a-f]{40}' /tmp/go-service.yml | sort -u | \
    while IFS=@ read -r repo sha; do \
      dir="$ACTIONS_RUNNER_ACTION_ARCHIVE_CACHE/${repo%/*}_${repo#*/}" && \
      mkdir -p "$dir" && \
      curl -fsSL ${TOKEN:+-H "Authorization: Bearer $TOKEN"} \
        "https://api.github.com/repos/$repo/tarball/$sha" -o "$dir/$sha.tar.gz" || exit 1; \
    done && \
    rm /tmp/go-service.yml && \
    find $ACTIONS_RUNNER_ACTION_ARCHIVE_CACHE -name '*.tar.gz'

USER runner
