//
//  View+Glass.swift
//  LiquidGlass
//
//  Created by Ricardo Guillen on 05/13/26.
//  Copyright © 2026 Ricardo Guillen. All rights reserved.
//

import SwiftUI

public extension View {

    /// Applies the Liquid Glass material to this view.
    ///
    /// On iOS 26 and later this uses the system `glassEffect(_:in:)` API.
    /// On iOS 17 and 18 the package falls back to `ultraThinMaterial` with
    /// a 0.5 pt white inner stroke and a per-style depth shadow.
    ///
    /// ```swift
    /// VStack {
    ///     Text("Settings")
    ///     Toggle("Wi-Fi", isOn: $isOn)
    /// }
    /// .padding()
    /// .glass(style: .card, tint: .blue)
    /// ```
    ///
    /// - Parameters:
    ///   - style: The visual variant. Defaults to ``GlassStyle/sheet``.
    ///   - tint: Optional color overlaid on top of the material at low opacity.
    ///   - cornerRadius: Overrides ``GlassStyle/defaultCornerRadius`` when set.
    /// - Returns: A view with the Liquid Glass material applied.
    func glass(
        style: GlassStyle = .sheet,
        tint: Color? = nil,
        cornerRadius: CGFloat? = nil
    ) -> some View {
        modifier(GlassModifier(style: style, tint: tint, cornerRadius: cornerRadius))
    }
}

#if DEBUG
extension View {

    /// Forces the iOS 17–18 reduced-transparency fallback for previews and tests.
    ///
    /// The system accessibility environment keys are read-only and cannot be set
    /// through `.environment(...)`, so this internal seam drives the fallback's
    /// reduced-transparency surface directly. Not part of the public API.
    func glassReducedTransparencyFallback(
        style: GlassStyle = .sheet,
        tint: Color? = nil,
        cornerRadius: CGFloat? = nil
    ) -> some View {
        modifier(
            GlassRenderingModifier(
                style: style,
                tint: tint,
                cornerRadius: cornerRadius ?? style.defaultCornerRadius,
                forceReduceTransparency: true
            )
        )
    }

    /// Forces the iOS 17–18 Increased Contrast fallback for previews and tests.
    ///
    /// The system accessibility environment keys are read-only and cannot be set
    /// through `.environment(...)`, so this internal seam drives the fallback's
    /// increased-contrast rim (wider stroke, raised opacity) directly. Not part
    /// of the public API.
    ///
    /// - Parameter reduceTransparency: Also forces the Reduce Transparency
    ///   fallback, so the combined state (both settings enabled at once) can
    ///   be previewed and tested. Defaults to `false`.
    func glassIncreasedContrastFallback(
        style: GlassStyle = .sheet,
        tint: Color? = nil,
        cornerRadius: CGFloat? = nil,
        reduceTransparency: Bool = false
    ) -> some View {
        modifier(
            GlassRenderingModifier(
                style: style,
                tint: tint,
                cornerRadius: cornerRadius ?? style.defaultCornerRadius,
                forceReduceTransparency: reduceTransparency,
                forceContrast: .increased
            )
        )
    }
}
#endif

struct GlassModifier: ViewModifier {

    let style: GlassStyle
    let tint: Color?
    let cornerRadius: CGFloat?

    /// Falls back to the ambient tint set via ``SwiftUI/View/glassThemeTint(_:)``
    /// when the caller does not pass an explicit `tint`.
    @Environment(\.glassTint) private var environmentTint

    func body(content: Content) -> some View {
        content.modifier(
            GlassRenderingModifier(
                style: style,
                tint: tint ?? environmentTint,
                cornerRadius: cornerRadius ?? style.defaultCornerRadius
            )
        )
    }
}
