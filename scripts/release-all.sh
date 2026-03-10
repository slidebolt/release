#!/usr/bin/env bash
set -euo pipefail

# release/scripts/release-all.sh - Orchestrates the entire Slidebolt release process.

BUMP="${1:-patch}"             # patch|minor|major
GUARD_FILE="scripts/.release_guard"

if [[ "$BUMP" != "patch" && "$BUMP" != "minor" && "$BUMP" != "major" ]]; then
  echo "BLOCKED: bump must be one of patch|minor|major (got: $BUMP)"
  exit 1
fi

if [[ -z "${RELEASE_GUARD:-}" && -f "$GUARD_FILE" ]]; then
  RELEASE_GUARD="$(tr -d '
' < "$GUARD_FILE")"
fi

if [[ -z "${RELEASE_GUARD:-}" ]]; then
  echo "BLOCKED: RELEASE_GUARD is not set."
  exit 1
fi

release_and_wait() {
  local repo=$1
  echo ">>> Releasing $repo ($BUMP)..."
  gh workflow run release.yml --repo "slidebolt/$repo" -f bump="$BUMP" -f release_guard="$RELEASE_GUARD"
  
  # Give it a few seconds to register the run
  sleep 5
  
  echo ">>> Waiting for $repo release to complete..."
  gh run watch --repo "slidebolt/$repo"
  echo ">>> $repo released successfully."
}

# --- Phase 1: SDKs (Sequential) ---
# Order matters: types -> entities -> registry -> runner
# registry depends on sdk-types; sdk-runner depends on sdk-entities and registry
release_and_wait "sdk-types"
release_and_wait "sdk-entities"
release_and_wait "registry"
release_and_wait "sdk-runner"

# --- Phase 2: Components (Parallel) ---
echo ">>> Triggering parallel release for all components..."
COMPONENTS=$(jq -r '.[].id' components.json)
CORE="gateway launcher"

for id in $COMPONENTS $CORE; do
  # Skip if it's already released in Phase 1 (though SDKs aren't in components.json usually)
  repo=$id
  if [[ "$id" == plugin-* ]]; then repo="$id"; fi
  
  echo ">>> Dispatching $repo..."
  gh workflow run release.yml --repo "slidebolt/$repo" -f bump="$BUMP" -f release_guard="$RELEASE_GUARD" &
done

echo ">>> Waiting for all component releases to finish..."
wait
echo ">>> All components triggered. (Note: 'wait' only waits for background dispatch, checking status manually is recommended or use 'gh run list')"

# --- Phase 3: Docker Image ---
echo ">>> Releasing Slidebolt Docker image..."
make "release-$BUMP"

# --- Phase 4: Post-Release Cleanup (Local Sync) ---
echo ">>> Syncing local repositories with remote updates..."
# List of all directories to pull
DIRS="../work/raw/sdk-types ../work/raw/sdk-entities ../work/raw/registry ../work/raw/sdk-runner"
for id in $COMPONENTS $CORE; do
  DIRS="$DIRS ../work/raw/$id"
done

for dir in $DIRS; do
  if [ -d "$dir" ]; then
    echo ">>> Pulling in $dir"
    git -C "$dir" pull --rebase origin main --tags
  fi
done

echo ">>> RELEASE COMPLETE! <<<"
