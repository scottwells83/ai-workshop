#!/usr/bin/env python3
"""Build a portable self-extracting Linux .run installer."""

from pathlib import Path
import shutil
import os
import subprocess
import sys
import tarfile
from tempfile import TemporaryDirectory
import tempfile

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = Path(sys.argv[1]).expanduser().resolve() if len(sys.argv) == 2 else ROOT / "dist" / "linux" / "AI-Workshop-Linux-Setup.run"
OUTPUT.parent.mkdir(parents=True, exist_ok=True)

with TemporaryDirectory(prefix="ai-workshop-linux-") as tmp:
    stage = Path(tmp) / "payload"
    subprocess.run([sys.executable, str(ROOT / "installer/fetch_ollama.py"), "linux", "--archive-only"], check=True)
    env = os.environ.copy()
    env["AI_WORKSHOP_OLLAMA_ARCHIVE"] = str(Path(os.environ.get("AI_WORKSHOP_DOWNLOAD_CACHE", tempfile.gettempdir())) / "ollama-linux-amd64.tar.zst")
    subprocess.run([sys.executable, str(ROOT / "installer/linux/stage.py"), str(stage)], check=True, env=env)
    archive_path = Path(tmp) / "payload.tar.zst"
    with archive_path.open("wb") as archive:
        with subprocess.Popen(["zstd", "-q", "-T0", "-10", "-c"], stdin=subprocess.PIPE, stdout=archive) as compressor:
            with tarfile.open(fileobj=compressor.stdin, mode="w|") as tar:
                for path in sorted((stage / "ai-workshop").rglob("*")):
                    relative = path.relative_to(stage)
                    info = tar.gettarinfo(str(path), arcname=str(relative))
                    info.uid = info.gid = 0
                    info.uname = info.gname = ""
                    info.mtime = 0
                    if path.is_file():
                        with path.open("rb") as source:
                            tar.addfile(info, source)
                    else:
                        tar.addfile(info)
            compressor.stdin.close()
            if compressor.wait() != 0:
                raise SystemExit("Linux payload compression failed")
    header = (ROOT / "installer/linux/launcher.sh").read_bytes()
    if not header.endswith(b"__AI_WORKSHOP_ARCHIVE_BELOW__\n"):
        raise SystemExit("Linux launcher marker is missing or not last")
    with OUTPUT.open("wb") as output, archive_path.open("rb") as archive:
        output.write(header)
        shutil.copyfileobj(archive, output, length=1024 * 1024)
    OUTPUT.chmod(0o755)
    if OUTPUT.stat().st_size >= 2 * 1024**3:
        raise SystemExit("Linux installer exceeds the GitHub release asset size limit")
print(OUTPUT)
