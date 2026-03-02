# Slidebolt Release Process

This repository orchestrates the official release process for the entire Slidebolt ecosystem.

## How to Trigger a Release

Official releases are triggered using the `Makefile`, which uses the GitHub CLI (`gh`) to initiate remote workflows.

### Steps:

1.  **Ensure you are on the `main` branch** and have the latest changes.
2.  **Determine the release type**:
    *   **Patch**: Bug fixes and minor updates (`v1.0.1` -> `v1.0.2`)
    *   **Minor**: New features, non-breaking (`v1.0.2` -> `v1.1.0`)
    *   **Major**: Breaking changes (`v1.1.0` -> `v2.0.0`)
3.  **Run the command**:
    ```bash
    make release-patch  # or release-minor, release-major
    ```

## What Happens Next?

1.  **GitHub Action**: The `release.yml` workflow is triggered in this repository.
2.  **Versioning**: The `VERSION` file is updated and a new Git tag is created.
3.  **Packaging**: The workflow triggers builds across the dependent component repositories (gateway, plugins).
4.  **Artifacts**: Official binaries are compiled, archived, and attached to a new GitHub Release in their respective repositories.
5.  **Lock Update**: The `production.lock.json` in the runner is eventually updated to point to these new tags.
