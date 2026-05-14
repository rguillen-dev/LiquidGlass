//
//  ContentView.swift
//  LiquidGlass
//
//  Created by Ricardo Guillen on 05/13/26.
//  Copyright © 2026 Ricardo Guillen. All rights reserved.
//

import SwiftUI
import LiquidGlass

struct ContentView: View {
    var body: some View {
        TabView {
            StylesShowcase()
                .tabItem {
                    Label("Styles", systemImage: "sparkles")
                }

            ComponentsShowcase()
                .tabItem {
                    Label("Components", systemImage: "square.on.square")
                }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
    }
}

// MARK: - StylesShowcase

struct StylesShowcase: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ForEach(GlassStyle.allCases, id: \.self) { style in
                    StyleSample(style: style)
                }
            }
            .padding(20)
        }
        .background(Color.black.opacity(0.04).ignoresSafeArea())
    }
}

private struct StyleSample: View {
    let style: GlassStyle

    var body: some View {
        ZStack {
            GradientBackground(seed: String(describing: style))
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            VStack(spacing: 4) {
                Text(label)
                    .font(.title3.bold())
                Text(".\(String(describing: style))")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .glass(style: style)
        }
    }

    private var label: String {
        switch style {
        case .sheet:    return "Sheet"
        case .card:     return "Card"
        case .button:   return "Button"
        case .toolbar:  return "Toolbar"
        case .sidebar:  return "Sidebar"
        case .overlay:  return "Overlay"
        }
    }
}

// MARK: - ComponentsShowcase

struct ComponentsShowcase: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ZStack {
                    GradientBackground(seed: "card-default")
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

                    GlassCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Glass Card")
                                .font(.title2.bold())
                            Text("Default style, no tint.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 24)
                }

                ZStack {
                    GradientBackground(seed: "card-tinted")
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

                    GlassCard(style: .sheet, tint: .pink) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Sheet style")
                                .font(.title2.bold())
                            Text("With a pink tint overlay.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 24)
                }

                ZStack {
                    GradientBackground(seed: "buttons-row")
                        .frame(height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

                    HStack(spacing: 12) {
                        GlassButton(action: {}) {
                            Text("Default")
                        }
                        GlassButton(tint: .blue, action: {}) {
                            Label("Blue", systemImage: "drop.fill")
                        }
                        GlassButton(tint: .orange, action: {}) {
                            Label("Orange", systemImage: "flame.fill")
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Color.black.opacity(0.04).ignoresSafeArea())
    }
}

// MARK: - GradientBackground

struct GradientBackground: View {
    let seed: String

    var body: some View {
        gradient
    }

    private var gradient: LinearGradient {
        let palettes: [[Color]] = [
            [.purple, .blue],
            [.orange, .pink],
            [.green, .cyan],
            [.yellow, .red],
            [.indigo, .mint],
            [.pink, .purple],
            [.teal, .blue]
        ]
        let hash = seed.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        let palette = palettes[hash % palettes.count]
        return LinearGradient(
            colors: palette,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Previews

#Preview("Content") {
    ContentView()
}

#Preview("Styles tab") {
    StylesShowcase()
}

#Preview("Components tab") {
    ComponentsShowcase()
}
