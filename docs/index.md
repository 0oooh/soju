# Soju wiki index

LLM-maintained wiki for the Soju project.

## Pages

- [design.md](design.md) — Binding UI design language: springs, materials, typography, feedback, restraint (from Apple fluid-interface principles).
- [log.md](log.md) — Append-only chronological project log.

## Decisions

- [decisions/001-name-and-identity.md](decisions/001-name-and-identity.md) — Why "Soju", bundle id, spirits-lineage naming.
- [decisions/002-engine-source.md](decisions/002-engine-source.md) — Wine engine from Gcenx GitHub releases, downloaded at first run; graphics backend roadmap (wined3d now, DXVK/GPTK later).
- [decisions/003-wrapper-app-strategy.md](decisions/003-wrapper-app-strategy.md) — Exported .app wrappers exec wine directly with baked paths; tradeoffs vs URL-scheme indirection.
- [decisions/004-legal-boundaries.md](decisions/004-legal-boundaries.md) — What may be bundled vs runtime-downloaded (GPTK, fonts, Steam); nothing proprietary in the repo.
