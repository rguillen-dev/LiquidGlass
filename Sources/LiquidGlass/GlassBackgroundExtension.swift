//
//  GlassBackgroundExtension.swift
//  LiquidGlass
//
//  Created by Ricardo Guillen on 07/09/26.
//  Copyright © 2026 Ricardo Guillen. All rights reserved.
//

import SwiftUI

// MARK: - glassBackgroundExtension

public extension View {

    /// Extends this view's background so it bleeds out under floating glass
    /// chrome (a toolbar, tab bar, or bottom accessory) instead of getting
    /// hard-clipped by it.
    ///
    /// This is for the **background layer specifically** — typically a hero
    /// image or media view on a detail screen that sits behind floating glass
    /// controls. Per this package's rule that glass is navigation-layer only,
    /// this modifier is the deliberate, narrow exception: it targets *content
    /// that will be letterboxed by chrome*, not a general-purpose way to add
    /// glass or transparency to arbitrary content. Don't reach for it outside
    /// that hero-background use case.
    ///
    /// On iOS 26+ this forwards straight to the system `backgroundExtensionEffect(isEnabled:)`,
    /// which mirrors/extends the view's own edge content under the safe area.
    /// iOS 17–18 have no such primitive, so the fallback approximates it
    /// without ever instantiating `content` a second time (an earlier
    /// approach that duplicated `content` into a blurred/scaled background
    /// layer double-fired side effects like `AsyncImage` fetches — fixed):
    /// the single `content` instance itself extends under the safe area via
    /// `.ignoresSafeArea()`, and a feathered scrim — a gradient-masked blur
    /// or solid band that samples no content pixels — is overlaid at the top
    /// and bottom edges to dissolve that extension into the floating chrome
    /// above it, rather than showing a hard edge. Reduce Transparency swaps
    /// the blurred `Material` scrim for a solid, fully opaque one; Increased
    /// Contrast (when Reduce Transparency is off) halves the blur and raises
    /// the opacity partway there, for a more defined edge that's still
    /// translucent. See ``GlassBackgroundExtensionMetrics`` for the exact
    /// values.
    ///
    /// ```swift
    /// AsyncImage(url: heroURL)
    ///     .resizable()
    ///     .aspectRatio(contentMode: .fill)
    ///     .glassBackgroundExtension()
    ///     .overlay(alignment: .top) {
    ///         GlassTabBar(items: tabs, selection: $tab) // floats above the bleed
    ///     }
    /// ```
    ///
    /// - Parameter isEnabled: Whether the extension is applied. Defaults to
    ///   `true`; pass `false` to conditionally disable without removing the
    ///   modifier (avoids a layout recalculation, matching the package's
    ///   `Glass.identity` convention).
    func glassBackgroundExtension(isEnabled: Bool = true) -> some View {
        modifier(GlassBackgroundExtensionModifier(isEnabled: isEnabled))
    }
}

// MARK: - GlassBackgroundExtensionModifier

struct GlassBackgroundExtensionModifier: ViewModifier {

    let isEnabled: Bool

    @Environment(\.accessibilityReduceTransparency) private var environmentReduceTransparency
    @Environment(\.accessibilityReduceMotion) private var environmentReduceMotion
    @Environment(\.colorSchemeContrast) private var environmentContrast

    /// Preview/test override — see the same seam pattern in `GlassRenderingModifier`.
    var forceReduceTransparency: Bool? = nil
    var forceReduceMotion: Bool? = nil

    /// Preview/test override for Increased Contrast — same seam pattern as
    /// `forceReduceTransparency`/`forceReduceMotion`.
    var forceContrast: ColorSchemeContrast? = nil

    private var reduceTransparency: Bool { forceReduceTransparency ?? environmentReduceTransparency }
    private var reduceMotion: Bool { forceReduceMotion ?? environmentReduceMotion }
    private var contrast: ColorSchemeContrast { forceContrast ?? environmentContrast }

    private var metrics: GlassBackgroundExtensionMetrics {
        GlassBackgroundExtensionMetrics(reduceTransparency: reduceTransparency, contrast: contrast)
    }

    func body(content: Content) -> some View {
        // `backgroundExtensionEffect` ships in the iOS 26 SDK (Swift 6.2+) —
        // same two-axis guard as `GlassRenderingModifier`.
        #if compiler(>=6.2)
        if #available(iOS 26.0, macOS 26.0, *) {
            content.backgroundExtensionEffect(isEnabled: isEnabled)
        } else {
            fallbackRendering(content)
        }
        #else
        fallbackRendering(content)
        #endif
    }

    // MARK: Fallback (iOS 17–18)

    /// `content` is instantiated exactly once here — never duplicated — so
    /// the documented `AsyncImage` hero-image use case fetches/decodes once,
    /// and any side-effecting modifier inside `content` fires once. The
    /// bleed effect comes entirely from `.ignoresSafeArea()` on that single
    /// instance plus an edge scrim overlay drawn from opaque shapes/materials,
    /// never from a second copy of `content`.
    ///
    /// `.ignoresSafeArea(_:edges:)` toggling between `.container` and `[]` by
    /// `isEnabled` is a value change on one continuous modifier (not a
    /// structural if/else branch), so it never affects `content`'s identity
    /// the way a branching wrapper would.
    private func fallbackRendering(_ content: Content) -> some View {
        let metrics = metrics
        return content
            .ignoresSafeArea(isEnabled ? .container : [], edges: .all)
            .overlay(alignment: .top) {
                if isEnabled {
                    edgeScrim(.top, metrics: metrics)
                        .transition(reduceMotion ? .identity : .opacity)
                }
            }
            .overlay(alignment: .bottom) {
                if isEnabled {
                    edgeScrim(.bottom, metrics: metrics)
                        .transition(reduceMotion ? .identity : .opacity)
                }
            }
            .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: isEnabled)
    }

    /// A single edge's feathered scrim: a gradient-masked blur/material (or,
    /// under Reduce Transparency, solid) band that fades from fully
    /// transparent over the visible content to the bleed layer's tuned
    /// opacity at the very edge — approximating how the extended content
    /// "dissolves" into the floating chrome that sits above it. Draws no
    /// content pixels of its own, so it never duplicates `content`.
    @ViewBuilder
    private func edgeScrim(_ edge: VerticalEdge, metrics: GlassBackgroundExtensionMetrics) -> some View {
        Group {
            if reduceTransparency {
                Rectangle().fill(opaqueScrimFill)
            } else {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .blur(radius: metrics.blurRadius)
            }
        }
        .frame(height: metrics.featherHeight)
        .opacity(metrics.bleedOpacity)
        .mask(
            LinearGradient(
                colors: [.clear, .black],
                startPoint: edge == .top ? .top : .bottom,
                endPoint: edge == .top ? .bottom : .top
            )
        )
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    /// The Reduce Transparency scrim fill: an opaque surface matching the
    /// same system background color `GlassMaterial.opaqueFallbackFill` uses
    /// for the rest of the package's Reduce Transparency degrade, kept local
    /// here since this type isn't tied to a `GlassStyle`.
    private var opaqueScrimFill: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .windowBackgroundColor)
        #else
        .white
        #endif
    }
}

// MARK: - GlassBackgroundExtensionMetrics

/// The fallback bleed layer's tuning for a given accessibility state. Kept as
/// a plain, pure struct (mirroring `GlassMaterial`) so the accessibility
/// degrade is unit-testable without rendering a view.
///
/// The fallback bleed layer is a single-instance edge scrim (see
/// `GlassBackgroundExtensionModifier.edgeScrim(_:metrics:)`) overlaid at the
/// top and bottom of the extended `content`, **not** a duplicated/blurred
/// copy of `content` itself — that duplication was an earlier design and was
/// removed because it double-fired `content`'s side effects (e.g. an
/// `AsyncImage` fetch). These metrics still tune that scrim's extent, blur,
/// and opacity, so a Reduce Transparency / Increased Contrast state reads the
/// same way it always has, even though the mechanism producing it changed.
///
/// `reduceTransparency` and `contrast` are independent settings, but for this
/// specific layer Reduce Transparency already pushes both `blurRadius` and
/// `bleedOpacity` to their most-defined values (`0` and `1.0`). Once there,
/// Increased Contrast has nothing left to add — there's no "more opaque than
/// opaque" — so it only has a visible effect when Reduce Transparency is off,
/// where it halves the blur and raises the opacity partway toward the Reduce
/// Transparency values, reading as a more defined (but still translucent)
/// edge rather than a fully solid one.
struct GlassBackgroundExtensionMetrics: Equatable {

    /// The base feather-scrim height (before ``scaleFactor`` scales it),
    /// before Reduce Transparency / Increased Contrast are taken into account.
    private static let baseFeatherHeight: CGFloat = 56

    let reduceTransparency: Bool
    let contrast: ColorSchemeContrast

    init(reduceTransparency: Bool, contrast: ColorSchemeContrast = .standard) {
        self.reduceTransparency = reduceTransparency
        self.contrast = contrast
    }

    /// Scales the edge scrim's ``featherHeight``. A blurred scrim needs more
    /// room to dissolve gradually, so the default (translucent, blurred)
    /// state uses a larger factor; Reduce Transparency's crisper, unblurred
    /// scrim needs less room, so it uses a smaller one.
    ///
    /// (Prior to the single-instance redesign, this scaled a duplicated,
    /// blurred copy of `content` up so its edges cleared the safe area with
    /// no visible seam — same relative ordering, different mechanism.)
    var scaleFactor: CGFloat { reduceTransparency ? 1.08 : 1.18 }

    /// The edge scrim's height, derived from ``scaleFactor`` so the same
    /// relative tuning (blurred states get more room, Reduce Transparency
    /// gets less) carries over from before the redesign.
    var featherHeight: CGFloat { GlassBackgroundExtensionMetrics.baseFeatherHeight * scaleFactor }

    /// The blur radius applied to the edge scrim. `0` under Reduce
    /// Transparency — a blurred scrim reads as a translucent/hazy effect,
    /// which Reduce Transparency should remove, not just dim. Increased
    /// Contrast (without Reduce Transparency) halves the blur so the bled
    /// edge reads as more defined without going fully opaque.
    var blurRadius: CGFloat {
        guard !reduceTransparency else { return 0 }
        return contrast == .increased ? 15 : 30
    }

    /// The edge scrim's opacity. Reduce Transparency renders it fully opaque
    /// so the extended region reads as a solid, non-translucent surface.
    /// Increased Contrast (without Reduce Transparency) raises it partway
    /// there.
    var bleedOpacity: Double {
        guard !reduceTransparency else { return 1.0 }
        return contrast == .increased ? 0.75 : 0.55
    }
}

// MARK: - Previews

#Preview("Background extension — hero image under a glass tab bar") {
    ZStack(alignment: .top) {
        LinearGradient(
            colors: [.indigo, .mint],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .glassBackgroundExtension()

        VStack {
            Spacer()
            GlassTabBar(
                items: [
                    GlassTabItem(icon: "house.fill", label: "Inicio"),
                    GlassTabItem(icon: "photo.on.rectangle", label: "Álbum")
                ],
                selection: .constant(0)
            )
            .padding(.horizontal, 40)
            .padding(.bottom, 12)
        }
    }
}

#if DEBUG
#Preview("Background extension — Reduce Transparency") {
    ZStack(alignment: .top) {
        LinearGradient(
            colors: [.purple, .blue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .modifier(GlassBackgroundExtensionModifier(isEnabled: true, forceReduceTransparency: true))
    }
}

// Increased Contrast alone (Reduce Transparency off): the bleed layer stays
// translucent but with half the blur and a higher opacity than the default —
// a more defined edge, short of the fully opaque Reduce Transparency surface.
#Preview("Background extension — Increased Contrast") {
    ZStack(alignment: .top) {
        LinearGradient(
            colors: [.indigo, .mint],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .modifier(GlassBackgroundExtensionModifier(isEnabled: true, forceContrast: .increased))
    }
}
#endif
