# AI Workshop release notes — October 8, 2026

## Status

This is a release candidate in [pull request #1](https://github.com/scottwells83/ai-workshop/pull/1). The Windows EXE and macOS DMG build successfully in GitHub Actions. A portable Linux `.run` installer is available. First-run installation of dependencies on clean destination computers has not yet been verified.

## What changed

- `universal-custom-instructions.md` is the single copy-ready instruction set for Codex, Claude, Gemini, and Meta Muse on Windows, macOS, and Linux. The earlier `chatgpt-custom-instructions.md` now points to it.
- The Windows and macOS installers include the new file. On a fresh setup, they copy it to Codex's global `AGENTS.md` if that file does not already exist. Existing global instructions are preserved.
- The shared text tells assistants to find AI Workshop, use its manager and relevant guides, inspect project state, consider local agents, run available tools themselves, verify outputs, and report unavailable access honestly.
- The installers stage reusable Workshop files without personal projects, memory, usage logs, or model blobs.
- The Linux `.run` installer now packages the same clean Workshop instructions and runner. It installs core dependencies on first run and provides a `--verify-only` package check.

## Install AI Workshop

### Windows

1. Download the `ai-workshop-windows-installer` artifact from the latest successful [Windows workflow run](https://github.com/scottwells83/ai-workshop/actions/workflows/build-windows-installer.yml). Extract the artifact and open `AI-Workshop-Windows-Setup.exe`.
2. Setup places the Workshop at `%USERPROFILE%\ai-workshop`. It downloads Ollama, creates the seven Workshop models, supplies Python 3.11 through uv when needed, and runs the Workshop doctor check. Internet access is required. Docker Desktop and Open WebUI are optional.
3. Keep the setup output if it reports a dependency or permission step that still needs attention. The EXE is unsigned, so Windows may show a publisher warning.

### macOS

1. Download the `ai-workshop-macos-installer` artifact from the latest successful [macOS workflow run](https://github.com/scottwells83/ai-workshop/actions/workflows/build-macos-installer.yml). Open `AI-Workshop-macOS.dmg`, then double-click `ai-workshop/Install AI Workshop.command` inside it.
2. Setup places the Workshop at `~/ai-workshop`, installs Ollama if needed, creates the seven models, makes Python 3.11 available through uv when needed, and runs the doctor check. Internet access is required. Docker Desktop and Open WebUI are optional.
3. The DMG is unsigned and unnotarized, so macOS may ask you to approve opening it. Keep the setup output if any dependency needs attention.

### Linux

1. Download the `ai-workshop-linux-installer` artifact from the latest successful [Linux workflow run](https://github.com/scottwells83/ai-workshop/actions/workflows/build-linux-installer.yml). Extract the artifact and ask a local-capable assistant to run `AI-Workshop-Linux-Setup.run`; or execute it in a terminal. Bash, tar, awk, and curl are bootstrap requirements.
2. Setup places the Workshop at `~/ai-workshop`, installs [Ollama](https://ollama.com/download) if missing, creates the seven models, supplies Python 3.11 through uv when needed, and runs the doctor check. Internet access is required. Ollama's official installer may request system permission.
3. Docker and Open WebUI are optional and are not installed by the Linux setup. If you only want to check the package, run the file with `--verify-only`; this does not install dependencies.

Existing Workshop folders are preserved by the Windows and macOS setup launchers. Review source updates before replacing customized files. Personal memory and project data must be transferred separately through a private channel.

## Add the universal instructions

Copy the **entire contents** of `universal-custom-instructions.md`. Use the same text in each product; keep project-specific details in that project's files. A cloud-only chat cannot read a local path merely because the instructions name it.

| Product | Where to add the shared text |
| --- | --- |
| Codex app or CLI | Put it in the user-level `AGENTS.md` at `~/.codex/AGENTS.md` on macOS/Linux or `%USERPROFILE%\.codex\AGENTS.md` on Windows. A fresh Workshop setup creates this file only when absent. Codex also reads the Workshop's own `AGENTS.md` when working there. [OpenAI Docs](https://developers.openai.com/cookbook/examples/gpt-5/codex_prompting_guide) |
| Claude chat | Open your profile **Settings → Instructions for Claude** and paste the text. This applies account-wide. [Claude Help](https://support.claude.com/en/articles/10185728-understanding-claude-s-personalization-features) |
| Claude Code | Put the text in `~/.claude/CLAUDE.md` for user-wide use. Preserve any existing content and avoid duplicating conflicting rules. [Claude Help](https://support.claude.com/en/articles/14553240-give-claude-context-claude-md-and-better-prompts) |
| Gemini app | Open **Settings & help → Personal Intelligence → Instructions for Gemini → Add**, then paste and submit. Availability depends on the account and app surface. [Gemini Help](https://support.google.com/gemini/answer/16598625) |
| Gemini CLI | Put the text in `~/.gemini/GEMINI.md`. [Gemini CLI docs](https://geminicli.com/docs/cli/gemini-md/) |
| Meta Muse Code | Work from the Workshop folder and trust that workspace; Muse Code reads its `AGENTS.md`. Its [official documentation](https://dev.meta.ai/docs/muse-code/configuration) describes this project-instruction mechanism. |
| Other Meta Muse apps | If that version offers a saved personal-instructions field, paste the same text there. Otherwise send it at the start of a conversation and do not assume it persists or has local file access. Meta's [Muse announcement](https://about.fb.com/news/2026/09/introducing-muse-personal-ai-agent/) does not establish a universal persistent-instructions setting across every Muse surface. |

After adding the instructions, start a new chat and ask the assistant to identify the Workshop's `AGENTS.md` and report whether it actually has local file access. On a new machine, have a local-capable assistant run the Workshop doctor check and report its result. Do not treat an instruction field alone as a completed installation.

## Verification and limits

- Windows GitHub Actions produced an EXE and uploaded its artifact; the artifact was downloaded and identified as a Windows executable.
- macOS GitHub Actions produced a DMG; its checksum passed, and the downloaded image mounted with the launcher and model files present.
- Payload staging checks found no personal projects, memory, or usage log in either installer.
- The Linux `.run` payload builds on a Linux GitHub runner and passes its extraction and syntax check. First-run Ollama, model, Python, Docker, Gatekeeper, and Windows permission behavior still needs testing on destination machines. The installers require network access to fetch core dependencies and model weights.
