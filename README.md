# SlideBolt Release Image

This repo builds the packaged SlideBolt runtime image from pinned binary releases.

It does not compile the binaries from source. Instead, it downloads released
artifacts from the individual SlideBolt repos, assembles them into one Docker
image, smoke-tests that image, and publishes it to GHCR.

## Triggering a Release

1. Update [`versions.env`](./versions.env) if any binary versions changed.
2. Commit and push to `main`.
3. Either:
   - run the GitHub Actions workflow manually, or
   - push a tag like `v1.0.0` in this repo.

The workflow publishes:

- `ghcr.io/slidebolt/slidebolt:<tag>`
- `ghcr.io/slidebolt/slidebolt:latest` on `main`

## Included Binaries

- `sb-manager`
- `sb-messenger`
- `sb-storage`
- `sb-api`
- `sb-script`
- `sb-virtual`
- `plugin-amcrest`
- `plugin-androidtv`
- `plugin-automation`
- `plugin-esphome`
- `plugin-frigate`
- `plugin-kasa`
- `plugin-system`
- `plugin-wiz`
- `plugin-zigbee2mqtt`
