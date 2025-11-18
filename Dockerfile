FROM ghcr.io/actions/actions-runner:latest

USER root

# Устанавливаем базовые утилиты и компиляторы
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

RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs \
    && corepack enable \
    && rm -rf /var/lib/apt/lists/*

# (Опционально) Установка Docker CLI — чтобы job мог собирать образы
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker.gpg && \
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" \
      > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

# Добавляем пользователя runner в docker-группу (если докер сокет маунтится)
RUN groupadd -f docker && usermod -aG docker runner

USER runner
