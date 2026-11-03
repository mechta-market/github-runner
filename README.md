## Runner image for github-actions

- `Dockerfile` — образ раннера `ghcr.io/mechta-market/github-runner:latest` (yc-arc).
- `.github/workflows/go-service.yml` — общая сборка Go-сервиса для других репозиториев.
- `alpine-base/` — базовый образ сервисов `ghcr.io/mechta-market/alpine-base:latest`
  (alpine + ca-certificates, tzdata, curl), пересобирается раз в неделю.
