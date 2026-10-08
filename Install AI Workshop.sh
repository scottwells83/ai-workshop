#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != Linux ]]; then
  echo 'This setup is for Linux.' >&2
  exit 1
fi
SOURCE="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/ai-workshop"
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:$PATH"
echo 'AI Workshop — Linux setup'

if [[ "$SOURCE" != "$DEST" ]]; then
  if [[ -e "$DEST" ]]; then
    echo "Existing workshop preserved at $DEST. Using it without overwriting files."
  else
    mkdir -p "$DEST"
    cp -a "$SOURCE/." "$DEST/"
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

command -v curl >/dev/null 2>&1 || {
  echo 'curl is required to install missing Linux dependencies.' >&2
  exit 1
}
if ! command -v ollama >/dev/null 2>&1; then
  echo 'Installing Ollama from its official installer...'
  OLLAMA_TMP="$(mktemp)"
  trap 'rm -f "$OLLAMA_TMP"' EXIT
  curl -fsSL https://ollama.com/install.sh -o "$OLLAMA_TMP"
  sh "$OLLAMA_TMP"
  rm -f "$OLLAMA_TMP"
  trap - EXIT
fi
command -v ollama >/dev/null 2>&1 || {
  echo 'Ollama command unavailable after installation.' >&2
  exit 1
}

if ! curl -fsS --max-time 2 http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
  nohup ollama serve >"$DEST/ollama-startup.log" 2>&1 &
fi
for _ in {1..30}; do
  if curl -fsS --max-time 2 http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then break; fi
  sleep 2
done
if ! curl -fsS --max-time 2 http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
  echo 'Ollama did not start. Start the Ollama service, then rerun setup.' >&2
  exit 1
fi

bash "$DEST/create-agents.sh"
if ! command -v python3 >/dev/null 2>&1 ||
   ! python3 -c 'import sys; assert sys.version_info >= (3, 11)' >/dev/null 2>&1; then
  UV="$HOME/.local/bin/uv"
  if [[ ! -x "$UV" ]]; then
    echo 'Installing uv from its official installer...'
    UV_TMP="$(mktemp)"
    trap 'rm -f "$UV_TMP"' EXIT
    curl -fsSL https://astral.sh/uv/install.sh -o "$UV_TMP"
    sh "$UV_TMP"
    rm -f "$UV_TMP"
    trap - EXIT
  fi
  [[ -x "$UV" ]] || { echo 'uv unavailable after installation.' >&2; exit 1; }
  "$UV" python install 3.11
fi

bash "$DEST/workshop.sh" doctor
bash "$DEST/workshop.sh" desktop-setup
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/ai-workshop.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=AI Workshop
Comment=Local AI Workshop Manager
Exec="$DEST/Open AI Workshop.sh"
Icon=$DEST/desktop/ai-workshop.svg
Terminal=false
Categories=Office;Utility;
EOF
echo "Workshop ready at $DEST"
echo 'Docker and Open WebUI are optional and are not installed by this Linux setup.'
