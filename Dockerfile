FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Binaries are fetched by fetch-binaries.sh into dist/
COPY dist/ /app/.bin/
COPY dist-manager/sb-manager /usr/local/bin/sb-manager

RUN chmod +x /app/.bin/* \
    && chmod +x /usr/local/bin/sb-manager \
    && test ! -e /app/.bin/sb-manager \
    && test -x /usr/local/bin/sb-manager \
    && test -x /app/.bin/sb-messenger \
    && test -x /app/.bin/sb-storage \
    && test -x /app/.bin/sb-api \
    && test -x /app/.bin/sb-logging \
    && test -x /app/.bin/sb

ENV PATH="/app/.bin:${PATH}"

# Default to starting the manager, which coordinates other processes
CMD ["/usr/local/bin/sb-manager", "--bin-dir", "/app/.bin"]
