# AI Workshop prerelease notes

October 8, 2026

AI Workshop now has a testable desktop workspace and installers for Windows, macOS, and Linux. The three installers in this folder passed their GitHub Actions build checks; the exact build commit and run links are recorded in the current release index. This remains a prerelease: first-run setup on clean destination computers, upgrades, recovery, and outside-provider calls need further validation. The [release readiness review](../RELEASE_READINESS.md) tracks those gaps.

## Changes in this build

- Added a separate local desktop window with Ollama-backed Manager chat, project creation, scoped file actions, bounded checks and local jobs, and optional outside API escalation. Automatic handoff can be disabled in settings; the browser interface remains a fallback.
- Kept the page and prompt composer fixed while the conversation pane scrolls to new responses, including on narrow screens.
- Improved local-job handling: the Manager accepts five-part briefs in heading or mapping form, retries after tool errors, and flags common pressure language in bedtime story drafts for review. This check cannot guarantee a story is suitable for an individual child.
- Added one universal instruction set for ChatGPT, Codex, Claude, Gemini, Meta Muse, OpenCode, Cursor, and GitHub Copilot across Windows, macOS, and Linux. A Gemini-focused Markdown copy is also available. Fresh installs create supported user-level instruction files only when absent and preserve existing personal instructions.
- Added optional `local-reviewer`, based on `qwen3:32b`, for bounded source-grounded checks. Setup creates it only when that base model is already installed; it does not force an approximately 20 GB download. `doctor` reports it separately from the seven required models. Its output still needs Manager review.
- Updated all three installers to stage reusable Workshop files without personal projects, memory, usage logs, or model blobs. The Linux `.run` adds a package verification mode.

## Build verification

The [Windows](https://github.com/scottwells83/ai-workshop/actions/runs/37814709879), [macOS](https://github.com/scottwells83/ai-workshop/actions/runs/37814709830), and [Linux](https://github.com/scottwells83/ai-workshop/actions/runs/37814710009) workflows succeeded for the release source. The downloaded macOS DMG passed `hdiutil verify`. The Linux workflow passed its `--verify-only` package check. The three repository copies match the hashes in [SHA256SUMS](SHA256SUMS).

These checks establish build and package integrity. Windows and Linux desktop behavior, dependency installation, model creation, permissions, and clean-machine first run remain unverified. The installers are unsigned; the macOS DMG is also unnotarized.

For installation and AI-platform instructions, use the separate [setup guide](SETUP_GUIDE.md).
