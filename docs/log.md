# Soju project log

Append-only. Entry format: `## [YYYY-MM-DD] kind | Title` (kind: ingest, milestone, decision, lint).

## [2026-07-17] ingest | Project founding sources

Ingested three guideline sources that govern this repo: emilkowalski apple-design skill (fluid interfaces, distilled into docs/design.md), Karpathy LLM Wiki gist (this docs/ structure), multica-ai karpathy-guidelines (four working principles in CLAUDE.md).

## [2026-07-17] decision | Founding decisions 001-003

Name "Soju"; engine from Gcenx/macOS_Wine_builds releases (wine-staging 11.10 current); exported wrapper apps exec wine directly with baked paths. Details in docs/decisions/.

## [2026-07-17] milestone | Repo scaffolded

SPM package (SojuKit + Soju + tests), CLAUDE.md schema, design language, MIT license, git initialized.

## [2026-07-17] milestone | v0.1.0 feature-complete and verified end-to-end

SojuKit (engines, bottles, runner, PE icon parser, exporter, Whisky import, Gcenx downloader) and the SwiftUI app built as a universal binary bundle. Verified on the maintainer's M1 Max, macOS 27: unit tests pass; integration test booted a fresh prefix with Wine Staging 11.10, launched notepad.exe (stayed alive), extracted its real PE icon (28 KB ICO), and exported Notepad.app; the exported wrapper launched via `open` (double-click semantics) and spawned notepad inside the bottle with Soju closed. GUI verified live by screenshot: sidebar, bottle view, pinned program with extracted icon, engine footer. README + CI (build/test on push, zip + GitHub Release on v* tags) added. Not yet pushed to GitHub.
