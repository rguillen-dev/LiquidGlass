//
//  GlassEffectContainer.swift
//  LiquidGlass
//
//  Created by Ricardo Guillen on 06/01/26.
//  Copyright © 2026 Ricardo Guillen. All rights reserved.
//

import SwiftUI

/// A container that coordinates Liquid Glass morph transitions between the
/// glass surfaces it contains.
///
/// Tag the surfaces you want to morph between with
/// ``SwiftUI/View/glassMorphID(_:in:)`` using a shared `Namespace.ID`. When a
/// tagged surface appears or disappears inside the same container, iOS 26
/// fluidly merges or splits the glass instead of cross-fading.
///
/// > Kill switch (2026-07-01): the system `SwiftUI.GlassEffectContainer`
/// > forward is disabled on **all** OS versions, including iOS 26, pending an
/// > Apple fix. Root-caused from Agenda (agenda-ios): the container was
/// > present on two unrelated screens (a feed list behind a floating
/// > `GlassTabBar`, and a card-detail hero) that both exhibited iOS 26.5
/// > device-only rendering corruption — sibling content (feed row colors /
/// > detail info-panel text) tiled into a mosaic and clipped at the screen
/// > edges, reproducing even before any navigation/transition fired. This
/// > matches the container's *own* prior incident (doc'd at the call site in
/// > CardDetailView — "collides and blanks the destination"), so rather than
/// > patch each call site, this type now always renders `content` directly
/// > (the same degrade already used for iOS 17–25: morph degrades to
/// > whatever transition the views already use, typically a cross-fade).
/// > Re-enable the iOS 26 branch below once Apple ships a fix and it's been
/// > verified on-device.
///
/// ```swift
/// @Namespace private var glass
///
/// GlassEffectContainer {
///     if expanded {
///         DetailSurface().glassMorphID("photo", in: glass)
///     } else {
///         ThumbnailSurface().glassMorphID("photo", in: glass)
///     }
/// }
/// ```
public struct GlassEffectContainer<Content: View>: View {

    private let spacing: CGFloat?
    private let content: Content

    /// Creates a glass effect container.
    ///
    /// - Parameters:
    ///   - spacing: The distance within which adjacent glass surfaces merge
    ///     into one another on iOS 26. Currently ignored — see the kill-switch
    ///     note above the type declaration.
    ///   - content: The views that participate in glass morphing.
    public init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        // Kill switch: do NOT forward to `SwiftUI.GlassEffectContainer` on any
        // OS version right now — see the doc comment above. Restore the
        // `#if compiler(>=6.2) / #available(iOS 26.0, ...)` branch once Apple's
        // implementation is verified stable on-device.
        content
    }
}

public extension View {

    /// Associates this glass surface with an identity used for morph
    /// transitions inside a ``GlassEffectContainer``.
    ///
    /// > Kill switch (2026-07-01): this is a no-op on **all** OS versions right
    /// > now, matching ``GlassEffectContainer``'s kill switch (see its doc
    /// > comment). Tagging an identity with `glassEffectID` only does anything
    /// > meaningful inside a real `SwiftUI.GlassEffectContainer`, which this
    /// > package no longer forwards to — so forwarding here would be dead code
    /// > at best and, per the iOS 26 rendering corruption this was root-caused
    /// > to, a live hazard at worst. Restore together with the container's
    /// > iOS 26 branch once Apple's implementation is verified stable.
    ///
    /// > Note: This is named `glassMorphID` rather than `glassEffectID` so it
    /// > never shadows the system API it would forward to.
    ///
    /// - Parameters:
    ///   - id: A stable identity shared by the surfaces that should morph.
    ///   - namespace: The namespace that scopes the identity, declared with
    ///     `@Namespace`.
    @ViewBuilder
    func glassMorphID(_ id: some Hashable & Sendable, in namespace: Namespace.ID) -> some View {
        self
    }
}
