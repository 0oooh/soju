# 001 — Name and identity

**Decision.** The app is named **Soju**. Bundle id `io.github.0oooh.Soju`. Exported wrapper apps use `io.github.0oooh.Soju.wrapper.<uuid>`.

**Why.** Whisky's successor should stay in the spirits lineage (Wine, Whisky, CrossOver's "bottles"), and soju is the Korean spirit — the maintainer is Korean, and the name is short, pronounceable worldwide, and available as a macOS app name. A README line writes itself: after Whisky, Soju.

**Known collision.** `soju` the IRC bouncer (emersion/soju) exists in a different domain; considered acceptable. Rename is a find-and-replace while the project is young if the maintainer objects.
