#!/usr/bin/env python3
"""Stage the public Windows installer payload without personal projects or memory."""

from pathlib import Path
import shutil
import sys

ROOT = Path(__file__).resolve().parents[2]
DEST = Path(sys.argv[1]).resolve() if len(sys.argv) == 2 else ROOT / "dist" / "windows-stage"
FILES = (
    "AGENTS.md", "manager-instructions.md", "chatgpt-custom-instructions.md",
    "README.md", "Modelfile", "Modelfile.drafter", "workshop.py", "workshop.cmd",
    "Install AI Workshop.cmd", "install-windows.ps1",
    "templates/project.md",
)
DIRECTORIES = ("agents", "guides")

if DEST == ROOT or ROOT in DEST.parents and DEST.name != "windows-stage":
    raise SystemExit("Refusing to replace a source directory")
if DEST.exists():
    shutil.rmtree(DEST)
DEST.mkdir(parents=True)
for name in FILES:
    target = DEST / name
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT / name, target)
for name in DIRECTORIES:
    shutil.copytree(ROOT / name, DEST / name)
for name in ("projects", "memory"):
    (DEST / name).mkdir()
(DEST / "projects" / "README.md").write_text("# AI Workshop projects\n", encoding="utf-8")
print(DEST)
