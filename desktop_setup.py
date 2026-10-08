#!/usr/bin/env python3
"""Install AI Workshop's native window dependencies in a private virtual environment."""
from __future__ import annotations

from pathlib import Path
import shutil
import subprocess
import sys
import venv

ROOT = Path(__file__).resolve().parent
ENV = ROOT / ".desktop-venv"
PACKAGE = "pywebview[qt]==6.2.1" if sys.platform.startswith("linux") else "pywebview==6.2.1"


def python_path() -> Path:
    return ENV / ("Scripts/python.exe" if sys.platform == "win32" else "bin/python")


def setup() -> Path:
    python = python_path()
    if not python.exists():
        try:
            venv.EnvBuilder(with_pip=True).create(ENV)
        except (OSError, subprocess.CalledProcessError):
            uv = shutil.which("uv") or str(Path.home() / ".local" / "bin" / ("uv.exe" if sys.platform == "win32" else "uv"))
            if not Path(uv).exists():
                raise
            subprocess.run([uv, "venv", "--python", sys.executable, "--seed", str(ENV)], check=True)
    check = subprocess.run([str(python), "-c", "import webview"], capture_output=True)
    if check.returncode:
        subprocess.run([str(python), "-m", "pip", "install", "--disable-pip-version-check", PACKAGE], check=True)
        subprocess.run([str(python), "-c", "import webview"], check=True)
    print(f"Desktop window ready: {python}")
    return python


if __name__ == "__main__":
    setup()
