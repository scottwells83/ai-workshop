# AI Workshop user manual

October 8, 2026 prerelease

This manual covers everyday use of the local AI Workshop Manager. Use the [setup guide](SETUP_GUIDE.md) for installation and assistant-specific custom-instruction placement; use the [release notes](RELEASE_NOTES.md) for changes and known limits.

## Open the workspace

- **macOS:** Open `~/ai-workshop/AI Workshop.app` or double-click `Open AI Workshop.command`.
- **Windows:** Use the **AI Workshop** Start menu shortcut or `Open AI Workshop.cmd` in `%USERPROFILE%\ai-workshop`.
- **Linux:** Choose AI Workshop from the applications menu or launch `Open AI Workshop.sh` in `~/ai-workshop`.

The launcher opens a separate desktop window when its web view is available; otherwise it opens the local browser interface. The Manager runs on your computer through Ollama. Wait for **Ollama ready** before starting a local chat. If Ollama is unavailable, use the installation check described in the setup guide.

## Start a project

1. Select **+** next to **Projects**.
2. Enter a project name. Optionally supply a **Workspace folder** path for existing files. Leave it blank to work inside AI Workshop. Select **Create project**.
3. Describe the result you want in the conversation box. Include relevant files, audience, format, constraints, and what would make the work complete. The Manager can ask a focused question when a missing detail changes the result.
4. Review the Manager's response and **Recent actions**. A successful tool action is evidence that a command ran; inspect the result before treating it as finished work.

The project list lets you return to an existing conversation. AI Workshop records durable project notes, chat history, and local-job run history in that project's folder. Your actual project files are available only within the workspace selected for that project.

## Work with the Manager

The Manager can read project notes, inspect scoped workspace files, run bounded commands, and call local specialists. It may split a suitable task into local jobs; the Manager is responsible for checking their output. Tell it directly when you want a revision, a status report, a deliverable, or a verification step. A one-step request may be handled without creating extra jobs.

For a coding task, point the project at the relevant repository and state the expected behavior. For a document, name the source file and desired output. Review the actual output file or result, especially for source fidelity and visual layout. AI Workshop does not turn a draft or a successful tool call into automatic proof of quality.

## Optional handoff from another assistant

Your universal instructions can direct a local-capable ChatGPT, Codex, Claude, Gemini, Muse Code, OpenCode, Cursor, or Copilot session to launch AI Workshop for continuing work. In **Settings**, **Open AI Workshop automatically for new work** controls this behavior. Turn it off to keep work in the current assistant; manual launch still works. Online chats without local execution cannot open an app on your computer. The assistant should say whether it actually read the Workshop files and launched the app.

## Optional outside AI

The **Outside AI** card shows whether escalation is active. It starts off. In **Settings**, select OpenAI, Claude, or Gemini API, enter a model ID and API key, and enable **Allow Manager escalation** only if you want that service available. The key is held in the running app process and cleared when it closes; it is not saved to disk. Provider usage may incur charges under your own account. The Manager sends a bounded task packet when it needs outside help. Review the provider status in the sidebar before sharing sensitive work.

## Move to another computer

Install AI Workshop on the new computer first. The installer provides the Workshop source and downloads runtime dependencies there. It does not sync your private `projects/`, `memory/`, or `usage-log.jsonl` between machines. Transfer those private files separately through a channel you trust, preserve existing files on the destination, and ask the Manager to reconcile differences. Keep Git repositories as separate clones; a Workshop installer is not a repository sync service.

## If something goes wrong

- If **Ollama unavailable** appears, ask a local-capable assistant to run the Workshop `doctor` check and report the exact failure. Confirm that Ollama is running and the required models are installed before retrying.
- If a local job or command fails, inspect **Recent actions** and the Manager response. Ask the Manager to inspect the project run report and output, correct the issue, and rerun only the affected step.
- If the desktop window does not open, use the browser fallback from the launcher. It still uses the local Workshop service.
- If an online assistant claims it launched AI Workshop, ask what local execution tool it used. A browser-only chat cannot start a local process by itself.

This is a prerelease. See [beta readiness](RELEASE_READINESS.md) for validation limits and remaining public-release work.
