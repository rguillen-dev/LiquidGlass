# Changelog

All notable changes to **LiquidGlass** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] — 2026-05-13

### Added

- `.glass(style:tint:cornerRadius:)` view modifier with native rendering on iOS 26 and a hand-tuned fallback on iOS 17 / 18.
- `GlassStyle` enum with six variants: `.sheet`, `.card`, `.button`, `.toolbar`, `.sidebar`, `.overlay`.
- `GlassCard` container for padded, card-shaped surfaces.
- `GlassButton` component with press-state scale and opacity animation.
- DocC catalog (`Documentation.docc`) covering the public API.
- `LiquidGlassDemo` executable target showcasing every style and component over vivid gradient backgrounds.
- Swift Testing suite covering default corner radii and modifier configuration.
