FROM ghcr.io/actions/actions-runner:latest

ARG GO_VERSION=1.27.3
ARG NODE_VERSIONS="22 24"
ARG COMPOSE_VERSION=5.6.1

USER root

# Базовые пакеты. Docker CLI с buildx, группа docker, curl, git, jq, unzip и python3 уже есть
# в базовом образе. build-essential — сборка с CGO (esign) и нативных модулей node-gyp,
# zip — showcase_wails_app, zstd — быстрое сжатие кэша (runs-on/cache берёт его вместо gzip).
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
      zstd \
      sudo \
      build-essential \
      python3 \
      && rm -rf /var/lib/apt/lists/*

# Docker Compose: в базовом образе docker только с buildx. Раньше compose приезжал вместе с
# docker-ce-cli из apt (рекомендуемый пакет docker-compose-plugin), теперь ставим плагином сами
RUN dir=/usr/local/lib/docker/cli-plugins && \
    url=https://github.com/docker/compose/releases/download/v${COMPOSE_VERSION}/docker-compose-linux-x86_64 && \
    curl -fsSL "$url" -o $dir/docker-compose && \
    echo "$(curl -fsSL "$url.sha256" | cut -d' ' -f1)  $dir/docker-compose" | sha256sum -c - && \
    chmod +x $dir/docker-compose

# Go
RUN curl -fsSL https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz | tar -C /usr/local -xz
ENV PATH="/usr/local/go/bin:${PATH}"

# Node через fnm: каждая версия лежит под своим именем в $FNM_DIR/aliases/<версия> (go-service.yml
# ставит её первой в PATH по input node), первая из списка — по умолчанию. corepack в каждой версии
# даёт pnpm/yarn той версии, что записана в packageManager у package.json.
# chown — в том же слое: отдельным RUN папка fnm легла бы в образ второй копией
ENV FNM_DIR="/usr/local/fnm"
ENV PATH="$FNM_DIR/aliases/default/bin:$FNM_DIR:$PATH"
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
RUN curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir $FNM_DIR --skip-shell && \
    bash -c "eval \"\$(fnm env)\" && \
      for v in $NODE_VERSIONS; do \
        fnm install \$v && fnm alias \$v \$v && \
        PATH=$FNM_DIR/aliases/\$v/bin:\$PATH corepack enable || exit 1; \
      done && \
      fnm default ${NODE_VERSIONS%% *}" && \
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
