#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
if command -v python3 >/dev/null 2>&1 &&
   python3 -c 'import sys; assert sys.version_info >= (3, 11)' >/dev/null 2>&1; then
  exec python3 "$ROOT/workshop.py" "$@"
fi
if [[ -x "$HOME/.local/bin/uv" ]]; then
  exec "$HOME/.local/bin/uv" run --python 3.11 "$ROOT/workshop.py" "$@"
fi
echo 'Python 3.11+ or uv is required. Run Install AI Workshop.sh.' >&2
exit 1
