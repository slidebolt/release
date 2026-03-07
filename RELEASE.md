# Slidebolt Release Process

## How it works

There is no lock file. The release workflow resolves the latest published GitHub Release
for each component at build time. Whatever is latest when you run `make release-patch`
is what goes into the image.

The docker image tag (`v2.5.0`) is the blessed release. The exact component versions
that went into it are recorded as OCI image labels and in the GitHub Release notes.

## Adding or removing a component

Edit `components.json` in this repo. No versions — just the component list.

## Releasing

```bash
# Release one or more components first (if they have new changes)
gh workflow run release.yml --repo slidebolt/<repo> -f bump=patch

# Then build and ship the docker image
cd /home/gavin/work/sb/release
make release-patch    # or minor, major
```

That's it. The workflow resolves latest versions, builds, pushes to GHCR, and
writes a release note listing every component version included.

## Inspecting what's in a running image

```bash
docker inspect ghcr.io/slidebolt/slidebolt:latest \
  --format '{{json .Config.Labels}}' | jq 'to_entries | map(select(.key | startswith("org.slidebolt."))) | from_entries'
```

## SDK base packages (sdk-types, sdk-runner, sdk-entities)

Release by triggering their workflow. Component releases will pick up the new
SDK version automatically on next release (via `go get @latest` in their CI).

```bash
gh workflow run release.yml --repo slidebolt/sdk-types -f bump=patch
```
