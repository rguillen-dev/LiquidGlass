//
//  GlassTabBar.swift
//  LiquidGlass
//
//  Created by Ricardo Guillen on 06/01/26.
//  Copyright © 2026 Ricardo Guillen. All rights reserved.
//

import SwiftUI

/// A single item in a ``GlassTabBar``.
public struct GlassTabItem: Hashable, Sendable {

    /// The SF Symbol name shown above the label.
    public let icon: String

    /// The text shown beneath the icon.
    public let label: String

    /// Creates a tab item.
    ///
    /// - Parameters:
    ///   - icon: An SF Symbol name (e.g. `"house.fill"`).
    ///   - label: The visible label.
    public init(icon: String, label: String) {
        self.icon = icon
        self.label = label
    }
}

/// A floating bottom navigation bar rendered with the Liquid Glass material.
///
/// Each item is selectable; `selection` is the zero-based index of the active
/// item. The bar reads its tint from the explicit `tint` argument, falling back
/// to the ambient ``EnvironmentValues/glassTint``.
///
/// On iOS 26 the bar's surfaces are wrapped in a ``GlassEffectContainer`` so the
/// glass merges fluidly; on iOS 17–25 it renders as a glass toolbar via the
/// `.glass(style:.toolbar)` fallback.
///
/// ```swift
/// GlassTabBar(
///     items: [GlassTabItem(icon: "house.fill", label: "Inicio")],
///     selection: $tab
/// )
/// .glassThemeTint(skin.tint)
/// ```
public struct GlassTabBar: View {

    private let items: [GlassTabItem]
    @Binding private var selection: Int
    private let tint: Color?

    @Environment(\.glassTint) private var environmentTint

    /// Creates a glass tab bar.
    ///
    /// - Parameters:
    ///   - items: The tab items, left to right.
    ///   - selection: A binding to the zero-based index of the selected item.
    ///   - tint: Optional tint for the active item and the glass surface.
    ///     Falls back to the ambient ``EnvironmentValues/glassTint``.
    public init(
        items: [GlassTabItem],
        selection: Binding<Int>,
        tint: Color? = nil
    ) {
        self.items = items
        self._selection = selection
        self.tint = tint
    }

    private var resolvedTint: Color? { tint ?? environmentTint }

    public var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    Button {
                        selection = index
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: item.icon)
                                .font(.system(size: 20, weight: .semibold))
                            Text(item.label)
                                .font(.caption2.weight(.medium))
                        }
                        .foregroundStyle(
                            selection == index ? (resolvedTint ?? Color.accentColor) : Color.secondary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(item.label)
                    .accessibilityAddTraits(selection == index ? [.isSelected, .isButton] : .isButton)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .glass(style: .toolbar, tint: resolvedTint, cornerRadius: 28)
        }
    }
}

// MARK: - Previews

#Preview("Tab bar — single") {
    ZStack(alignment: .bottom) {
        LinearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        GlassTabBar(
            items: [GlassTabItem(icon: "house.fill", label: "Inicio")],
            selection: .constant(0)
        )
        .padding(.horizontal, 80)
        .padding(.bottom, 12)
    }
}

#Preview("Tab bar — multiple, tinted") {
    ZStack(alignment: .bottom) {
        LinearGradient(colors: [.orange, .pink], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        GlassTabBar(
            items: [
                GlassTabItem(icon: "house.fill", label: "Inicio"),
                GlassTabItem(icon: "photo.on.rectangle", label: "Álbum"),
                GlassTabItem(icon: "person.fill", label: "Perfil")
            ],
            selection: .constant(1),
            tint: .orange
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }
}
