# AI Workshop setup guide

October 8, 2026 prerelease

This guide covers installing AI Workshop on Windows, macOS, and Linux, adding its shared instructions to AI assistants, and opening the local workspace. The installers need internet access to fetch dependencies and model weights. They do not include personal projects, memory, usage logs, Ollama model blobs, or Python runtimes. Clean-machine first-run setup still needs validation.

## Install AI Workshop

### Windows

1. Download [AI-Workshop-Windows-Setup.exe](https://github.com/scottwells83/ai-workshop/blob/main/current%20release/AI-Workshop-Windows-Setup.exe) and open it.
2. Setup places the Workshop at `%USERPROFILE%\ai-workshop`. It downloads Ollama, creates the seven required Workshop models, supplies Python 3.11 through uv when needed, and runs the Workshop doctor check. Internet access is required. Docker Desktop and Open WebUI are optional.
3. Keep the setup output if it reports a dependency or permission step that still needs attention. The EXE is unsigned, so Windows may show a publisher warning.

### macOS

1. Download [AI-Workshop-macOS.dmg](https://github.com/scottwells83/ai-workshop/blob/main/current%20release/AI-Workshop-macOS.dmg), open it, then double-click `ai-workshop/Install AI Workshop.command` inside it.
2. Setup places the Workshop at `~/ai-workshop`, installs Ollama if needed, creates the seven required models, makes Python 3.11 available through uv when needed, and runs the doctor check. Internet access is required. Docker Desktop and Open WebUI are optional.
3. The DMG is unsigned and unnotarized, so macOS may ask you to approve opening it. Keep the setup output if any dependency needs attention.

### Linux

1. Download [AI-Workshop-Linux-Setup.run](https://github.com/scottwells83/ai-workshop/blob/main/current%20release/AI-Workshop-Linux-Setup.run). Ask a local-capable assistant to run it, or execute it in a terminal. Bash, tar, awk, and curl are bootstrap requirements.
2. Setup places the Workshop at `~/ai-workshop`, installs [Ollama](https://ollama.com/download) if missing, creates the seven required models, supplies Python 3.11 through uv when needed, and runs the doctor check. Internet access is required. Ollama's official installer may request system permission.
3. Docker and Open WebUI are optional and are not installed by the Linux setup. If you only want to check the package, run the file with `--verify-only`; this does not install dependencies.

Existing Workshop folders are preserved by the Windows and macOS setup launchers. Review source updates before replacing customized files. Personal memory and project data must be transferred separately through a private channel.

## Add the universal instructions

Copy the **entire contents** of [`universal-custom-instructions.md`](universal-custom-instructions.md). Use the same text in each product; keep project-specific details in that project's files. A cloud-only chat cannot read a local path merely because the instructions name it.

| Product | Where to add the shared text |
| --- | --- |
| ChatGPT | Add the shared text to personal instructions. Use a local-capable Work or Codex session when a task needs local files or commands. |
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

## Open the local workspace

The package now includes a separate AI Workshop desktop window. Double-click `AI Workshop.app` or `Open AI Workshop.command` on macOS, use the AI Workshop Start menu shortcut or `Open AI Workshop.cmd` on Windows, or choose AI Workshop from the Linux applications menu. A browser fallback is available if the desktop web view cannot start. Its Manager uses Ollama for project chat and can inspect scoped files, run bounded checks, create temporary local-agent jobs, and record project notes. OpenAI, Claude, and Gemini API escalation is optional and off by default; API keys are held only in the running process.

In **Settings**, uncheck **Open AI Workshop automatically for new work** to disable assistant-initiated handoff. Manual launch still works. The universal instructions describe the handoff command for assistants with local execution; a cloud-only chat cannot start a program on your computer. This is an app preview. Recovery, provider validation, first-run installation, and full end-to-end QA still need work before complete release. See [RELEASE_READINESS.md](RELEASE_READINESS.md).

## Check the installation

In a new local-capable chat, ask the assistant to identify and read the Workshop `AGENTS.md` and run `doctor`. It should report what it actually accessed and the check result. An instruction field alone does not complete installation. Use [SHA256SUMS](https://github.com/scottwells83/ai-workshop/blob/main/current%20release/SHA256SUMS) to check downloaded installers.
