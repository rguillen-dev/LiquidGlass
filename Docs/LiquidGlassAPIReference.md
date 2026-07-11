# Liquid Glass — Verified API Reference

Grounding doc for agents working in this package. Scope: the SwiftUI Liquid Glass
surface as of the iOS 26.x cycle. Use this to verify signatures before writing
native-path code. If an API you need is missing here, do not invent it — flag it.

Sources: Apple Developer documentation (`glassEffect`, `GlassEffectContainer`,
"Applying Liquid Glass to custom views"), Apple HIG (Materials), and the
community reference at github.com/conorluddy/LiquidGlassReference (verified
against Apple docs). Last reconciled: 2026-06.

---

## 1. Core modifier

```swift
func glassEffect<S: Shape>(
    _ glass: Glass = .regular,
    in shape: S = DefaultGlassEffectShape,   // capsule by default
    isEnabled: Bool = true
) -> some View
```

- Default variant is `.regular`; default shape is capsule.
- Apply glass **last** in the modifier chain.
- Do NOT put `.blur`, `.opacity`, or a solid `.background` (Color.white/black)
  behind a glass view — it fights the material.

## 2. The `Glass` type

```swift
struct Glass {
    static var regular: Glass    // default; adapts to any content
    static var clear: Glass      // high transparency; media-rich bg + dimming layer
    static var identity: Glass   // no effect — use to conditionally disable

    func tint(_ color: Color) -> Glass   // semantic, not decorative
    func interactive() -> Glass          // iOS only; press scale/bounce/shimmer/illumination
}
```

Chaining is order-independent: `.regular.tint(.orange).interactive()`.

> Incidental finding (2026-07-09, live iOS 26.4 SDK, not otherwise part of
> this reference pass): the live SDK's `tint` and `interactive` are
> `func tint(_ color: Color?) -> Glass` (optional color) and
> `func interactive(_ isEnabled: Bool = true) -> Glass` (defaulted param) —
> both are backward-compatible with the signatures above, so nothing in this
> package needed to change, but flagging the drift here for the next agent
> who touches `Glass` chaining directly.

Variant selection:
- `.regular` — toolbars, buttons, nav bars, tab bars, standard controls.
- `.clear` — only when ALL hold: over media-rich content, content survives a
  dimming layer, and foreground content is bold/bright.
- `.identity` — conditional toggle, e.g. `glassEffect(isEnabled ? .regular : .identity)`.
  This is also the correct accessibility off-switch.

## 3. Containers, morphing, union

```swift
struct GlassEffectContainer<Content: View>: View {
    init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content)
}
```
Glass cannot sample other glass — the container provides a shared sampling region,
improves performance, and enables morphing. `spacing` is the distance within which
adjacent surfaces blend/morph.

```swift
func glassEffectID<ID: Hashable>(_ id: ID, in namespace: Namespace.ID) -> some View
```
Tag surfaces with a shared `@Namespace` ID; conditionally showing/hiding them inside
one container makes the glass morph rather than cross-fade.
> In THIS package, wrap this as `glassMorphID(_:in:)` — never shadow the system name.

```swift
func glassEffectUnion(id: (some Hashable & Sendable)?, namespace: Namespace.ID) -> some View
```
Manually merge glass shapes too far apart to merge by `spacing`. Requirements:
same id, same glass type, similar shapes, all in the same container.
> Confirmed 2026-07-09 against the live iOS 26.4 SDK symbol index
> (`SwiftUICore.swiftmodule`) while building `glassMorphUnion`: signature is
> exactly as above (optional opaque `id`, not a plain `ID: Hashable` generic —
> this doc's earlier signature was slightly off). Availability:
> `@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *)`,
> `@available(visionOS, unavailable)`.
> In THIS package, wrap this as `glassMorphUnion(id:in:style:tint:cornerRadius:)`
> — never shadow the system name.

```swift
func glassEffectTransition(_ transition: GlassEffectTransition, isEnabled: Bool = true) -> some View

enum GlassEffectTransition {
    case identity         // no change
    case matchedGeometry  // default
    case materialize      // material appearance transition
}
```

## 4. Shapes

```swift
.glassEffect(.regular, in: .capsule)                          // default
.glassEffect(.regular, in: .circle)
.glassEffect(.regular, in: .ellipse)
.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
.glassEffect(.regular, in: .rect(cornerRadius: .containerConcentric)) // matches container corners
```

## 5. Button styles & control sizing

```swift
.buttonStyle(.glass)           // translucent — secondary actions
.buttonStyle(.glassProminent)  // opaque — primary actions

.controlSize(.mini | .small | .regular | .large | .extraLarge)  // extraLarge new in 26
.buttonBorderShape(.capsule | .circle | .roundedRectangle(radius:))
```
KNOWN ISSUE: `.glassProminent` + `.buttonBorderShape(.circle)` shows artifacts.
Workaround: add `.clipShape(Circle())`.

KNOWN ISSUE: `.glassEffect(.regular.interactive(), in: RoundedRectangle())` may
respond with a capsule hit shape. For buttons prefer `.buttonStyle(.glass)`.

## 6. Toolbar / navigation (native-only; these auto-adopt glass on iOS 26)

```swift
ToolbarSpacer(.fixed, spacing: 20)
ToolbarSpacer(.flexible)
.sharedBackgroundVisibility(.hidden)   // drop glass bg on a specific item
.badge(Int)
```

TabView:
```swift
.tabBarMinimizeBehavior(.automatic | .onScrollDown | .never)
.tabViewBottomAccessory { /* persistent glass view above tab bar */ }
.tabViewBottomAccessory(isEnabled: Bool) { /* iOS 26.1+ only — see note below */ }
@Environment(\.tabViewBottomAccessoryPlacement) var placement  // TabViewBottomAccessoryPlacement?
Tab("Search", systemImage: "magnifyingglass", role: .search) { ... }  // floating search
```
> Confirmed 2026-07-09 against the live iOS 26.4 SDK symbol index
> (`SwiftUI.swiftmodule`'s `arm64e-apple-ios.swiftinterface`) while building
> `GlassBottomAccessory`:
> - `tabViewBottomAccessory(content:)` — `@available(iOS 26.0, *)`.
> - `tabViewBottomAccessory(isEnabled:content:)` — `@available(iOS 26.1, *)`,
>   **one point release later** than the base overload. Code targeting exactly
>   iOS 26.0 must gate `isEnabled` manually (no such parameter exists yet).
> - Both overloads are **iOS-only**: `@available(macOS, unavailable)`,
>   `@available(tvOS, unavailable)`, `@available(watchOS, unavailable)`,
>   `@available(visionOS, unavailable)`. There is no accessory slot outside iOS.
> - `TabViewBottomAccessoryPlacement` (`SwiftUICore`) has exactly two cases:
>   **`.inline` and `.expanded`** — not `.collapsed`, correcting this doc's
>   earlier placeholder. The `tabViewBottomAccessoryPlacement` environment
>   value itself is available on iOS/macOS/tvOS/watchOS/visionOS 26.0 (it's
>   just always `nil` off iOS, since there's no accessory to report a
>   placement for).

Sheets / zoom morph:
```swift
.matchedTransitionSource(id: ID, in: namespace)
.navigationTransition(.zoom(sourceID: ID, in: namespace))
.scrollContentBackground(.hidden)         // let glass show through a Form/List chrome
.backgroundExtensionEffect()              // extend content under floating chrome
.backgroundExtensionEffect(isEnabled: Bool)
```
> Confirmed 2026-07-09 against the live iOS 26.4 SDK symbol index
> (`SwiftUI.swiftmodule`) while building `glassBackgroundExtension`: both
> overloads are `@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)`
> — no split availability between them (unlike `tabViewBottomAccessory` above).
> In THIS package, wrap this as `glassBackgroundExtension(isEnabled:)`.

## 7. Accessibility

System handles these automatically on the NATIVE path (do not override unless
necessary): Reduce Transparency (more frosting), Increased Contrast (borders),
Reduce Motion (calmer animation), and iOS 26.1+ user "Tinted Mode" (opacity up).

On the FALLBACK path (iOS 17–18) you must do this yourself:
```swift
@Environment(\.accessibilityReduceTransparency) var reduceTransparency
@Environment(\.accessibilityReduceMotion) var reduceMotion
@Environment(\.colorSchemeContrast) var contrast   // ColorSchemeContrast: .standard / .increased
```
- Reduce Transparency → drop translucency toward an opaque surface.
- Reduce Motion → remove press/morph animation.
- Increased Contrast → crisp up the rim/border (e.g. wider stroke, higher opacity)
  so edges read clearly even when the fill stays translucent.

`ColorSchemeContrast` (`SwiftUI`, stable since iOS 14) is not a Liquid-Glass-specific
API, so reading it needs no availability grounding or `#available` guard of its own —
it's gated the same way as `reduceTransparency`/`reduceMotion` above: behind the
package's existing fallback-path branch, in `GlassRenderingModifier`. This package's
implementation lives in `GlassMaterial.borderOpacity(reduceTransparency:contrast:boost:)`
and `GlassMaterial.borderLineWidth(contrast:)`, both consumed by `GlassRenderingModifier`
and `GlassMorphUnionSurfaces`. `GlassBackgroundExtensionMetrics` also takes `contrast`
for its own bleed-layer blur/opacity tuning. Reduce Transparency and Increased
Contrast are independent — a user can enable either, both, or neither — so treat
them as separate boosts to combine, not a single flag.

> Corrected 2026-07-09, verified against the live `SwiftUICore.swiftinterface`
> (both macOS and iOS 26.4 SDKs): the Increased Contrast environment key is
> **`colorSchemeContrast`**, not `accessibilityContrast` — no such member
> exists on `EnvironmentValues` in the current SDK (confirmed by a failed
> `swift build`: "value of type 'EnvironmentValues' has no member
> 'accessibilityContrast'"). Unlike `accessibilityReduceTransparency` /
> `accessibilityReduceMotion`, this one doesn't carry the `accessibility`
> prefix. Don't reintroduce `accessibilityContrast` from memory.

## 8. UIKit equivalents (only if we ever add a UIKit layer)

```swift
UIGlassEffect(glass: .regular, isInteractive: true)   // in a UIVisualEffectView
UIGlassContainerEffect()                               // container equivalent
```

## 9. Performance & cost notes

- Native glass is GPU/battery heavy relative to `Material`; real-world reports cite
  a large battery delta vs iOS 18 on flagship hardware. Our fallback is lighter.
- Always group multiple glass surfaces in a container (shared sampling).
- Let glass rest in steady states; avoid continuous repeating animation on glass.
- Prefer `.identity` over removing the modifier when toggling — no layout recalc.

## 10. Backward-compatibility pattern (the shape this package implements)

```swift
@ViewBuilder
func glassedEffect(in shape: some Shape = Capsule(), interactive: Bool = false) -> some View {
    if #available(iOS 26.0, *) {
        let glass: Glass = interactive ? .regular.interactive() : .regular
        self.glassEffect(glass, in: shape)
    } else {
        self.background(
            shape.fill(.ultraThinMaterial)
                 .overlay(shape.stroke(.white.opacity(0.2), lineWidth: 1))
        )
    }
}
```
(Illustrative — our real implementation lives in `GlassRenderingModifier` and is
per-style tuned. Use that, not this snippet.)

## Quick "is this real?" checklist before writing native code

- [ ] The modifier/type appears in this doc.
- [ ] Variant is one of `.regular` / `.clear` / `.identity`.
- [ ] Multiple surfaces share a `GlassEffectContainer`.
- [ ] Both render paths handled, behind the two-axis guard.
- [ ] Fallback handles Reduce Transparency / Reduce Motion / Increased Contrast.
