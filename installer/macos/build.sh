#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/ai-workshop-macos.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT
OUTPUT="${1:-$ROOT/dist/macos/AI-Workshop-macOS.dmg}"
mkdir -p "$(dirname "$OUTPUT")"
python3 "$ROOT/installer/macos/stage.py" "$STAGE/payload"
hdiutil create -volname 'AI Workshop' -srcfolder "$STAGE/payload" -ov -format UDZO "$OUTPUT"
hdiutil verify "$OUTPUT"
echo "$OUTPUT"
