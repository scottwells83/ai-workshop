# AI Workshop beta readiness review

October 8, 2026

## Recommendation

AI Workshop is suitable for a **small, supervised macOS preview** after one clean-machine installation smoke test. It is **not ready for an unsupervised cross-platform beta or public release**. Windows and Linux installer builds succeeded, but their desktop launch and first-run dependency setup have not been tested on destination machines. The app is still a preview with limited recovery, verification, and upgrade behavior.

## Evidence reviewed

- The three GitHub Actions installer workflows succeeded for merged `main` commit `ec3b2cf`; the current delivery binaries and exact rebuild runs are listed in [the release index](README.md).
- Nine Python unit tests pass. They cover brief normalization, bedtime-language warnings, and optional reviewer behavior; they do not exercise project recovery, tool security, installation, or provider calls.
- A prior local macOS session verified the app window, one project handoff, file reading, token guard, and automatic-handoff preference. The macOS DMG passed checksum verification. This is not a clean-machine installation test.
- Source review confirms the app uses a token-protected loopback server and scoped workspace paths. It stores chat and run history as files, but has no durable task state machine or complete action audit. The current `run_check` set includes Python unit tests, which can execute code from a selected workspace; testers must use trusted workspaces.
- Setup scripts fetch dependencies and model weights at installation time. Existing `ai-workshop` folders are preserved without a versioned migration, leaving updated files unreconciled.

## Minimum gate before inviting beta testers

1. On a clean macOS test account or machine, install the exact DMG, confirm Ollama and all seven required models, run `doctor`, open the desktop app, create a project, finish a small local task, and verify saved history after restart.
2. Repeat the same end-to-end test on a clean Windows PC and Linux machine before offering those installers to testers. Check shortcuts, web view, permissions, model downloads, and dependency failure messages.
3. Provide a visible beta limitation notice: use a trusted local workspace and test data; outside API calls stay off unless the tester knowingly configures them; keep backups of existing Workshop folders.
4. Establish a support path for test reports with installer version or commit, operating system, logs, reproduction steps, and a way to remove or reset a failed test installation.
5. Test at least one interrupted task and one failed local job so the Manager's response and saved state are clear. Confirm the tester can resume without repeating destructive work.

## Before a public release

- Implement safe updates and rollback for existing installations, with backups and versioned data migrations.
- Add deterministic project-state and tool-policy tests, including path traversal, permission boundaries, job failure, and restart recovery. A model response or successful runner exit must not count as output QA.
- Validate representative local-model tasks and outside-provider calls, with an explicit data preview, per-provider budgets, credential storage, and consent boundaries.
- Improve the interface for job progress, QA evidence, deliverables, error recovery, keyboard use, and screen readers; verify it on all three operating systems.
- Sign the Windows installer and sign/notarize the macOS package. Publish verified hashes and source provenance for every release.
- Make optional Docker/Open WebUI setup opt-in, and document disk, RAM, download, and network requirements before installation.

The [product readiness review](../RELEASE_READINESS.md) contains the fuller architecture and gap analysis. This review is based on source inspection, passing unit/build checks, and the previously recorded macOS preview; it does not claim clean-machine acceptance.
