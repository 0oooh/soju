# Soju

Run Windows apps and games on your Mac — from a real Mac app.

After Whisky, Soju. Whisky's development ended in 2025; Soju is an open-source successor built with SwiftUI. It manages Wine bottles, runs Windows executables, imports your old Whisky bottles, and — its signature feature — exports any Windows program as a standalone macOS app: a real icon in your Dock and Launchpad that launches the program directly, no terminal, no manager app required.

## Features

- **Bottles**: self-contained Windows environments, created in one click
- **Export as Mac app**: turn any Windows program into a standalone `.app` with its real icon (extracted from the `.exe`), launchable from Dock, Launchpad, or Spotlight — works even when Soju is not running
- **Whisky import**: brings your existing Whisky bottles over
- **Managed engine**: downloads the latest maintained Wine build from the [Gcenx macOS Wine builds](https://github.com/Gcenx/macOS_Wine_builds) project on first run; existing Wine or CrossOver installs are auto-detected
- Native SwiftUI, light and dark mode, no Electron, no Homebrew required

## Requirements

- macOS 14 Sonoma or later
- On Apple Silicon: Rosetta 2 (Soju checks and tells you the one-line install command)

## Install

Download the latest `Soju-*.zip` from [Releases](../../releases), unzip, and move `Soju.app` to Applications.

Builds are not notarized (no paid developer account behind this project). On first launch macOS will warn you; either right-click the app and choose Open, or run:

```
xattr -cr /Applications/Soju.app
```

## Build from source

```
git clone <this repo>
cd soju
Scripts/build-app.sh
open build/Soju.app
```

Requires Xcode command line tools with Swift 5.9+.

## How it works

Soju's own code is a thin, native manager. The heavy lifting is Wine — the open-source Windows compatibility layer — using actively maintained builds from the Gcenx project, downloaded into `~/Library/Application Support/Soju/Engines` on first run. Bottles are plain Wine prefixes stored in `.../Soju/Bottles`. Exported Mac apps are small launcher bundles that exec Wine directly with the bottle and program paths baked in, so they start instantly and independently.

## Roadmap

- DXVK graphics backend (DirectX 9-11 over Vulkan/MoltenVK)
- Apple Game Porting Toolkit / D3DMetal engine flavor (DirectX 12)
- Winetricks integration
- Per-bottle Windows version and display settings UI

## Credits

- [Wine](https://www.winehq.org/) — the compatibility layer that makes all of this possible (LGPL)
- [Gcenx](https://github.com/Gcenx) — maintained macOS Wine builds
- [Whisky](https://github.com/Whisky-App/Whisky) — the inspiration; rest well

## License

MIT. Soju does not bundle or redistribute Wine; engines are downloaded from their upstream releases at first run.
