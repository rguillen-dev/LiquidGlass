//
//  GlassButton.swift
//  LiquidGlass
//
//  Created by Ricardo Guillen on 05/13/26.
//  Copyright © 2026 Ricardo Guillen. All rights reserved.
//

import SwiftUI

/// A button rendered with the Liquid Glass material.
///
/// Scales and dims slightly while pressed so the surface reads as a tactile
/// material instead of a static fill.
///
/// ```swift
/// GlassButton(tint: .indigo) {
///     // action
/// } label: {
///     Label("Continue", systemImage: "arrow.right")
/// }
/// ```
public struct GlassButton<Label: View>: View {

    private let style: GlassStyle
    private let tint: Color?
    private let action: () -> Void
    private let label: Label

    /// Creates a glass button.
    ///
    /// - Parameters:
    ///   - style: The visual variant. Defaults to ``GlassStyle/button``.
    ///   - tint: Optional color overlaid on top of the material at low opacity.
    ///   - action: The closure invoked when the button is tapped.
    ///   - label: The button's label.
    public init(
        style: GlassStyle = .button,
        tint: Color? = nil,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.style = style
        self.tint = tint
        self.action = action
        self.label = label()
    }

    public var body: some View {
        Button(action: action) {
            label
        }
        .buttonStyle(GlassButtonStyle(style: style, tint: tint))
    }
}

// MARK: - GlassButtonStyle

private struct GlassButtonStyle: ButtonStyle {

    let style: GlassStyle
    let tint: Color?

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .glass(style: style, tint: tint)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Previews

#Preview("Button — default") {
    ZStack {
        LinearGradient(
            colors: [.indigo, .mint],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        GlassButton(action: {}) {
            Text("Continue")
        }
    }
}

#Preview("Button — tinted") {
    ZStack {
        LinearGradient(
            colors: [.pink, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        HStack(spacing: 12) {
            GlassButton(tint: .blue, action: {}) {
                Label("Save", systemImage: "checkmark")
            }
            GlassButton(tint: .red, action: {}) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
