#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
if "$ROOT/workshop.command" desktop-setup; then
  exec "$ROOT/.desktop-venv/bin/python" "$ROOT/workshop.py" app --desktop "$@"
fi
echo 'Desktop web view unavailable. Opening the browser interface.' >&2
exec "$ROOT/workshop.command" app "$@"
