# Current release

AI Workshop prerelease package dated October 8, 2026. The installers were built from merged `main` commit `379808db642f899116b7500288cbdcdb5293eed4`.

| Item | File |
| --- | --- |
| Release notes | [Markdown](RELEASE_NOTES.md) · [Word](RELEASE_NOTES.docx) |
| Setup guide | [Markdown](SETUP_GUIDE.md) · [Word](SETUP_GUIDE.docx) |
| User manual | [Markdown](USER_MANUAL.md) · [Word](USER_MANUAL.docx) |
| Universal instructions | [Full](universal-custom-instructions.md) · [Short](universal-custom-instructions-short.md) |
| Gemini-specific instructions | [Markdown](gemini-ai-workshop-instructions.md) |
| Beta readiness review | [BETA_READINESS.md](BETA_READINESS.md) |
| Windows installer | [AI-Workshop-Windows-Setup.exe](AI-Workshop-Windows-Setup.exe) |
| macOS installer | [AI-Workshop-macOS.dmg](AI-Workshop-macOS.dmg) |
| Linux installer | [AI-Workshop-Linux-Setup.run](AI-Workshop-Linux-Setup.run) |
| File hashes | [SHA256SUMS](SHA256SUMS) |

The installer builds came from successful GitHub Actions runs: [Windows 37834544613](https://github.com/scottwells83/ai-workshop/actions/runs/37834544613), [macOS 37834544585](https://github.com/scottwells83/ai-workshop/actions/runs/37834544585), and [Linux 37834544672](https://github.com/scottwells83/ai-workshop/actions/runs/37834544672). First-run installation on clean destination machines is still unverified.

This folder is the repository delivery location for newly built installers and current release documents. Keep old builds and working renders out of it.

If you saved an older AI Workshop instruction or skill in Gemini, replace its text with the [updated Gemini instructions](gemini-ai-workshop-instructions.md). Reinstalling the local app does not update instructions stored in your Gemini account.

Windows setup now checks its two required Ollama base models before creating agents and attempts to download missing layers. A first-run failure is recorded at `%LOCALAPPDATA%\AI Workshop\setup.log`.
