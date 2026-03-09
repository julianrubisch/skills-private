#!/bin/bash
# Publish skills by resolving symlinks into real copies
#
# Usage:
#   ./scripts/publish.sh [output_dir]           # all skills (private distribution)
#   ./scripts/publish.sh --public [output_dir]   # public skills only (marketplace)

set -euo pipefail

# Skills included in the public marketplace
PUBLIC_SKILLS=(jr-rails-classic jr-rails-new jr-rails-phlex)

# Reference files excluded from public distribution
PRIVATE_REFERENCE_PATTERNS=(
  "review-*.md"
)

PUBLIC=false

# Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --public) PUBLIC=true; shift ;;
    *) break ;;
  esac
done

OUTPUT_DIR="${1:-dist}"

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

if [ "$PUBLIC" = true ]; then
  echo "Publishing PUBLIC skills to $OUTPUT_DIR/"

  for skill in "${PUBLIC_SKILLS[@]}"; do
    # cp -rL follows symlinks and copies real files
    cp -rL "skills/$skill" "$OUTPUT_DIR/$skill"

    # Remove private reference files from the resolved copies
    for pattern in "${PRIVATE_REFERENCE_PATTERNS[@]}"; do
      find "$OUTPUT_DIR/$skill/reference" -name "$pattern" -delete 2>/dev/null || true
    done
  done

  # Generate marketplace.json
  mkdir -p "$OUTPUT_DIR/.claude-plugin"
  cat > "$OUTPUT_DIR/.claude-plugin/marketplace.json" <<'MARKETPLACE'
{
  "name": "jr-rails-skills",
  "description": "Rails coding skills: classic style, Phlex components, app scaffolder",
  "skills": [
    {
      "name": "jr-rails-classic",
      "path": "jr-rails-classic",
      "description": "Write Rails code in 37signals/classic style"
    },
    {
      "name": "jr-rails-new",
      "path": "jr-rails-new",
      "description": "Scaffold a new Rails app with preferred stack"
    },
    {
      "name": "jr-rails-phlex",
      "path": "jr-rails-phlex",
      "description": "Write Phlex views and components for Rails"
    }
  ]
}
MARKETPLACE

  # Copy public repo files if they exist
  [ -f LICENSE ] && cp LICENSE "$OUTPUT_DIR/"
  [ -f PUBLIC_README.md ] && cp PUBLIC_README.md "$OUTPUT_DIR/README.md"

  echo "Public skills published to $OUTPUT_DIR/"
  echo ""
  echo "Included skills:"
  ls -d "$OUTPUT_DIR"/jr-* 2>/dev/null | xargs -I{} basename {}
  echo ""
  echo "Verification — private reference files (should be empty):"
  for pattern in "${PRIVATE_REFERENCE_PATTERNS[@]}"; do
    find "$OUTPUT_DIR" -name "$pattern" 2>/dev/null
  done
else
  # Full distribution — all skills
  cp -rL skills/ "$OUTPUT_DIR/"

  echo "Published to $OUTPUT_DIR/ with symlinks resolved"
  ls -la "$OUTPUT_DIR/"
fi
