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

if [[ ! -f "$DEST/runtime/ollama/entrypoint.txt" && -f "$DEST/runtime/ollama.tar.zst" ]]; then
  echo 'Preparing the bundled Ollama helper...'
  printf '%s  %s\n' '726bee78706c281b0eeef00746efe51a044d71c592c3f0b195820707f31fdf04' "$DEST/runtime/ollama.tar.zst" | sha256sum -c -
  mkdir -p "$DEST/runtime/ollama"
  zstd -dc "$DEST/runtime/ollama.tar.zst" | tar -xf - -C "$DEST/runtime/ollama"
  printf 'bin/ollama\n' > "$DEST/runtime/ollama/entrypoint.txt"
  cp "$DEST/runtime/OLLAMA-LICENSE.txt" "$DEST/runtime/ollama/OLLAMA-LICENSE.txt"
  rm "$DEST/runtime/ollama.tar.zst"
fi
if [[ ! -f "$DEST/runtime/ollama/entrypoint.txt" ]]; then
  echo 'This package is missing its bundled Ollama helper.' >&2
  exit 1
fi

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
echo 'Open AI Workshop to prepare local models. Docker and Open WebUI are not installed.'
