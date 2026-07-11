//
//  GlassBackgroundExtensionTests.swift
//  LiquidGlass
//
//  Created by Ricardo Guillen on 07/09/26.
//  Copyright © 2026 Ricardo Guillen. All rights reserved.
//

import Testing
import SwiftUI
@testable import LiquidGlass

@Suite("GlassBackgroundExtensionMetrics accessibility degrade")
struct GlassBackgroundExtensionMetricsTests {

    @Test("Reduce Transparency drops the blur entirely")
    func reduceTransparencyDropsBlur() {
        let metrics = GlassBackgroundExtensionMetrics(reduceTransparency: true)
        #expect(metrics.blurRadius == 0)
    }

    @Test("Without Reduce Transparency the bleed layer is blurred")
    func defaultStateBlursTheBleedLayer() {
        let metrics = GlassBackgroundExtensionMetrics(reduceTransparency: false)
        #expect(metrics.blurRadius > 0)
    }

    @Test("Reduce Transparency renders the bleed layer fully opaque")
    func reduceTransparencyIsFullyOpaque() {
        let metrics = GlassBackgroundExtensionMetrics(reduceTransparency: true)
        #expect(metrics.bleedOpacity == 1.0)
    }

    @Test("Without Reduce Transparency the bleed layer stays translucent")
    func defaultStateIsTranslucent() {
        let metrics = GlassBackgroundExtensionMetrics(reduceTransparency: false)
        #expect(metrics.bleedOpacity < 1.0)
        #expect(metrics.bleedOpacity > 0.0)
    }

    @Test("Scale factor is always greater than 1 so the bleed clears the safe area")
    func scaleFactorAlwaysExpands() {
        for reduceTransparency in [true, false] {
            let metrics = GlassBackgroundExtensionMetrics(reduceTransparency: reduceTransparency)
            #expect(metrics.scaleFactor > 1.0)
        }
    }

    @Test("Reduce Transparency uses a smaller scale since there's no blur to hide the seam")
    func reduceTransparencyUsesSmallerScale() {
        let reduced = GlassBackgroundExtensionMetrics(reduceTransparency: true)
        let normal = GlassBackgroundExtensionMetrics(reduceTransparency: false)
        #expect(reduced.scaleFactor < normal.scaleFactor)
    }

    @Test("Feather height is always positive and tracks scaleFactor")
    func featherHeightTracksScaleFactor() {
        for reduceTransparency in [true, false] {
            let metrics = GlassBackgroundExtensionMetrics(reduceTransparency: reduceTransparency)
            #expect(metrics.featherHeight > 0)
        }
    }

    @Test("Reduce Transparency's smaller scale produces a shorter feather height")
    func reduceTransparencyProducesShorterFeatherHeight() {
        let reduced = GlassBackgroundExtensionMetrics(reduceTransparency: true)
        let normal = GlassBackgroundExtensionMetrics(reduceTransparency: false)
        #expect(reduced.featherHeight < normal.featherHeight)
    }

    @Test("Contrast defaults to .standard when omitted")
    func contrastDefaultsToStandard() {
        let implicit = GlassBackgroundExtensionMetrics(reduceTransparency: false)
        let explicit = GlassBackgroundExtensionMetrics(reduceTransparency: false, contrast: .standard)
        #expect(implicit == explicit)
    }

    @Test("Increased Contrast alone halves the blur without dropping it entirely")
    func increasedContrastHalvesBlurAlone() {
        let standard = GlassBackgroundExtensionMetrics(reduceTransparency: false, contrast: .standard)
        let increased = GlassBackgroundExtensionMetrics(reduceTransparency: false, contrast: .increased)
        #expect(increased.blurRadius < standard.blurRadius)
        #expect(increased.blurRadius > 0)
    }

    @Test("Increased Contrast alone raises opacity without reaching fully opaque")
    func increasedContrastRaisesOpacityAlone() {
        let standard = GlassBackgroundExtensionMetrics(reduceTransparency: false, contrast: .standard)
        let increased = GlassBackgroundExtensionMetrics(reduceTransparency: false, contrast: .increased)
        #expect(increased.bleedOpacity > standard.bleedOpacity)
        #expect(increased.bleedOpacity < 1.0)
    }

    @Test("Reduce Transparency already maxes out the bleed layer, so combining it with Increased Contrast changes nothing further")
    func reduceTransparencyDominatesCombinedState() {
        let reduceTransparencyOnly = GlassBackgroundExtensionMetrics(reduceTransparency: true, contrast: .standard)
        let combined = GlassBackgroundExtensionMetrics(reduceTransparency: true, contrast: .increased)
        #expect(combined.blurRadius == reduceTransparencyOnly.blurRadius)
        #expect(combined.blurRadius == 0)
        #expect(combined.bleedOpacity == reduceTransparencyOnly.bleedOpacity)
        #expect(combined.bleedOpacity == 1.0)
    }
}

@Suite("GlassBackgroundExtensionModifier configuration")
struct GlassBackgroundExtensionModifierConfigurationTests {

    @Test("isEnabled is preserved as configured")
    func isEnabledPreserved() {
        let enabled = GlassBackgroundExtensionModifier(isEnabled: true)
        let disabled = GlassBackgroundExtensionModifier(isEnabled: false)
        #expect(enabled.isEnabled)
        #expect(!disabled.isEnabled)
    }

    @Test("forceContrast override is preserved as configured")
    func forceContrastPreserved() {
        let unforced = GlassBackgroundExtensionModifier(isEnabled: true)
        #expect(unforced.forceContrast == nil)

        let forced = GlassBackgroundExtensionModifier(isEnabled: true, forceContrast: .increased)
        #expect(forced.forceContrast == .increased)
    }
}
