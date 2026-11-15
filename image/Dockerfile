# Multi-stage build: compile all binaries, then run with manager.
FROM golang:1.26-alpine AS builder

WORKDIR /src
RUN apk add --no-cache ca-certificates git
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
COPY sb-scheduler-sdk/     sb-scheduler-sdk/
COPY sb-scheduler/         sb-scheduler/
COPY asterisk-host/        asterisk-host/
COPY sb-speech-sdk/        sb-speech-sdk/
COPY sb-speech-provider-sdk/ sb-speech-provider-sdk/
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
COPY plugin-hdhomerun/     plugin-hdhomerun/
COPY plugin-jellyfin/      plugin-jellyfin/
COPY plugin-plex/          plugin-plex/
COPY plugin-kasa/          plugin-kasa/
COPY plugin-system/        plugin-system/
COPY plugin-wiz/           plugin-wiz/
COPY plugin-homeassistant/ plugin-homeassistant/
COPY plugin-alexa/         plugin-alexa/
COPY plugin-zigbee/        plugin-zigbee/
COPY plugin-zigbee2mqtt/   plugin-zigbee2mqtt/

# Build the manager
RUN cd sb-manager && go build -o /out/sb-manager ./cmd/sb-manager
RUN cd sb-cli && go build -o /out/sb ./cmd/sb-cli

# Build all service and plugin binaries into .bin/
RUN cd sb-messenger      && go build -o /out/.bin/sb-messenger      ./cmd/sb-messenger
RUN cd sb-storage        && go build -o /out/.bin/sb-storage        ./cmd/sb-storage
RUN cd sb-logging        && go build -o /out/.bin/sb-logging        ./cmd/sb-logging
RUN cd sb-api            && go build -o /out/.bin/sb-api            ./cmd/sb-api
RUN cd sb-media          && go build -o /out/.bin/sb-media          ./cmd/sb-media
RUN cd sb-scheduler      && go build -o /out/.bin/sb-scheduler      ./cmd/sb-scheduler
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
RUN cd plugin-hdhomerun  && go build -o /out/.bin/plugin-hdhomerun  ./cmd/plugin-hdhomerun
RUN cd plugin-jellyfin   && go build -o /out/.bin/plugin-jellyfin   ./cmd/plugin-jellyfin
RUN cd plugin-plex       && go build -o /out/.bin/plugin-plex       ./cmd/plugin-plex
RUN cd plugin-kasa       && go build -o /out/.bin/plugin-kasa       ./cmd/plugin-kasa
RUN cd plugin-system     && go build -o /out/.bin/plugin-system     ./cmd/plugin-system
RUN cd plugin-wiz        && go build -o /out/.bin/plugin-wiz        ./cmd/plugin-wiz

RUN cd plugin-homeassistant && go build -o /out/.bin/plugin-homeassistant ./cmd/plugin-homeassistant
RUN cd plugin-alexa       && go build -o /out/.bin/plugin-alexa       ./cmd/plugin-alexa
RUN cd plugin-zigbee      && go build -o /out/.bin/plugin-zigbee      ./cmd/plugin-zigbee
RUN cd plugin-zigbee2mqtt && go build -o /out/.bin/plugin-zigbee2mqtt ./cmd/plugin-zigbee2mqtt

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
RUN ffmpeg -version 2>&1 | grep -q 'ffmpeg version' && \
    ffprobe -version 2>&1 | grep -q 'ffprobe version' && \
    ffmpeg -hide_banner -encoders 2>&1 | grep -q ' libx264 ' && \
    ffmpeg -hide_banner -encoders 2>&1 | grep -q ' aac ' && \
    ffmpeg -hide_banner -muxers 2>&1 | grep -q ' matroska ' && \
    ffmpeg -hide_banner -muxers 2>&1 | grep -q ' mp4 ' && \
    ffmpeg -hide_banner -muxers 2>&1 | grep -q ' mpegts ' && \
    ffmpeg -hide_banner -filters 2>&1 | grep -q ' bwdif ' && \
    ffmpeg -hide_banner -filters 2>&1 | grep -q ' scale ' && \
    ffmpeg -hide_banner -filters 2>&1 | grep -q ' setsar '

COPY --from=builder /out/sb-manager /usr/local/bin/sb-manager
COPY --from=builder /out/sb /usr/local/bin/sb
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
