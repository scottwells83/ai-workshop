"""Run a bundled Ollama CLI as an invisible AI Workshop helper."""
from __future__ import annotations

import json
import os
from pathlib import Path
import subprocess
import sys
import time
from urllib.error import URLError
from urllib.request import urlopen

ROOT = Path(__file__).resolve().parent
BUNDLE = ROOT / "runtime" / "ollama"
PRIVATE_API = "http://127.0.0.1:11435"
SYSTEM_API = "http://127.0.0.1:11434"
REQUIRED = (
    ("local-worker", "Modelfile"),
    ("local-drafter", "Modelfile.drafter"),
    ("chief-of-staff", "agents/Modelfile.chief-of-staff"),
    ("watcher", "agents/Modelfile.watcher"),
    ("sweeper", "agents/Modelfile.sweeper"),
    ("archivist", "agents/Modelfile.archivist"),
    ("usage-analyst", "agents/Modelfile.usage-analyst"),
)


def executable() -> Path | None:
    marker = BUNDLE / "entrypoint.txt"
    if not marker.is_file():
        return None
    relative = Path(marker.read_text(encoding="utf-8").strip())
    if relative.is_absolute() or ".." in relative.parts:
        raise RuntimeError("Invalid bundled Ollama entry point")
    path = (BUNDLE / relative).resolve()
    if BUNDLE.resolve() not in path.parents or not path.is_file():
        raise RuntimeError("Bundled Ollama executable is missing")
    return path


def api_url() -> str:
    return os.environ.get("AI_WORKSHOP_OLLAMA_API") or (PRIVATE_API if executable() else SYSTEM_API)


def data_dir() -> Path:
    override = os.environ.get("AI_WORKSHOP_DATA_DIR")
    if override:
        return Path(override).expanduser()
    if sys.platform == "darwin":
        return Path.home() / "Library" / "Application Support" / "AI Workshop"
    if sys.platform == "win32":
        return Path(os.environ.get("LOCALAPPDATA", str(Path.home()))) / "AI Workshop"
    return Path(os.environ.get("XDG_DATA_HOME", str(Path.home() / ".local" / "share"))) / "ai-workshop"


def models_dir() -> Path:
    override = os.environ.get("AI_WORKSHOP_MODELS")
    if override:
        return Path(override).expanduser()
    previous = Path.home() / ".ollama" / "models"
    return previous if previous.is_dir() else data_dir() / "models"


def healthy(api: str | None = None) -> bool:
    try:
        with urlopen((api or api_url()) + "/api/tags", timeout=2) as response:
            return response.status == 200
    except (OSError, URLError):
        return False


def environment() -> dict[str, str]:
    env = os.environ.copy()
    env["OLLAMA_HOST"] = api_url().removeprefix("http://")
    env["OLLAMA_MODELS"] = str(models_dir())
    env["OLLAMA_NO_CLOUD"] = "1"
    return env


def start() -> subprocess.Popen | None:
    """Return the child we own, or None when a compatible server is already up."""
    if healthy():
        return None
    binary = executable()
    if binary is None:
        raise RuntimeError("Ollama is unavailable; install or start it to use this source build")
    models_dir().mkdir(parents=True, exist_ok=True)
    log_dir = data_dir() / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    log = (log_dir / "ollama.log").open("ab")
    flags = subprocess.CREATE_NO_WINDOW if sys.platform == "win32" else 0
    try:
        process = subprocess.Popen([str(binary), "serve"], cwd=str(BUNDLE), env=environment(),
                                   stdin=subprocess.DEVNULL, stdout=log, stderr=subprocess.STDOUT,
                                   creationflags=flags)
    finally:
        log.close()
    for _ in range(60):
        if healthy():
            return process
        if process.poll() is not None:
            raise RuntimeError("Bundled Ollama stopped during startup; see the Workshop Ollama log")
        time.sleep(1)
    process.terminate()
    raise RuntimeError("Bundled Ollama did not become ready; see the Workshop Ollama log")


def model_names() -> set[str]:
    with urlopen(api_url() + "/api/tags", timeout=5) as response:
        data = json.load(response)
    return {str(item.get("name", "")).removesuffix(":latest") for item in data.get("models", [])}


def cli(*args: str) -> None:
    binary = executable()
    if binary is None:
        raise RuntimeError("Bundled Ollama executable is missing")
    flags = subprocess.CREATE_NO_WINDOW if sys.platform == "win32" else 0
    result = subprocess.run([str(binary), *args], cwd=str(ROOT), env=environment(),
                            stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, text=True, encoding="utf-8",
                            errors="replace", creationflags=flags)
    if result.returncode:
        raise RuntimeError(f"Ollama {' '.join(args[:2])} failed: {result.stdout[-600:]}")


def model_readable(name: str) -> bool:
    try:
        cli("show", name, "--modelfile")
        return True
    except RuntimeError:
        return False


def ensure_models(progress) -> None:
    """Download only missing base models, then create the Workshop roles."""
    names = model_names()
    for base in ("llama3.2:3b", "llama3.1:8b"):
        if base not in names or not model_readable(base):
            progress(f"Downloading {base}…")
            cli("pull", base)
            if not model_readable(base):
                raise RuntimeError(f"Base model {base} is unreadable after download")
    names = model_names()
    for name, modelfile in REQUIRED:
        if name not in names or not model_readable(name):
            progress(f"Preparing {name}…")
            cli("create", name, "-f", str(ROOT / modelfile))
    if "qwen3:32b" in names and model_readable("qwen3:32b") and ("local-reviewer" not in names or not model_readable("local-reviewer")):
        progress("Preparing optional local-reviewer…")
        cli("create", "local-reviewer", "-f", str(ROOT / "agents/Modelfile.reviewer"))


def stop(process: subprocess.Popen | None) -> None:
    if process is None or process.poll() is not None:
        return
    process.terminate()
    try:
        process.wait(timeout=10)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait(timeout=5)
