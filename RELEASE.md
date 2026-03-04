# Slidebolt Release Process

This repository orchestrates the official release process for the entire Slidebolt ecosystem.

## Confirmed Release Order (Source First)

This is the verified order that produces a successful end-to-end release.

1. **Release source repos first (raw modules)**
   - Commit code changes in each affected raw repo.
   - Ensure `go.mod` only references tags that exist on remote.
   - Run `go mod tidy` so `go.sum` is complete.
   - Create patch tags and push `main --tags`.

2. **Wait for component release workflows to finish**
   - Each tagged component repo must publish GitHub Release assets, not just tags.
   - Required asset format is:
     - `{binary}_{version}_linux_amd64.tar.gz`
   - Example: `gateway_1.6.3_linux_amd64.tar.gz`.

3. **Update production lock in slidebolt/slidebolt**
   - Update `cmd/runner/templates/prod/production.lock.json` to the new component tags.
   - Push to `main` before triggering this repo’s release workflow.

4. **Trigger release image build from this repo**
   - Run:
     ```bash
     make release-patch
     ```
     or:
     ```bash
     gh workflow run release.yml --repo slidebolt/release -f bump=patch
     ```
   - The workflow bumps `VERSION`, tags this repo, downloads binaries from lockfile tags, builds/pushes `ghcr.io/slidebolt/slidebolt`, and creates a GitHub Release.

## Critical Checks

Run these checks before triggering `release`:

1. All lockfile components have a release:
   ```bash
   gh release view <tag> --repo <org/repo>
   ```
2. All required assets exist on those releases:
   - `gateway_*_linux_amd64.tar.gz`
   - `launcher_*_linux_amd64.tar.gz`
   - each enabled plugin binary tarball
3. `production.lock.json` tags match what was actually released.

## Notes

- A tag existing locally is not enough; it must be pushed and have release assets.
- If a component release workflow fails, fix that component repo first, retag with a new patch version, update `production.lock.json`, then rerun this release workflow.
