# Git Workflow for release

This repository coordinates the creation of the Slidebolt Docker image by fetching pre-built binaries from other repositories.

## Dependencies
- **Internal:** Depends on the latest GitHub Releases of:
  - `sb-manager`, `sb-messenger`, `sb-storage`, `sb-api`, `sb-script`, `sb-virtual`, `sb-logging`, `sb-cli`.
  - All `plugin-*` repositories that produce binaries.
- **External:** 
  - Docker.
  - Bash and cURL (for fetching binaries).

## Build Process
- **Type:** Docker Image Build.
- **Consumption:** Pulled by production environments to run the Slidebolt stack.
- **Artifacts:** Unified Docker image containing all Slidebolt binaries.
- **Commands:**
  1. Update `versions.env` with latest tags.
  2. Run `./fetch-binaries.sh` to download assets into `dist/`.
  3. Run `docker build -t slidebolt:latest .`.
- **Validation:** 
  - Validated by checking that all binaries are present and executable in the image.

## Pre-requisites & Publishing
This repository should be updated **last**, after all core services and plugins have been tagged and their GitHub Releases have been automatically created.

**Before publishing:**
1. Ensure all dependent repositories have successfully completed their `Release` workflows.
2. Verify that binaries are available in the GitHub Releases of those repositories.

**Publishing Order:**
1. Update `versions.env`.
2. Update `fetch-binaries.sh` if new components were added.
3. Commit and push the changes to `main`.
4. Determine next semantic version for the image (e.g., `v1.0.0`).
5. Tag the repository: `git tag v1.0.0`.
6. Push the tag: `git push origin main v1.0.0`.

## Update Workflow & Verification
1. **Modify:** Update version strings in `versions.env`.
2. **Verify Local:**
   - Run `./fetch-binaries.sh`.
   - Run `docker build -t slidebolt:test .`.
   - Run `docker run --rm slidebolt:test sb-manager --version` (or similar).
3. **Commit:** Ensure the commit message lists the major version bumps.
4. **Tag & Push:** (Follow the Publishing Order above).
