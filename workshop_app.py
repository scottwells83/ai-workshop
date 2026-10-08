#!/usr/bin/env python3
"""Local AI Workshop interface. Runs on loopback and uses Ollama first."""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import secrets
import subprocess
import sys
import threading
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen
import webbrowser

import workshop

ROOT = Path(__file__).resolve().parent
UI = ROOT / "ui" / "index.html"
INSTANCE = Path.home() / ".ai-workshop-app.json"
PREFERENCES = ROOT / "app-preferences.json"
MAX_BODY = 1024 * 1024
MAX_FILE = 120_000
SAFE_CHECKS = {"rg", "ls", "pwd", "file", "shasum", "sha256sum", "git", "python", "python3", "bash"}


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def request_json(url: str, payload: dict, headers: dict | None = None, timeout: int = 120) -> dict:
    data = json.dumps(payload).encode("utf-8")
    req = Request(url, data=data, headers={"Content-Type": "application/json", **(headers or {})}, method="POST")
    with urlopen(req, timeout=timeout) as response:
        return json.load(response)


def append_event(project: Path, role: str, text: str, extra: dict | None = None) -> dict:
    event = {"at": now(), "role": role, "text": text, **(extra or {})}
    with (project / "chat-history.jsonl").open("a", encoding="utf-8") as out:
        out.write(json.dumps(event, ensure_ascii=False) + "\n")
    return event


def history(project: Path) -> list[dict]:
    path = project / "chat-history.jsonl"
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()][-80:]


def project_path(project_id: str) -> Path:
    if not workshop.ID.fullmatch(project_id):
        raise ValueError("Invalid project ID")
    path = (ROOT / "projects" / project_id).resolve()
    if not path.is_dir() or not (path / "project.md").is_file():
        raise ValueError("Project not found")
    return path


def workspace_for(project: Path) -> Path:
    setting = project / "workspace.json"
    if setting.exists():
        value = json.loads(setting.read_text(encoding="utf-8")).get("path")
        if isinstance(value, str) and Path(value).expanduser().is_dir():
            return Path(value).expanduser().resolve()
    return ROOT


def scoped_path(project: Path, value: str) -> Path:
    base = workspace_for(project)
    raw = Path(value).expanduser()
    if not raw.is_absolute() and raw.parts and raw.parts[0] == base.name:
        target = (base.parent / raw).resolve()
    else:
        target = (base / raw).resolve() if not raw.is_absolute() else raw.resolve()
    if target != base and base not in target.parents:
        raise ValueError("Path is outside this project's workspace")
    return target


def list_projects() -> list[dict]:
    out = []
    for path in (ROOT / "projects").iterdir():
        if path.is_dir() and (path / "project.md").is_file():
            text = (path / "project.md").read_text(encoding="utf-8")
            title = text.splitlines()[0].removeprefix("# ") if text else path.name
            out.append({"id": path.name, "title": title, "updated": (path / "project.md").stat().st_mtime})
    return sorted(out, key=lambda x: x["updated"], reverse=True)


def create_project(title: str, workspace: str | None = None) -> Path:
    title = title.strip()[:80] or "New Project"
    selected = None
    if workspace:
        selected = Path(workspace).expanduser().resolve()
        if not selected.is_dir():
            raise ValueError("Workspace directory does not exist")
    path = workshop.create_project(title)
    if selected:
        (path / "workspace.json").write_text(json.dumps({"path": str(selected)}) + "\n", encoding="utf-8")
    with (ROOT / "projects" / "README.md").open("a", encoding="utf-8") as index:
        index.write(f"- [{title}]({path.name}/project.md) — active in AI Workshop app.\n")
    return path


def tool_specs() -> list[dict]:
    def spec(name, description, props, required):
        return {"type": "function", "function": {"name": name, "description": description,
                "parameters": {"type": "object", "properties": props, "required": required}}}
    string = lambda desc: {"type": "string", "description": desc}
    return [
        spec("list_files", "List files within this project's selected workspace.", {"path": string("Relative directory, default .")}, []),
        spec("read_file", "Read a text file within the selected workspace.", {"path": string("Relative file path")}, ["path"]),
        spec("read_project", "Read this project's durable project.md and current jobs.json.", {}, []),
        spec("write_file", "Create or replace a text file in the selected workspace; existing content is backed up.", {"path": string("Relative file path"), "content": string("Complete new text")}, ["path", "content"]),
        spec("run_check", "Run a bounded, read-only validation command inside the selected workspace.", {"argv": {"type": "array", "items": {"type": "string"}}, "cwd": string("Relative working directory, default .")}, ["argv"]),
        spec("local_job", "Run a bounded brief through one Workshop local specialist and return its draft for review.", {"model": {"type": "string", "enum": ["local-worker", "local-drafter", "chief-of-staff"]}, "brief": string("Self-contained brief with Task, Context, Constraints, Deliverable, Definition of done")}, ["model", "brief"]),
        spec("project_note", "Append a dated checkpoint to the project's durable project.md record.", {"note": string("Concise verified progress or next action")}, ["note"]),
        spec("outside_help", "Ask the configured outside AI provider only when local work cannot meet the task. Send a compact task packet.", {"task": string("The bounded question"), "context": string("Minimum facts needed")}, ["task", "context"]),
    ]


def outside_help(app: "App", task: str, context: str) -> dict:
    cfg = app.provider
    if not cfg.get("enabled") or not cfg.get("key") or not cfg.get("model"):
        return {"error": "Outside AI is not configured. Continue locally or tell the user what capability is missing."}
    kind = cfg["kind"]
    prompt = f"Task: {task[:4000]}\n\nContext: {context[:12000]}\n\nAnswer only this bounded task. State uncertainty."
    if kind == "openai":
        data = request_json("https://api.openai.com/v1/responses", {"model": cfg["model"], "input": prompt, "store": False}, {"Authorization": "Bearer " + cfg["key"]})
        answer = "\n".join(part.get("text", "") for item in data.get("output", []) for part in item.get("content", []) if part.get("type") == "output_text")
        usage = data.get("usage", {})
    elif kind == "anthropic":
        data = request_json("https://api.anthropic.com/v1/messages", {"model": cfg["model"], "max_tokens": 1200, "messages": [{"role": "user", "content": prompt}]}, {"x-api-key": cfg["key"], "anthropic-version": "2023-06-01"})
        answer = "\n".join(item.get("text", "") for item in data.get("content", []) if item.get("type") == "text")
        usage = data.get("usage", {})
    elif kind == "gemini":
        data = request_json(f"https://generativelanguage.googleapis.com/v1beta/models/{cfg['model']}:generateContent", {"contents": [{"parts": [{"text": prompt}]}]}, {"x-goog-api-key": cfg["key"]})
        answer = "\n".join(part.get("text", "") for item in data.get("candidates", []) for part in item.get("content", {}).get("parts", []))
        usage = data.get("usageMetadata", {})
    else:
        return {"error": "Unsupported provider"}
    if not answer.strip():
        return {"error": "Outside provider returned no text"}
    return {"provider": kind, "model": cfg["model"], "answer": answer.strip(), "usage": usage}


def do_tool(app: "App", project: Path, name: str, args: dict) -> dict:
    if name == "list_files":
        path = scoped_path(project, args.get("path", "."))
        if not path.is_dir():
            raise ValueError("Not a directory")
        return {"path": str(path), "items": [{"name": p.name, "type": "directory" if p.is_dir() else "file"} for p in sorted(path.iterdir())[:100] if not p.name.startswith(".")]}
    if name == "read_file":
        path = scoped_path(project, args["path"])
        if not path.is_file():
            raise ValueError(f"Text file not found: {path}")
        if path.stat().st_size > MAX_FILE:
            raise ValueError(f"Text file exceeds 120 KB: {path}")
        return {"path": str(path), "content": path.read_text(encoding="utf-8")}
    if name == "read_project":
        return {"project_md": (project / "project.md").read_text(encoding="utf-8")[:16000],
                "jobs_json": (project / "jobs.json").read_text(encoding="utf-8")[:8000],
                "workspace": str(workspace_for(project))}
    if name == "write_file":
        path = scoped_path(project, args["path"])
        content = args["content"]
        if not isinstance(content, str) or len(content.encode("utf-8")) > MAX_FILE:
            raise ValueError("Content must be text under 120 KB")
        path.parent.mkdir(parents=True, exist_ok=True)
        if path.exists():
            if not path.is_file():
                raise ValueError("Target is not a file")
            backup = project / "outputs" / "backups"
            backup.mkdir(parents=True, exist_ok=True)
            stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
            (backup / f"{path.name}-{stamp}.bak").write_bytes(path.read_bytes())
        tmp = path.with_name(path.name + ".ai-workshop-tmp")
        tmp.write_text(content, encoding="utf-8")
        tmp.replace(path)
        return {"path": str(path), "bytes": len(content.encode("utf-8"))}
    if name == "run_check":
        argv = args.get("argv")
        if not isinstance(argv, list) or not 1 <= len(argv) <= 12 or any(not isinstance(x, str) or len(x) > 300 for x in argv):
            raise ValueError("Invalid command arguments")
        exe = Path(argv[0]).name
        if any(Path(x).is_absolute() or ".." in Path(x).parts for x in argv[1:]):
            raise ValueError("Check arguments must stay within the workspace")
        if exe not in SAFE_CHECKS or any(x in {"-c", "--exec", "-e", "-o"} for x in argv[1:]):
            raise ValueError("Command is outside the read-only check set")
        if exe == "git" and (len(argv) < 2 or argv[1] not in {"status", "diff", "log", "rev-parse"}):
            raise ValueError("Only read-only Git checks are allowed")
        if exe in {"python", "python3"} and argv[1:3] not in (["-m", "py_compile"], ["-m", "unittest"]):
            raise ValueError("Only Python compile/unittest checks are allowed")
        if exe == "bash" and (len(argv) < 3 or argv[1] != "-n"):
            raise ValueError("Only bash -n is allowed")
        cwd = scoped_path(project, args.get("cwd", "."))
        if not cwd.is_dir():
            raise ValueError("Working directory is missing")
        result = subprocess.run(argv, cwd=cwd, text=True, capture_output=True, timeout=60, check=False)
        return {"exit_code": result.returncode, "stdout": result.stdout[-8000:], "stderr": result.stderr[-4000:]}
    if name == "local_job":
        brief = args.get("brief", "")
        if args.get("model") not in {"local-worker", "local-drafter", "chief-of-staff"} or any(f"{h}\n" not in brief for h in ("Task", "Context", "Constraints", "Deliverable", "Definition of done")):
            raise ValueError("Model or five-heading brief is invalid")
        ident = "app-" + secrets.token_hex(5)
        brief_name = ident + ".txt"
        (project / "briefs" / brief_name).write_text(brief, encoding="utf-8")
        job = {"id": ident, "model": args["model"], "category": "app", "brief": brief_name}
        manifest = project / "jobs.json"
        data = json.loads(manifest.read_text(encoding="utf-8"))
        data["jobs"].append(job)
        manifest.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
        result = workshop.execute_job(project, job, False)
        run_at = now()
        report = {"at": run_at, "results": [result], "source": "app"}
        (project / "run-report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
        with (project / "run-history.jsonl").open("a", encoding="utf-8") as out:
            out.write(json.dumps(report) + "\n")
        workshop.append_usage({"recorded_at": run_at, "event_type": "local_job", "project": project.name,
                               "surface": job["model"], "run_at": run_at, "job_id": ident,
                               "status": result["status"], "category": "app",
                               "prompt_tokens": result.get("prompt_tokens"), "response_tokens": result.get("response_tokens"),
                               "elapsed_seconds": result.get("elapsed_seconds"), "qa_status": "pending"})
        append_event(project, "tool", f"Local {args['model']} job {ident}: {result['status']}", {"tool": name, "result": result})
        if result["status"] == "completed":
            result["draft"] = (project / "outputs" / f"{ident}.md").read_text(encoding="utf-8")[:12000]
        return result
    if name == "project_note":
        note = str(args.get("note", "")).strip()
        if not note or len(note) > 1500:
            raise ValueError("Project note must be 1–1,500 characters")
        with (project / "project.md").open("a", encoding="utf-8") as out:
            out.write(f"\n- {now()}: {note}\n")
        return {"saved": True}
    if name == "outside_help":
        result = outside_help(app, args.get("task", ""), args.get("context", ""))
        append_event(project, "tool", f"Outside AI: {result.get('provider', 'unavailable')}", {"tool": name, "result": {k: v for k, v in result.items() if k != "answer"}})
        return result
    raise ValueError("Unknown tool")


class App:
    def __init__(self):
        self.token = secrets.token_urlsafe(32)
        self.lock = threading.Lock()
        self.provider = {"enabled": False, "kind": "openai", "model": "", "key": ""}

    def preferences(self) -> dict:
        try:
            data = json.loads(PREFERENCES.read_text(encoding="utf-8"))
            return {"auto_handoff": bool(data.get("auto_handoff", True))}
        except (OSError, ValueError):
            return {"auto_handoff": True}

    def set_preferences(self, auto_handoff: bool) -> None:
        PREFERENCES.write_text(json.dumps({"auto_handoff": auto_handoff}, indent=2) + "\n", encoding="utf-8")

    def respond(self, project: Path, prompt: str) -> dict:
        if not self.lock.acquire(blocking=False):
            raise ValueError("Manager is busy with another request")
        try:
            append_event(project, "user", prompt)
            prior = [e for e in history(project) if e["role"] in {"user", "assistant"}][-8:]
            system = ("You are the AI Workshop Manager in a local app. Use Ollama and local tools first. "
                      "Inspect relevant project files and perform authorized reversible work. Ask only for a material missing decision. "
                      "Use local_job for bounded drafts when useful. Treat its output as unverified until checked against the task and source. "
                      "Use outside_help only when configured and local work cannot meet the task. Send the minimum context. "
                      "Never claim a tool ran unless its result confirms it. Keep answers concise. "
                      "Workspace: " + str(workspace_for(project)) + ". Project record: " + str(project) + ".\n\n"
                      + (ROOT / "AGENTS.md").read_text(encoding="utf-8")[:3500] + "\n"
                      + (ROOT / "manager-instructions.md").read_text(encoding="utf-8")[:8500])
            messages = [{"role": "system", "content": system}]
            messages += [{"role": e["role"], "content": e["text"][:6000]} for e in prior]
            actions = []
            for _ in range(8):
                data = request_json(workshop.API + "/api/chat", {"model": "chief-of-staff", "messages": messages, "tools": tool_specs(), "stream": False, "options": {"num_ctx": 16384}}, timeout=600)
                message = data.get("message", {})
                calls = message.get("tool_calls") or []
                if not calls:
                    answer = str(message.get("content") or "").strip() or "The local Manager returned no answer."
                    append_event(project, "assistant", answer, {"actions": actions})
                    return {"answer": answer, "actions": actions}
                messages.append(message)
                for call in calls[:3]:
                    fn = call.get("function", {})
                    name = fn.get("name", "")
                    arguments = fn.get("arguments") or {}
                    try:
                        if isinstance(arguments, str):
                            arguments = json.loads(arguments)
                        result = do_tool(self, project, name, arguments)
                        detail = {"tool": name, "status": "ok", "summary": str(result)[:280]}
                    except (ValueError, OSError, KeyError, TypeError, HTTPError, URLError, TimeoutError, subprocess.TimeoutExpired) as exc:
                        result = {"error": str(exc)}
                        detail = {"tool": name, "status": "error", "summary": str(exc)[:280]}
                    actions.append(detail)
                    append_event(project, "tool", f"{name}: {detail['status']}", detail)
                    messages.append({"role": "tool", "tool_name": name, "content": json.dumps(result, ensure_ascii=False)[:16000]})
            answer = "I reached the local action limit for this turn. Review the actions and continue the project."
            append_event(project, "assistant", answer, {"actions": actions})
            return {"answer": answer, "actions": actions}
        finally:
            self.lock.release()

    def start_handoff(self, project: Path, prompt: str) -> None:
        def work():
            try:
                self.respond(project, prompt)
            except Exception as exc:
                append_event(project, "tool", f"Handoff could not finish: {exc}")
        threading.Thread(target=work, daemon=True).start()


def serve(app: App, port: int = 0, initial: str = "", workspace: str = "") -> None:
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *args):
            return
        def send_json(self, status, value):
            data = json.dumps(value, ensure_ascii=False).encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Cache-Control", "no-store")
            self.send_header("X-Content-Type-Options", "nosniff")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers(); self.wfile.write(data)
        def authorized(self):
            return secrets.compare_digest(self.headers.get("X-Workshop-Token", ""), app.token)
        def do_GET(self):
            if self.path == "/":
                data = UI.read_bytes()
                self.send_response(200); self.send_header("Content-Type", "text/html; charset=utf-8")
                self.send_header("Cache-Control", "no-store"); self.send_header("Content-Length", str(len(data)))
                self.end_headers(); self.wfile.write(data); return
            if not self.authorized():
                return self.send_json(403, {"error": "Not authorized"})
            if self.path == "/api/state":
                return self.send_json(200, {"projects": list_projects(), "provider": {k:v for k,v in app.provider.items() if k != "key"}, "provider_has_key": bool(app.provider["key"]), "ollama": self.ollama_status(), "preferences": app.preferences()})
            if self.path.startswith("/api/history/"):
                try: return self.send_json(200, {"history": history(project_path(self.path.split("/")[-1]))})
                except ValueError as exc: return self.send_json(400, {"error": str(exc)})
            return self.send_json(404, {"error": "Not found"})
        def ollama_status(self):
            try:
                with urlopen(workshop.API + "/api/tags", timeout=2) as response: return response.status == 200
            except (OSError, URLError): return False
        def do_POST(self):
            if not self.authorized(): return self.send_json(403, {"error": "Not authorized"})
            length = int(self.headers.get("Content-Length", "0") or "0")
            if length < 0 or length > MAX_BODY: return self.send_json(413, {"error": "Request too large"})
            try:
                body = json.loads(self.rfile.read(length) or b"{}")
                if self.path == "/api/project":
                    project = create_project(str(body.get("title", "")), body.get("workspace"))
                    return self.send_json(200, {"id": project.name})
                if self.path == "/api/message":
                    project = project_path(str(body.get("project", "")))
                    prompt = str(body.get("prompt", "")).strip()
                    if not prompt or len(prompt) > 12000: raise ValueError("Prompt must be 1–12,000 characters")
                    return self.send_json(200, app.respond(project, prompt))
                if self.path == "/api/provider":
                    kind = str(body.get("kind", ""))
                    if kind not in {"openai", "anthropic", "gemini"}: raise ValueError("Choose OpenAI, Claude API, or Gemini API")
                    model = str(body.get("model", "")).strip()
                    if not model or len(model) > 100 or not all(c.isalnum() or c in "-_.:" for c in model): raise ValueError("Enter a valid model ID")
                    app.provider.update({"kind": kind, "model": model, "enabled": bool(body.get("enabled"))})
                    if body.get("key"): app.provider["key"] = str(body["key"])
                    return self.send_json(200, {"ok": True})
                if self.path == "/api/preferences":
                    if type(body.get("auto_handoff")) is not bool:
                        raise ValueError("auto_handoff must be true or false")
                    app.set_preferences(body["auto_handoff"])
                    return self.send_json(200, {"ok": True})
                if self.path == "/api/handoff":
                    prompt = str(body.get("prompt", "")).strip()
                    if not prompt: raise ValueError("Handoff needs an objective")
                    title = str(body.get("title") or prompt[:48])
                    project = create_project(title, body.get("workspace"))
                    app.start_handoff(project, prompt)
                    return self.send_json(200, {"id": project.name})
                return self.send_json(404, {"error": "Not found"})
            except (ValueError, KeyError, TypeError, json.JSONDecodeError) as exc:
                return self.send_json(400, {"error": str(exc)})
            except (OSError, URLError, HTTPError, RuntimeError) as exc:
                return self.send_json(500, {"error": str(exc)})
    server = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    address = f"http://127.0.0.1:{server.server_address[1]}/#token={app.token}"
    INSTANCE.write_text(json.dumps({"port": server.server_address[1], "token": app.token, "pid": os.getpid()}), encoding="utf-8")
    try: INSTANCE.chmod(0o600)
    except OSError: pass
    if initial:
        project = create_project(initial[:48], workspace or None)
        app.start_handoff(project, initial)
        address += f"&project={project.name}"
    print(address, flush=True)
    webbrowser.open(address)
    try: server.serve_forever()
    finally:
        server.server_close()
        try: INSTANCE.unlink()
        except OSError: pass


def launch(prompt: str = "", workspace: str = "", handoff: bool = False) -> None:
    if handoff and not App().preferences()["auto_handoff"]:
        print("AI Workshop automatic handoff is disabled. Continue in the current assistant.")
        return
    if INSTANCE.exists():
        try:
            info = json.loads(INSTANCE.read_text(encoding="utf-8"))
            port, token = int(info["port"]), str(info["token"])
            with urlopen(f"http://127.0.0.1:{port}/", timeout=1): pass
            address = f"http://127.0.0.1:{port}/#token={token}"
            if prompt:
                data = request_json(f"http://127.0.0.1:{port}/api/handoff", {"prompt": prompt, "workspace": workspace or None}, {"X-Workshop-Token": token}, timeout=3)
                address += "&project=" + data["id"]
            webbrowser.open(address)
            print(address)
            return
        except (OSError, ValueError, KeyError, URLError, HTTPError, json.JSONDecodeError): pass
    serve(App(), initial=prompt, workspace=workspace)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="AI Workshop local interface")
    parser.add_argument("--prompt", default="")
    parser.add_argument("--workspace", default="")
    parser.add_argument("--handoff", action="store_true", help="respect the saved automatic handoff preference")
    args = parser.parse_args()
    launch(args.prompt, args.workspace, args.handoff)
