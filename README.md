## Runner image for github-actions

- `Dockerfile` — образ раннера `ghcr.io/mechta-market/github-runner:latest` (yc-arc),
  пересобирается раз в неделю и при изменении самого образа.
- `.github/workflows/go-service.yml` — общая сборка Go-сервиса для других репозиториев.
- `.github/workflows/front.yml` — общая сборка фронта (статика на раннере, образ на nginx-base).
- `alpine-base/` — базовый образ сервисов `ghcr.io/mechta-market/alpine-base:latest`
  (alpine + ca-certificates, tzdata, curl), пересобирается раз в неделю.
- `nginx-base/` — базовый образ фронтов `ghcr.io/mechta-market/nginx-base:latest`
  (nginx:alpine + ca-certificates, tzdata, curl), пересобирается раз в неделю.
