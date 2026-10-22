# LiquidGlass — Status

> "Where are we?" Read this first; update it before ending a session. Keep it ≤ ~100 lines.
> History and detail: [CHANGELOG.md](CHANGELOG.md) (release history),
> [Docs/v1.2-plan.md](Docs/v1.2-plan.md) (v2.0 deferrals and watch-items),
> [Docs/LiquidGlassAPIReference.md](Docs/LiquidGlassAPIReference.md) (verified API signatures).

**Shipped:** 1.3.0 (2026-07-11), tagged. Consumed by agenda-ios as a local path dependency.
**In flight:** nothing on the package itself. `develop` is 1.3.0 plus tooling only
(MCP pins, XcodeBuildMCP, Dependabot).

## Now

- **Agent tune-up** — `chore/agent-tuneup` (2026-10-21, pushed, not merged): `glass-component-author` gets
  `mcp__xcodebuild`, `mcp__apple-docs` and `mcp__context7`, so it can verify signatures as its prompt requires.

## Next

- **Re-enable native glass morphing on iOS 26** — flip `GlassMaterial.nativeGlassMorphingEnabled`
  (`Sources/LiquidGlass/GlassMaterial.swift`, `false` by default) and run an on-device verification
  pass. It gates `GlassEffectContainer`, `glassMorphID` and `glassMorphUnion`, which were switched off
  over the iOS 26.5 device-only rendering-corruption bug.

## Blocked

- Nothing.

## Backlog

- **v2.0 navigation toolkit** (deferred in the v1.2 plan): `.buttonStyle(.glass / .glassProminent)`
  wrappers and control sizes; `ToolbarSpacer`, `.sharedBackgroundVisibility`, badge helpers;
  `.tabBarMinimizeBehavior`, search-role tab; sheet zoom morph; possibly native `TabView` glass on 26 with
  `GlassTabBar` as the 17–18 fallback; an optional design-token layer.
- Watch-items: `.clear` needs a dimming layer to stay legible; the native interactive hit-shape quirk with
  `RoundedRectangle`; the native path can't be verified visually without an iOS 26 simulator or device.

## Recently done

- 2026-10-21 — Weekly grouped Dependabot config; MCP servers pinned (no `@latest`); XcodeBuildMCP added.
- 2026-07-11 — 1.3.0: `GlassBottomAccessory`, `.glassMorphUnion`, `.glassBackgroundExtension`, Increased
  Contrast in the fallback path, and the shared native-morphing kill switch.
