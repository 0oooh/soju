# 002 — Engine source and graphics backend

**Decision.** Soju does not bundle Wine. On first run it downloads the latest `wine-staging-<v>-osx64.tar.xz` from the Gcenx/macOS_Wine_builds GitHub releases (11.10 at time of writing) into `~/Library/Application Support/Soju/Engines/<version>/`, verifies extraction, and locates the wine binary by searching for `Contents/Resources/wine/bin/wine64` inside the extracted app. Existing installs (`/Applications/Wine*.app`, Whisky's leftover WhiskyWine at `~/Library/Application Support/com.isaacmarovitz.Whisky/Libraries/Wine`) are auto-detected and offered as engines too.

**Why.** Whisky died partly because maintaining a Wine fork is expensive; Gcenx's builds are actively maintained, and pointing at their releases keeps this project maintainable by one person. Builds are x86_64, so Apple Silicon needs Rosetta (checked at onboarding; `softwareupdate --install-rosetta` offered). Wine is LGPL — downloading at runtime rather than redistributing also keeps the repo license simple (MIT for our code).

**Graphics backend roadmap.** v1 ships with wine's built-in wined3d (works for DX9-11, modest performance). DXVK and Apple Game Porting Toolkit (D3DMetal, DX12) are roadmap items — engine handling is a plain directory-of-engines so adding a CrossOver/GPTK-flavored engine later requires no schema change.

**Rejected.** Bundling WhiskyWine (unmaintained, license gray area for D3DMetal); requiring Homebrew (bad first-run UX for non-developers).
