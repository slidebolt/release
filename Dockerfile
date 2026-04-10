FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Binaries are fetched by fetch-binaries.sh into dist/
COPY dist/ /app/.bin/

RUN chmod +x /app/.bin/* \
    && test -x /app/.bin/sb-manager \
    && test -x /app/.bin/sb-messenger \
    && test -x /app/.bin/sb-storage \
    && test -x /app/.bin/sb-api \
    && test -x /app/.bin/sb-logging \
    && test -x /app/.bin/sb

ENV PATH="/app/.bin:${PATH}"

# Default to starting the manager, which coordinates other processes
CMD ["/app/.bin/sb-manager"]
