//
//  GlassMorphUnion.swift
//  LiquidGlass
//
//  Created by Ricardo Guillen on 07/09/26.
//  Copyright © 2026 Ricardo Guillen. All rights reserved.
//

import SwiftUI

// MARK: - glassMorphUnion

public extension View {

    /// Merges this glass surface with every other surface sharing the same
    /// `id` and `namespace` inside the same ``GlassEffectContainer``, so they
    /// read as one continuous piece of glass instead of several separate
    /// surfaces that happen to be near each other.
    ///
    /// > Kill switch: whether this forwards to the system
    /// > `glassEffect(...).glassEffectUnion(id:namespace:)` chain on iOS 26+
    /// > is gated on `GlassMaterial.nativeGlassMorphingEnabled`, the same flag
    /// > that gates ``GlassEffectContainer`` and
    /// > ``SwiftUI/View/glassMorphID(_:in:)`` — see that flag's doc comment
    /// > for the device-only iOS 26.5 rendering-corruption bug that led to
    /// > disabling it. `glassMorphUnion`'s native path shares the same
    /// > underlying Liquid Glass rendering pipeline implicated in that bug, so
    /// > it's gated together rather than independently, even though a scoped
    /// > union call is plausibly lower-risk than the container itself — that
    /// > reasoning is unverified on-device, so it isn't worth a separate flag.
    /// > While the flag is `false` (the current default), this always renders
    /// > the iOS 17–18 fallback surface described below, on every OS version.
    /// > The native forward is still compiled and type-checked against the
    /// > live SDK; only entry into it is gated.
    ///
    /// On iOS 26, once the flag is re-enabled, this forwards to the system
    /// `glassEffectUnion(id:namespace:)` after applying `glassEffect` — the
    /// same chain Apple's API expects (`.glassEffect(...).glassEffectUnion(id:namespace:)`),
    /// so **do not** also call ``SwiftUI/View/glass(style:tint:cornerRadius:)``
    /// on a `glassMorphUnion` participant; this modifier applies the glass itself.
    ///
    /// iOS 17–18 — and, while the kill switch is off, every OS version for
    /// now — have no *live* union primitive, so the fallback does not fake it
    /// with `matchedGeometryEffect` (that animates position, not a shared-shape
    /// material sample — it produces the wrong visual). Instead each
    /// participant reports its laid-out frame via an anchor preference; the
    /// enclosing ``GlassEffectContainer`` collects every participant sharing a
    /// union key, unions their bounding boxes, and draws **one** shared
    /// fallback-material surface behind the whole group. Participants
    /// themselves render no individual background on the fallback path, so
    /// nothing double-renders.
    ///
    /// > Important: a `glassMorphUnion` group only *merges* visually inside a
    /// > ``GlassEffectContainer`` — that's the reduction point that collects
    /// > every participant's reported frame and draws the one shared surface.
    /// > Passing `id: nil` is the off switch: the view falls back to plain
    /// > ``SwiftUI/View/glass(style:tint:cornerRadius:)`` rendering (matching
    /// > how the system `glassEffectUnion` treats a `nil` id). A non-`nil` `id`
    /// > used **outside** a ``GlassEffectContainer`` degrades the same way: the
    /// > fallback path has nowhere to reduce the reported frame, so it renders
    /// > this surface as plain, unmerged glass instead of silently rendering
    /// > nothing.
    ///
    /// > Note: Named `glassMorphUnion` — not `glassEffectUnion` — so it never
    /// > shadows the system API it wraps. Same precedent as ``SwiftUI/View/glassMorphID(_:in:)``.
    ///
    /// ```swift
    /// @Namespace private var glass
    ///
    /// GlassEffectContainer {
    ///     HStack {
    ///         Image(systemName: "play.fill")
    ///             .padding()
    ///             .glassMorphUnion(id: "transport", in: glass, style: .toolbar)
    ///         Image(systemName: "forward.fill")
    ///             .padding()
    ///             .glassMorphUnion(id: "transport", in: glass, style: .toolbar)
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - id: The shared union key. Surfaces with equal `id`s in the same
    ///     `namespace` merge. `nil` disables merging for this surface.
    ///   - namespace: The namespace scoping `id`, declared with `@Namespace`.
    ///   - style: The visual variant used for both the native glass and the
    ///     fallback shared surface. Defaults to ``GlassStyle/toolbar``, matching
    ///     Apple's guidance that union is primarily for grouping toolbar-style
    ///     controls.
    ///   - tint: Optional color overlaid on the surface. Falls back to the
    ///     ambient ``EnvironmentValues/glassTint``.
    ///   - cornerRadius: Overrides `style`'s default corner radius when set.
    func glassMorphUnion<ID: Hashable & Sendable>(
        id: ID?,
        in namespace: Namespace.ID,
        style: GlassStyle = .toolbar,
        tint: Color? = nil,
        cornerRadius: CGFloat? = nil
    ) -> some View {
        modifier(
            GlassMorphUnionModifier(
                id: id,
                namespace: namespace,
                style: style,
                tint: tint,
                cornerRadius: cornerRadius ?? style.defaultCornerRadius
            )
        )
    }
}

// MARK: - GlassMorphUnionModifier

struct GlassMorphUnionModifier<ID: Hashable & Sendable>: ViewModifier {

    let id: ID?
    let namespace: Namespace.ID
    let style: GlassStyle
    let tint: Color?
    let cornerRadius: CGFloat

    @Environment(\.glassTint) private var environmentTint
    @Environment(\.isInsideGlassMorphUnionReducer) private var isInsideReducer

    private var resolvedTint: Color? { tint ?? environmentTint }

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        // Kill switch: entry into the native forward is gated on
        // `GlassMaterial.nativeGlassMorphingEnabled` — see the doc comment on
        // `glassMorphUnion(id:in:style:tint:cornerRadius:)`. The native branch
        // is compiled and type-checked continuously; only entry is gated.
        #if compiler(>=6.2)
        if #available(iOS 26.0, macOS 26.0, *), GlassMaterial.nativeGlassMorphingEnabled {
            nativeRendering(content, shape: shape)
        } else {
            fallbackRendering(content, shape: shape)
        }
        #else
        fallbackRendering(content, shape: shape)
        #endif
    }

    // MARK: Native (iOS 26+, while `GlassMaterial.nativeGlassMorphingEnabled` is `true`)

    #if compiler(>=6.2)
    @available(iOS 26.0, macOS 26.0, *)
    @ViewBuilder
    private func nativeRendering(_ content: Content, shape: RoundedRectangle) -> some View {
        let glass: Glass = resolvedTint.map { Glass.regular.tint($0) } ?? .regular
        content
            .glassEffect(glass, in: shape)
            .glassEffectUnion(id: id, namespace: namespace)
    }
    #endif

    // MARK: Fallback (iOS 17–18, and — while the kill switch is off — iOS 26+ too)

    @ViewBuilder
    private func fallbackRendering(_ content: Content, shape: RoundedRectangle) -> some View {
        if let id, isInsideReducer {
            // No individual background here — the shared surface is drawn once
            // by the enclosing `GlassEffectContainer` from the collected
            // preference entries, so this participant doesn't double-render.
            content
                .contentShape(shape)
                .anchorPreference(key: GlassMorphUnionPreferenceKey.self, value: .bounds) { anchor in
                    [
                        GlassMorphUnionEntry(
                            groupKey: GlassMorphUnionGroupKey(id: AnyHashable(id), namespace: namespace),
                            anchor: anchor,
                            style: style,
                            tint: resolvedTint,
                            cornerRadius: cornerRadius
                        )
                    ]
                }
        } else {
            // `nil` id: the off switch. A non-`nil` id used outside a
            // `GlassEffectContainer` degrades the same way — there's no
            // reducer to collect the anchor preference into a shared surface,
            // so this renders as a normal, unmerged glass surface instead of
            // silently rendering nothing.
            content.glass(style: style, tint: resolvedTint, cornerRadius: cornerRadius)
        }
    }
}

// MARK: - Fallback container presence

/// Internal environment flag set by ``GlassEffectContainer``'s fallback body
/// so a `glassMorphUnion` participant can tell whether it's actually inside a
/// container capable of reducing its anchor preference into a shared surface.
/// Not public API — purely a fallback-path implementation detail that lets
/// `GlassMorphUnionModifier` degrade to plain, unmerged glass instead of
/// silently rendering nothing when used outside a container.
struct GlassMorphUnionReducerPresenceKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isInsideGlassMorphUnionReducer: Bool {
        get { self[GlassMorphUnionReducerPresenceKey.self] }
        set { self[GlassMorphUnionReducerPresenceKey.self] = newValue }
    }
}

// MARK: - Fallback union bookkeeping

/// Groups fallback `glassMorphUnion` participants that share an `id` inside
/// the same `namespace`.
///
/// `AnyHashable` itself isn't `Sendable`, but every `id` boxed into it here
/// came from `glassMorphUnion`'s own `ID: Hashable & Sendable` generic
/// constraint, so the erased value is always safe to send. `@unchecked` is
/// scoped to that one guarantee.
struct GlassMorphUnionGroupKey: Hashable, @unchecked Sendable {
    let id: AnyHashable
    let namespace: Namespace.ID
}

/// One fallback `glassMorphUnion` participant's reported frame and styling,
/// collected via ``GlassMorphUnionPreferenceKey``.
struct GlassMorphUnionEntry: Equatable, Sendable {
    let groupKey: GlassMorphUnionGroupKey
    let anchor: Anchor<CGRect>
    let style: GlassStyle
    let tint: Color?
    let cornerRadius: CGFloat
}

struct GlassMorphUnionPreferenceKey: PreferenceKey {
    static let defaultValue: [GlassMorphUnionEntry] = []

    static func reduce(value: inout [GlassMorphUnionEntry], nextValue: () -> [GlassMorphUnionEntry]) {
        value.append(contentsOf: nextValue())
    }
}

/// A fallback union participant's frame, resolved from its anchor into a
/// concrete `CGRect`. Kept separate from ``GlassMorphUnionEntry`` so the
/// grouping math in ``GlassMorphUnionReducer`` is pure and unit-testable
/// without a live `GeometryProxy`.
struct GlassMorphUnionResolvedEntry: Equatable {
    let groupKey: GlassMorphUnionGroupKey
    let rect: CGRect
    let style: GlassStyle
    let tint: Color?
    let cornerRadius: CGFloat
}

/// Reduces resolved fallback union entries into one bounding surface per
/// union group.
enum GlassMorphUnionReducer {

    /// The default outward padding applied to a group's unioned bounding box,
    /// so a merged surface doesn't hug its participants too tightly.
    static let defaultPadding: CGFloat = 6

    /// Groups `entries` by ``GlassMorphUnionGroupKey``, unions each group's
    /// rects, and pads the result outward by `padding`.
    ///
    /// Style, tint, and corner radius are taken from the first entry seen for
    /// each group (participants sharing a union key are expected to share
    /// glass styling — the same contract the system `glassEffectUnion`
    /// documents for "same glass type, similar shapes").
    static func group(
        _ entries: [GlassMorphUnionResolvedEntry],
        padding: CGFloat = defaultPadding
    ) -> [GlassMorphUnionResolvedEntry] {
        var order: [GlassMorphUnionGroupKey] = []
        var rectsByKey: [GlassMorphUnionGroupKey: CGRect] = [:]
        var firstByKey: [GlassMorphUnionGroupKey: GlassMorphUnionResolvedEntry] = [:]

        for entry in entries {
            if let existing = rectsByKey[entry.groupKey] {
                rectsByKey[entry.groupKey] = existing.union(entry.rect)
            } else {
                rectsByKey[entry.groupKey] = entry.rect
                firstByKey[entry.groupKey] = entry
                order.append(entry.groupKey)
            }
        }

        return order.compactMap { key in
            guard let rect = rectsByKey[key], let first = firstByKey[key] else { return nil }
            return GlassMorphUnionResolvedEntry(
                groupKey: key,
                rect: rect.insetBy(dx: -padding, dy: -padding),
                style: first.style,
                tint: first.tint,
                cornerRadius: first.cornerRadius
            )
        }
    }
}

/// Passive memoization cache for ``GlassMorphUnionSurfaces``'s last resolved
/// entries and their grouped result. A plain reference type (not `@Observable`
/// or otherwise change-tracked) so mutating its properties from inside a
/// view's `body` — to update the cache after a miss — never itself triggers a
/// SwiftUI view update; only reassigning the `@State` property holding the
/// cache instance would do that, and this type is never reassigned after
/// creation.
private final class GlassMorphUnionGroupCache {
    var resolved: [GlassMorphUnionResolvedEntry] = []
    var grouped: [GlassMorphUnionResolvedEntry] = []
}

// MARK: - Fallback shared surface rendering

/// Draws the shared fallback-material surface behind every `glassMorphUnion`
/// group collected inside a ``GlassEffectContainer``.
struct GlassMorphUnionSurfaces: View {

    let entries: [GlassMorphUnionEntry]

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    /// Read directly from the environment, mirroring `GlassRenderingModifier`.
    /// This type has no forced-override seam (like the other environment
    /// reads above), consistent with how the rest of this fallback surface
    /// already reads accessibility state.
    @Environment(\.colorSchemeContrast) private var contrast

    /// Memoizes the last resolved entries and their grouped result so
    /// `GlassMorphUnionReducer.group(...)` — an O(n) union pass — isn't redone
    /// on every layout pass `GeometryReader` triggers when nothing actually
    /// moved. A reference type held via `@State` so its lifetime tracks this
    /// view's identity, but its properties are mutated directly (never
    /// reassigned) so updating the cache during `body` never itself triggers
    /// a SwiftUI view update — it's a passive cache, not view state.
    @State private var cache = GlassMorphUnionGroupCache()

    var body: some View {
        GeometryReader { proxy in
            let resolved = entries.map {
                GlassMorphUnionResolvedEntry(
                    groupKey: $0.groupKey,
                    rect: proxy[$0.anchor],
                    style: $0.style,
                    tint: $0.tint,
                    cornerRadius: $0.cornerRadius
                )
            }
            ForEach(groupedEntries(for: resolved), id: \.groupKey) { group in
                surface(for: group)
                    .frame(width: max(group.rect.width, 0), height: max(group.rect.height, 0))
                    .position(x: group.rect.midX, y: group.rect.midY)
                    .animation(
                        reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.78),
                        value: group.rect
                    )
            }
        }
        .allowsHitTesting(false)
    }

    /// Returns the grouped result for `resolved`, reusing the cached grouping
    /// from the previous layout pass when `resolved` is unchanged.
    private func groupedEntries(for resolved: [GlassMorphUnionResolvedEntry]) -> [GlassMorphUnionResolvedEntry] {
        if resolved == cache.resolved {
            return cache.grouped
        }
        let grouped = GlassMorphUnionReducer.group(resolved)
        cache.resolved = resolved
        cache.grouped = grouped
        return grouped
    }

    /// Mirrors `GlassRenderingModifier`'s fallback tuning (material, tint,
    /// stroke, shadow) so a merged union surface reads consistently with
    /// every other fallback glass surface in the package — including the
    /// same Reduce Transparency + Increased Contrast handling, routed through
    /// the same central ``GlassMaterial`` computations. Fill and border color
    /// selection are shared with `GlassRenderingModifier` via
    /// ``GlassMaterial/fallbackFill(reduceTransparency:)`` and
    /// ``GlassMaterial/borderColor(reduceTransparency:colorScheme:)`` rather
    /// than reimplemented here.
    private func surface(for group: GlassMorphUnionResolvedEntry) -> some View {
        let shape = RoundedRectangle(cornerRadius: group.cornerRadius, style: .continuous)
        let material = GlassMaterial(style: group.style)
        let fill = material.fallbackFill(reduceTransparency: reduceTransparency)
        let borderColor = GlassMaterial.borderColor(reduceTransparency: reduceTransparency, colorScheme: colorScheme)

        return shape
            .fill(fill)
            .overlay {
                if let tint = group.tint {
                    shape.fill(tint.opacity(material.tintOpacity))
                }
            }
            .overlay {
                shape.strokeBorder(
                    borderColor.opacity(
                        material.borderOpacity(reduceTransparency: reduceTransparency, contrast: contrast)
                    ),
                    lineWidth: material.borderLineWidth(contrast: contrast)
                )
            }
            .shadow(
                color: Color.black.opacity(material.fallbackShadowOpacity),
                radius: material.fallbackShadowRadius,
                x: 0,
                y: material.fallbackShadowY
            )
    }
}

// MARK: - Previews

#Preview("Morph union — merged toolbar group") {
    @Previewable @Namespace var glass

    ZStack {
        LinearGradient(
            colors: [.purple, .blue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(["backward.fill", "play.fill", "forward.fill"], id: \.self) { symbol in
                    Image(systemName: symbol)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .glassMorphUnion(id: "transport", in: glass, style: .toolbar, tint: .indigo)
                }
            }
        }
    }
}

#Preview("Morph union — two independent groups") {
    @Previewable @Namespace var glass

    ZStack {
        LinearGradient(
            colors: [.orange, .pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        GlassEffectContainer(spacing: 8) {
            VStack(spacing: 20) {
                HStack(spacing: 4) {
                    ForEach(["heart.fill", "bookmark.fill"], id: \.self) { symbol in
                        Image(systemName: symbol)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .glassMorphUnion(id: "actions", in: glass, style: .toolbar)
                    }
                }
                // A different union id merges independently from "actions" above,
                // even inside the same container.
                Image(systemName: "ellipsis")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .glassMorphUnion(id: "more", in: glass, style: .toolbar)
            }
        }
    }
}
