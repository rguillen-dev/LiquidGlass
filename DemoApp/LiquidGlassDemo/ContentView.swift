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

            NavigationShowcase()
                .tabItem {
                    Label("Navigation", systemImage: "rectangle.bottomthird.inset.filled")
                }

            MorphingShowcase()
                .tabItem {
                    Label("Morphing", systemImage: "wand.and.stars")
                }

            NowPlayingShowcase()
                .tabItem {
                    Label("Now Playing", systemImage: "play.circle.fill")
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

// MARK: - NavigationShowcase

/// Demonstrates `GlassTabBar` with a real, interactive selection binding and
/// an ambient tint (`.glassThemeTint`) inherited by both the tab bar and a
/// `GlassCard` that sets no explicit `tint` of its own — the environment
/// injection story shipped in 1.1.0.
struct NavigationShowcase: View {
    @State private var selection = 0

    private let items = [
        GlassTabItem(icon: "house.fill", label: "Inicio"),
        GlassTabItem(icon: "photo.on.rectangle", label: "Álbum"),
        GlassTabItem(icon: "person.fill", label: "Perfil")
    ]

    private let sectionTitles = ["Inicio", "Álbum", "Perfil"]

    var body: some View {
        ZStack(alignment: .bottom) {
            GradientBackground(seed: "navigation-\(selection)")
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text(sectionTitles[selection])
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .padding(.top, 60)

                GlassCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ambient tint")
                            .font(.headline)
                        Text("Neither this card nor the tab bar below passes an explicit tint — both inherit the brand teal from .glassThemeTint set once on this screen.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }

            GlassTabBar(items: items, selection: $selection)
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
        }
        // Ambient tint: propagates to GlassTabBar and GlassCard above, since
        // neither passes an explicit `tint:`.
        .glassThemeTint(Color(red: 0.12, green: 0.50, blue: 0.50))
    }
}

// MARK: - MorphingShowcase

/// Demonstrates `GlassEffectContainer` + `.glassMorphID(_:in:)` (a real
/// expand/collapse toggle between two tagged surfaces sharing one
/// `@Namespace`) and `.glassMorphUnion(id:in:style:tint:cornerRadius:)`
/// (a row of toolbar buttons merged into one surface).
struct MorphingShowcase: View {
    @Namespace private var glass
    @State private var expanded = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                killSwitchNote
                expandCollapseSection
                unionSection
            }
            .padding(20)
        }
        .background(Color.black.opacity(0.04).ignoresSafeArea())
    }

    /// Native morphing forwards nowhere yet — see `GlassMaterial.nativeGlassMorphingEnabled`.
    /// Called out on screen (not just in a code comment) so a developer
    /// evaluating the package understands what they're looking at.
    private var killSwitchNote: some View {
        Text("Native morphing is currently behind an internal kill switch pending an Apple fix (a device-only iOS 26.5 rendering-corruption bug). Everything below renders the fallback surface — on every OS, including iOS 26+ — until that flag is re-enabled.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(14)
            .glass(style: .card)
    }

    private var expandCollapseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Expand / collapse morph")
                .font(.headline)
            Text("Tap the surface. A real @State Bool toggles between two .glassMorphID-tagged surfaces sharing one @Namespace, inside a shared GlassEffectContainer.")
                .font(.caption)
                .foregroundStyle(.secondary)

            ZStack {
                GradientBackground(seed: "morph-detail")
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

                GlassEffectContainer {
                    if expanded {
                        detailSurface
                    } else {
                        thumbnailSurface
                    }
                }
                .padding(20)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    expanded.toggle()
                }
            }
        }
    }

    private var thumbnailSurface: some View {
        HStack(spacing: 10) {
            Image(systemName: "photo.fill")
                .font(.title2)
            Text("Tap to expand")
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(.white)
        .padding()
        .glass(style: .card, cornerRadius: 24)
        .glassMorphID("photo", in: glass)
    }

    private var detailSurface: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Synthwave Drive")
                .font(.title2.bold())
            Text("Tap to collapse")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glass(style: .sheet, cornerRadius: 28)
        .glassMorphID("photo", in: glass)
    }

    private var unionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Merged toolbar group")
                .font(.headline)
            Text(".glassMorphUnion groups these three buttons sharing the same id into one continuous surface instead of three separate ones.")
                .font(.caption)
                .foregroundStyle(.secondary)

            ZStack {
                GradientBackground(seed: "morph-union")
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

                GlassEffectContainer(spacing: 8) {
                    HStack(spacing: 4) {
                        ForEach(["backward.fill", "play.fill", "forward.fill"], id: \.self) { symbol in
                            Image(systemName: symbol)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .glassMorphUnion(id: "transport", in: glass, style: .toolbar, tint: .indigo)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - NowPlayingShowcase

/// A realistic composed scenario: a hero background bleeding under the safe
/// area via `.glassBackgroundExtension()`, `GlassTabBar` as the floating
/// host, and `GlassBottomAccessory` docking a toggleable "now playing" pill
/// above it. The toggle is real, interactive `@State` — exactly the
/// `isEnabled` state-preservation scenario the fix earlier in this session
/// targeted: flipping it never resets the tab selection inside `content`.
struct NowPlayingShowcase: View {
    @State private var tab = 0
    @State private var isNowPlayingVisible = false

    private let items = [
        GlassTabItem(icon: "square.grid.2x2.fill", label: "Library"),
        GlassTabItem(icon: "magnifyingglass", label: "Search")
    ]

    private let sectionTitles = ["Library", "Search"]

    var body: some View {
        // `.customTabBar` — GlassTabBar below is not a real TabView, so this
        // always renders the fallback pill via safeAreaInset, on every OS.
        GlassBottomAccessory(host: .customTabBar, isEnabled: isNowPlayingVisible, tint: .indigo) {
            ZStack(alignment: .bottom) {
                GradientBackground(seed: "now-playing-hero")
                    .glassBackgroundExtension()
                    .overlay(alignment: .top) {
                        heroContent
                    }

                GlassTabBar(items: items, selection: $tab)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
            }
        } accessory: {
            nowPlayingPill
        }
    }

    private var heroContent: some View {
        VStack(spacing: 16) {
            Text(sectionTitles[tab])
                .font(.title2.bold())
                .foregroundStyle(.white)
                .padding(.top, 80)

            Text("Toggling below flips GlassBottomAccessory's isEnabled. content is wrapped by the same modifier structure either way, so the tab selection above is never reset.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            GlassButton(action: { isNowPlayingVisible.toggle() }) {
                Label(
                    isNowPlayingVisible ? "Hide Now Playing" : "Show Now Playing",
                    systemImage: isNowPlayingVisible ? "eye.slash" : "play.circle.fill"
                )
            }
        }
    }

    private var nowPlayingPill: some View {
        HStack(spacing: 10) {
            Image(systemName: "waveform")
            VStack(alignment: .leading, spacing: 1) {
                Text("Synthwave Drive")
                    .font(.subheadline.weight(.semibold))
                Text("Neon Skyline")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                isNowPlayingVisible = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
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

#Preview("Navigation tab") {
    NavigationShowcase()
}

#Preview("Morphing tab") {
    MorphingShowcase()
}

#Preview("Now Playing tab") {
    NowPlayingShowcase()
}
