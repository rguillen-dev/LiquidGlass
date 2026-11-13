# LiquidGlass — Status

> "Where are we?" Read this first; update it before ending a session. Keep it ≤ ~100 lines.
> History and detail: [CHANGELOG.md](CHANGELOG.md) (release history),
> [Docs/v1.2-plan.md](Docs/v1.2-plan.md) (v2.0 deferrals and watch-items),
> [Docs/LiquidGlassAPIReference.md](Docs/LiquidGlassAPIReference.md) (verified API signatures).

**Shipped:** 1.3.0 (2026-07-11), tagged. Used in production by one app (as a local path dependency).
**In flight:** nothing on the package itself. `develop` is 1.3.0 plus tooling only
(MCP pins, XcodeBuildMCP, Dependabot).

## Now

- Nothing in flight.

**Tracked with the maintainer's tooling:**
- **I59:** before the first 1.4.0 code commit, the consuming app pins `exactVersion: 1.3.0` instead of a local path.

## Next

- **1.4.0: native glass morphing on iOS 27** — `GlassMaterial.nativeGlassMorphingEnabled` (`false`) was a
  global kill switch for the device-only iOS 26.5 rendering corruption (07-01, found in the consuming app); never
  retested on 27.x. (0) consuming app pinned to 1.3.0 first (I59). (1) On-device pass on iOS 27.2 (`GlassEffectContainer`, `glassMorphID`, `glassMorphUnion`,
  the two app screens where it showed: a feed behind `GlassTabBar` and a detail hero). (2) If fixed: gate on `#available(iOS 27.0, *)` instead of flipping it, so
  26.x keeps today's non-morphing path. (3) Ride-alongs: `glassMorphTransition` wrapper (`glassEffectTransition`,
  v1.2 plan #5); check iOS 27's automatic glass tint doesn't stack with `glassThemeTint`.
  Start after the consuming app's current release is submitted. Agent: `glass-component-author`; the device
  pass is by hand. Minor bump, CHANGELOG, tag.

## Blocked

- Nothing.

## Backlog

- **v2.0 navigation toolkit** (deferred in the v1.2 plan): `.buttonStyle(.glass / .glassProminent)`
  wrappers and control sizes; `ToolbarSpacer`, `.sharedBackgroundVisibility`, badge helpers;
  `.tabBarMinimizeBehavior`, search-role tab; sheet zoom morph; possibly native `TabView` glass on 26 with
  `GlassTabBar` as the 17–18 fallback; an optional design-token layer.
- Watch-items: `.clear` needs a dimming layer to stay legible; the native interactive hit-shape quirk with
  `RoundedRectangle`; the native path needs an iOS 26+ simulator or a device to verify visually; morphing needs a device.

## Recently done

- 2026-11-13 — `mise run test` (iOS simulator, 62/62); the package tests now run in the maintainer's nightly (I58).
- 2026-11-12 — `CLAUDE.md` "API grounding": optional swift-dev-links lookup (read-only); public files cleaned of internal notes.
- 2026-10-21 — `chore/agent-tuneup` merged (PR #3, `5cf1e2a`): `glass-component-author` gets its MCP tools.
- 2026-10-21 — Weekly grouped Dependabot config; MCP servers pinned (no `@latest`); XcodeBuildMCP added.
- 2026-07-11 — 1.3.0: `GlassBottomAccessory`, `.glassMorphUnion`, `.glassBackgroundExtension`, Increased
  Contrast in the fallback path, and the shared native-morphing kill switch.
