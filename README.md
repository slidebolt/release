# SlideBolt

SlideBolt is a home-automation runtime: plugins for Zigbee, Wi-Fi lights, ESPHome,
cameras, Home Assistant, Alexa and Asterisk phones, Lua automations, an HTTP and
MCP API, and a web UI. This repo is the installable product: the image, a compose
file to run it, and the settings it takes.

## Install

Needs Linux (x86_64) with Docker and the compose plugin.

```bash
git clone https://github.com/slidebolt/release slidebolt && cd slidebolt
cp .env.example .env
# Set UI_DB_PASSWORD and UI_SESSION_SECRET (openssl rand -hex 32), plus any
# integrations you use.
docker compose up -d
```

Open `http://<this machine>:49101`. The setup page connects the UI to SlideBolt
and creates its first admin token; then create your UI account.

Data lives in `./data` (`SB_DATA_DIR`). Back it up, and the `ui-db-data` volume,
to keep devices, scripts and accounts.

SlideBolt uses the host network so plugins can discover devices on your LAN. Its
ports: UI 49101, UI API 40001, sb-api 29011, messaging 4222, Home Assistant link
39444, zigbee-host 47831, asterisk-host 47832, agent 4096. Keep them behind your
firewall: SlideBolt is meant for a trusted home network.

## Options

| You have | Do this |
|---|---|
| A Zigbee USB coordinator | Set `ZIGBEE_ADAPTER` and `COMPOSE_FILE=compose.yml:compose.zigbee.yml` |
| WiZ or Kasa lights | Set `WIZ_SUBNET` / `KASA_SUBNET` |
| ESPHome devices | Set `ESPHOME_API_KEY` (and the dashboard settings to find devices) |
| Home Assistant | Install [slidebolt-hacs](https://github.com/slidebolt/slidebolt-hacs), set `HA_URL` and `HA_LONG_LIVED_ACCESS_TOKEN` |
| Asterisk phones | See [stack/asterisk](stack/asterisk/README.md) |
| An OpenCode API key | Set the agent section of `.env` and `COMPOSE_PROFILES=agent`; save the scripts in [stack/scripts](stack/scripts) |

Leave an integration's settings empty and its plugin stays idle.

## Upgrade

```bash
docker compose pull && docker compose up -d
```

Pin `SLIDEBOLT_VERSION` in `.env` to stay on one release.

## What is in this repo

| Path | What |
|---|---|
| `compose.yml`, `compose.zigbee.yml`, `.env.example` | Running SlideBolt |
| `image/` | The image: Dockerfile, entrypoint, nginx config, UI database bootstrap, `go.work` |
| `versions.env` | The tag of every repo in the image |
| `build.sh` | Builds the image from those tags, or from a local workspace |
| `opencode/` | The OpenCode agent container |
| `stack/` | Asterisk configuration and Lua scripts that SlideBolt features rely on |

## Releasing

Every component repo is released first, layer by layer (see the workspace's
`GIT.md`). Then, in a workspace where every repo's HEAD is on its new tag:

```bash
./build.sh --pin ..                     # versions.env := the tag at each HEAD
./build.sh --workspace .. --tag test    # optional: build and test locally
git commit -am "release vX.Y.Z" && git tag vX.Y.Z && git push origin main vX.Y.Z
```

CI builds the image from `versions.env` with `./build.sh`, checks it, and
publishes `ghcr.io/slidebolt/release:vX.Y.Z` and `:latest`.

Every image carries `/app/build-manifest.json`: the release and the commit of
every repo it was built from.
