#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
command -v ollama >/dev/null || { echo 'Ollama is required.' >&2; exit 1; }
ollama create local-worker -f "$ROOT/Modelfile"
ollama create local-drafter -f "$ROOT/Modelfile.drafter"
for role in chief-of-staff watcher sweeper archivist usage-analyst; do
  ollama create "$role" -f "$ROOT/agents/Modelfile.$role"
done
echo 'Workshop models created.'
