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
func glassEffectUnion<ID: Hashable>(id: ID, namespace: Namespace.ID) -> some View
```
Manually merge glass shapes too far apart to merge by `spacing`. Requirements:
same id, same glass type, similar shapes, all in the same container.

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
@Environment(\.tabViewBottomAccessoryPlacement) var placement  // .expanded | .collapsed
Tab("Search", systemImage: "magnifyingglass", role: .search) { ... }  // floating search
```

Sheets / zoom morph:
```swift
.matchedTransitionSource(id: ID, in: namespace)
.navigationTransition(.zoom(sourceID: ID, in: namespace))
.scrollContentBackground(.hidden)         // let glass show through a Form/List chrome
.backgroundExtensionEffect()              // extend content under floating chrome
```

## 7. Accessibility

System handles these automatically on the NATIVE path (do not override unless
necessary): Reduce Transparency (more frosting), Increased Contrast (borders),
Reduce Motion (calmer animation), and iOS 26.1+ user "Tinted Mode" (opacity up).

On the FALLBACK path (iOS 17–18) you must do this yourself:
```swift
@Environment(\.accessibilityReduceTransparency) var reduceTransparency
@Environment(\.accessibilityReduceMotion) var reduceMotion
```
- Reduce Transparency → drop translucency toward an opaque surface.
- Reduce Motion → remove press/morph animation.

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
- [ ] Fallback handles Reduce Transparency / Reduce Motion.
