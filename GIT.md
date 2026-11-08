# Git Workflow for release

Layer 9 (Delivery), released last. See the workspace's root `GIT.md` for the
layered process and `README.md` here for the release steps.

- `versions.env` must name the tag of every repo `image/Dockerfile` copies;
  `build.sh` refuses to build otherwise. Write it with `./build.sh --pin <workspace>`.
- CI (`.github/workflows/release-image.yml`) builds from those tags on every
  `v*` tag and publishes `ghcr.io/slidebolt/release:<tag>` and `:latest`.
