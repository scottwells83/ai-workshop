# AI Workshop

This folder is the local source/configuration for a Manager-led AI Workshop. The Manager entry point is `AGENTS.md`; read it only when a workshop task is active. Reusable Workshop files are kept in the root Git history; `projects/`, `memory/`, and `usage-log.jsonl` are private operating data and must stay out of that repository. The Manager creates project workspaces, dispatches bounded local runs, checks results, and delivers finished files. The local models do not have file or command permissions by themselves; the Manager's host environment invokes `workshop.py` for them.

## First setup

- macOS: double-click `Install AI Workshop.command` from the extracted package.
- Windows: double-click `Install AI Workshop.cmd` from the extracted package.

The setup creates `~/ai-workshop` or `%USERPROFILE%\ai-workshop`, adds a short Codex global instruction file if none exists, installs Ollama if needed, creates the seven workshop models, and checks the local runner. It attempts to set up Open WebUI through Docker Desktop. Operating-system permission, Docker license, or app sign-in prompts may still need the computer owner. Re-running setup does not overwrite an existing workshop folder. On an existing computer, use the Manager to review package changes before replacing customized files.

The model roster includes the general `local-worker` and `local-drafter`, four personal workflow agents, and `usage-analyst` for reviewing local-versus-cloud usage records and proposing evidence-based routing improvements.

Draw Things is optional and currently available for Apple devices; it is not required for text projects or installed by this setup. Model downloads happen separately on each computer. The ZIP does not carry Ollama model blobs, Docker data, or ChatGPT account settings.

## Using the Manager

Open the `ai-workshop` folder in a local-capable ChatGPT Work or Codex session and say what you want to do. For an ordinary ChatGPT chat, the short text in `chatgpt-custom-instructions.md` can start intake, but a chat without local access cannot execute the runner. In Codex, this folder's `AGENTS.md` is discovered as project guidance. A ChatGPT Project is created only when the active product surface exposes that capability; the Manager must confirm it exists.

## Portability

The personal package contains the `memory/` files and `projects/` folders in this workshop, but omits Git internals and reproducible build/cache directories such as `bin/` and `obj/`. Treat the ZIP as private. On another computer with an existing workshop, preserve its local changes and have the Manager reconcile project and memory differences. A single live shared folder across machines is not configured by this installer. Git-backed code repositories remain independent and should have one canonical clone; see `guides/project-lifecycle.md` for project paths, checkpoints, backup, and repository rules.

## Runner

The Manager applies the local-delegation check whenever a project starts or resumes, including older projects. Use `workshop.command` on macOS or `workshop.cmd` on Windows: `new` creates a project, `run <project-path>` runs its active `jobs.json` assignments, and `doctor` checks Ollama and the core models. See `guides/jobs-example.md` for assignment and verification steps. Each run writes a latest `run-report.json` and appends execution and Ollama token/timing metrics to `run-history.jsonl`. These confirm execution, not content quality; the Manager reviews every output and records whether it was accepted.

The private `usage-log.jsonl` at the workshop root keeps local job token/time records and Work/Codex session records. Local job metrics are appended by the runner. Managers record each Work/Codex session with `workshop usage add`; exact token counts stay blank when unavailable, while message and visible-word counts are clearly marked as transcript proxies. Record local output acceptance with `workshop usage qa`. Run `workshop usage summary` periodically to compare measured tokens, proxies, elapsed time, and QA outcomes. See `guides/usage-tracking.md` for commands and interpretation rules. Do not log prompts or sensitive content.
