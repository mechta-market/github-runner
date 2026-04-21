FROM ghcr.io/actions/actions-runner:latest

USER root

# Базовые пакеты
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      apt-transport-https \
      ca-certificates \
      curl \
      gnupg \
      git \
      make \
      wget \
      unzip \
      zip \
      jq \
      sudo \
      build-essential \
      python3 python3-pip \
      && rm -rf /var/lib/apt/lists/*

# Docker CLI
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker.gpg && \
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" \
      > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

# Go
RUN wget https://go.dev/dl/go1.26.0.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.26.0.linux-amd64.tar.gz && \
    rm go1.26.0.linux-amd64.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"

# FNM
ENV FNM_DIR="/usr/local/fnm"
RUN curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir $FNM_DIR
ENV PATH="$FNM_DIR:$PATH"

# Устанавливаем Node версии
RUN bash -c "eval \"$(fnm env)\" && fnm install 22 && fnm default 22"
ENV PATH="$FNM_DIR/aliases/default/bin:$PATH"

RUN corepack enable

RUN chown -R runner:runner $FNM_DIR

# Docker group
RUN groupadd -f docker && usermod -aG docker runner

USER runner
