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
/// On iOS 26 and later this wraps the system `GlassEffectContainer`. On
/// iOS 17–25 it renders its content directly — the morph degrades to whatever
/// transition the views already use (typically a cross-fade), which is an
/// acceptable downgrade.
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
    ///     into one another on iOS 26. Ignored on the fallback path.
    ///   - content: The views that participate in glass morphing.
    public init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, macOS 26.0, *) {
            SwiftUI.GlassEffectContainer(spacing: spacing) {
                content
            }
        } else {
            content
        }
        #else
        content
        #endif
    }
}

public extension View {

    /// Associates this glass surface with an identity used for morph
    /// transitions inside a ``GlassEffectContainer``.
    ///
    /// On iOS 26 and later this forwards to the system `glassEffectID(_:in:)`.
    /// On iOS 17–25 it is a no-op and returns the view unchanged.
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
        if #available(iOS 26.0, macOS 26.0, *) {
            glassEffectID(id, in: namespace)
        } else {
            self
        }
        #else
        self
        #endif
    }
}
