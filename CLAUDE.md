# Soju

A modern, open-source Wine wrapper for macOS built with SwiftUI — the successor workflow to the discontinued Whisky. Soju manages Wine "bottles", runs Windows executables, imports old Whisky bottles, and exports any Windows program as a standalone macOS .app that launches from the Dock like a native app.

- Repo root: this directory. GitHub: to be published under the `0oooh` account.
- App target: macOS 14+, Apple Silicon + Intel (universal). Wine engine binaries are x86_64 (Rosetta on AS).
- Engine: downloaded at first run from Gcenx/macOS_Wine_builds GitHub releases (wine-staging-*-osx64.tar.xz). Never bundled in the repo.

## Layout

```
Package.swift          SPM: SojuKit (library) + Soju (executable app) + SojuKitTests
Sources/SojuKit/       Engine discovery/download, Bottle CRUD, WineRunner, PE icon parser,
                       app exporter, Whisky importer. No UI imports here.
Sources/Soju/          SwiftUI app. Views stay thin; logic lives in SojuKit.
Scripts/               build-app.sh (assemble Soju.app), make-icon.swift (render AppIcon.icns)
Resources/             Info.plist template, generated icon assets
docs/                  LLM-maintained wiki (see below)
.github/workflows/     CI build + tag-triggered release packaging
```

## Build and run

```
swift build                          # debug build
Scripts/build-app.sh                 # release .app bundle -> build/Soju.app, ad-hoc signed
open build/Soju.app                  # run the real bundle (preferred over `swift run` for UI)
swift test                           # SojuKit unit tests
```

Do not build on Linux; this is a macOS-only project. The maintainer's machine has Xcode-beta on macOS 27; CI uses GitHub macOS runners.

## Working principles (Karpathy guidelines)

1. **Think before coding.** State assumptions; if multiple interpretations exist, present them instead of picking silently. Push back when a simpler approach exists.
2. **Simplicity first.** Minimum code that solves the problem. No speculative flexibility, no abstractions for single-use code. If 200 lines could be 50, rewrite.
3. **Surgical changes.** Touch only what the task requires. Match existing style. Clean up only orphans your own change created.
4. **Goal-driven execution.** Every task gets a verifiable success criterion (test passes, app launches, bottle boots) and is looped until verified — not "looks done".

## Design language

`docs/design.md` is binding for all UI work. It translates Apple's fluid-interface principles (WWDC "Designing Fluid Interfaces", HIG) into concrete SwiftUI rules for this app: spring parameters, materials, typography, feedback, restraint. Key hard rules: instant feedback on press, continuous progress during long operations (engine download, prefix boot), critically-damped springs by default, system fonts, one primary action per screen, and **no emoji anywhere** (code, docs, commits, UI).

## Wiki maintenance (LLM Wiki pattern)

`docs/` is a persistent wiki maintained by the LLM, not scratch notes.

- `docs/index.md` — catalog of every wiki page with one-line summaries. Update on every ingest.
- `docs/log.md` — append-only chronological log. Entry format: `## [YYYY-MM-DD] kind | Title` where kind is one of `ingest`, `milestone`, `decision`, `lint`.
- `docs/decisions/` — one page per non-obvious decision (engine source, wrapper .app strategy, naming). File decisions here when made, link from index.
- Answers to questions worth keeping (comparisons, analyses) get filed back into the wiki, not lost in chat.
- Periodically lint: contradictions, stale claims, orphan pages, missing cross-references.

## Conventions

- Code, comments, docs, commits: English. Conversation with the maintainer: Korean.
- Commits: imperative subject, no emoji. Milestone commits after each verified phase.
- Never commit engine binaries, bottles, or build output. `.gitignore` covers `build/`, `.build/`.
- Outward-facing actions (creating the GitHub repo, pushing, publishing releases) require explicit maintainer confirmation.
