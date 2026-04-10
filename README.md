# Notes Service API

A production-style Dart backend built with Shelf and clean architecture.

## Features
- Notes CRUD API (`/v1/notes`)
- API key authentication via `X-API-Key`
- Per-key fixed-window rate limiting
- Tier-based feature flags (`/v1/feature-flags`)
- Structured JSON logging and standardized JSON error responses
- SQLite persistence with Drift
- OpenAPI spec (`/openapi.yaml`) and Swagger UI (`/docs`)

## Tech Stack
- Dart 3
- Shelf + shelf_router
- Drift + SQLite
- GitHub Actions CI
- Docker (multi-stage)

## Project Structure
- `app/lib/app.dart`: application composition root
- `app/lib/core/`: configuration and core bootstrapping
- `app/lib/shared/`: cross-cutting concerns (errors, middleware, http helpers)
- `app/lib/src/<feature>/{domain,data,presentation}`:
  - `notes`
  - `auth`
  - `rate_limit`
  - `feature_flags`
  - `docs`

## Environment Variables
- `PORT` (default: `8080`)
- `API_KEYS` (required): `sandbox:standard:enhanced:enterprise`
- `RATE_LIMIT_MAX` (default: `60`)
- `RATE_LIMIT_WINDOW_SEC` (default: `60`)
- `DATABASE_PATH` (default: `data/notes.sqlite`)

Example:
```bash
export PORT=8080
export API_KEYS='key_sandbox:key_standard:key_enhanced:key_enterprise'
export RATE_LIMIT_MAX=60
export RATE_LIMIT_WINDOW_SEC=60
export DATABASE_PATH='data/notes.sqlite'
```

## Run Locally
```bash
cd app
dart pub get
dart run bin/server.dart
```

## API Docs
- OpenAPI YAML: `http://localhost:8080/openapi.yaml`
- Swagger UI: `http://localhost:8080/docs`

For protected routes in Swagger UI, click **Authorize** and provide an API key value (for example `key_sandbox`).

## Quick Smoke Checks
```bash
curl -i http://127.0.0.1:8080/health
curl -i http://127.0.0.1:8080/openapi.yaml
curl -i -H 'X-API-Key: key_sandbox' 'http://127.0.0.1:8080/v1/notes?page=1&limit=20'
```

## Test and Lint
```bash
cd app
dart analyze
dart test
```

## Docker
Build and run from `app/`:
```bash
docker build -t notes-service .
docker run --rm -p 8080:8080 \
  -e API_KEYS='key_sandbox:key_standard:key_enhanced:key_enterprise' \
  notes-service
```

Health endpoint:
- `GET /health`

## CI
Workflow file:
- `.github/workflows/ci.yml`

Pipeline runs:
- `dart pub get`
- `dart analyze`
- `dart test`
