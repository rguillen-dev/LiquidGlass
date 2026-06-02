//
//  GlassTintKey.swift
//  LiquidGlass
//
//  Created by Ricardo Guillen on 06/01/26.
//  Copyright © 2026 Ricardo Guillen. All rights reserved.
//

import SwiftUI

/// Environment key carrying the ambient glass tint.
///
/// When a `.glass(...)` surface is applied without an explicit `tint`, it reads
/// this value from the environment. This lets a theming layer set the tint once
/// near the root instead of threading a color through every call site.
public struct GlassTintKey: EnvironmentKey {
    public static let defaultValue: Color? = nil
}

public extension EnvironmentValues {

    /// The ambient tint applied to descendant glass surfaces that do not set
    /// their own. `nil` (the default) means no ambient tint.
    var glassTint: Color? {
        get { self[GlassTintKey.self] }
        set { self[GlassTintKey.self] = newValue }
    }
}

public extension View {

    /// Sets the ambient ``EnvironmentValues/glassTint`` for this view and its
    /// descendants.
    ///
    /// Any descendant `.glass(...)`, ``GlassCard``, ``GlassButton``, or
    /// ``GlassTabBar`` that does not pass an explicit `tint` picks up this color.
    ///
    /// ```swift
    /// FeedView()
    ///     .glassThemeTint(skin.tint) // one place sets the whole screen's tint
    /// ```
    ///
    /// - Parameter color: The tint to inject, or `nil` to clear it.
    func glassThemeTint(_ color: Color?) -> some View {
        environment(\.glassTint, color)
    }
}
