# Current release

AI Workshop prerelease package dated October 9, 2026. The installers were built from `main` commit `5e6a0927bf20cd8cf46103bf4b5ed2fadbe45a79`.

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

The installer builds came from successful GitHub Actions runs: [Windows 37951306475](https://github.com/scottwells83/ai-workshop/actions/runs/37951306475), [macOS 37951306603](https://github.com/scottwells83/ai-workshop/actions/runs/37951306603), and [Linux 37951306717](https://github.com/scottwells83/ai-workshop/actions/runs/37951306717). The macOS disk image and all three downloaded file hashes were checked locally; the Linux package check passed in its workflow. First-run installation on clean destination machines is still unverified.

This folder is the repository delivery location for newly built installers and current release documents. Keep old builds and working renders out of it.

If you saved an older AI Workshop instruction or skill in Gemini, replace its text with the [updated Gemini instructions](gemini-ai-workshop-instructions.md). Reinstalling the local app does not update instructions stored in your Gemini account.

Windows setup now checks its two required Ollama base models before creating agents and attempts to download missing layers. A first-run failure is recorded at `%LOCALAPPDATA%\AI Workshop\setup.log`.

The October 9 update adds Workshop-first routing and private task outcome logging. `workshop usage summary --day YYYY-MM-DD` reports executor percentages among logged responses plus routing gaps; [usage tracking](../guides/usage-tracking.md) explains coverage limits. A daily local review is scheduled in the author's ChatGPT desktop chat; each installation needs its own schedule if that report is wanted there.
