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
/// > Kill switch: whether this forwards to the system
/// > `SwiftUI.GlassEffectContainer` on iOS 26+ is gated on
/// > `GlassMaterial.nativeGlassMorphingEnabled`, currently `false` — see that
/// > flag's doc comment for the device-only iOS 26.5 rendering-corruption bug
/// > (root-caused from Agenda/agenda-ios) that led to disabling it, and for
/// > why the same flag also gates ``SwiftUI/View/glassMorphID(_:in:)`` and
/// > `glassMorphUnion(id:in:style:tint:cornerRadius:)`. While the flag is
/// > `false`, this type always renders `content` directly (the same degrade
/// > already used for iOS 17–25: morph degrades to whatever transition the
/// > views already use, typically a cross-fade). The native branch below is
/// > still compiled and type-checked against the live SDK — only entry into
/// > it is gated — so re-enabling is "flip the flag" plus an on-device
/// > verification pass.
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
    ///     into one another on iOS 26. Ignored while
    ///     `GlassMaterial.nativeGlassMorphingEnabled` is `false` — see the
    ///     kill-switch note above the type declaration.
    ///   - content: The views that participate in glass morphing.
    public init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        // Kill switch: forwarding to `SwiftUI.GlassEffectContainer` is gated
        // on `GlassMaterial.nativeGlassMorphingEnabled` — see the doc comment
        // above. The native branch is compiled and type-checked continuously;
        // only entry into it is gated, so restoring behavior is "flip the
        // flag", not restoring deleted code.
        #if compiler(>=6.2)
        if #available(iOS 26.0, macOS 26.0, *), GlassMaterial.nativeGlassMorphingEnabled {
            nativeRendering
        } else {
            fallbackRendering
        }
        #else
        fallbackRendering
        #endif
    }

    #if compiler(>=6.2)
    @available(iOS 26.0, macOS 26.0, *)
    private var nativeRendering: some View {
        SwiftUI.GlassEffectContainer(spacing: spacing) {
            content
        }
    }
    #endif

    /// The always-compiled fallback: renders `content` directly (morph
    /// degrades to whatever transition the views already use, typically a
    /// cross-fade) while still hosting `glassMorphUnion`'s iOS 17–18
    /// reduction step.
    ///
    /// `backgroundPreferenceValue` below is unrelated to the kill switch:
    /// it's the reduction step for `glassMorphUnion`'s fallback (see
    /// GlassMorphUnion.swift). It's always attached so a container works as
    /// the union's reduction point on every OS version, but it only draws
    /// anything when a `glassMorphUnion` fallback participant has reported a
    /// frame — while `GlassMaterial.nativeGlassMorphingEnabled` is `true` on
    /// iOS 26+ (where `glassMorphUnion` forwards straight to the system
    /// `glassEffectUnion` instead of reporting a frame), no entries are ever
    /// reported here, so this stays an empty, effectively free no-op. While
    /// the flag is `false` (the current default), this drives the shared
    /// fallback surface on every OS version, including iOS 26.
    private var fallbackRendering: some View {
        content
            .backgroundPreferenceValue(GlassMorphUnionPreferenceKey.self) { entries in
                GlassMorphUnionSurfaces(entries: entries)
            }
    }
}

public extension View {

    /// Associates this glass surface with an identity used for morph
    /// transitions inside a ``GlassEffectContainer``.
    ///
    /// > Kill switch: gated on the same `GlassMaterial.nativeGlassMorphingEnabled`
    /// > flag as ``GlassEffectContainer``'s (see its doc comment) — while the
    /// > flag is `false`, this is a no-op on every OS version, since tagging
    /// > an identity with `glassEffectID` only does anything meaningful inside
    /// > a real `SwiftUI.GlassEffectContainer`, which this package doesn't
    /// > forward to while the flag is off. The native forward below is still
    /// > compiled and type-checked continuously; only entry into it is gated.
    ///
    /// > Note: This is named `glassMorphID` rather than `glassEffectID` so it
    /// > never shadows the system API it forwards to.
    ///
    /// - Parameters:
    ///   - id: A stable identity shared by the surfaces that should morph.
    ///   - namespace: The namespace that scopes the identity, declared with
    ///     `@Namespace`.
    @ViewBuilder
    func glassMorphID(_ id: some Hashable & Sendable, in namespace: Namespace.ID) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, macOS 26.0, *), GlassMaterial.nativeGlassMorphingEnabled {
            glassEffectID(id, in: namespace)
        } else {
            self
        }
        #else
        self
        #endif
    }
}
