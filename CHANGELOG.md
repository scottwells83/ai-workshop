# Changelog

This file records user-facing AI Workshop changes. Keep entries factual and update it when code, installers, or release documents change. The [current release](https://github.com/scottwells83/ai-workshop/tree/main/current%20release/) folder contains the installers and documents intended for download.

## October 8 2026 setup and manual update

- Added separate browser and installed-app instruction placement in the setup guide, with links to each vendor's documentation.
- Added a user manual for daily local workspace use, handoff, outside AI, moving machines, and recovery.
- Added a 1,500-character-compatible short universal instruction variant and included the manual and short variant in all three installer payloads.

## October 8 2026 documentation and delivery update

- Split release notes from platform setup and AI-assistant instructions.
- Established `current release/` as the delivery folder for the current installers, release notes, setup guide, and checksums. Updated the root README to point there.
- Added this changelog for future changes.
- Added a beta readiness review with separate gates for supervised testing and public release.

## October 8 2026 prerelease

- Added Windows, macOS, and Linux installer workflows and produced prerelease installers from merged `main` commit `ec3b2cf`.
- Added the local desktop Manager preview, desktop windows and AI Workshop icons, optional automatic handoff, fixed composer with a scrolling conversation pane, and local-job recovery improvements.
- Added universal assistant instructions and a Gemini-focused Markdown copy.
- Added optional source-grounded `local-reviewer` based on `qwen3:32b` when the base model is already installed.
- Added the three merged-main installer binaries to the repository in commit `cc7dae4`, with hashes and download links.

## October 6 2026 foundation

- Separated reusable Workshop source from private project, memory, and usage data.
- Added project continuity guidance, usage categories, repeatable setup behavior, and backup exclusions for build caches.
