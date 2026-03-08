#!/usr/bin/env bash
set -euo pipefail

# release/scripts/feature-start.sh - Create a feature branch across all repos

BRANCH_NAME="${1:-}"

if [[ -z "$BRANCH_NAME" ]]; then
  echo "Usage: $0 <branch-name>"
  exit 1
fi

COMPONENTS=$(jq -r '.[].id' components.json)
CORE="gateway launcher"
SDKS="sdk-types sdk-entities sdk-runner"

# Build list of all local directories
DIRS=""
for sdk in $SDKS; do DIRS="$DIRS ../work/raw/$sdk"; done
for id in $COMPONENTS $CORE; do DIRS="$DIRS ../work/raw/$id"; done

echo ">>> Creating feature branch '$BRANCH_NAME' across all repos..."

for dir in $DIRS; do
  if [ -d "$dir" ]; then
    echo ">>> Processing $dir"
    # 1. Sync main
    git -C "$dir" checkout main
    git -C "$dir" pull --rebase origin main
    
    # 2. Create and switch to new branch
    if git -C "$dir" show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
      echo ">>> Branch '$BRANCH_NAME' already exists in $dir, skipping creation."
      git -C "$dir" checkout "$BRANCH_NAME"
    else
      git -C "$dir" checkout -b "$BRANCH_NAME"
    fi
  else
    echo ">>> Skipping $dir (not found)"
  fi
done

echo ">>> Feature branch '$BRANCH_NAME' ready in all repositories."
