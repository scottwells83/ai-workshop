#!/usr/bin/env bash
set -euo pipefail
if [[ "$(uname -s)" != Linux ]]; then
  echo 'AI Workshop Linux installer requires Linux.' >&2
  exit 1
fi
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
LINE="$(awk '/^__AI_WORKSHOP_ARCHIVE_BELOW__$/ { print NR + 1; exit }' "$0")"
[[ -n "$LINE" ]] || { echo 'Installer payload marker missing.' >&2; exit 1; }
tail -n +"$LINE" "$0" | tar -xz -C "$TMP"
PAYLOAD="$TMP/ai-workshop"
[[ -f "$PAYLOAD/Install AI Workshop.sh" && -f "$PAYLOAD/workshop.py" ]] || {
  echo 'Installer payload is incomplete.' >&2
  exit 1
}
if [[ "${1:-}" == '--verify-only' ]]; then
  [[ -f "$PAYLOAD/universal-custom-instructions.md" && -f "$PAYLOAD/RELEASE_NOTES.md" ]] || exit 1
  [[ ! -f "$PAYLOAD/usage-log.jsonl" && ! -f "$PAYLOAD/projects/jobs.json" ]] || exit 1
  bash -n "$PAYLOAD/Install AI Workshop.sh" "$PAYLOAD/Open AI Workshop.sh" "$PAYLOAD/workshop.sh" "$PAYLOAD/create-agents.sh"
  python3 -m py_compile "$PAYLOAD/workshop.py" "$PAYLOAD/workshop_app.py"
  echo 'AI Workshop Linux installer payload verified.'
  exit 0
fi
bash "$PAYLOAD/Install AI Workshop.sh"
exit $?
__AI_WORKSHOP_ARCHIVE_BELOW__
