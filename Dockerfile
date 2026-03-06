FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        avahi-utils \
        adb \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/slidebolt
COPY bin/ .build/bin/
COPY production.lock.json .
ARG VERSION=dev
ENV APP_VERSION=$VERSION
EXPOSE 39011
ENTRYPOINT [".build/bin/launcher", "up"]
