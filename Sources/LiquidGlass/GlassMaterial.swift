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

    /// Contrast boost applied to the fallback rim when Reduce Transparency is
    /// enabled. Kept as a named constant so visual tuning is centralized.
    private static let reduceTransparencyBorderBoost: Double = 0.35

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

    /// Resolves the inner-stroke opacity for the current accessibility state.
    ///
    /// Returns ``fallbackBorderOpacity`` normally. When `reduceTransparency` is
    /// `true` the value is raised (and clamped to `1.0`) so the rim still reads
    /// against the now-opaque fill.
    ///
    /// - Parameters:
    ///   - reduceTransparency: Whether Reduce Transparency is enabled.
    ///   - boost: The contrast increment to apply when Reduce Transparency is
    ///     enabled. Must be non-negative. Defaults to ``reduceTransparencyBorderBoost``.
    /// - Returns: A stroke opacity clamped to `0…1`.
    func borderOpacity(
        reduceTransparency: Bool,
        boost: Double = GlassMaterial.reduceTransparencyBorderBoost
    ) -> Double {
        reduceTransparency
            ? max(0.0, min(fallbackBorderOpacity + boost, 1.0))
            : fallbackBorderOpacity
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

    /// Preview/test override. The system accessibility environment keys are
    /// read-only, so they cannot be forced through `.environment(...)`; this
    /// seam lets previews and tests exercise the reduced-transparency fallback.
    /// `nil` (the only value the public `.glass(...)` path ever sets) means
    /// "use the real environment value".
    var forceReduceTransparency: Bool? = nil

    private var reduceTransparency: Bool {
        forceReduceTransparency ?? environmentReduceTransparency
    }

    /// The fallback rim stroke should stay bright on dark backgrounds and dark
    /// on light backgrounds once Reduce Transparency switches to opaque fills.
    private var fallbackBorderColor: Color {
        guard reduceTransparency else { return .white }
        return colorScheme == .dark ? .white : .black
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
        // and raises the rim contrast. `AnyShapeStyle` keeps both branches the
        // same `fill` type.
        let fill: AnyShapeStyle = reduceTransparency
            ? AnyShapeStyle(material.opaqueFallbackFill)
            : AnyShapeStyle(material.fallbackMaterial)
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
                            fallbackBorderColor.opacity(material.borderOpacity(reduceTransparency: reduceTransparency)),
                            lineWidth: 0.5
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
