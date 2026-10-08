#!/usr/bin/env python3
"""Stage a macOS disk image without personal Workshop state."""

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
    "universal-custom-instructions.md", "universal-custom-instructions-short.md", "gemini-ai-workshop-instructions.md",
    "README.md", "RELEASE_NOTES.md", "SETUP_GUIDE.md", "USER_MANUAL.md", "CHANGELOG.md", "RELEASE_READINESS.md", "Modelfile", "Modelfile.drafter", "workshop.py", "workshop_app.py", "desktop_setup.py",
    "workshop.command", "Open AI Workshop.command", "Install AI Workshop.command", "create-agents.sh",
    ".github/copilot-instructions.md",
    "templates/project.md",
)
for name in FILES:
    target = PAYLOAD / name
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT / name, target)
for name in ("agents", "guides", "ui"):
    shutil.copytree(ROOT / name, PAYLOAD / name)
shutil.copytree(ROOT / "desktop" / "macos" / "AI Workshop.app", PAYLOAD / "AI Workshop.app")
for name in ("projects", "memory"):
    (PAYLOAD / name).mkdir()
(PAYLOAD / "projects" / "README.md").write_text("# AI Workshop projects\n", encoding="utf-8")
(DEST / "START HERE.txt").write_text(
    "Open the ai-workshop folder and double-click Install AI Workshop.command.\n"
    "After setup, open ~/ai-workshop/AI Workshop.app for its own desktop window.\n"
    "Setup downloads Ollama, model weights, and Python when needed. Internet access is required.\n"
    "Docker Desktop and Open WebUI are optional. Existing ~/ai-workshop files are preserved.\n"
    "This disk image is unsigned; macOS may ask you to approve opening it.\n",
    encoding="utf-8",
)
print(DEST)
