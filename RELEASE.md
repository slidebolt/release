# Slidebolt Release Process

This repository orchestrates the official release process for the entire Slidebolt ecosystem.

## Component Releases (plugins, gateway, launcher)

Releases are triggered via GitHub Actions `workflow_dispatch` — **do not create tags manually**.

```bash
gh workflow run release.yml --repo slidebolt/<repo> -f bump=patch
# or: minor, major
```

The workflow automatically:
1. Fetches all tags to determine the current version
2. Runs `go get github.com/slidebolt/sdk-*@latest && go mod tidy` to pick up latest internal deps
3. Bumps the version, commits the updated `go.mod`/`go.sum`, tags, and pushes
4. Builds and publishes `{binary}_{version}_linux_{amd64,arm64}.tar.gz` assets

## SDK Base Package Releases (sdk-types, sdk-runner, sdk-entities)

These have no internal SDK deps. Release by pushing a tag manually:

```bash
cd /home/gavin/work/sb/work/raw/<sdk-repo>
git tag v1.x.x
git push origin main --tags
```

Release these before triggering component releases if they have new changes.

## Main Release (Docker Image)

Once all required components are released and `production.lock.json` is updated:

```bash
cd /home/gavin/work/sb/release
make release-patch    # or minor, major
```

The workflow fetches `production.lock.json` from `slidebolt/slidebolt` main, downloads all
component binaries, builds and pushes `ghcr.io/slidebolt/slidebolt:latest`.

## Updating the Lock File

After releasing components, update `slidebolt-runner/cmd/runner/templates/prod/production.lock.json`
and push to main before triggering the main release:

```bash
cd /home/gavin/work/sb/slidebolt-runner
# Edit: cmd/runner/templates/prod/production.lock.json
git add cmd/runner/templates/prod/production.lock.json
git commit -m "chore: update component versions"
git push origin main
```

## Critical Checks Before Main Release

Verify release assets exist for every component in the lock file:

```bash
gh release view <tag> --repo slidebolt/<repo>
```

Required asset format: `{binary}_{version}_linux_amd64.tar.gz`

## Notes

- A tag existing locally is not enough; it must be pushed and have release assets.
- If a component release workflow fails, re-run via `gh workflow run release.yml --repo slidebolt/<repo> -f bump=patch`.
- `production.lock.json` must be pushed to `slidebolt/slidebolt` main before triggering the main release workflow.
