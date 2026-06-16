//
//  GlassCard.swift
//  LiquidGlass
//
//  Created by Ricardo Guillen on 05/13/26.
//  Copyright © 2026 Ricardo Guillen. All rights reserved.
//

import SwiftUI

/// A padded container with the Liquid Glass material applied.
///
/// A thin convenience over ``SwiftUI/View/glass(style:tint:cornerRadius:)``.
/// Use it for card-shaped surfaces; use the raw `.glass()` modifier when you
/// need the material on an arbitrarily shaped view.
///
/// ```swift
/// GlassCard(tint: .indigo) {
///     VStack(alignment: .leading) {
///         Text("Now Playing").font(.headline)
///         Text("Synthwave Drive").font(.subheadline)
///     }
/// }
/// ```
public struct GlassCard<Content: View>: View {

    private let style: GlassStyle
    private let tint: Color?
    private let content: Content

    /// Creates a glass card.
    ///
    /// - Parameters:
    ///   - style: The visual variant. Defaults to ``GlassStyle/card``.
    ///   - tint: Optional color overlaid on top of the material at low opacity.
    ///   - content: The card's contents.
    public init(
        style: GlassStyle = .card,
        tint: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.tint = tint
        self.content = content()
    }

    public var body: some View {
        content
            .padding(16)
            .glass(style: style, tint: tint)
    }
}

// MARK: - Previews

#Preview("Card — default") {
    ZStack {
        LinearGradient(
            colors: [.purple, .blue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Glass Card")
                    .font(.title2.bold())
                Text("Default style, no tint.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

#Preview("Card — tinted") {
    ZStack {
        LinearGradient(
            colors: [.orange, .pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        GlassCard(style: .sheet, tint: .pink) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Sheet style")
                    .font(.title2.bold())
                Text("With a pink tint overlay.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

// The system `accessibilityReduceTransparency` key is read-only and cannot be
// set through `.environment(...)`, so this preview drives the fallback's
// reduced-transparency surface through the internal seam instead. On a device
// or simulator with the setting enabled, the public `.glass(style:)` path
// produces the same opaque surface.
//
// Guarded by `#if DEBUG`: the preview calls `glassReducedTransparencyFallback`,
// which is itself a DEBUG-only internal seam (see View+Glass.swift). `#Preview`
// bodies compile in all configurations, so without this guard a non-DEBUG build
// (Staging / Release) fails to resolve the seam.
#if DEBUG
#Preview("Card — Reduce Transparency") {
    ZStack {
        LinearGradient(
            colors: [.purple, .blue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(alignment: .leading, spacing: 8) {
            Text("Reduce Transparency")
                .font(.title2.bold())
            Text("Opaque surface with a higher-contrast rim.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .glassReducedTransparencyFallback(style: .card)
        .padding()
    }
}
#endif
