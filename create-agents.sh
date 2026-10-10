#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
PYTHON=python3
if [[ -x "$ROOT/.desktop-venv/bin/python" ]]; then PYTHON="$ROOT/.desktop-venv/bin/python"; fi
"$PYTHON" - "$ROOT" <<'PY'
from pathlib import Path
import sys
sys.path.insert(0, sys.argv[1])
import ollama_runtime
process = ollama_runtime.start()
try:
    ollama_runtime.ensure_models(print)
    print('Workshop models created.')
finally:
    ollama_runtime.stop(process)
PY
