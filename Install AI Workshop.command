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
  cp "$DEST/chatgpt-custom-instructions.md" "$HOME/.codex/AGENTS.md"
  echo 'Added the short Codex entry instructions.'
fi

if ! command -v ollama >/dev/null 2>&1; then
  echo 'Installing Ollama from its official installer...'
  TMP="$(mktemp)"
  trap 'rm -f "$TMP"' EXIT
  curl -fsSL https://ollama.com/install.sh -o "$TMP"
  sh "$TMP"
fi
if ! command -v ollama >/dev/null 2>&1 && [[ -x /Applications/Ollama.app/Contents/Resources/ollama ]]; then
  mkdir -p "$HOME/.local/bin"
  ln -sfn /Applications/Ollama.app/Contents/Resources/ollama "$HOME/.local/bin/ollama"
fi
command -v ollama >/dev/null 2>&1 || { echo 'Ollama command unavailable after installation.' >&2; exit 1; }
RAM_BYTES="$(sysctl -n hw.memsize)"
if (( RAM_BYTES >= 25769803776 )); then
  export OLLAMA_NUM_PARALLEL=2
  launchctl setenv OLLAMA_NUM_PARALLEL 2
  echo 'Configured up to two Ollama requests per model after Ollama restarts.'
fi
open -a Ollama >/dev/null 2>&1 || true
if ! curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
  nohup ollama serve >"$DEST/ollama-startup.log" 2>&1 &
fi
for _ in {1..30}; do
  if curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then break; fi
  sleep 2
done
if ! curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
  echo 'Ollama did not start. Open the Ollama app, then run this installer again.' >&2
  exit 1
fi

bash "$DEST/create-agents.sh"
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
"$DEST/workshop.command" doctor

export PATH="$HOME/.docker/bin:/Applications/Docker.app/Contents/Resources/bin:$PATH"
if ! command -v docker >/dev/null 2>&1 && [[ ! -d /Applications/Docker.app ]]; then
  if command -v brew >/dev/null 2>&1; then
    echo 'Installing Docker Desktop to host Open WebUI...'
    brew install --cask docker || true
  fi
  if [[ ! -d /Applications/Docker.app ]]; then
    echo 'Downloading Docker Desktop from its official source...'
    DOCKER_TMP="$(mktemp -d)"
    if [[ "$(uname -m)" == arm64 ]]; then DOCKER_ARCH=arm64; else DOCKER_ARCH=amd64; fi
    if curl -fL "https://desktop.docker.com/mac/main/$DOCKER_ARCH/Docker.dmg" -o "$DOCKER_TMP/Docker.dmg" &&
       hdiutil attach "$DOCKER_TMP/Docker.dmg" -nobrowse -quiet -mountpoint "$DOCKER_TMP/mount"; then
      sudo ditto "$DOCKER_TMP/mount/Docker.app" /Applications/Docker.app
      hdiutil detach "$DOCKER_TMP/mount" -quiet || true
    fi
    rm -rf "$DOCKER_TMP"
  fi
fi
if command -v docker >/dev/null 2>&1; then
  open -a Docker >/dev/null 2>&1 || true
  for _ in {1..30}; do
    if docker info >/dev/null 2>&1; then break; fi
    sleep 2
  done
  if docker info >/dev/null 2>&1; then
    if docker container inspect ai-workshop-webui >/dev/null 2>&1; then
      docker start ai-workshop-webui >/dev/null
    elif docker container inspect open-webui >/dev/null 2>&1; then
      docker start open-webui >/dev/null
    else
      docker run -d --name ai-workshop-webui --restart unless-stopped \
        -p 127.0.0.1:3000:8080 \
        -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
        -v ai-workshop-webui:/app/backend/data \
        ghcr.io/open-webui/open-webui:main
    fi
    echo 'Open WebUI: check http://localhost:3000 after startup.'
  else
    echo 'Docker Desktop is installed but not ready. Open it, accept its terms, then rerun setup for Open WebUI.'
  fi
else
  echo 'Open WebUI setup needs Docker Desktop. Install or start it, then rerun setup.'
fi
echo "Workshop ready at $DEST"
