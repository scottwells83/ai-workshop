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

Copy the **entire contents** of [`universal-custom-instructions.md`](universal-custom-instructions.md) into the appropriate setting below. On ChatGPT Free or Go, use the [short version](universal-custom-instructions-short.md) if the full text exceeds the 1,500-character limit. Keep project-specific details in that project's files. A cloud-only chat cannot read a local path merely because the instructions name it.

### Browser-based assistants

These account settings store instructions in the online service. They do not grant access to files on your computer. Start a fresh chat after saving instructions.

| Product | Exact placement |
| --- | --- |
| ChatGPT web | Profile menu → **Settings → Personalization → Custom Instructions**; turn on **Enable customization**, paste the text, and save. The ChatGPT desktop app uses the same settings route. On the mobile app, use **Settings → Customize ChatGPT**. A ChatGPT Project has its own **Project settings** instructions, which apply only inside that project. [OpenAI Help](https://help.openai.com/en/articles/8096356-custom-instructions-for-chatgpt) · [Projects](https://help.openai.com/en/articles/10169521-using-projects-in-chatgpt) |
| Claude web and desktop chat | Select your profile initials → **Settings → Instructions for Claude**; paste the text and save. This is Claude chat's account-wide setting, separate from Claude Code files. [Claude Help](https://support.claude.com/en/articles/10185728-understanding-claude-s-personalization-features) |
| Gemini web | In `gemini.google.com`, open **Menu → Settings & help → Personal Intelligence → Instructions for Gemini → Add**; paste the text and submit. On mobile, open **Menu → profile → Personal Intelligence → Instructions for Gemini → Add**. This feature depends on account eligibility; work, school, and supervised accounts may not have it. [Gemini Help](https://support.google.com/gemini/answer/16598625) |
| GitHub.com Copilot Chat | Open Copilot Chat on GitHub, select your profile picture at the lower left → **Personal instructions**; paste the text and select **Save**. These personal instructions apply to Copilot Chat on GitHub.com, not automatically to an IDE. [GitHub Docs](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/add-custom-instructions/add-personal-instructions) |
| Other Meta Muse apps | Meta has not documented one persistent custom-instructions path that applies to every Muse app. If your version exposes personal instructions, use that field. Otherwise send the short instructions at the start of each chat and verify whether that surface can access local files. [Muse Code configuration](https://dev.meta.ai/docs/muse-code/configuration) |

### Locally installed coding assistants and apps

For file-based settings, `~` means your home directory on macOS or Linux; on Windows it means `%USERPROFILE%`. Preserve existing instruction files and merge the text if they already contain rules. Open the AI Workshop directory as the active workspace when you want the app to discover its project instructions.

| Product | Where to add the shared text |
| --- | --- |
| Codex app or CLI | Put the text in `~/.codex/AGENTS.md` (Windows: `%USERPROFILE%\.codex\AGENTS.md`). Codex also reads the Workshop root `AGENTS.md` when working in that folder. ChatGPT's Custom Instructions field is not a substitute for this Codex file. [OpenAI Docs](https://developers.openai.com/cookbook/examples/gpt-5/codex_prompting_guide) |
| Claude Code | Put the text in `~/.claude/CLAUDE.md` for user-wide use. Preserve any existing content and avoid duplicating conflicting rules. [Claude Help](https://support.claude.com/en/articles/14553240-give-claude-context-claude-md-and-better-prompts) |
| Gemini CLI | Put the text in `~/.gemini/GEMINI.md`. [Gemini CLI docs](https://geminicli.com/docs/cli/gemini-md/) |
| Meta Muse Code | Work from the Workshop folder and trust that workspace; Muse Code reads its `AGENTS.md`. Its [official documentation](https://dev.meta.ai/docs/muse-code/configuration) describes this project-instruction mechanism. |
| OpenCode | Put the shared text in `~/.config/opencode/AGENTS.md` on macOS/Linux or `%USERPROFILE%\.config\opencode\AGENTS.md` on Windows. A fresh Workshop setup creates it only when absent. OpenCode also reads the Workshop's root `AGENTS.md`; configure Ollama as its provider if you want OpenCode itself to use local models. [OpenCode rules](https://docs.opencode.ai/docs/rules/) · [Ollama provider](https://opencode.ai/docs/providers) |
| Cursor IDE or CLI | Open **Cursor Settings → Rules → User Rules** and paste the text. Open the Workshop directory so Cursor can also read its root `AGENTS.md`. Cursor's account user rules and local file rules have different scopes; check access in the active workspace. [Cursor rules](https://cursor.com/docs/rules) |
| GitHub Copilot in VS Code | Open the Workshop folder; VS Code Copilot Chat supports its root `AGENTS.md`, and the package includes `.github/copilot-instructions.md`. [GitHub support matrix](https://docs.github.com/en/copilot/reference/custom-instructions-support) |
| GitHub Copilot CLI | Put the shared text in `~/.copilot/copilot-instructions.md` on macOS/Linux or `%USERPROFILE%\.copilot\copilot-instructions.md` on Windows. A fresh Workshop setup creates this file only when absent. [Copilot CLI instructions](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions) |

After adding the instructions, start a new chat and ask the assistant to identify the Workshop's `AGENTS.md` and report whether it actually has local file access. On a new machine, have a local-capable assistant run the Workshop doctor check and report its result. Do not treat an instruction field alone as a completed installation.

OpenCode, Cursor, and GitHub Copilot are optional applications, not runtime dependencies of AI Workshop. The installers add instruction files where supported but do not install these applications or sign into their accounts. Each app's own permissions and model/provider settings still apply.

## Open the local workspace

The package now includes a separate AI Workshop desktop window. Double-click `AI Workshop.app` or `Open AI Workshop.command` on macOS, use the AI Workshop Start menu shortcut or `Open AI Workshop.cmd` on Windows, or choose AI Workshop from the Linux applications menu. A browser fallback is available if the desktop web view cannot start. Its Manager uses Ollama for project chat and can inspect scoped files, run bounded checks, create temporary local-agent jobs, and record project notes. OpenAI, Claude, and Gemini API escalation is optional and off by default; API keys are held only in the running process.

In **Settings**, uncheck **Open AI Workshop automatically for new work** to disable assistant-initiated handoff. Manual launch still works. The universal instructions describe the handoff command for assistants with local execution; a cloud-only chat cannot start a program on your computer. This is an app preview. Recovery, provider validation, first-run installation, and full end-to-end QA still need work before complete release. See [RELEASE_READINESS.md](RELEASE_READINESS.md).

## Check the installation

In a new local-capable chat, ask the assistant to identify and read the Workshop `AGENTS.md` and run `doctor`. It should report what it actually accessed and the check result. An instruction field alone does not complete installation. Use [SHA256SUMS](https://github.com/scottwells83/ai-workshop/blob/main/current%20release/SHA256SUMS) to check downloaded installers.
