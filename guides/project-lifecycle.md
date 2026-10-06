# Project lifecycle and continuity

## Where things live

- Keep this Workshop at its current home-directory location (`~/AI-Workshop` on Scott's Mac; Windows installers use `%USERPROFILE%\\ai-workshop`). The case difference on macOS currently resolves to the same filesystem object. Do not move the live Workshop casually; installers and personal instructions refer to this path.
- Treat the Workshop root as the local source/configuration repository. Its Git history must contain only reusable Workshop code, templates, documentation, and agent definitions.
- Treat `projects/`, `memory/`, and `usage-log.jsonl` as private operating data, never as part of the root source Git repository. The portable personal ZIP includes project and memory state, so store it privately and use it as a data backup, not a public release.
- Each project has one workspace at `projects/<stable-slug>/` with `project.md`, `jobs.json`, `briefs/`, `outputs/`, and `deliverables/`. Preserve `run-history.jsonl` and older generated outputs as process evidence.
- A code project has exactly one canonical Git checkout. Prefer `projects/<slug>/repository/` for a new code project. If the user already supplied a clone elsewhere, keep that clone in place and record its absolute or workspace-relative path and remote in `project.md`; point to it instead of cloning again.

## Repository rules

Before code work or resuming a repository project:

1. Read the project checkpoint and relevant decisions.
2. Resolve the canonical repository path. Confirm its Git root, origin, branch, current commit, and working-tree status.
3. Reuse that checkout. Do not create another clone or move the repository unless the user asks or a verified need justifies a safe migration.
4. Keep generated local builds, secrets, user books/data, private logs, and machine-specific files out of source commits. Keep reproducible source/build instructions in the code repository and user-facing release artifacts in the project's `deliverables/` or approved release channel.
5. Never commit or push without the user's applicable authorization. For a code change, report the final commit and push state accurately.

A repository's source code and the Workshop project record serve different purposes. The code repo preserves reviewed source history. The workspace preserves task briefs, decisions, local run history, QA results, and deliverables. Link them in `project.md`; do not force every project file into the code repository.

## Start, resume, and finish

At start or resume, update the checkpoint after inspecting it: current goal and scope, active branch/commit, changed files, existing `jobs.json` and log, local-agent suitability, and the next concrete action. Never rely on chat history alone for confirmed project decisions.

For local jobs, record a category in `jobs.json` (`analysis`, `coding`, `comparison`, `drafting`, `extraction`, `review`, `other`, or another short lowercase label). Use the required five-heading brief, preserve previous run history, inspect outputs, and record Manager QA against the exact run timestamp. `completed` means the runner returned an output; it does not mean the work passed review.

At finish, write the completion record in `project.md`: deliverables, verification performed, repository commit, accepted/rejected/rework outcomes, and any next action. Mark status `complete` only when the user's requested result is done; use `paused` or `blocked` only with their precise meaning. Keep completed workspaces in place as an archive; do not delete them to make the directory look tidy.

## Continuous improvement

Review the usage summary periodically, but change routing only when comparable tasks show a repeatable difference in total effort and outcome. Keep model input/output token counts separate from human review time, acceptance/rework, elapsed time, and unavailable commercial token data. Measure Manager review time only when actually tracked; otherwise keep it unknown. Change one process or prompt at a time, record the reason/date and expected effect, then compare later QA records. Do not add agents to meet a quota.
