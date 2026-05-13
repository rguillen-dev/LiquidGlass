//
//  GlassStyleTests.swift
//  LiquidGlass
//
//  Created by Ricardo Guillen on 05/13/26.
//  Copyright © 2026 Ricardo Guillen. All rights reserved.
//

import Testing
import SwiftUI
@testable import LiquidGlass

@Suite("GlassStyle defaults")
struct GlassStyleDefaultsTests {

    @Test("Each style exposes its documented default corner radius")
    func defaultCornerRadii() {
        #expect(GlassStyle.sheet.defaultCornerRadius == 24)
        #expect(GlassStyle.card.defaultCornerRadius == 16)
        #expect(GlassStyle.button.defaultCornerRadius == 12)
        #expect(GlassStyle.toolbar.defaultCornerRadius == 10)
        #expect(GlassStyle.sidebar.defaultCornerRadius == 20)
        #expect(GlassStyle.overlay.defaultCornerRadius == 0)
    }

    @Test("Every case has a non-negative corner radius")
    func cornerRadiiNonNegative() {
        for style in GlassStyle.allCases {
            #expect(style.defaultCornerRadius >= 0)
        }
    }

    @Test("All six documented styles are present in allCases")
    func allCasesCovered() {
        #expect(GlassStyle.allCases.count == 6)
        let expected: Set<GlassStyle> = [.sheet, .card, .button, .toolbar, .sidebar, .overlay]
        #expect(Set(GlassStyle.allCases) == expected)
    }
}
