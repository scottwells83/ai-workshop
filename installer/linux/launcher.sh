#!/usr/bin/env bash
set -euo pipefail
if [[ "$(uname -s)" != Linux ]]; then
  echo 'AI Workshop Linux installer requires Linux.' >&2
  exit 1
fi
if [[ "$(uname -m)" != x86_64 ]]; then
  echo 'This Linux development installer supports x86-64 computers.' >&2
  exit 1
fi
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
if ! command -v zstd >/dev/null 2>&1; then
  if [[ "${1:-}" == '--verify-only' ]]; then
    echo 'Package verification requires zstd.' >&2
    exit 1
  fi
  echo 'Installing the small archive decoder needed for this package...'
  RUN_AS_ROOT=()
  if [[ "$(id -u)" != 0 ]]; then RUN_AS_ROOT=(sudo); fi
  if command -v apt-get >/dev/null 2>&1; then
    "${RUN_AS_ROOT[@]}" apt-get update && "${RUN_AS_ROOT[@]}" apt-get install -y zstd
  elif command -v dnf >/dev/null 2>&1; then
    "${RUN_AS_ROOT[@]}" dnf install -y zstd
  elif command -v pacman >/dev/null 2>&1; then
    "${RUN_AS_ROOT[@]}" pacman -S --noconfirm zstd
  fi
fi
command -v zstd >/dev/null 2>&1 || { echo 'zstd is required to unpack this Linux installer.' >&2; exit 1; }
LINE="$(awk '/^__AI_WORKSHOP_ARCHIVE_BELOW__$/ { print NR + 1; exit }' "$0")"
[[ -n "$LINE" ]] || { echo 'Installer payload marker missing.' >&2; exit 1; }
tail -n +"$LINE" "$0" | zstd -dc | tar -xf - -C "$TMP"
PAYLOAD="$TMP/ai-workshop"
[[ -f "$PAYLOAD/Install AI Workshop.sh" && -f "$PAYLOAD/workshop.py" ]] || {
  echo 'Installer payload is incomplete.' >&2
  exit 1
}
printf '%s  %s\n' '726bee78706c281b0eeef00746efe51a044d71c592c3f0b195820707f31fdf04' "$PAYLOAD/runtime/ollama.tar.zst" | sha256sum -c -
if [[ "${1:-}" == '--verify-only' ]]; then
  [[ -f "$PAYLOAD/universal-custom-instructions.md" && -f "$PAYLOAD/RELEASE_NOTES.md" ]] || exit 1
  [[ ! -f "$PAYLOAD/usage-log.jsonl" && ! -f "$PAYLOAD/projects/jobs.json" ]] || exit 1
  bash -n "$PAYLOAD/Install AI Workshop.sh" "$PAYLOAD/Open AI Workshop.sh" "$PAYLOAD/workshop.sh" "$PAYLOAD/create-agents.sh"
  python3 -m py_compile "$PAYLOAD/workshop.py" "$PAYLOAD/workshop_app.py" "$PAYLOAD/ollama_runtime.py"
  echo 'AI Workshop Linux installer payload verified.'
  exit 0
fi
bash "$PAYLOAD/Install AI Workshop.sh"
exit $?
__AI_WORKSHOP_ARCHIVE_BELOW__
