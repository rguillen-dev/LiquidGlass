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
        // `@Environment` does not update inside a `ButtonStyle`, so the styled
        // label lives in a nested `View` that can read Reduce Motion itself.
        PressableGlassLabel(
            label: configuration.label,
            isPressed: configuration.isPressed,
            style: style,
            tint: tint
        )
    }

    /// The button's label with press-state styling. Reads Reduce Motion and,
    /// when enabled, drops the scale/bounce while keeping the opacity dim as
    /// instantaneous press feedback.
    fileprivate struct PressableGlassLabel<Content: View>: View {

        let label: Content
        let isPressed: Bool
        let style: GlassStyle
        let tint: Color?

        /// Preview override. The system `accessibilityReduceMotion` key is
        /// read-only and cannot be forced through `.environment(...)`; when
        /// non-`nil` it overrides the environment value for previews.
        var forceReduceMotion: Bool? = nil

        @Environment(\.accessibilityReduceMotion) private var environmentReduceMotion

        private var reduceMotion: Bool { forceReduceMotion ?? environmentReduceMotion }

        var body: some View {
            label
                .font(.body.weight(.semibold))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .glass(style: style, tint: tint)
                .scaleEffect(scale)
                .opacity(isPressed ? 0.85 : 1.0)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: isPressed)
        }

        private var scale: CGFloat {
            guard !reduceMotion else { return 1.0 }
            return isPressed ? 0.96 : 1.0
        }
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

// The system `accessibilityReduceMotion` key is read-only and cannot be set
// through `.environment(...)`, so this preview drives the styled label through
// its internal Reduce Motion override (pressed, but held at scale 1.0 with no
// bounce). On a device or simulator with the setting enabled, the public
// `GlassButton` behaves the same way.
#Preview("Button — Reduce Motion") {
    ZStack {
        LinearGradient(
            colors: [.indigo, .mint],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 16) {
            GlassButtonStyle.PressableGlassLabel(
                label: Text("Pressed — no bounce"),
                isPressed: true,
                style: .button,
                tint: nil,
                forceReduceMotion: true
            )
            GlassButton(action: {}) {
                Text("Continue")
            }
        }
    }
}
