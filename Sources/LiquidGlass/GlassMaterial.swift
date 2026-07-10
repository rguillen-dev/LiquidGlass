//
//  GlassMaterial.swift
//  LiquidGlass
//
//  Created by Ricardo Guillen on 05/13/26.
//  Copyright © 2026 Ricardo Guillen. All rights reserved.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - GlassMaterial

/// Resolves the fallback rendering parameters for a given ``GlassStyle``.
///
/// Only used on iOS 17 and 18 — on iOS 26+ the package goes through
/// `glassEffect` directly and skips these values entirely.
struct GlassMaterial {

    /// Kill switch for native `SwiftUI.GlassEffectContainer` /
    /// `glassEffectID(_:in:)` / `glassEffectUnion(id:namespace:)` forwarding
    /// on iOS 26+, shared by every call site that would otherwise forward to
    /// those system APIs: `GlassEffectContainer.body`,
    /// `View.glassMorphID(_:in:)`, and `GlassMorphUnionModifier.body`.
    ///
    /// Disabled 2026-07-01 after a device-only iOS 26.5 rendering-corruption
    /// bug root-caused from Agenda (agenda-ios): `GlassEffectContainer` was
    /// present on two unrelated screens (a feed list behind a floating
    /// `GlassTabBar`, and a card-detail hero) that both showed sibling
    /// content (feed row colors / detail info-panel text) tiling into a
    /// mosaic and clipping at the screen edges, reproducing even before any
    /// navigation/transition fired. This matched the container's own prior
    /// incident, so rather than patch each call site individually, every
    /// native forward that shares the same underlying Liquid Glass
    /// containment/morphing pipeline is gated on this one flag.
    ///
    /// The native branches at all three call sites remain live, compiled,
    /// and type-checked against the real SDK — only entry into them is
    /// gated — so re-enabling once Apple ships a fix is "flip this to
    /// `true`" plus an on-device verification pass, not a git-archaeology
    /// exercise, and a partial re-enable (fixing one call site but not
    /// another) can't happen by accident.
    ///
    /// Keep `false` until Apple's fix has been verified stable on-device.
    static let nativeGlassMorphingEnabled = false

    /// Contrast boost applied to the fallback rim when Reduce Transparency is
    /// enabled. Kept as a named constant so visual tuning is centralized.
    private static let reduceTransparencyBorderBoost: Double = 0.35

    /// Contrast boost applied to the fallback rim when Increased Contrast is
    /// enabled. Smaller than ``reduceTransparencyBorderBoost`` — Reduce
    /// Transparency already swaps in an opaque fill (a much bigger perceptual
    /// change), while Increased Contrast alone is a narrower nudge to keep the
    /// rim crisp against an otherwise-unchanged translucent surface.
    private static let increasedContrastBorderBoost: Double = 0.15

    /// The fallback rim's stroke width outside Increased Contrast.
    private static let baseBorderLineWidth: CGFloat = 0.5

    /// The fallback rim's stroke width under Increased Contrast — doubled so
    /// the rim reads as a visibly more defined edge.
    private static let increasedContrastBorderLineWidth: CGFloat = 1.0

    let style: GlassStyle

    var fallbackMaterial: Material {
        switch style {
        case .sheet:    return .ultraThinMaterial
        case .card:     return .thinMaterial
        case .button:   return .regularMaterial
        case .toolbar:  return .bar
        case .sidebar:  return .thickMaterial
        case .overlay:  return .ultraThickMaterial
        }
    }

    /// White stroke on the inner edge, simulating the bright refraction line
    /// you get along the rim of real frosted glass.
    var fallbackBorderOpacity: Double {
        switch style {
        case .sheet, .card, .sidebar:   return 0.20
        case .button, .toolbar:         return 0.15
        case .overlay:                  return 0.10
        }
    }

    /// Opaque surface that replaces ``fallbackMaterial`` when the user has
    /// Reduce Transparency enabled. The translucent material would otherwise
    /// fail to honor the accessibility setting on the iOS 17 / 18 fallback path.
    var opaqueFallbackFill: Color {
        #if canImport(UIKit)
        return Color(uiColor: .systemBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .windowBackgroundColor)
        #else
        return .white
        #endif
    }

    /// Resolves the fallback background fill for the current Reduce
    /// Transparency state.
    ///
    /// Shared by every fallback glass surface in the package
    /// (`GlassRenderingModifier`, `GlassMorphUnionSurfaces`) so the
    /// fill-selection logic — translucent ``fallbackMaterial`` normally,
    /// opaque ``opaqueFallbackFill`` under Reduce Transparency — lives in one
    /// place instead of being copy-pasted at each call site.
    ///
    /// - Parameter reduceTransparency: Whether Reduce Transparency is enabled.
    /// - Returns: An erased shape style wrapping whichever fill applies.
    func fallbackFill(reduceTransparency: Bool) -> AnyShapeStyle {
        reduceTransparency ? AnyShapeStyle(opaqueFallbackFill) : AnyShapeStyle(fallbackMaterial)
    }

    /// Resolves the fallback rim's stroke color for the current accessibility
    /// and color-scheme state.
    ///
    /// Shared by every fallback glass surface in the package
    /// (`GlassRenderingModifier`, `GlassMorphUnionSurfaces`) so the
    /// color-selection logic lives in one place. Bright white normally, so
    /// the rim reads against a translucent material on any background; once
    /// Reduce Transparency swaps in an opaque fill, the rim instead needs to
    /// contrast against that fill's actual light/dark value — white on a dark
    /// opaque fill, black on a light one.
    ///
    /// - Parameters:
    ///   - reduceTransparency: Whether Reduce Transparency is enabled.
    ///   - colorScheme: The current `ColorScheme`, consulted only when
    ///     `reduceTransparency` is `true`.
    /// - Returns: `.white` normally; `.white` or `.black` under Reduce
    ///   Transparency depending on `colorScheme`.
    static func borderColor(reduceTransparency: Bool, colorScheme: ColorScheme) -> Color {
        guard reduceTransparency else { return .white }
        return colorScheme == .dark ? .white : .black
    }

    /// Resolves the inner-stroke opacity for the current accessibility state.
    ///
    /// Returns ``fallbackBorderOpacity`` normally. `reduceTransparency` and
    /// `contrast` are independent settings a user can combine in any way, so
    /// each contributes its own boost and both apply together when both are
    /// enabled — the result is still clamped to `1.0`, so combining them never
    /// overshoots into an absurd value, it just reaches the ceiling sooner.
    ///
    /// - Parameters:
    ///   - reduceTransparency: Whether Reduce Transparency is enabled.
    ///   - contrast: The current ``ColorSchemeContrast``. Defaults to
    ///     `.standard` (no boost).
    ///   - boost: The increment applied when Reduce Transparency is enabled.
    ///     Must be non-negative. Defaults to ``reduceTransparencyBorderBoost``.
    ///     The Increased Contrast increment is not parameterized — it always
    ///     uses ``increasedContrastBorderBoost`` — since nothing in the
    ///     package has ever needed to override it independently of the named
    ///     constant.
    /// - Returns: A stroke opacity clamped to `0…1`.
    func borderOpacity(
        reduceTransparency: Bool,
        contrast: ColorSchemeContrast = .standard,
        boost: Double = GlassMaterial.reduceTransparencyBorderBoost
    ) -> Double {
        var opacity = fallbackBorderOpacity
        if reduceTransparency { opacity += boost }
        if contrast == .increased { opacity += GlassMaterial.increasedContrastBorderBoost }
        return max(0.0, min(opacity, 1.0))
    }

    /// Resolves the inner-stroke line width for the current Increased
    /// Contrast state. Reduce Transparency does not affect width — it's
    /// handled entirely through ``borderOpacity(reduceTransparency:contrast:boost:)``
    /// raising the rim's opacity against the now-opaque fill. Increased
    /// Contrast instead widens the stroke itself, since a crisper, more
    /// defined edge is the point of that setting even when the fill stays
    /// translucent.
    ///
    /// - Parameter contrast: The current ``ColorSchemeContrast``.
    /// - Returns: ``increasedContrastBorderLineWidth`` when `contrast` is
    ///   `.increased`, otherwise ``baseBorderLineWidth``.
    func borderLineWidth(contrast: ColorSchemeContrast) -> CGFloat {
        contrast == .increased
            ? GlassMaterial.increasedContrastBorderLineWidth
            : GlassMaterial.baseBorderLineWidth
    }

    var fallbackShadowRadius: CGFloat {
        switch style {
        case .sheet:    return 20
        case .card:     return 10
        case .button:   return 4
        case .toolbar:  return 2
        case .sidebar:  return 12
        case .overlay:  return 0
        }
    }

    var fallbackShadowOpacity: Double {
        switch style {
        case .sheet:    return 0.18
        case .card:     return 0.12
        case .button:   return 0.08
        case .toolbar:  return 0.05
        case .sidebar:  return 0.15
        case .overlay:  return 0.0
        }
    }

    var fallbackShadowY: CGFloat {
        switch style {
        case .sheet:    return 8
        case .card:     return 4
        case .button:   return 2
        case .toolbar:  return 1
        case .sidebar:  return 6
        case .overlay:  return 0
        }
    }

    var tintOpacity: Double {
        switch style {
        case .button, .toolbar:         return 0.22
        case .sheet, .card, .sidebar:   return 0.18
        case .overlay:                  return 0.12
        }
    }
}

// MARK: - GlassRenderingModifier

/// Dispatches to the native Liquid Glass renderer on iOS 26+ and to a
/// `Material`-based approximation on iOS 17 / 18. All availability checks
/// for the package live in this type.
///
/// The fallback path reads Reduce Transparency (swaps the translucent
/// material for an opaque fill) and Increased Contrast (widens and brightens
/// the inner rim) directly, since the native iOS 26 renderer honors both for
/// free. The two settings are independent — a user can enable either, both,
/// or neither — so ``fallbackRendering(_:shape:)`` combines them through
/// ``GlassMaterial/borderOpacity(reduceTransparency:contrast:boost:)``
/// and ``GlassMaterial/borderLineWidth(contrast:)`` rather than branching on
/// one setting at a time. Fill selection and rim color come from
/// ``GlassMaterial/fallbackFill(reduceTransparency:)`` and
/// ``GlassMaterial/borderColor(reduceTransparency:colorScheme:)``, shared with
/// ``GlassMorphUnionSurfaces``'s fallback surface so both stay in sync.
struct GlassRenderingModifier: ViewModifier {

    let style: GlassStyle
    let tint: Color?
    let cornerRadius: CGFloat

    /// Read on the fallback path only. The native iOS 26 renderer honors
    /// Reduce Transparency itself, so the native branch never consults this.
    @Environment(\.accessibilityReduceTransparency) private var environmentReduceTransparency

    /// Used by the fallback path to keep rim contrast readable when Reduce
    /// Transparency replaces translucent materials with an opaque fill.
    @Environment(\.colorScheme) private var colorScheme

    /// Read on the fallback path only. The native iOS 26 renderer honors
    /// Increased Contrast itself, so the native branch never consults this.
    @Environment(\.colorSchemeContrast) private var environmentContrast

    /// Preview/test override. The system accessibility environment keys are
    /// read-only, so they cannot be forced through `.environment(...)`; this
    /// seam lets previews and tests exercise the reduced-transparency fallback.
    /// `nil` (the only value the public `.glass(...)` path ever sets) means
    /// "use the real environment value".
    var forceReduceTransparency: Bool? = nil

    /// Preview/test override for Increased Contrast, matching
    /// `forceReduceTransparency`'s seam pattern — `colorSchemeContrast` is
    /// also a read-only system environment key. `nil` means "use the real
    /// environment value".
    var forceContrast: ColorSchemeContrast? = nil

    private var reduceTransparency: Bool {
        forceReduceTransparency ?? environmentReduceTransparency
    }

    private var contrast: ColorSchemeContrast {
        forceContrast ?? environmentContrast
    }

    /// The fallback rim stroke should stay bright on dark backgrounds and dark
    /// on light backgrounds once Reduce Transparency switches to opaque fills.
    /// Delegates to ``GlassMaterial/borderColor(reduceTransparency:colorScheme:)``,
    /// shared with ``GlassMorphUnionSurfaces``.
    private var fallbackBorderColor: Color {
        GlassMaterial.borderColor(reduceTransparency: reduceTransparency, colorScheme: colorScheme)
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        // `glassEffect` ships in the iOS 26 SDK (Swift 6.2+). Older
        // toolchains compile only the fallback path so the package can be
        // adopted from Xcode 16 too.
        #if compiler(>=6.2)
        if #available(iOS 26.0, macOS 26.0, *) {
            nativeRendering(content, shape: shape)
        } else {
            fallbackRendering(content, shape: shape)
        }
        #else
        fallbackRendering(content, shape: shape)
        #endif
    }

    // MARK: Native (iOS 26+)

    #if compiler(>=6.2)
    @available(iOS 26.0, macOS 26.0, *)
    @ViewBuilder
    private func nativeRendering(_ content: Content, shape: RoundedRectangle) -> some View {
        if let tint {
            content.glassEffect(.regular.tint(tint), in: shape)
        } else {
            content.glassEffect(.regular, in: shape)
        }
    }
    #endif

    // MARK: Fallback (iOS 17–18)

    private func fallbackRendering(_ content: Content, shape: RoundedRectangle) -> some View {
        let material = GlassMaterial(style: style)
        // Reduce Transparency swaps the translucent material for an opaque fill
        // and raises the rim contrast. `GlassMaterial.fallbackFill` keeps this
        // in sync with `GlassMorphUnionSurfaces`'s identical fallback surface.
        let fill = material.fallbackFill(reduceTransparency: reduceTransparency)
        return content
            .background {
                shape
                    .fill(fill)
                    .overlay {
                        if let tint {
                            shape.fill(tint.opacity(material.tintOpacity))
                        }
                    }
                    .overlay {
                        shape.strokeBorder(
                            fallbackBorderColor.opacity(
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
}
