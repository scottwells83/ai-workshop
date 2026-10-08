#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
command -v ollama >/dev/null || { echo 'Ollama is required.' >&2; exit 1; }
ollama create local-worker -f "$ROOT/Modelfile"
ollama create local-drafter -f "$ROOT/Modelfile.drafter"
for role in chief-of-staff watcher sweeper archivist usage-analyst; do
  ollama create "$role" -f "$ROOT/agents/Modelfile.$role"
done
# Optional heavier reviewer (needs ~20 GB): created only when its base model is already pulled.
if ollama list | grep -q '^qwen3:32b'; then
  ollama create local-reviewer -f "$ROOT/agents/Modelfile.reviewer"
else
  echo 'Skipping optional local-reviewer because qwen3:32b is not installed.'
fi
echo 'Workshop models created.'
