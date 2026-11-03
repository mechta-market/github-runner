FROM alpine:latest

LABEL org.opencontainers.image.source=https://github.com/mechta-market/github-runner

# Базовый образ сервисов: пакеты ставятся один раз здесь, а не в каждой сборке сервиса
RUN apk upgrade --no-cache && \
    apk add --no-cache ca-certificates tzdata curl
