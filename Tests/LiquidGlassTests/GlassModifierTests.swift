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

    @Test("Reduce Transparency keeps border opacity in 0…1 and at least the base")
    func reduceTransparencyBorderOpacityInRange() {
        for style in GlassStyle.allCases {
            let material = GlassMaterial(style: style)
            let raised = material.borderOpacity(reduceTransparency: true)
            #expect(raised >= 0)
            #expect(raised <= 1)
            #expect(raised >= material.fallbackBorderOpacity)
        }
    }

    @Test("Reduce Transparency raises border contrast for styles below full opacity")
    func reduceTransparencyRaisesContrast() {
        for style in GlassStyle.allCases {
            let material = GlassMaterial(style: style)
            guard material.fallbackBorderOpacity < 1 else { continue }
            #expect(material.borderOpacity(reduceTransparency: true) > material.fallbackBorderOpacity)
        }
    }

    @Test("Without Reduce Transparency the border opacity equals the base")
    func borderOpacityMatchesBaseWhenDisabled() {
        for style in GlassStyle.allCases {
            let material = GlassMaterial(style: style)
            #expect(material.borderOpacity(reduceTransparency: false) == material.fallbackBorderOpacity)
        }
    }

    @Test("Border opacity clamps at 1.0 when the boost would overflow")
    func borderOpacityClampPath() {
        // boost: 2.0 guarantees fallbackBorderOpacity + boost > 1 for every
        // style (max base is 0.20), so the min(…, 1.0) clamp is always exercised.
        for style in GlassStyle.allCases {
            let material = GlassMaterial(style: style)
            let clamped = material.borderOpacity(reduceTransparency: true, boost: 2.0)
            #expect(clamped == 1.0)
        }
    }

    @Test("Contrast defaults to .standard, matching the pre-Increased-Contrast behavior")
    func contrastDefaultsToStandard() {
        for style in GlassStyle.allCases {
            let material = GlassMaterial(style: style)
            let implicit = material.borderOpacity(reduceTransparency: false)
            let explicit = material.borderOpacity(reduceTransparency: false, contrast: .standard)
            #expect(implicit == explicit)
        }
    }

    @Test("Increased Contrast raises border opacity independently of Reduce Transparency")
    func increasedContrastRaisesBorderOpacityAlone() {
        for style in GlassStyle.allCases {
            let material = GlassMaterial(style: style)
            let standard = material.borderOpacity(reduceTransparency: false, contrast: .standard)
            let increased = material.borderOpacity(reduceTransparency: false, contrast: .increased)
            #expect(standard == material.fallbackBorderOpacity)
            #expect(increased > standard)
            #expect(increased <= 1)
        }
    }

    @Test("Reduce Transparency and Increased Contrast combine, clamped to 1.0")
    func combinedReduceTransparencyAndIncreasedContrastClamped() {
        for style in GlassStyle.allCases {
            let material = GlassMaterial(style: style)
            let reduceTransparencyOnly = material.borderOpacity(reduceTransparency: true, contrast: .standard)
            let increasedContrastOnly = material.borderOpacity(reduceTransparency: false, contrast: .increased)
            let combined = material.borderOpacity(reduceTransparency: true, contrast: .increased)

            #expect(combined >= 0)
            #expect(combined <= 1)
            #expect(combined >= reduceTransparencyOnly)
            #expect(combined >= increasedContrastOnly)
        }
    }

    @Test("Increased Contrast doubles the fallback rim's line width")
    func increasedContrastDoublesLineWidth() {
        for style in GlassStyle.allCases {
            let material = GlassMaterial(style: style)
            let standard = material.borderLineWidth(contrast: .standard)
            let increased = material.borderLineWidth(contrast: .increased)
            #expect(increased == standard * 2)
        }
    }

    @Test("Line width is unaffected by which style is used")
    func lineWidthIsStyleAgnostic() {
        let widths = GlassStyle.allCases.map { GlassMaterial(style: $0).borderLineWidth(contrast: .increased) }
        #expect(Set(widths).count == 1)
    }

    @Test("fallbackFill selects the opaque fill under Reduce Transparency and the material otherwise")
    func fallbackFillSelectsByReduceTransparency() {
        // `AnyShapeStyle` isn't Equatable, so this pins the *selection*
        // contract (never crashes / always produces a value) rather than the
        // erased style identity — the actual visual selection is exercised by
        // `GlassRenderingModifier` and `GlassMorphUnionSurfaces`, which both
        // route through this same method.
        for style in GlassStyle.allCases {
            let material = GlassMaterial(style: style)
            _ = material.fallbackFill(reduceTransparency: true)
            _ = material.fallbackFill(reduceTransparency: false)
        }
    }

    @Test("borderColor is white outside Reduce Transparency, regardless of color scheme")
    func borderColorWhiteWithoutReduceTransparency() {
        #expect(GlassMaterial.borderColor(reduceTransparency: false, colorScheme: .light) == .white)
        #expect(GlassMaterial.borderColor(reduceTransparency: false, colorScheme: .dark) == .white)
    }

    @Test("borderColor contrasts against the opaque fill under Reduce Transparency")
    func borderColorContrastsUnderReduceTransparency() {
        #expect(GlassMaterial.borderColor(reduceTransparency: true, colorScheme: .dark) == .white)
        #expect(GlassMaterial.borderColor(reduceTransparency: true, colorScheme: .light) == .black)
    }
}

@Suite("GlassMaterial native morphing kill switch")
struct GlassMaterialNativeMorphingKillSwitchTests {

    @Test("nativeGlassMorphingEnabled defaults to false")
    func defaultsToFalse() {
        // Pinned as a regression test: `GlassEffectContainer`, `glassMorphID`,
        // and `GlassMorphUnionModifier` all gate their native forward on this
        // one flag (see its doc comment for the iOS 26.5 rendering-corruption
        // incident that led to disabling it). Flipping this to `true` without
        // an on-device verification pass would silently re-enable native
        // morphing across all three call sites at once.
        #expect(GlassMaterial.nativeGlassMorphingEnabled == false)
    }
}

@Suite("GlassRenderingModifier accessibility overrides")
struct GlassRenderingModifierAccessibilityTests {

    @Test("forceContrast is preserved as configured")
    func forceContrastPreserved() {
        let unforced = GlassRenderingModifier(style: .card, tint: nil, cornerRadius: 16)
        #expect(unforced.forceContrast == nil)

        let forced = GlassRenderingModifier(
            style: .card,
            tint: nil,
            cornerRadius: 16,
            forceContrast: .increased
        )
        #expect(forced.forceContrast == .increased)
    }

    @Test("forceReduceTransparency and forceContrast are independent overrides")
    func forceOverridesAreIndependent() {
        let combined = GlassRenderingModifier(
            style: .sheet,
            tint: nil,
            cornerRadius: 24,
            forceReduceTransparency: true,
            forceContrast: .increased
        )
        #expect(combined.forceReduceTransparency == true)
        #expect(combined.forceContrast == .increased)
    }
}
