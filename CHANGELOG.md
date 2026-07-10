# Changelog

All notable changes to **LiquidGlass** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `GlassBottomAccessory` component wrapping `tabViewBottomAccessory`: a persistent glass control (e.g. a "now playing" pill) docked above the tab bar that survives navigation. Forwards to the system accessory slot on iOS 26+ (handling the `isEnabled:` overload's split availability — it ships in iOS 26.1, one point release after the base overload). iOS 17–18 (and any non-iOS platform, where the system API doesn't exist) render a floating glass pill via `safeAreaInset(edge: .bottom)`, wrapped in its own `GlassEffectContainer`. Takes a `GlassBottomAccessoryHost` (`.tabView` or `.customTabBar`) so it composes correctly whether the screen uses a real `TabView` or `GlassTabBar`. `content` is wrapped by the exact same modifier structure regardless of `isEnabled`, so toggling it at runtime only animates the accessory pill in/out — it never tears down and rebuilds `content` (which would otherwise lose `@State`, `TabView` selection, navigation stack, or scroll position inside it).
- `.glassMorphUnion(id:in:style:tint:cornerRadius:)` view modifier wrapping `glassEffectUnion`, named to avoid shadowing the system API (same precedent as `glassMorphID`). iOS 17–18 have no union primitive, so rather than fake it with `matchedGeometryEffect` (which animates position, not a shared-shape material sample — a mistake seen in real adopters), the fallback uses an anchor-preference approach: participants report their frame, and the enclosing `GlassEffectContainer` draws one shared fallback-material surface behind the whole group, with individual participant backgrounds suppressed so nothing double-renders. **Kill-switched on iOS 26 too, for now** — gated behind the new `GlassMaterial.nativeGlassMorphingEnabled` flag (`false` by default; see the "Fixed" entry below), the same flag `GlassEffectContainer`/`glassMorphID` use, since the native `glassEffect` + `glassEffectUnion` forward shares the rendering pipeline implicated in that prior device-only corruption bug and hasn't been verified safe on-device.
- `.glassBackgroundExtension(isEnabled:)` view modifier wrapping `backgroundExtensionEffect`, for extending a background layer (e.g. a hero image) under floating glass chrome instead of getting hard-clipped by it. Forwards directly on iOS 26+. iOS 17–18 approximate it by applying `.ignoresSafeArea()` directly to the extended content (instantiated exactly once — see the "Fixed" entry below) and overlaying a gradient-masked feather scrim at the top and bottom edges; Reduce Transparency swaps the blurred scrim for a solid, fully opaque one. Documented as a background-layer-only exception to this package's navigation-layer-only glass rule.

### Fixed

- `Docs/LiquidGlassAPIReference.md`: corrected `TabViewBottomAccessoryPlacement`'s cases to the confirmed `.inline` / `.expanded` (was previously listed as `.expanded` / `.collapsed`), and documented the split availability between `tabViewBottomAccessory(content:)` (iOS 26.0) and `tabViewBottomAccessory(isEnabled:content:)` (iOS 26.1), verified live against the iOS 26.4 SDK symbol index.
- iOS 17–18 fallback now honors **Increased Contrast** (`colorSchemeContrast`), closing a gap against this package's own accessibility rule: the native iOS 26 path already gets it from the system, but the fallback path never read it. `GlassMaterial.borderOpacity(reduceTransparency:contrast:boost:)` and the new `GlassMaterial.borderLineWidth(contrast:)` widen and brighten the fallback rim under Increased Contrast (independently of, and combinable with, Reduce Transparency), and flow through `GlassRenderingModifier` to every component built on `.glass(...)` (`GlassButton`, `GlassCard`, `GlassTabBar`, `GlassBottomAccessory`). `GlassMorphUnionSurfaces`'s own fallback stroke (drawn outside `GlassRenderingModifier`) now reads the same environment value and routes through the same central computations. `GlassBackgroundExtensionMetrics` gains an independent `contrast` input that halves the bleed layer's blur and raises its opacity when Increased Contrast is on without Reduce Transparency (Reduce Transparency alone already maxes out both, so combining the two adds nothing further there).
- `GlassBottomAccessory`: toggling `isEnabled` at runtime used to wrap `content` in structurally different branches (`if isEnabled { content.someModifier{...} } else { content }`), so SwiftUI treated `content` as having different identity per branch and tore it down/rebuilt it on every toggle — losing `@State`, `TabView` selection, navigation stack, and scroll position inside it, and dropping the intended appear/disappear transition in the process (it lived inside the now-discarded branch). `content` is now wrapped by the same modifier structure on every render; only the accessory subtree itself conditionally appears/disappears.
- `.glassBackgroundExtension(isEnabled:)`: the iOS 17–18 fallback used to instantiate `content` twice — once as the real view, once (scaled/blurred) inside its `.background`. For the documented `AsyncImage` hero-image use case this meant two independent fetches/decodes, and any side-effecting modifier inside `content` fired twice. `content` is now instantiated exactly once; the bleed effect comes from `.ignoresSafeArea()` on that single instance plus a feathered edge scrim that samples no content pixels.
- Native `SwiftUI.GlassEffectContainer` / `glassEffectID` / `glassEffectUnion` forwarding was previously disabled by deleting each call site's native branch independently (`GlassEffectContainer.body`, `glassMorphID`, `GlassMorphUnionModifier.body`), connected only by prose doc comments — a partial re-enable (restoring one site but not another) could have silently reintroduced the iOS 26.5 rendering-corruption bug the kill switch exists to prevent. All three now gate entry into a *live, compiled, type-checked* native branch behind one shared flag, `GlassMaterial.nativeGlassMorphingEnabled` (`Sources/LiquidGlass/GlassMaterial.swift`, defaults to `false`), so re-enabling is "flip the flag" plus an on-device verification pass, not git archaeology. Also corrects `GlassEffectContainer.swift`'s stale doc comment, which claimed `glassMorphUnion` forwards to the system `glassEffectUnion` on iOS 26 (it didn't, on any OS, at the time that comment was written).
- `GlassMorphUnionSurfaces.surface(for:)` hand-reimplemented `GlassRenderingModifier`'s fallback fill-selection and border-color logic, including a verbatim copy of its border-color computation. Both now route through shared `GlassMaterial.fallbackFill(reduceTransparency:)` and `GlassMaterial.borderColor(reduceTransparency:colorScheme:)` methods.
- Removed `GlassMaterial.borderOpacity(reduceTransparency:contrast:boost:contrastBoost:)`'s unused `contrastBoost` parameter (never called with a non-default value); the function now always uses `GlassMaterial.increasedContrastBorderBoost` internally. New signature: `borderOpacity(reduceTransparency:contrast:boost:)`.
- `GlassMorphUnionSurfaces` recomputed its grouped union surfaces on every `GeometryReader` layout pass regardless of whether the resolved entries actually changed. It now caches the last resolved entries and their grouped result, skipping `GlassMorphUnionReducer.group(...)` when nothing moved.

## [1.2.0] — 2026-06-13

### Added

- `GlassTabBar` gains an `activeForeground:` parameter for the active item's
  icon and label. When omitted, the bar now derives a **contrast-safe**
  foreground from the resolved tint instead of reusing the tint directly, so an
  ambient `.glassThemeTint` no longer makes the selected item collide with the
  tinted surface and disappear.
- `GlassContrast` helper (WCAG relative luminance, contrast ratio, and the
  active-foreground derivation) plus `Color` resolution helpers (`glassRGBA`,
  `glassRelativeLuminance`, `glassBrightnessScaled`).

### Fixed

- `GlassTabBar` active item was drawn in the same color as the surface tint, so
  with an ambient `.glassThemeTint` the selected tab was illegible
  (tint-on-tint). The active foreground is now decoupled from the surface tint.
- iOS 17–18 fallback now honors **Reduce Transparency** (renders an opaque surface with a higher-contrast inner stroke instead of a translucent material) and **Reduce Motion** (`GlassButton` disables its press scale/bounce animation while keeping the opacity dim as instantaneous feedback). The native iOS 26 path already gets these from the system. Closes #3.

## [1.1.0] — 2026-06-01

### Added

- `GlassEffectContainer` view that coordinates Liquid Glass morph transitions between its child surfaces. Wraps the system `GlassEffectContainer` on iOS 26 and renders content directly on iOS 17–25.
- `.glassMorphID(_:in:)` view modifier that tags a surface for morphing inside a `GlassEffectContainer`. Forwards to the system `glassEffectID(_:in:)` on iOS 26; a no-op on iOS 17–25. Named to avoid shadowing the system API.
- Environment-injected glass tint: `EnvironmentValues.glassTint` and the `.glassThemeTint(_:)` modifier. Any `.glass(...)`, `GlassCard`, `GlassButton`, or `GlassTabBar` without an explicit `tint` now inherits the ambient tint, so a theming layer can set it once near the root.
- `GlassTabBar` floating bottom-navigation component with `GlassTabItem` (SF Symbol + label) and an index-based selection binding. Uses `GlassEffectContainer` on iOS 26 and a `.glass(style: .toolbar)` surface on iOS 17–25.

## [1.0.0] — 2026-05-13

### Added

- `.glass(style:tint:cornerRadius:)` view modifier with native rendering on iOS 26 and a hand-tuned fallback on iOS 17 / 18.
- `GlassStyle` enum with six variants: `.sheet`, `.card`, `.button`, `.toolbar`, `.sidebar`, `.overlay`.
- `GlassCard` container for padded, card-shaped surfaces.
- `GlassButton` component with press-state scale and opacity animation.
- DocC catalog (`Documentation.docc`) covering the public API.
- `LiquidGlassDemo` executable target showcasing every style and component over vivid gradient backgrounds.
- Swift Testing suite covering default corner radii and modifier configuration.
