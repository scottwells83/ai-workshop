# Installation and portability

The package contains AI Workshop instructions, model definitions, a local runner, setup launchers, and optional personal memory. Its canonical machine-facing name is `ai-workshop`; the display name remains `AI Workshop`. Run the macOS `Install AI Workshop.command` or Windows `Install AI Workshop.cmd` from the extracted package. The setup copies files to the user's home `ai-workshop` directory, installs Ollama from its official source if missing, creates workshop models, and attempts to set up Open WebUI when Docker Desktop is available. App installation, sign-in, license acceptance, Windows virtualization, macOS Gatekeeper, and App Store prompts may still require the computer owner. The scripts report those remaining steps; do not claim a complete install until the doctor check passes.

Draw Things is optional on macOS and is not a current workshop dependency. There is no supported Windows Draw Things installation in this package. Do not copy Ollama model blobs or Docker volumes between computers. Recreate models from Modelfiles. Transfer personal memory and project files only through a user-chosen private channel; never put them in a public distribution.

The local runner works without Open WebUI. The installer does not configure account-wide ChatGPT custom instructions. Use `chatgpt-custom-instructions.md` as the short text to apply through ChatGPT Personalization; open the workshop folder in a local-capable session. Codex discovers this directory's `AGENTS.md` when started here.

## Windows installer build

The GitHub Actions workflow at `.github/workflows/build-windows-installer.yml` builds `AI-Workshop-Windows-Setup.exe` on a Windows runner and uploads it as a workflow artifact. You can also run `installer/windows/build.ps1` on Windows with Python 3 and Inno Setup 6 installed. The installer embeds a clean Workshop payload; it excludes personal projects, memory, usage logs, and model blobs. Existing files in `%USERPROFILE%\ai-workshop` are preserved.

The installer is an online bootstrapper. On the destination PC, setup installs Ollama from its official installer, creates the seven models from the bundled Modelfiles (downloading their base models), and provides Python 3.11 through uv when needed. Docker Desktop and Open WebUI are optional browser UI components; their setup may need Windows virtualization, elevated permission, or a sign-in. Internet access is required on first setup. The GitHub artifact is an unsigned installer; Windows may display a publisher warning until it is code signed.
