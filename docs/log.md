# Soju project log

Append-only. Entry format: `## [YYYY-MM-DD] kind | Title` (kind: ingest, milestone, decision, lint).

## [2026-07-17] ingest | Project founding sources

Ingested three guideline sources that govern this repo: emilkowalski apple-design skill (fluid interfaces, distilled into docs/design.md), Karpathy LLM Wiki gist (this docs/ structure), multica-ai karpathy-guidelines (four working principles in CLAUDE.md).

## [2026-07-17] decision | Founding decisions 001-003

Name "Soju"; engine from Gcenx/macOS_Wine_builds releases (wine-staging 11.10 current); exported wrapper apps exec wine directly with baked paths. Details in docs/decisions/.

## [2026-07-17] milestone | Repo scaffolded

SPM package (SojuKit + Soju + tests), CLAUDE.md schema, design language, MIT license, git initialized.

## [2026-07-18] milestone | v0.2.0: GPTK engine flavor, Korean font fix, Steam one-click

Published as 0oooh/soju (public, v0.1.0 released with zip via Actions). v0.2.0 adds: second engine flavor (Gcenx Game Porting Toolkit 3.0-3 for DX12, runtime-downloaded; verified download+extract+prefix boot in 69 s), Korean font fix (Noto Sans CJK KR + 14 FontSubstitutes entries; verified visually — wine notepad renders hangul cleanly), Install Steam button (official Valve CDN installer; verified the setup wizard runs in a bottle), per-bottle Windows version (winecfg /v verified via registry), Whisky-style README. Legal boundaries recorded in decisions/004. Community already sharing the repo link on the maintainer's Discord within hours of publish.

## [2026-07-17] milestone | v0.1.0 feature-complete and verified end-to-end

SojuKit (engines, bottles, runner, PE icon parser, exporter, Whisky import, Gcenx downloader) and the SwiftUI app built as a universal binary bundle. Verified on the maintainer's M1 Max, macOS 27: unit tests pass; integration test booted a fresh prefix with Wine Staging 11.10, launched notepad.exe (stayed alive), extracted its real PE icon (28 KB ICO), and exported Notepad.app; the exported wrapper launched via `open` (double-click semantics) and spawned notepad inside the bottle with Soju closed. GUI verified live by screenshot: sidebar, bottle view, pinned program with extracted icon, engine footer. README + CI (build/test on push, zip + GitHub Release on v* tags) added. Not yet pushed to GitHub.
