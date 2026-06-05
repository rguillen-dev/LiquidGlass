# CLAUDE.md — LiquidGlass

Guidance for AI agents (Claude Code and others) working in this repository.
Read this fully before writing or editing any Swift in `Sources/`.

## What this package is

A SwiftUI library that brings Apple's iOS 26 **Liquid Glass** material to any
view, with a **hand-tuned fallback for iOS 17 and 18**. The promise is: the same
call site reads as glass on every supported OS. Never break that promise — every
public surface MUST render acceptably on both the native (iOS 26+) and the
fallback (iOS 17–18) path.

- Swift 6.0+, Swift 6 language mode (strict concurrency).
- iOS 17.0+ deployment, builds from Xcode 16; Xcode 26+ for native rendering.
- Library target: `Sources/LiquidGlass`. Tests: `Tests/LiquidGlassTests` (Swift Testing).
- Runnable demo: `DemoApp/LiquidGlassDemo.xcodeproj`.

## Architecture rules (do not violate)

1. **All availability checks live in one place.** `GlassRenderingModifier` in
   `GlassMaterial.swift` is the *only* type that branches on OS/compiler. Every
   other file stays version-agnostic and routes through `.glass(...)`. If you
   find yourself writing `#available` or `#if compiler` outside that file (or the
   thin `GlassEffectContainer`/`glassMorphID` wrappers that already exist), stop —
   you're adding it in the wrong layer.

2. **Two-axis availability guard.** The native path is gated on BOTH:
   ```swift
   #if compiler(>=6.2)
   if #available(iOS 26.0, *) { /* native */ } else { /* fallback */ }
   #else
   /* fallback */
   #endif
   ```
   The compiler check lets the package build from Xcode 16 (where `glassEffect`
   doesn't exist in the SDK). Never drop either guard.

3. **Never shadow a system API.** When wrapping an Apple API, give the wrapper a
   distinct name. Precedent: our `glassMorphID(_:in:)` forwards to the system
   `glassEffectID(_:in:)` specifically so it never shadows it. Follow this for any
   new wrapper (e.g. a union wrapper should NOT be named `glassEffectUnion`).

4. **Glass is the navigation layer only.** Apple's rule, and ours: glass belongs
   to controls/chrome that float above content (toolbars, tab bars, sheets, FABs).
   Never apply it to the content layer (lists, tables, media, scrollable bodies).
   Don't add components or docs that encourage content-layer glass.

5. **Glass cannot sample other glass.** Stacked glass goes muddy. Multiple nearby
   glass surfaces must share a `GlassEffectContainer`. Don't nest `.glass(...)`
   surfaces without one.

6. **Fallback must honor accessibility.** The native path gets Reduce
   Transparency / Reduce Motion / Increased Contrast for free from the system. The
   fallback path does NOT — it must read those environment values and degrade
   itself. Treat missing a11y handling in the fallback as a bug, not a nice-to-have.

## Conventions

- Every public type carries a DocC comment with a runnable `swift` example.
- Every new surface ships with: (a) a Swift Testing case, and (b) at least one
  `#Preview` over a vivid gradient background (match the existing previews in
  `GlassCard.swift` / `GlassButton.swift`).
- Public enums are `Sendable, Hashable`; add `CaseIterable` when the tests iterate
  all cases (see `GlassStyle`).
- Tint is **semantic**, not decorative: it signals a primary action or a state.
  Don't introduce APIs or examples that tint everything for looks.
- Keep the `tint ?? environmentTint` resolution pattern when adding components
  (see `GlassModifier` and `GlassTabBar`).
- Update `CHANGELOG.md` (Keep a Changelog format, SemVer) in the same change.
- The README has drifted behind the code before. If you add or change public API,
  update `README.md` in the same PR.

## API grounding — REQUIRED

Liquid Glass is new (WWDC 2025) and changed across point releases. Do **not** write
`glassEffect`-family code from memory — signatures get hallucinated. Before writing
or reviewing any native-path code, verify the signature against:

  `Docs/LiquidGlassAPIReference.md`

If something you need isn't in that reference, say so and ask — don't invent it.

## Build & test

```bash
swift build
swift test
```

For native rendering you need Xcode 26 + an iOS 26 simulator; `swift build` on an
older toolchain will compile only the fallback path (by design — see rule 2).

## When in doubt

Prefer the smallest change that keeps both render paths correct. Ask before
expanding public API surface, retiring a component, or changing the fallback's
visual tuning (the material/stroke/shadow values are deliberate).
