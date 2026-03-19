FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY dist/ /app/.bin/

RUN chmod +x /app/.bin/* \
    && test -x /app/.bin/sb-manager \
    && test -x /app/.bin/sb-messenger \
    && test -x /app/.bin/sb-storage \
    && test -x /app/.bin/sb-api

ENV PATH="/app/.bin:${PATH}"

CMD ["/app/.bin/sb-manager"]
