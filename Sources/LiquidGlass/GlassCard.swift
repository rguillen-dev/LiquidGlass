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
