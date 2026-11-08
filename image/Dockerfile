# Multi-stage build: compile all binaries, then run with manager.
FROM golang:1.26-alpine AS builder

WORKDIR /src
COPY release/image/go.work   go.work

# Copy all modules (order: deps first, then dependents)
COPY sb-contract/          sb-contract/
COPY sb-domain/            sb-domain/
COPY sb-log-spy/           sb-log-spy/
COPY sb-messenger-sdk/     sb-messenger-sdk/
COPY sb-storage-sdk/       sb-storage-sdk/
COPY sb-storage-server/    sb-storage-server/
COPY sb-logging/           sb-logging/
COPY sb-logging-sdk/       sb-logging-sdk/
COPY sb-cli/               sb-cli/
COPY sb-runtime/           sb-runtime/
COPY sb-manager-sdk/       sb-manager-sdk/
COPY sb-manager/           sb-manager/
COPY sb-messenger/         sb-messenger/
COPY sb-media-sdk/         sb-media-sdk/
COPY sb-media/             sb-media/
COPY asterisk-host/        asterisk-host/
COPY sb-speech-sdk/        sb-speech-sdk/
COPY sb-speech/            sb-speech/
COPY plugin-intent/       plugin-intent/
COPY plugin-opencode/      plugin-opencode/
COPY sb-storage/           sb-storage/
COPY sb-api/               sb-api/
COPY sb-testkit/           sb-testkit/
COPY plugin-clean/         plugin-clean/
COPY plugin-virtual/       plugin-virtual/
COPY sb-script/            sb-script/
COPY sb-virtual/           sb-virtual/
COPY plugin-amcrest/       plugin-amcrest/
COPY plugin-androidphone/  plugin-androidphone/
COPY plugin-androidtv/     plugin-androidtv/
COPY plugin-asterisk/      plugin-asterisk/
COPY plugin-automation/    plugin-automation/
COPY plugin-esphome/       plugin-esphome/
COPY plugin-frigate/       plugin-frigate/
COPY plugin-kasa/          plugin-kasa/
COPY plugin-system/        plugin-system/
COPY plugin-wiz/           plugin-wiz/
COPY plugin-homeassistant/ plugin-homeassistant/
COPY plugin-alexa/         plugin-alexa/
COPY plugin-zigbee/        plugin-zigbee/

# Build the manager
RUN cd sb-manager && go build -o /out/sb-manager ./cmd/sb-manager
RUN cd sb-cli && go build -o /out/sb ./cmd/sb-cli

# Build all service and plugin binaries into .bin/
RUN cd sb-messenger      && go build -o /out/.bin/sb-messenger      ./cmd/sb-messenger
RUN cd sb-storage        && go build -o /out/.bin/sb-storage        ./cmd/sb-storage
RUN cd sb-logging        && go build -o /out/.bin/sb-logging        ./cmd/sb-logging
RUN cd sb-api            && go build -o /out/.bin/sb-api            ./cmd/sb-api
RUN cd sb-media          && go build -o /out/.bin/sb-media          ./cmd/sb-media
RUN cd asterisk-host     && go build -o /out/.bin/asterisk-host     ./cmd/asterisk-host
RUN cd sb-speech         && go build -o /out/.bin/sb-speech         ./cmd/sb-speech
RUN cd plugin-intent    && go build -o /out/.bin/plugin-intent    ./cmd/plugin-intent
RUN cd plugin-opencode   && go build -o /out/.bin/plugin-opencode   ./cmd/plugin-opencode
RUN cd sb-script         && go build -o /out/.bin/sb-script         ./cmd/sb-script
RUN cd sb-virtual        && go build -o /out/.bin/sb-virtual        ./cmd/sb-virtual
RUN cd plugin-amcrest    && go build -o /out/.bin/plugin-amcrest    ./cmd/plugin-amcrest
RUN cd plugin-androidphone && go build -o /out/.bin/plugin-androidphone ./cmd/plugin-androidphone
RUN cd plugin-androidtv  && go build -o /out/.bin/plugin-androidtv  ./cmd/plugin-androidtv
RUN cd plugin-asterisk   && go build -o /out/.bin/plugin-asterisk   ./cmd/plugin-asterisk
RUN cd plugin-automation && go build -o /out/.bin/plugin-automation ./cmd/plugin-automation
RUN cd plugin-virtual    && go build -o /out/.bin/plugin-virtual    ./cmd/plugin-virtual
RUN cd plugin-esphome    && go build -o /out/.bin/plugin-esphome    ./cmd/plugin-esphome
RUN cd plugin-frigate    && go build -o /out/.bin/plugin-frigate    ./cmd/plugin-frigate
RUN cd plugin-kasa       && go build -o /out/.bin/plugin-kasa       ./cmd/plugin-kasa
RUN cd plugin-system     && go build -o /out/.bin/plugin-system     ./cmd/plugin-system
RUN cd plugin-wiz        && go build -o /out/.bin/plugin-wiz        ./cmd/plugin-wiz

RUN cd plugin-homeassistant && go build -o /out/.bin/plugin-homeassistant ./cmd/plugin-homeassistant
RUN cd plugin-alexa       && go build -o /out/.bin/plugin-alexa       ./cmd/plugin-alexa
RUN cd plugin-zigbee      && go build -o /out/.bin/plugin-zigbee      ./cmd/plugin-zigbee

# --- whisper.cpp for sb-speech ---
FROM node:22-alpine AS whisper-build
RUN apk add --no-cache build-base cmake git curl
RUN git clone --depth 1 --branch v1.7.6 https://github.com/ggml-org/whisper.cpp /src/whisper && \
    cmake -S /src/whisper -B /src/whisper/build -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DGGML_NATIVE=OFF && \
    cmake --build /src/whisper/build --target whisper-cli -j
RUN mkdir -p /out/models && \
    curl -fsSL -o /out/models/ggml-base.en.bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin

# --- piper for sb-speech replies ---
# The release is built for glibc. It runs on the Alpine runtime through its own
# glibc loader and libraries, kept in /opt/piper so nothing else uses them.
FROM debian:bookworm-slim AS piper-build
RUN apt-get update -qq && apt-get install -y -qq --no-install-recommends curl ca-certificates >/dev/null && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL -o /tmp/piper.tgz https://github.com/rhasspy/piper/releases/download/2023.11.14-2/piper_linux_x86_64.tar.gz && \
    echo "a50cb45f355b7af1f6d758c1b360717877ba0a398cc8cbe6d2a7a3a26e225992  /tmp/piper.tgz" | sha256sum -c - && \
    tar -xzf /tmp/piper.tgz -C /opt && rm /tmp/piper.tgz && \
    mkdir /opt/piper/glibc && \
    for l in ld-linux-x86-64.so.2 libc.so.6 libm.so.6 libpthread.so.0 libdl.so.2 librt.so.1 libgcc_s.so.1; do cp -L /lib/x86_64-linux-gnu/$l /opt/piper/glibc/; done && \
    cp -L /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /opt/piper/glibc/
RUN mkdir -p /out/piper && cd /out/piper && \
    curl -fsSL -O https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/lessac/medium/en_US-lessac-medium.onnx && \
    curl -fsSL -O https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json && \
    printf '%s\n' "5efe09e69902187827af646e1a6e9d269dee769f9877d17b16b1b46eeaaf019f  en_US-lessac-medium.onnx" \
                   "efe19c417bed055f2d69908248c6ba650fa135bc868b0e6abb3da181dab690a0  en_US-lessac-medium.onnx.json" | sha256sum -c -

# --- zigbee-host build (TypeScript + native serial bindings) ---
FROM node:22-alpine AS zigbee-host-build
RUN apk add --no-cache python3 make g++ linux-headers
WORKDIR /src/zigbee-host
COPY zigbee-host/package.json zigbee-host/package-lock.json ./
RUN npm ci
COPY zigbee-host/tsconfig.json ./
COPY zigbee-host/src ./src
RUN npm run build && npm prune --omit=dev

FROM node:22-alpine AS ui-deps

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

RUN corepack enable && corepack prepare pnpm@10.28.1 --activate

WORKDIR /src/ui
COPY ui/package.json ui/pnpm-workspace.yaml ui/pnpm-lock.yaml ui/turbo.json ./
COPY ui/apps/api/package.json ./apps/api/
COPY ui/apps/web/package.json ./apps/web/
COPY ui/packages/database/package.json ./packages/database/
RUN pnpm install --frozen-lockfile

FROM ui-deps AS ui-build

COPY ui/apps/api ./apps/api
COPY ui/apps/web ./apps/web
COPY ui/packages/database ./packages/database
RUN pnpm --filter @repo/database build
RUN pnpm --filter api build
RUN pnpm --filter web build

# --- Runtime stage ---
FROM node:22-alpine

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

RUN corepack enable && corepack prepare pnpm@10.28.1 --activate && \
    apk add --no-cache ca-certificates ffmpeg libgomp libstdc++ nginx tzdata

COPY --from=builder /out/sb-manager /usr/local/bin/sb-manager
COPY --from=builder /out/sb /usr/local/bin/sb
COPY --from=whisper-build /src/whisper/build/bin/whisper-cli /usr/local/bin/whisper-cli
COPY --from=whisper-build /out/models/ /app/models/
COPY --from=piper-build /opt/piper /opt/piper
COPY --from=piper-build /out/piper/ /app/models/piper/
RUN printf '#!/bin/sh\nexec /opt/piper/glibc/ld-linux-x86-64.so.2 --library-path /opt/piper/glibc:/opt/piper /opt/piper/piper --espeak_data /opt/piper/espeak-ng-data "$@"\n' > /usr/local/bin/piper && \
    chmod +x /usr/local/bin/piper && \
    echo "Testing one two." | piper --model /app/models/piper/en_US-lessac-medium.onnx --output_raw --quiet | head -c 1000 | wc -c | grep -q 1000
COPY --from=builder /out/.bin/      /app/.bin.image/
COPY ui/package.json ui/pnpm-workspace.yaml ui/pnpm-lock.yaml ui/turbo.json /app/ui/
COPY ui/apps/api/package.json /app/ui/apps/api/package.json
COPY ui/apps/web/package.json /app/ui/apps/web/package.json
COPY ui/packages/database/package.json /app/ui/packages/database/package.json
COPY ui/packages/database/drizzle.config.ts /app/ui/packages/database/drizzle.config.ts
COPY ui/packages/database/src /app/ui/packages/database/src
RUN cd /app/ui && pnpm install --frozen-lockfile
COPY --from=ui-build /src/ui/apps/api/dist /app/ui/apps/api/dist
COPY --from=ui-build /src/ui/packages/database/dist /app/ui/packages/database/dist
COPY --from=ui-build /src/ui/apps/web/dist /usr/share/nginx/html

# zigbee-host runtime
COPY --from=zigbee-host-build /src/zigbee-host/package.json /app/zigbee-host/
COPY --from=zigbee-host-build /src/zigbee-host/node_modules /app/zigbee-host/node_modules
COPY --from=zigbee-host-build /src/zigbee-host/dist         /app/zigbee-host/dist

WORKDIR /app

# On startup the entrypoint copies the image's binaries into .bin/, starts
# zigbee-host, the UI API and nginx, then hands off to the manager.
COPY release/image/bootstrap-ui-db.mjs /app/ui/bootstrap-ui-db.mjs
COPY release/image/nginx.conf /etc/nginx/http.d/default.conf
COPY release/image/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# What this image was built from. release/build.sh passes the release and the
# commit of every repo; plain docker builds get an empty manifest.
ARG SB_BUILD_ID=unversioned
ARG SB_BUILD_MANIFEST={}
LABEL org.slidebolt.build-id=$SB_BUILD_ID
RUN printf '%s\n' "$SB_BUILD_MANIFEST" > /app/build-manifest.json

ENTRYPOINT ["/entrypoint.sh"]
