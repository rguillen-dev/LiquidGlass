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

struct GlassModifier: ViewModifier {

    let style: GlassStyle
    let tint: Color?
    let cornerRadius: CGFloat?

    func body(content: Content) -> some View {
        content.modifier(
            GlassRenderingModifier(
                style: style,
                tint: tint,
                cornerRadius: cornerRadius ?? style.defaultCornerRadius
            )
        )
    }
}
