//
//  GlassModifierTests.swift
//  LiquidGlass
//
//  Created by Ricardo Guillen on 05/13/26.
//  Copyright © 2026 Ricardo Guillen. All rights reserved.
//

import Testing
import SwiftUI
@testable import LiquidGlass

@Suite("GlassModifier configuration")
struct GlassModifierConfigurationTests {

    @Test("A nil tint and a set tint produce different configurations")
    func tintNilVersusSet() {
        let untinted = GlassModifier(style: .card, tint: nil, cornerRadius: nil)
        let tinted = GlassModifier(style: .card, tint: .blue, cornerRadius: nil)

        #expect(untinted.tint == nil)
        #expect(tinted.tint == .blue)
        #expect(untinted.tint != tinted.tint)
    }

    @Test("An explicit corner radius overrides the style default")
    func explicitCornerRadiusOverride() {
        let custom = GlassModifier(style: .card, tint: nil, cornerRadius: 42)
        #expect(custom.cornerRadius == 42)

        let defaulted = GlassModifier(style: .card, tint: nil, cornerRadius: nil)
        #expect(defaulted.cornerRadius == nil)
    }

    @Test("The modifier preserves the style it is created with")
    func stylePreserved() {
        for style in GlassStyle.allCases {
            let modifier = GlassModifier(style: style, tint: nil, cornerRadius: nil)
            #expect(modifier.style == style)
        }
    }
}

@Suite("GlassMaterial fallback parameters")
struct GlassMaterialFallbackTests {

    @Test("Every style produces a non-negative shadow radius")
    func shadowRadiiNonNegative() {
        for style in GlassStyle.allCases {
            let material = GlassMaterial(style: style)
            #expect(material.fallbackShadowRadius >= 0)
        }
    }

    @Test("Every style produces a border opacity in 0…1")
    func borderOpacityInRange() {
        for style in GlassStyle.allCases {
            let material = GlassMaterial(style: style)
            #expect(material.fallbackBorderOpacity >= 0)
            #expect(material.fallbackBorderOpacity <= 1)
        }
    }

    @Test("Every style produces a shadow opacity in 0…1")
    func shadowOpacityInRange() {
        for style in GlassStyle.allCases {
            let material = GlassMaterial(style: style)
            #expect(material.fallbackShadowOpacity >= 0)
            #expect(material.fallbackShadowOpacity <= 1)
        }
    }

    @Test("Every style produces a tint opacity in 0…1")
    func tintOpacityInRange() {
        for style in GlassStyle.allCases {
            let material = GlassMaterial(style: style)
            #expect(material.tintOpacity >= 0)
            #expect(material.tintOpacity <= 1)
        }
    }
}
