#!/bin/bash
# Sync public skills to julianrubisch/skills repo
#
# Usage: ./scripts/sync-public.sh
#
# Requires: gh CLI authenticated, push access to julianrubisch/skills
#
# When the version in marketplace.json differs from the latest GitHub release,
# a new release is created with notes extracted from CHANGELOG.md.

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
gh repo clone "$PUBLIC_REPO" "$WORK_DIR/skills" -- --depth 1 2>&1 || true

# Ensure target directory exists (empty repos may not create it properly)
mkdir -p "$WORK_DIR/skills"

# Initialize if empty clone didn't set up git
if [ ! -d "$WORK_DIR/skills/.git" ]; then
  cd "$WORK_DIR/skills"
  git init
  git remote add origin "git@github.com:$PUBLIC_REPO.git"
  git checkout -b main
else
  cd "$WORK_DIR/skills"
fi

echo "==> Syncing files..."
# Remove old content (preserve .git)
find . -maxdepth 1 -not -name '.git' -not -name '.' -not -name '..' -exec rm -rf {} +

# Copy new content
cp -r "$DIST_DIR"/. .

# Check for changes
if git diff --quiet 2>/dev/null && [ -z "$(git ls-files --others --exclude-standard)" ]; then
  echo "==> No changes to sync"
  exit 0
fi

git add -A
git commit -m "Sync from private repo @ $SHORT_SHA"
git push -u origin main

echo "==> Synced to $PUBLIC_REPO @ $SHORT_SHA"

# --- Release creation ---
# Read version from marketplace.json
LOCAL_VERSION=$(python3 -c "import json; print(json.load(open('.claude-plugin/marketplace.json'))['version'])" 2>/dev/null || true)

if [ -z "$LOCAL_VERSION" ]; then
  echo "==> No version field in marketplace.json, skipping release"
  exit 0
fi

TAG="v$LOCAL_VERSION"

# Check if this release already exists
LATEST_RELEASE=$(gh release view "$TAG" --repo "$PUBLIC_REPO" --json tagName --jq '.tagName' 2>/dev/null || true)

if [ "$LATEST_RELEASE" = "$TAG" ]; then
  echo "==> Release $TAG already exists, skipping"
  exit 0
fi

echo "==> Creating release $TAG on $PUBLIC_REPO..."

# Extract release notes from CHANGELOG.md
# Grabs everything between "## v1.0.0" and the next "## " heading
RELEASE_NOTES=""
if [ -f CHANGELOG.md ]; then
  RELEASE_NOTES=$(awk "/^## $TAG\$/{found=1; next} /^## /{if(found) exit} found{print}" CHANGELOG.md)
fi

if [ -z "$RELEASE_NOTES" ]; then
  RELEASE_NOTES="Release $TAG — see CHANGELOG.md for details."
fi

gh release create "$TAG" \
  --repo "$PUBLIC_REPO" \
  --title "$TAG" \
  --notes "$RELEASE_NOTES"

echo "==> Released $TAG on $PUBLIC_REPO"
