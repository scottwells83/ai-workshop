# AI Workshop

**A local-first workspace for AI-assisted projects.** AI Workshop keeps project context and source history, routes bounded work to local agents where they fit, and uses commercial AI tools when they add value. The Manager checks the results and records usage and QA so the process can improve over time.

The Manager entry point is `AGENTS.md`; read it only when a workshop task is active. Reusable Workshop files are kept in the root Git history; `projects/`, `memory/`, and `usage-log.jsonl` are private operating data and must stay out of that repository. The Manager creates project workspaces, dispatches bounded local runs, checks results, and delivers finished files. The local models do not have file or command permissions by themselves; the Manager's host environment invokes `workshop.py` for them.

The canonical machine-readable name is `ai-workshop` (folder, repository, package, and service identifiers); the human-facing product name is **AI Workshop**. The source repository is [scottwells83/ai-workshop](https://github.com/scottwells83/ai-workshop).

## First setup

- macOS: double-click `Install AI Workshop.command` from the extracted package.
- Windows: double-click `Install AI Workshop.cmd` from the extracted package.
- Linux: run `AI-Workshop-Linux-Setup.run` from a local-capable assistant or terminal. It extracts the Workshop and starts `Install AI Workshop.sh`.

The setup creates `~/ai-workshop` or `%USERPROFILE%\ai-workshop`, adds Codex, OpenCode, and GitHub Copilot CLI user instruction files if absent, installs Ollama if needed, creates the seven required workshop models, and checks the local runner. If `qwen3:32b` is already present in Ollama, setup also creates the optional `local-reviewer` without downloading its roughly 20 GB base model. The Windows and macOS launchers attempt to set up Open WebUI through Docker Desktop; the Linux installer leaves Docker and Open WebUI optional. Operating-system permission, Docker license, or app sign-in prompts may still need the computer owner. Re-running setup does not overwrite an existing workshop folder. On an existing computer, use the Manager to review package changes before replacing customized files.

The required model roster includes the general `local-worker` and `local-drafter`, four personal workflow agents, and `usage-analyst` for reviewing local-versus-cloud usage records. The optional `local-reviewer` is a heavier, source-grounded reviewer built from `qwen3:32b` only when that base model is already installed. Its output still requires Manager QA.

This prerelease includes a standalone desktop window with project chat, a tool-capable Ollama Manager, bounded local jobs, and optional outside API escalation. It is a testable preview, not a fully verified standalone product. See [RELEASE_READINESS.md](RELEASE_READINESS.md) for release gaps.

Draw Things is optional and currently available for Apple devices; it is not required for text projects or installed by this setup. Model downloads happen separately on each computer. The ZIP does not carry Ollama model blobs, Docker data, or ChatGPT account settings.

## Using the Manager

Double-click `AI Workshop.app` or `Open AI Workshop.command` on macOS, use the AI Workshop Start menu shortcut or `Open AI Workshop.cmd` on Windows, or choose AI Workshop from the Linux applications menu. These open a separate desktop window. If the desktop web view cannot start, the launcher opens the browser interface. Start a project there and work with the local Manager. In Settings, uncheck **Open AI Workshop automatically for new work** to keep new tasks in your current assistant; manual launch still works. Outside AI is off until you configure an API provider and key in Settings.

Open the `ai-workshop` folder in a local-capable AI session and say what you want to do. Use the copy-ready text in `universal-custom-instructions.md` in ChatGPT, Codex, Claude, Gemini, Meta Muse, OpenCode, Cursor, GitHub Copilot, or another assistant's personal-instruction field. For a Gemini-focused Markdown version, use `gemini-ai-workshop-instructions.md`. A chat without local access cannot execute the runner. In Codex, this folder's `AGENTS.md` is discovered as project guidance. A ChatGPT Project is created only when the active product surface exposes that capability; the Manager must confirm it exists.

## Portability

The personal package contains the `memory/` files and `projects/` folders in this workshop, but omits Git internals and reproducible build/cache directories such as `bin/` and `obj/`. Treat the ZIP as private. On another computer with an existing workshop, preserve its local changes and have the Manager reconcile project and memory differences. A single live shared folder across machines is not configured by this installer. Git-backed code repositories remain independent and should have one canonical clone; see `guides/project-lifecycle.md` for project paths, checkpoints, backup, and repository rules.

## Runner

The Manager applies the local-delegation check whenever a project starts or resumes, including older projects. Check `projects/README.md` and the project checkpoint before creating or resuming work. Use `workshop.command` on macOS or `workshop.cmd` on Windows: `new` creates a project from `templates/project.md`, `run <project-path>` runs its active `jobs.json` assignments, and `doctor` checks Ollama and the core models. See `guides/jobs-example.md` and `guides/project-lifecycle.md` for assignment, repository, continuity, and verification steps. Each run writes a latest `run-report.json` and appends execution and Ollama token/timing metrics to `run-history.jsonl`. These confirm execution, not content quality; the Manager reviews every output and records whether it was accepted.

The private `usage-log.jsonl` at the workshop root keeps local job token/time records and Work/Codex session records. Local job metrics are appended by the runner, grouped by an optional workload category. Managers record each Work/Codex session with `workshop usage add`; exact token counts stay blank when unavailable, while message and visible-word counts are clearly marked as transcript proxies. Record local output acceptance and measured review time (only when actually measured) with `workshop usage qa`. Run `workshop usage summary` periodically to compare tokens, proxies, elapsed time, category, and QA outcomes. See `guides/usage-tracking.md` for commands and interpretation rules. Do not log prompts or sensitive content.
