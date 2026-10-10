# AI Workshop product readiness and local-first workspace

October 8, 2026. Source reviewed: the Manager guides, `workshop.py`, Ollama Modelfiles, installers, workflows, and current project/usage records. This is a source and package review, not a clean-machine acceptance test.

## Decision

AI Workshop now has a testable local desktop app preview. It starts an Ollama-backed Manager in a separate desktop window, creates projects, reads scoped files, runs bounded checks and local jobs, and can call a configured outside API. The user can disable automatic handoff while retaining manual launch. A local macOS session verified the interface, file tool, authentication guard, preference behavior, and standalone WebKit window. Windows and Linux desktop windows still need destination-machine testing. This is not yet a complete release: cross-platform first run, recovery, outside-provider calls, installer upgrades, and result QA remain unverified.

## Current capability and gap

| Area | Current implementation | Remaining gap |
| --- | --- | --- |
| Project state | App lists and creates projects and keeps chat history. | Durable step-by-step recovery and deliverable state are limited. |
| Local Manager | Ollama `chief-of-staff` tool loop can read/write scoped files, run bounded checks, create local jobs, and record notes. | Representative task benchmarking and stronger content QA. |
| Interface | Loopback browser chat, project switcher, action feed, settings, optional handoff. | Artifact review, clearer job progress, accessibility and cross-platform UI checks. |
| External AI | Optional OpenAI, Anthropic, or Gemini API calls with in-memory key. | Live provider validation, explicit data preview, usage budgets, OS keychain. |
| Installation | Installer workflows stage the app and launchers. | Clean destination installs, safe update/rollback, signing/notarization. |

## Release blockers

1. **Complete Manager recovery and delivery.** The preview has intake and chat; add a durable Manager state machine that resumes after interruption and distinguishes drafted, executed, verified, and delivered work.
2. **Harden controlled local actions.** Expand the current scoped tool broker with policy tests, audit details, document rendering, and explicit controls for sensitive files and irreversible operations.
3. **Acceptance gates.** Add source-derived checks for project outputs and clear thresholds for retry, local model selection, or external escalation. Never treat Ollama completion alone as QA.
4. **Install and upgrade path.** Test the exact installer on clean Windows, macOS, and Linux systems; verify model downloads and doctor results. Add a safe update process with backups and versioned migrations for an existing `~/ai-workshop`. Current setup preserves old folders and does not reconcile package updates.
5. **Cross-platform automated verification.** Add meaningful tests for project state, job dependency failures, tool permissions, recovery, public payload privacy, and installers. Current CI primarily proves packages build, not that first setup and the Manager work.

## High-value usability and efficiency improvements

- Make a first-launch screen show dependency state, model readiness, available disk/RAM, and a one-click repair path. The current `doctor` checks Ollama and seven required model names, and reports optional `local-reviewer` availability; it does not benchmark model quality or hardware fit.
- The October 9 development installers now omit Docker/Open WebUI setup and bundle the Ollama CLI. Validate first-run model downloads and helper lifecycle on clean destination machines before release.
- Show a concise project timeline, current chunk, QA result, and final files in one place. Do not require the user to inspect `jobs.json` or run reports.
- Store reusable source summaries and retrieve only task-relevant excerpts. Send a bounded brief to each local model or external service, with explicit token limits and usage accounting.
- Treat model capability as measured. Test local models on representative writing, extraction, coding, tool-use, and QA tasks on each target machine; route by observed quality and hardware, not by model name alone.
- Separate public distribution from private project migration. Keep personal projects and memory out of release artifacts and provide a private backup/restore workflow.

## Recommended local-first architecture

1. **Workspace service:** a local process owns project records, files, jobs, logs, and recovery. The UI connects over loopback by default; remote access requires explicit authentication and network setup.
2. **Manager state machine:** intake → inspect → plan → local execution → verification → deliver or escalate. Every step records inputs, result, evidence, and next action. Deterministic code handles state and validation; the local model handles language and judgment within bounded prompts.
3. **Tool broker:** expose only scoped operations to the model, with path boundaries, command policies, timeouts, backups, and visible results. Keep credentials and private memory out of model prompts unless needed for the task.
4. **Local model router:** start with the existing Ollama specialists and a stronger tool-capable Manager model if benchmark results require it. Ollama supports tool calls and structured outputs, but AI Workshop must implement the loop and validate every call.
5. **Optional escalation connectors:** send a compact, approved task packet to an external AI service only after local retry or a task-specific capability check fails. Track exact provider/model, tokens when reported, artifact provenance, and result QA. Keep provider credentials in the OS credential store, not project files.
6. **AI Workshop UI:** show conversation, project state, delegated chunks, tool actions, QA evidence, usage, and deliverables. Offer an explicit setting for local-only work and per-provider budgets. A local-only request must never silently use a cloud model.

This design can reduce external token usage; it cannot guarantee that a local model can complete every project or that paid services will never be needed. OpenCode, Cursor, and GitHub Copilot integration broadens access to the Workshop but does not itself create a local-first Manager or reduce their own service usage.

## Entry from ChatGPT, Codex, or another assistant

The intended handoff is: the user states an idea in an existing assistant; if that assistant has local execution, it starts AI Workshop and opens a new local project prompt with a short objective and source references. AI Workshop acknowledges the handoff, then owns the conversation, Manager state, tools, QA, and deliverables. External services receive only bounded requests that the local Manager decides it cannot complete. The originating chat gets a concise handoff or final result rather than every intermediate message. A local-capable assistant can now start a project with `workshop.py app --handoff --prompt` when the user enables automatic handoff.

The preview implements a local launcher and token-protected loopback endpoint. Improve the handoff record so it contains the objective, permitted source paths, originating surface, and optional project identifier. The record should contain the objective, permitted source paths, originating surface, and optional project identifier; it should not contain credentials or an unrestricted command. The local UI must show and confirm the project it opened. A cloud-only chat cannot start a process on the user's computer by naming a path; it needs a connected local tool, a user-clickable registered link, or a separately installed integration. A direct AI Workshop desktop shortcut should offer the same intake path when the user does not start in another service.

Starting in a paid assistant can still consume a small amount of that service's tokens for the initiating message. The design minimizes subsequent paid-service context by transferring work to the local UI and returning only short status/result packets. It should never claim zero outside token use when the entry message or an escalation used an outside service.

## Suggested implementation order

1. Add versioned project state, recovery, and deterministic QA/permission tests to the existing runner.
2. Build a small local UI around project intake, status, artifacts, and doctor/repair; keep external AI disabled initially.
3. Implement the tool broker and local Manager loop, then benchmark it on real Workshop projects.
4. Add optional external escalation with explicit usage accounting and data boundaries.
5. Verify clean installs, updates, rollback, and signed release artifacts on each platform before declaring a complete package.

## Verification performed and limits

- Reviewed the current code and instructions; `workshop.py` now includes `app` alongside `new`, `run`, `doctor`, and `usage`.
- Ran `doctor` on this Mac. It initially found six of seven models; recreated `usage-analyst` from the existing base model and reran `doctor` successfully.
- The local-worker capability inventory was rejected after it invented current capabilities; this assessment is based on direct source inspection.
- The local UI, file read, token guard, and handoff preference were tested on this Mac. Outside-provider calls and clean destination installs were not tested.

Reference for technical feasibility: [Ollama tool calling](https://github.com/ollama/ollama/blob/main/docs/capabilities/tool-calling.mdx) and [structured outputs](https://github.com/ollama/ollama/blob/main/docs/capabilities/structured-outputs.mdx).
