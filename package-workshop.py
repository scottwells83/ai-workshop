#!/usr/bin/env python3
"""Create a private portable AI Workshop ZIP from this folder."""

from pathlib import Path
import sys
from zipfile import ZipFile, ZIP_DEFLATED

root = Path(__file__).resolve().parent
target = Path(sys.argv[1]).expanduser().resolve() if len(sys.argv) > 1 else root.parent / "AI-Workshop-Personal.zip"
target.parent.mkdir(parents=True, exist_ok=True)
excluded = {
    ".DS_Store", "__pycache__", ".git", ".venv", "venv",
    "bin", "obj", "node_modules",
}
with ZipFile(target, "w", ZIP_DEFLATED) as archive:
    for path in sorted(root.rglob("*")):
        if not path.is_file() or path.suffix == ".log" or any(part in excluded for part in path.relative_to(root).parts):
            continue
        archive.write(path, Path("AI-Workshop") / path.relative_to(root))
print(target)
