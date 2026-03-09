#!/bin/bash
# Sync public skills to julianrubisch/skills repo
#
# Usage: ./scripts/sync-public.sh
#
# Requires: gh CLI authenticated, push access to julianrubisch/skills

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PUBLIC_REPO="julianrubisch/skills"
DIST_DIR="$REPO_ROOT/dist-public"
WORK_DIR=$(mktemp -d)
SHORT_SHA=$(git -C "$REPO_ROOT" rev-parse --short HEAD)

trap 'rm -rf "$WORK_DIR" "$DIST_DIR"' EXIT

echo "==> Building public distribution..."
"$SCRIPT_DIR/publish.sh" --public "$DIST_DIR"

echo "==> Cloning $PUBLIC_REPO..."
gh repo clone "$PUBLIC_REPO" "$WORK_DIR/skills" -- --depth 1

echo "==> Syncing files..."
# Remove old content (preserve .git)
find "$WORK_DIR/skills" -maxdepth 1 -not -name '.git' -not -name '.' -not -name '..' -exec rm -rf {} +

# Copy new content
cp -r "$DIST_DIR"/* "$WORK_DIR/skills/"

cd "$WORK_DIR/skills"

# Check for changes
if git diff --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
  echo "==> No changes to sync"
  exit 0
fi

git add -A
git commit -m "Sync from private repo @ $SHORT_SHA"
git push

echo "==> Synced to $PUBLIC_REPO @ $SHORT_SHA"
