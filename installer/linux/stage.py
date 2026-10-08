#!/usr/bin/env python3
"""Stage the public Linux installer payload without personal state."""

from pathlib import Path
import shutil
import sys

ROOT = Path(__file__).resolve().parents[2]
if len(sys.argv) != 2:
    raise SystemExit("Usage: stage.py STAGING_DIRECTORY")
DEST = Path(sys.argv[1]).resolve()
if DEST == ROOT or ROOT in DEST.parents:
    raise SystemExit("Staging directory must be outside the Workshop source")
if DEST.exists():
    shutil.rmtree(DEST)
PAYLOAD = DEST / "ai-workshop"
PAYLOAD.mkdir(parents=True)

FILES = (
    "AGENTS.md", "manager-instructions.md", "chatgpt-custom-instructions.md",
    "universal-custom-instructions.md", "README.md", "RELEASE_NOTES.md",
    "Modelfile", "Modelfile.drafter", "workshop.py", "workshop.sh",
    "Install AI Workshop.sh", "create-agents.sh", "templates/project.md",
)
for name in FILES:
    target = PAYLOAD / name
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT / name, target)
for name in ("agents", "guides"):
    shutil.copytree(ROOT / name, PAYLOAD / name)
for name in ("projects", "memory"):
    (PAYLOAD / name).mkdir()
(PAYLOAD / "projects" / "README.md").write_text("# AI Workshop projects\n", encoding="utf-8")
print(DEST)
