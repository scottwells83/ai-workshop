#!/usr/bin/env python3
"""Build a portable self-extracting Linux .run installer."""

from gzip import GzipFile
from io import BytesIO
from pathlib import Path
import subprocess
import sys
import tarfile
from tempfile import TemporaryDirectory

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = Path(sys.argv[1]).expanduser().resolve() if len(sys.argv) == 2 else ROOT / "dist" / "linux" / "AI-Workshop-Linux-Setup.run"
OUTPUT.parent.mkdir(parents=True, exist_ok=True)

with TemporaryDirectory(prefix="ai-workshop-linux-") as tmp:
    stage = Path(tmp) / "payload"
    subprocess.run([sys.executable, str(ROOT / "installer/linux/stage.py"), str(stage)], check=True)
    archive = BytesIO()
    with GzipFile(fileobj=archive, mode="wb", mtime=0) as gz:
        with tarfile.open(fileobj=gz, mode="w|") as tar:
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
    header = (ROOT / "installer/linux/launcher.sh").read_bytes()
    if not header.endswith(b"__AI_WORKSHOP_ARCHIVE_BELOW__\n"):
        raise SystemExit("Linux launcher marker is missing or not last")
    OUTPUT.write_bytes(header + archive.getvalue())
    OUTPUT.chmod(0o755)
print(OUTPUT)
