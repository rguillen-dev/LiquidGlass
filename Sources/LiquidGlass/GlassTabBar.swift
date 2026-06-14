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
/// The `tint` colors the glass *surface*. The active item's foreground is a
/// separate concern: drawing it in the same tint would make it collide with the
/// tinted surface and vanish. By default the bar derives a contrast-safe
/// foreground from the resolved tint (see ``GlassContrast/activeForeground(for:surfaceTintOpacity:minLightContrast:)``);
/// pass `activeForeground` to override it explicitly.
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
/// .glassThemeTint(skin.tint) // tints the surface; active item stays legible
/// ```
public struct GlassTabBar: View {

    private let items: [GlassTabItem]
    @Binding private var selection: Int
    private let tint: Color?
    private let activeForeground: Color?

    @Environment(\.glassTint) private var environmentTint

    /// Creates a glass tab bar.
    ///
    /// - Parameters:
    ///   - items: The tab items, left to right.
    ///   - selection: A binding to the zero-based index of the selected item.
    ///   - tint: Optional tint for the glass surface. Falls back to the ambient
    ///     ``EnvironmentValues/glassTint``.
    ///   - activeForeground: Optional color for the active item's icon and
    ///     label. When `nil` (the default) the bar derives a contrast-safe color
    ///     from the resolved tint so the active item never collides with the
    ///     tinted surface.
    public init(
        items: [GlassTabItem],
        selection: Binding<Int>,
        tint: Color? = nil,
        activeForeground: Color? = nil
    ) {
        self.items = items
        self._selection = selection
        self.tint = tint
        self.activeForeground = activeForeground
    }

    private var resolvedTint: Color? { tint ?? environmentTint }

    /// The active item's foreground: the explicit `activeForeground` if set,
    /// otherwise a contrast-safe color derived from the surface tint, falling
    /// back to the accent color when there is no tint to derive from.
    private var resolvedActiveForeground: Color {
        if let activeForeground { return activeForeground }
        guard let resolvedTint else { return .accentColor }
        return GlassContrast.activeForeground(for: resolvedTint, surfaceTintOpacity: surfaceTintOpacity)
    }

    /// The effective opacity the surface tint composites at, which differs by
    /// render path: the native iOS 26 glass tint reads as saturated, while the
    /// iOS 17–18 fallback lays the tint at the literal `.toolbar` tint opacity
    /// over a translucent material. The derived active foreground must contrast
    /// against the surface it will actually appear on.
    private var surfaceTintOpacity: Double {
        if #available(iOS 26.0, macOS 26.0, *) { return 0.85 } else { return 0.22 }
    }

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
                            selection == index ? resolvedActiveForeground : Color.secondary
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

// The active item used to be drawn in the same tint as the surface, so an
// ambient `.glassThemeTint` made it collide and vanish. The bar now derives a
// contrast-safe foreground from the tint — the selected item stays legible.
#Preview("Tab bar — themed tint, legible active item") {
    ZStack(alignment: .bottom) {
        Color(white: 0.96).ignoresSafeArea()
        GlassTabBar(
            items: [
                GlassTabItem(icon: "house.fill", label: "Inicio"),
                GlassTabItem(icon: "clock.arrow.circlepath", label: "Historial"),
                GlassTabItem(icon: "person.fill", label: "Perfil")
            ],
            selection: .constant(0)
        )
        .glassThemeTint(Color(red: 0.12, green: 0.50, blue: 0.50)) // brand teal
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
}

// An explicit `activeForeground` overrides the derived color entirely.
#Preview("Tab bar — explicit active foreground") {
    ZStack(alignment: .bottom) {
        Color(white: 0.96).ignoresSafeArea()
        GlassTabBar(
            items: [
                GlassTabItem(icon: "house.fill", label: "Inicio"),
                GlassTabItem(icon: "photo.on.rectangle", label: "Álbum"),
                GlassTabItem(icon: "person.fill", label: "Perfil")
            ],
            selection: .constant(2),
            activeForeground: .white
        )
        .glassThemeTint(Color(red: 0.12, green: 0.50, blue: 0.50))
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
}
