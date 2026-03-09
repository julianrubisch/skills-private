#!/bin/bash
# Publish skills by resolving symlinks into real copies
# Usage: ./scripts/publish.sh [output_dir]

set -euo pipefail

OUTPUT_DIR="${1:-dist}"

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# cp -rL follows symlinks and copies real files
cp -rL skills/ "$OUTPUT_DIR/"

echo "Published to $OUTPUT_DIR/ with symlinks resolved"
ls -la "$OUTPUT_DIR/"
