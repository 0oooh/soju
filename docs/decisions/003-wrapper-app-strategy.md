# 003 — Exported wrapper .app strategy

**Decision.** "Export as Mac app" generates a self-contained launcher bundle:

```
<Name>.app/Contents/
  Info.plist            name, wrapper bundle id, icon
  MacOS/<Name>          zsh script: cd to exe dir, export WINEPREFIX, exec wine64 <exe>
  Resources/AppIcon.icns  icon extracted from the .exe's PE resources
```

Paths (engine wine64, bottle prefix, exe) are baked into the script at export time. The script `exec`s wine in the foreground so the wrapper stays in the Dock while the program runs. If the engine is missing at launch, the script shows an osascript alert telling the user to open Soju and re-export.

**Why.** The user's core requirement is "click an icon like a real Mac app". Direct exec means the wrapper works even if Soju.app is not running or was deleted, has zero IPC complexity, and starts instantly. Simplicity-first: no URL scheme, no agent process.

**Tradeoff accepted.** If the engine or bottle moves, wrappers break until re-exported. Soju lists exported wrappers per bottle so re-exporting after an engine update is one click. A `soju://` URL-scheme indirection was rejected for v1: it couples every game launch to the manager app and adds a failure mode (scheme registration) for marginal benefit.
