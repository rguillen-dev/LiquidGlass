# Changelog

All notable changes to **LiquidGlass** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] — 2026-06-04

### Fixed

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
