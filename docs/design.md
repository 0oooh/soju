# Soju design language

Binding rules for all UI in this app. Derived from Apple's fluid-interface principles (WWDC 2018 "Designing Fluid Interfaces", WWDC 2020 "The Details of UI Typography", WWDC 2026 "Principles of Great Design") translated to native SwiftUI on macOS.

## Motion

- Default spring for all UI state changes: `.spring(response: 0.35, dampingFraction: 1.0)` — critically damped, no overshoot. Menus, sheets, list changes never bounce.
- Bounce (`dampingFraction: 0.8`) is allowed only when the user's gesture carried momentum (drag-and-drop release). Nothing that merely appears may overshoot.
- Never lock input during a transition. No `disabled(true)` while something animates unless the underlying operation genuinely cannot be interrupted.
- Animate from current value: state-driven SwiftUI animation only; no fire-and-forget `DispatchQueue.asyncAfter` choreography.
- Respect Reduce Motion: replace movement with opacity cross-fades via `@Environment(\.accessibilityReduceMotion)`.

## Response and feedback

- Feedback on press, not on release: buttons use visible pressed states (standard bordered/borderedProminent styles already do this — do not build custom buttons that lose it).
- Long operations show continuous, truthful progress: engine download shows bytes/percent as they stream; prefix boot shows an indeterminate spinner plus the current wine stage line from the log. Never a frozen button.
- Four feedback kinds, all present: status (engine installed/missing, bottle running), completion (export done — reveal in Finder), warning (Rosetta missing before it blocks), error (wine exit code with the log one click away).
- Errors name the fix, not just the failure ("Engine not installed — Install in Settings"), and never dead-end.

## Materials and depth

- Sidebar: NavigationSplitView's default translucent material. Never override with opaque colors.
- Sheets and popovers: system `.regularMaterial` backgrounds where custom backgrounds are needed at all.
- Never stack two translucent surfaces. Color accents live on solid layers, not on materials.
- Dim-and-block (sheet) only for genuinely modal tasks: create bottle, export app, onboarding. Everything else stays in the flow.

## Typography

- System font only, default text styles (`.largeTitle` through `.caption`). SF handles optical sizing and tracking; do not set `tracking()` or custom fonts.
- Hierarchy through weight + size + spacing, not color variety. Secondary text uses `.secondary`, never custom grays.
- Layout spacing in multiples of 4; respect Dynamic Type by never fixing text container heights.

## Structure and restraint

- One primary action per screen. A bottle view's primary action is Run; everything else is secondary or in menus.
- Wayfinding: every screen answers where am I (title), where can I go (sidebar/toolbar), how do I get out (standard close/back). No trapped states.
- Direct labels: "Bottles", "Programs", "Engine" — never "Home", "Stuff", "Manage".
- Controls sit next to what they affect. If a control needs a caption to explain it, the mapping is wrong — redesign, don't caption.
- Destructive actions (delete bottle) get one confirmation naming the object; nothing else gets a confirmation dialog.
- No emoji anywhere in the product.

## Craft checklist (before any UI phase is "done")

- Every spacing/timing value is deliberate and consistent across screens.
- Light and dark mode both verified by screenshot.
- Keyboard: default button responds to Return, sheets dismiss with Escape.
- Nothing jitters, nothing jumps a frame on appear, icons align to the pixel.
