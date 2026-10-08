# AI Workshop prerelease notes — October 8, 2026

## Status

This is a prerelease build in [pull request #1](https://github.com/scottwells83/ai-workshop/pull/1). The Windows EXE, macOS DMG, and Linux `.run` build successfully in GitHub Actions. First-run installation of dependencies on clean destination computers has not yet been verified. The [product readiness review](RELEASE_READINESS.md) identifies the work needed before calling AI Workshop a complete standalone package.

## What changed

- `universal-custom-instructions.md` is the single copy-ready instruction set for ChatGPT, Codex, Claude, Gemini, Meta Muse, OpenCode, Cursor, and GitHub Copilot on Windows, macOS, and Linux. The earlier `chatgpt-custom-instructions.md` now points to it.
- The Windows, macOS, and Linux installers include the shared file. On a fresh setup, they copy it to Codex, OpenCode, and GitHub Copilot CLI user-level instruction files only when absent. Existing personal instructions are preserved. Cursor uses the Workshop's root `AGENTS.md`; its optional global User Rules are set inside Cursor.
- A short `.github/copilot-instructions.md` gives GitHub Copilot on the repository an entry point to the Workshop's shared Manager instructions.
- The shared text tells assistants to find AI Workshop, use its manager and relevant guides, inspect project state, consider local agents, run available tools themselves, verify outputs, and report unavailable access honestly.
- The installers stage reusable Workshop files without personal projects, memory, usage logs, or model blobs.
- The local app now accepts model-produced five-part briefs in heading or mapping form. The Manager retries work after a tool error and checks bedtime story drafts for common pressure language before answering; this is an aid to review, not a guarantee about an individual child's triggers.
- The local app keeps the page and prompt composer fixed while the conversation pane scrolls to the newest response, including on narrow screens.
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

1. Download the `ai-workshop-linux-installer` artifact from the successful [Linux workflow run](https://github.com/scottwells83/ai-workshop/actions/runs/37797742629). A local release-candidate package is also available. Ask a local-capable assistant to run `AI-Workshop-Linux-Setup.run`, or execute it in a terminal. Bash, tar, awk, and curl are bootstrap requirements.
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
| OpenCode | Put the shared text in `~/.config/opencode/AGENTS.md` on macOS/Linux or `%USERPROFILE%\.config\opencode\AGENTS.md` on Windows. A fresh Workshop setup creates it only when absent. OpenCode also reads the Workshop's root `AGENTS.md`; configure Ollama as its provider if you want OpenCode itself to use local models. [OpenCode rules](https://docs.opencode.ai/docs/rules/) · [Ollama provider](https://opencode.ai/docs/providers) |
| Cursor IDE or CLI | Open the Workshop directory so Cursor reads its root `AGENTS.md`. For the same behavior in every project, paste the shared text into **Cursor Settings → Rules → User Rules**. Cursor does not gain access to a separate project merely because the rule names it; verify access in the active workspace. [Cursor rules](https://docs.cursor.com/context/rules-for-ai) |
| GitHub Copilot in VS Code | Open the Workshop folder; VS Code Copilot Chat supports its root `AGENTS.md`, and the package includes `.github/copilot-instructions.md`. [GitHub support matrix](https://docs.github.com/en/copilot/reference/custom-instructions-support) |
| GitHub Copilot CLI | Put the shared text in `~/.copilot/copilot-instructions.md` on macOS/Linux or `%USERPROFILE%\.copilot\copilot-instructions.md` on Windows. A fresh Workshop setup creates this file only when absent. [Copilot CLI instructions](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions) |
| GitHub.com Copilot Chat | Paste the shared text into **Copilot Chat → profile picture → Personal instructions** if you want it account-wide. GitHub.com Chat cannot read a Workshop folder on your computer without a connected local execution surface. [GitHub personal instructions](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/add-custom-instructions/add-personal-instructions) |

After adding the instructions, start a new chat and ask the assistant to identify the Workshop's `AGENTS.md` and report whether it actually has local file access. On a new machine, have a local-capable assistant run the Workshop doctor check and report its result. Do not treat an instruction field alone as a completed installation.

OpenCode, Cursor, and GitHub Copilot are optional applications, not runtime dependencies of AI Workshop. The installers add instruction files where supported but do not install these applications or sign into their accounts. Each app's own permissions and model/provider settings still apply.

## Local AI Workshop app preview

The package now includes a local browser interface. Double-click `Open AI Workshop.command` on macOS, `Open AI Workshop.cmd` on Windows, or run `Open AI Workshop.sh` on Linux. Its Manager uses Ollama for project chat and can inspect scoped files, run bounded checks, create temporary local-agent jobs, and record project notes. OpenAI, Claude, and Gemini API escalation is optional and off by default; API keys are held only in the running process.

In **Settings**, uncheck **Open AI Workshop automatically for new work** to disable assistant-initiated handoff. Manual launch still works. The universal instructions describe the handoff command for assistants with local execution; a cloud-only chat cannot start a program on your computer. This is an app preview. Recovery, provider validation, first-run installation, and full end-to-end QA still need work before complete release. See [RELEASE_READINESS.md](RELEASE_READINESS.md).

## Verification and limits

- Windows GitHub Actions produced an EXE and uploaded its artifact; the artifact was downloaded and identified as a Windows executable.
- macOS GitHub Actions produced a DMG; its checksum passed, and the downloaded image mounted with the launcher and model files present.
- Payload staging checks found no personal projects, memory, or usage log in either installer.
- The Linux `.run` payload built on an Ubuntu GitHub runner and passed extraction and script syntax checks. The CI artifact was downloaded and identified by SHA-256. First-run Ollama, model, Python, Docker, Gatekeeper, and Windows permission behavior still needs testing on destination machines. The installers require network access to fetch core dependencies and model weights.
