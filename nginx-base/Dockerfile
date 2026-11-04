FROM nginx:alpine

LABEL org.opencontainers.image.source=https://github.com/mechta-market/github-runner

# Базовый образ фронтов: пакеты ставятся один раз здесь, а не в каждой сборке фронта
RUN apk upgrade --no-cache && \
    apk add --no-cache ca-certificates tzdata curl
