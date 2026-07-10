//
//  GlassBottomAccessory.swift
//  LiquidGlass
//
//  Created by Ricardo Guillen on 07/09/26.
//  Copyright © 2026 Ricardo Guillen. All rights reserved.
//

import SwiftUI

/// What ``GlassBottomAccessory`` is docking its accessory content above.
///
/// The system `tabViewBottomAccessory` slot only exists on a real `TabView`.
/// This package's ``GlassTabBar`` is a floating component, not a `TabView`, so
/// there's nothing for the system slot to attach to when it's in use — this
/// tells ``GlassBottomAccessory`` which case it's in.
public enum GlassBottomAccessoryHost: Sendable, Hashable, CaseIterable {

    /// `content` contains (or is) a real `TabView`. Forwards to the system
    /// `tabViewBottomAccessory` slot on iOS 26+; iOS 17–18 and non-iOS
    /// platforms use the fallback pill via `safeAreaInset(edge: .bottom)`,
    /// which docks correctly just above the `TabView`'s own tab bar.
    case tabView

    /// `content` is a custom floating tab bar such as ``GlassTabBar`` — not a
    /// real `TabView`. There is no system accessory slot to attach to on any
    /// OS version, so this always renders the fallback pill, including on
    /// iOS 26+.
    case customTabBar
}

/// A persistent glass control docked above a tab bar — the "now playing pill"
/// pattern used across real apps for content that should survive navigation
/// between tabs.
///
/// Wraps `tabViewBottomAccessory` on iOS 26+. iOS 17–18 have no accessory slot
/// on `TabView` at all, so the fallback renders its own floating glass pill.
/// Because this package doesn't own the tab bar in the general case, tell it
/// what it's docking above with ``GlassBottomAccessoryHost``:
///
/// ```swift
/// // A real SwiftUI TabView — natively hosts the accessory on iOS 26+.
/// GlassBottomAccessory(tint: .indigo) {
///     TabView {
///         Tab("Library", systemImage: "books.vertical") { LibraryView() }
///         Tab("Search", systemImage: "magnifyingglass") { SearchView() }
///     }
/// } accessory: {
///     NowPlayingPill(track: player.currentTrack)
/// }
///
/// // A GlassTabBar — not a real TabView, so this always renders the
/// // fallback pill, even on iOS 26+.
/// GlassBottomAccessory(host: .customTabBar, tint: .indigo) {
///     ZStack(alignment: .bottom) {
///         content
///         GlassTabBar(items: tabs, selection: $tab)
///             .padding(.horizontal, 16)
///             .padding(.bottom, 12)
///     }
/// } accessory: {
///     NowPlayingPill(track: player.currentTrack)
/// }
/// ```
///
/// Inside `accessory`, read `@Environment(\.tabViewBottomAccessoryPlacement)`
/// (system-provided, `.inline` or `.expanded`) to adapt layout on iOS 26+; the
/// fallback pill has no separate placement state, so this reads `nil` there.
///
/// > Important: the fallback pill wraps its own `.glass(...)` surface in its
/// > own ``GlassEffectContainer`` (per this package's rule that glass can't
/// > sample glass without a shared container). It does **not**, and cannot,
/// > share that container with whatever glass surfaces live inside `content`
/// > — e.g. a ``GlassTabBar`` composed via `.customTabBar` — because this
/// > type has no visibility into `content`'s view tree. Each surface gets its
/// > own container rather than true shared sampling; on iOS 17–18's
/// > `Material`-based fallback this is a known constraint with no visible
/// > cost, but it's a real limitation to keep in mind if this component's
/// > native path is ever extended to render its own glass directly.
public struct GlassBottomAccessory<Content: View, Accessory: View>: View {

    let host: GlassBottomAccessoryHost
    let isEnabled: Bool
    let tint: Color?
    private let content: Content
    private let accessory: Accessory

    @Environment(\.glassTint) private var environmentTint
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Creates a bottom accessory.
    ///
    /// - Parameters:
    ///   - host: What the accessory is docking above. Defaults to ``GlassBottomAccessoryHost/tabView``.
    ///   - isEnabled: Whether the accessory is shown. Defaults to `true`; pass
    ///     `false` to hide it without removing the modifier. `content` is
    ///     wrapped by the exact same modifier structure on every render
    ///     regardless of `isEnabled` — only the accessory subtree itself
    ///     conditionally appears/disappears — so toggling this at runtime
    ///     never tears down and rebuilds `content` (which would otherwise
    ///     lose `@State`, `TabView` selection, navigation stack, and scroll
    ///     position inside it).
    ///   - tint: Optional color applied to the accessory's fallback surface
    ///     (and propagated to it via ``EnvironmentValues/glassTint`` on every
    ///     path). Falls back to the ambient ``EnvironmentValues/glassTint``.
    ///   - content: The screen content — typically a `TabView`, or a `ZStack`
    ///     that layers ``GlassTabBar`` over the screen's content.
    ///   - accessory: The persistent accessory content, e.g. a "now playing" pill.
    public init(
        host: GlassBottomAccessoryHost = .tabView,
        isEnabled: Bool = true,
        tint: Color? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.host = host
        self.isEnabled = isEnabled
        self.tint = tint
        self.content = content()
        self.accessory = accessory()
    }

    private var resolvedTint: Color? { tint ?? environmentTint }

    public var body: some View {
        switch host {
        case .tabView:
            tabViewBody
        case .customTabBar:
            // No system TabView to attach to on any OS version — always the
            // fallback pill.
            fallbackBody
        }
    }

    @ViewBuilder
    private var tabViewBody: some View {
        // `tabViewBottomAccessory` is iOS-only (unavailable on macOS, tvOS,
        // watchOS, visionOS) — a real constraint of the system API, not this
        // package's usual two-axis guard, so this file adds the platform check
        // on top of it. Still fully contained to this thin wrapper file per
        // this package's rule that availability branching stays out of
        // unrelated files.
        #if compiler(>=6.2) && os(iOS)
        if #available(iOS 26.1, *) {
            // `isEnabled:` overload ships in iOS 26.1, one point release after
            // the base `tabViewBottomAccessory(content:)` (iOS 26.0) —
            // confirmed against the live iOS 26.4 SDK symbol index, since our
            // reference doc didn't have the split. The system parameter
            // itself is the correct off-switch here — it hides the accessory
            // without this package needing to branch `content`'s modifier
            // structure at all.
            content.tabViewBottomAccessory(isEnabled: isEnabled) { accessoryContent }
        } else if #available(iOS 26.0, *) {
            // No `isEnabled:` parameter yet on iOS 26.0, so this package must
            // gate manually. `content` is wrapped by `.tabViewBottomAccessory`
            // unconditionally on every render; only the *closure's* content
            // branches on `isEnabled`, so `content` itself never changes
            // structural identity when `isEnabled` toggles (see this type's
            // `isEnabled` doc comment — the same identity-preservation
            // requirement as the fallback path below).
            //
            // Unverified on-device (no iOS 26 simulator in this environment):
            // whether an `EmptyView()` accessory closure fully collapses the
            // system's accessory slot or leaves a visible empty
            // system-styled bar. If the latter, this branch needs a
            // different disabled-state treatment once verified — flagged
            // here rather than asserted as correct.
            content.tabViewBottomAccessory {
                if isEnabled {
                    accessoryContent
                } else {
                    EmptyView()
                }
            }
        } else {
            fallbackBody
        }
        #else
        fallbackBody
        #endif
    }

    /// The accessory content on the native path: no extra glass wrapper (the
    /// system already renders `tabViewBottomAccessory` content with glass
    /// chrome automatically — wrapping it again would be glass sampling
    /// glass), just the tint propagated for anything nested inside that reads
    /// it.
    private var accessoryContent: some View {
        accessory
            .glassThemeTint(resolvedTint)
            .tint(resolvedTint)
    }

    /// `content` gets the exact same `.safeAreaInset` structure on every
    /// render, regardless of `isEnabled` — only the inset's *closure content*
    /// (a different subtree) branches on `isEnabled`, so SwiftUI diffs that
    /// inner appear/disappear as a transition instead of tearing down and
    /// rebuilding `content` itself. `spacing` collapses to `0` when disabled
    /// so no dead gap is reserved at the bottom once the pill is hidden.
    private var fallbackBody: some View {
        content
            .safeAreaInset(edge: .bottom, spacing: isEnabled ? 8 : 0) {
                Group {
                    if isEnabled {
                        // Own `GlassEffectContainer` for this fallback pill's
                        // `.glass(...)` surface — see this type's doc comment
                        // for why this can't literally share a container with
                        // whatever glass surface `content` renders (e.g. a
                        // `GlassTabBar` in `.customTabBar` mode): this wrapper
                        // has no visibility into `content`'s view tree.
                        GlassEffectContainer {
                            accessory
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .glass(style: .toolbar, tint: resolvedTint, cornerRadius: 24)
                        }
                        .padding(.horizontal, 12)
                        .transition(reduceMotion ? .identity : .move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.82), value: isEnabled)
    }
}

// MARK: - Previews

#Preview("Bottom accessory — plain TabView") {
    GlassBottomAccessory(tint: .indigo) {
        TabView {
            ZStack {
                LinearGradient(
                    colors: [.indigo, .mint],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                Text("Library")
                    .font(.title.bold())
                    .foregroundStyle(.white)
            }
            .tabItem { Label("Library", systemImage: "books.vertical") }

            ZStack {
                LinearGradient(
                    colors: [.orange, .pink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                Text("Search")
                    .font(.title.bold())
                    .foregroundStyle(.white)
            }
            .tabItem { Label("Search", systemImage: "magnifyingglass") }
        }
    } accessory: {
        Label("Synthwave Drive", systemImage: "play.fill")
            .font(.subheadline.weight(.semibold))
    }
}

#Preview("Bottom accessory — GlassTabBar") {
    GlassBottomAccessory(host: .customTabBar, tint: .teal) {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [.purple, .blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            GlassTabBar(
                items: [
                    GlassTabItem(icon: "house.fill", label: "Inicio"),
                    GlassTabItem(icon: "person.fill", label: "Perfil")
                ],
                selection: .constant(0)
            )
            .padding(.horizontal, 40)
            .padding(.bottom, 12)
        }
    } accessory: {
        Label("Synthwave Drive", systemImage: "play.fill")
            .font(.subheadline.weight(.semibold))
    }
}

// The system Reduce Motion key is read-only and can't be forced through
// `.environment(...)`, so previews for it live at the fallback-pill level in
// GlassButton.swift-style internal seams elsewhere. This preview instead shows
// the `isEnabled: false` state, which any accessibility setting still degrades
// correctly (no accessory, no floating pill).
#Preview("Bottom accessory — disabled") {
    GlassBottomAccessory(host: .customTabBar, isEnabled: false, tint: .teal) {
        ZStack(alignment: .bottom) {
            Color(white: 0.92).ignoresSafeArea()
            GlassTabBar(
                items: [GlassTabItem(icon: "house.fill", label: "Inicio")],
                selection: .constant(0)
            )
            .padding(.horizontal, 80)
            .padding(.bottom, 12)
        }
    } accessory: {
        Text("Hidden")
    }
}
