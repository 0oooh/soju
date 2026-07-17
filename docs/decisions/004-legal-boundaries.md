# 004 — Legal boundaries for bundled and downloaded components

**Principle.** The repo and release artifacts contain only MIT-licensed Soju code and assets we authored. Everything else arrives at runtime, at the user's request, from its official upstream source. Nothing proprietary is ever committed or re-hosted by this project.

| Component | How Soju gets it | License basis |
|---|---|---|
| Wine Staging engine | Runtime download from Gcenx/macOS_Wine_builds releases | Wine is LGPL; we do not redistribute, we fetch upstream |
| Game Porting Toolkit engine (D3DMetal, DX12) | Runtime download from Gcenx/game-porting-toolkit releases | Apple's D3DMetal is proprietary; the community build is redistributed by Gcenx, not by us. Soju only downloads from their releases at the user's request, same legal position as a browser download |
| Korean font fix | Runtime download of Noto Sans CJK KR from notofonts/noto-cjk | SIL Open Font License — redistribution would also be fine; we still fetch upstream to keep the repo small |
| Steam | Runtime download of SteamSetup.exe from Valve's official CDN (cdn.cloudflare.steamstatic.com) | Valve distributes the installer freely; identical to a user downloading it in a browser |

**Explicitly rejected.** Committing D3DMetal binaries or any GPTK payload to this repo or its releases (Apple EULA); re-hosting engine tarballs ourselves.

**Future option (cleanest possible DX12 path).** A "bring your own GPTK" flow: the user downloads Apple's GPTK dmg with their own free developer account, drops it on Soju, and Soju grafts the libraries into an engine locally. Not implemented yet; the Gcenx engine flavor covers the need.
