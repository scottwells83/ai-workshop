#!/usr/bin/env bash
set -euo pipefail
SOURCE="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/ai-workshop"
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

echo 'AI Workshop — a local-first workspace for AI-assisted projects (macOS setup)'
if [[ "$SOURCE" != "$DEST" ]]; then
  if [[ -e "$DEST" ]]; then
    echo "Existing workshop preserved at $DEST. Using it without overwriting files."
  else
    ditto "$SOURCE" "$DEST"
    echo "Copied workshop to $DEST"
  fi
fi

mkdir -p "$HOME/.codex"
if [[ ! -e "$HOME/.codex/AGENTS.md" ]]; then
  cp "$DEST/universal-custom-instructions.md" "$HOME/.codex/AGENTS.md"
  echo 'Added the short Codex entry instructions.'
fi

mkdir -p "$HOME/.config/opencode" "$HOME/.copilot"
if [[ ! -e "$HOME/.config/opencode/AGENTS.md" ]]; then
  cp "$DEST/universal-custom-instructions.md" "$HOME/.config/opencode/AGENTS.md"
  echo 'Added OpenCode user instructions.'
fi
if [[ ! -e "$HOME/.copilot/copilot-instructions.md" ]]; then
  cp "$DEST/universal-custom-instructions.md" "$HOME/.copilot/copilot-instructions.md"
  echo 'Added GitHub Copilot CLI user instructions.'
fi

if [[ ! -f "$DEST/runtime/ollama/entrypoint.txt" ]]; then
  echo 'This package is missing its bundled Ollama helper.' >&2
  exit 1
fi
RAM_BYTES="$(sysctl -n hw.memsize)"
if (( RAM_BYTES >= 25769803776 )); then
  export OLLAMA_NUM_PARALLEL=2
fi

if ! command -v python3 >/dev/null 2>&1 ||
   ! python3 -c 'import sys; assert sys.version_info >= (3, 11)' >/dev/null 2>&1; then
  if [[ -x "$HOME/.local/bin/uv" ]]; then
    echo 'Using the existing uv Python runtime.'
  else
    echo 'Installing the uv Python runtime from its official installer...'
    UV_TMP="$(mktemp)"
    curl -fsSL https://astral.sh/uv/install.sh -o "$UV_TMP"
    sh "$UV_TMP"
    rm -f "$UV_TMP"
  fi
fi
if ! command -v python3 >/dev/null 2>&1 ||
   ! python3 -c 'import sys; assert sys.version_info >= (3, 11)' >/dev/null 2>&1; then
  "$HOME/.local/bin/uv" python install 3.11
fi
"$DEST/workshop.command" desktop-setup
echo "Desktop app: $DEST/AI Workshop.app"

echo "Workshop ready at $DEST. Open AI Workshop to prepare local models."
