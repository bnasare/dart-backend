# syntax=docker/dockerfile:1

FROM dart:stable AS build
WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN dart pub get --offline || dart pub get

COPY . .
RUN dart pub get --offline
RUN mkdir -p build
RUN dart compile exe bin/server.dart -o build/server

FROM debian:bookworm-slim AS runtime
WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl libsqlite3-0 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /app/build/server /app/server
COPY --from=build /app/openapi.yaml /app/openapi.yaml

RUN mkdir -p /app/data

EXPOSE 8080
ENV PORT=8080
ENV API_KEYS=key_sandbox:key_standard:key_enhanced:key_enterprise
ENV DATABASE_PATH=/app/data/notes.sqlite

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl --fail --silent http://127.0.0.1:${PORT}/health > /dev/null || exit 1

CMD ["/app/server"]
