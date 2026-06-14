//
//  GlassColorContrast.swift
//  LiquidGlass
//
//  Created by Ricardo Guillen on 06/13/26.
//  Copyright © 2026 Ricardo Guillen. All rights reserved.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Color resolution helpers

extension Color {

    /// The color's sRGB components in `0...1`, or `nil` when it can't be
    /// flattened to concrete components (e.g. an unresolved dynamic/catalog
    /// color on a platform that won't resolve it outside a render context).
    var glassRGBA: (red: Double, green: Double, blue: Double, alpha: Double)? {
        #if canImport(UIKit)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return (Double(r), Double(g), Double(b), Double(a))
        #elseif canImport(AppKit)
        guard let resolved = NSColor(self).usingColorSpace(.sRGB) else { return nil }
        return (Double(resolved.redComponent),
                Double(resolved.greenComponent),
                Double(resolved.blueComponent),
                Double(resolved.alphaComponent))
        #else
        return nil
        #endif
    }

    /// The color's WCAG relative luminance (`0` = black, `1` = white), or `nil`
    /// when its components can't be resolved (see ``glassRGBA``).
    var glassRelativeLuminance: Double? {
        guard let (r, g, b, _) = glassRGBA else { return nil }
        func linearize(_ channel: Double) -> Double {
            channel <= 0.03928 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b)
    }

}

// MARK: - GlassContrast

/// Derives contrast-safe colors for glass surfaces.
///
/// A tinted glass surface and an active foreground drawn in the *same* tint
/// collide — the foreground vanishes into the surface. ``activeForeground(for:surfaceTintOpacity:minLightContrast:)``
/// returns a neutral foreground that both reads against the tinted surface and
/// stands apart from the dimmed (dark) inactive items, so the active item stays
/// legible without the caller having to pick a color by hand.
enum GlassContrast {

    /// The WCAG contrast ratio between two relative luminances (`1...21`).
    static func contrastRatio(_ lhs: Double, _ rhs: Double) -> Double {
        let lighter = max(lhs, rhs)
        let darker = min(lhs, rhs)
        return (lighter + 0.05) / (darker + 0.05)
    }

    /// The relative luminance of the glass surface for a given tint, modeled as
    /// the tint composited over a light backdrop at `surfaceTintOpacity`.
    ///
    /// The compositing strength is path-dependent: the native iOS 26 glass tint
    /// reads as a *saturated* surface (high effective opacity), while the iOS
    /// 17–18 fallback lays the tint at the literal `.toolbar` tint opacity over
    /// a translucent material (a *pale* surface). The caller passes the opacity
    /// that matches the path it renders on.
    static func surfaceLuminance(forTint tint: Color, surfaceTintOpacity: Double) -> Double? {
        guard let tintLuminance = tint.glassRelativeLuminance else { return nil }
        return tintLuminance * surfaceTintOpacity + 1.0 * (1 - surfaceTintOpacity)
    }

    /// A legible foreground color for the active item of a glass surface tinted
    /// with `tint`.
    ///
    /// The inactive items are drawn in `.secondary` (a dark, dimmed color), so a
    /// *light* active item both reads against the tinted surface and flips
    /// against the inactive items — the conventional "highlighted = selected"
    /// affordance. White is used whenever it clears `minLightContrast` (the bar
    /// is an icon plus a short label, so large-text AA, `3.0`, is the relevant
    /// bar); on light surfaces where white can't carry, a near-black is used
    /// instead, which contrasts strongly with the now-light surface.
    ///
    /// - Parameters:
    ///   - tint: The surface tint the foreground must contrast against.
    ///   - surfaceTintOpacity: The opacity the tint is composited at — pass the
    ///     value that matches the render path (see ``surfaceLuminance(forTint:surfaceTintOpacity:)``).
    ///   - minLightContrast: The minimum contrast white must clear to be chosen.
    ///     Defaults to `3.0` (WCAG AA for large text / non-text).
    /// - Returns: `.white` for mid/dark surfaces, a near-black for light ones,
    ///   or the tint itself when its components can't be resolved.
    static func activeForeground(
        for tint: Color,
        surfaceTintOpacity: Double,
        minLightContrast: Double = 3.0
    ) -> Color {
        guard let surface = surfaceLuminance(forTint: tint, surfaceTintOpacity: surfaceTintOpacity) else {
            return tint
        }
        return contrastRatio(surface, 1.0) >= minLightContrast ? .white : Color(white: 0.12)
    }
}
