#!/usr/bin/env bash
set -euo pipefail

# release/scripts/feature-finish.sh - Merge a feature branch across all repos

BRANCH_NAME="${1:-}"

if [[ -z "$BRANCH_NAME" ]]; then
  echo "Usage: $0 <branch-name>"
  exit 1
fi

COMPONENTS=$(jq -r '.[].id' components.json)
CORE="gateway launcher"
SDKS="sdk-types sdk-entities registry sdk-runner"

# Build list of all local directories
DIRS=""
for sdk in $SDKS; do DIRS="$DIRS ../work/raw/$sdk"; done
for id in $COMPONENTS $CORE; do DIRS="$DIRS ../work/raw/$id"; done

echo ">>> Finalizing and merging feature branch '$BRANCH_NAME'..."

for dir in $DIRS; do
  if [ -d "$dir" ]; then
    echo ">>> Processing $dir"
    
    # 1. Switch back to main and update
    git -C "$dir" checkout main
    git -C "$dir" pull --rebase origin main
    
    # 2. Check if the feature branch exists locally
    if git -C "$dir" show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
      # 3. Merge feature branch into main
      echo ">>> Merging '$BRANCH_NAME' into 'main' in $dir..."
      # Use --no-ff to always create a merge commit, so it's clear what happened
      git -C "$dir" merge --no-ff -m "chore: merge feature '$BRANCH_NAME'" "$BRANCH_NAME" || {
        echo ">>> MERGE CONFLICT in $dir. Please resolve manually, commit, and then rerun or continue."
        exit 1
      }
      
      # 4. Push main
      git -C "$dir" push origin main
      
      # 5. Cleanup: Delete local branch
      git -C "$dir" branch -d "$BRANCH_NAME"
      
      # 6. Cleanup: Delete remote branch (if it was pushed)
      if git -C "$dir" ls-remote --exit-code --heads origin "$BRANCH_NAME" >/dev/null 2>&1; then
        echo ">>> Deleting remote branch 'origin/$BRANCH_NAME'..."
        git -C "$dir" push origin --delete "$BRANCH_NAME"
      fi
    else
      echo ">>> Branch '$BRANCH_NAME' not found in $dir, skipping merge."
    fi
    
    # Final fresh pull to ensure everything is perfectly in sync
    git -C "$dir" pull --rebase origin main --tags
  else
    echo ">>> Skipping $dir (not found)"
  fi
done

echo ">>> Feature branch '$BRANCH_NAME' finalized and merged in all repositories."
