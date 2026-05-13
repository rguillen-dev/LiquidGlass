//
//  GlassMaterial.swift
//  LiquidGlass
//
//  Created by Ricardo Guillen on 05/13/26.
//  Copyright © 2026 Ricardo Guillen. All rights reserved.
//

import SwiftUI

// MARK: - GlassMaterial

/// Resolves the fallback rendering parameters for a given ``GlassStyle``.
///
/// Only used on iOS 17 and 18 — on iOS 26+ the package goes through
/// `glassEffect` directly and skips these values entirely.
struct GlassMaterial {

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

    @ViewBuilder
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        // `glassEffect` ships in the iOS 26 SDK (Swift 6.2+). Older
        // toolchains compile only the fallback path so the package can be
        // adopted from Xcode 16 too.
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
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
    @available(iOS 26.0, *)
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
        return content
            .background {
                shape
                    .fill(material.fallbackMaterial)
                    .overlay {
                        if let tint {
                            shape.fill(tint.opacity(material.tintOpacity))
                        }
                    }
                    .overlay {
                        shape.strokeBorder(
                            Color.white.opacity(material.fallbackBorderOpacity),
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
