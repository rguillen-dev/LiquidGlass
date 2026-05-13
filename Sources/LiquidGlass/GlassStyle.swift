//
//  GlassStyle.swift
//  LiquidGlass
//
//  Created by Ricardo Guillen on 05/13/26.
//  Copyright © 2026 Ricardo Guillen. All rights reserved.
//

import SwiftUI

/// The visual variant of the Liquid Glass material.
///
/// Each case represents a distinct UI role and controls the underlying
/// material thickness, default corner radius, and (on the fallback path)
/// the strength of the depth shadow.
///
/// ```swift
/// Text("Hello")
///     .padding()
///     .glass(style: .card)
/// ```
public enum GlassStyle: Sendable, Hashable, CaseIterable {

    /// Floating panel with prominent depth. Use for modal sheets.
    case sheet

    /// Contained surface with medium depth. The default for grouped content.
    case card

    /// Compact surface tuned for interactive controls.
    case button

    /// Inline element for toolbars and navigation chrome.
    case toolbar

    /// Full-height navigation surface with a thicker material.
    case sidebar

    /// Full-coverage overlay with maximum blur. Use behind alerts and modals.
    case overlay

    /// The default corner radius applied when the caller does not provide one.
    public var defaultCornerRadius: CGFloat {
        switch self {
        case .sheet:    return 24
        case .card:     return 16
        case .button:   return 12
        case .toolbar:  return 10
        case .sidebar:  return 20
        case .overlay:  return 0
        }
    }
}
