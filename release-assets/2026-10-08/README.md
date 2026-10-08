# AI Workshop installer files — October 8, 2026

These prerelease installers were downloaded from successful GitHub Actions runs built from merged `main` commit `ec3b2cf701f0ae1b0e77c6ac59d94b88cd6d9caa`:

| Platform | File | Actions run |
| --- | --- | --- |
| Windows | `AI-Workshop-Windows-Setup.exe` | [37814709879](https://github.com/scottwells83/ai-workshop/actions/runs/37814709879) |
| macOS | `AI-Workshop-macOS.dmg` | [37814709830](https://github.com/scottwells83/ai-workshop/actions/runs/37814709830) |
| Linux | `AI-Workshop-Linux-Setup.run` | [37814710009](https://github.com/scottwells83/ai-workshop/actions/runs/37814710009) |

See `SHA256SUMS` for the downloaded files' hashes. The macOS disk image passed `hdiutil verify`; the Linux Actions run passed its `--verify-only` package check. Windows and Linux first-run behavior, plus dependency installation on clean destination machines, remains to be tested.

These packages include reusable Workshop files, not Ollama model weights, Python runtimes, personal projects, memory, or usage logs. Setup downloads dependencies when needed and requires an internet connection.
