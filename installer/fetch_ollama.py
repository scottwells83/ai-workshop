#!/usr/bin/env python3
"""Fetch the pinned, checksum-verified Ollama CLI for an installer build."""
from __future__ import annotations

import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from urllib.request import urlretrieve
import zipfile

VERSION = "v0.40.2"
ASSETS = {
    "macos": ("ollama-darwin.tgz", "e888b7637291ceb80b622c00ea067f62c86d9c50d419b3eb903032e4f1f8a4f6", "ollama"),
    "linux": ("ollama-linux-amd64.tar.zst", "726bee78706c281b0eeef00746efe51a044d71c592c3f0b195820707f31fdf04", "bin/ollama"),
    "windows": ("ollama-windows-amd64.zip", "e29ad1d5063dd4b54b2492d9b00adab2cff9621bfa654b6c92aa8d6f1fdfe7fc", "ollama.exe"),
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def fetch(platform: str, destination: Path | None) -> Path:
    name, digest, entrypoint = ASSETS[platform]
    cache = Path(os.environ.get("AI_WORKSHOP_DOWNLOAD_CACHE", tempfile.gettempdir())) / name
    if not cache.is_file() or sha256(cache) != digest:
        cache.parent.mkdir(parents=True, exist_ok=True)
        temporary = cache.with_suffix(cache.suffix + ".download")
        urlretrieve(f"https://github.com/ollama/ollama/releases/download/{VERSION}/{name}", temporary)
        if sha256(temporary) != digest:
            temporary.unlink(missing_ok=True)
            raise RuntimeError(f"Ollama download checksum mismatch: {name}")
        temporary.replace(cache)
    if destination is None:
        return cache
    destination.mkdir(parents=True, exist_ok=True)
    if name.endswith(".zip"):
        with zipfile.ZipFile(cache) as archive:
            archive.extractall(destination)
    elif name.endswith(".tar.zst"):
        with subprocess.Popen(["zstd", "-dc", str(cache)], stdout=subprocess.PIPE) as decompressor:
            subprocess.run(["tar", "-xf", "-", "-C", str(destination)], stdin=decompressor.stdout, check=True)
            if decompressor.wait() != 0:
                raise RuntimeError("Ollama archive decompression failed")
    else:
        subprocess.run(["tar", "-xzf", str(cache), "-C", str(destination)], check=True)
    binary = destination / entrypoint
    if not binary.is_file():
        matches = list(destination.rglob(Path(entrypoint).name))
        if len(matches) != 1:
            raise RuntimeError(f"Bundled Ollama entry point not found: {entrypoint}")
        binary = matches[0]
    binary.chmod(binary.stat().st_mode | 0o111)
    (destination / "entrypoint.txt").write_text(str(binary.relative_to(destination)) + "\n", encoding="utf-8")
    shutil.copy2(Path(__file__).parents[1] / "installer" / "OLLAMA-LICENSE.txt", destination / "OLLAMA-LICENSE.txt")
    return cache


if __name__ == "__main__":
    if len(sys.argv) != 3 or sys.argv[1] not in ASSETS:
        raise SystemExit("Usage: fetch_ollama.py {macos|linux|windows} {DESTINATION|--archive-only}")
    fetch(sys.argv[1], None if sys.argv[2] == "--archive-only" else Path(sys.argv[2]))
