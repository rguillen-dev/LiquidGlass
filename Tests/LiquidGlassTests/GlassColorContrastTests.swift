//
//  GlassColorContrastTests.swift
//  LiquidGlass
//
//  Created by Ricardo Guillen on 06/13/26.
//  Copyright © 2026 Ricardo Guillen. All rights reserved.
//

import Testing
import SwiftUI
@testable import LiquidGlass

@Suite("GlassContrast — active foreground derivation")
struct GlassContrastTests {

    /// The brand teal that drives the agenda tab bar (`#1F8080`).
    private let brandTeal = Color(red: 0x1F / 255.0, green: 0x80 / 255.0, blue: 0x80 / 255.0)

    /// Effective surface opacities per render path (see `GlassTabBar`).
    private let nativeOpacity = 0.85
    private let fallbackOpacity = 0.22

    @Test("Contrast ratio is symmetric and bounded to 1...21")
    func contrastRatioBounds() {
        #expect(GlassContrast.contrastRatio(0, 1) == GlassContrast.contrastRatio(1, 0))
        #expect(abs(GlassContrast.contrastRatio(0, 1) - 21) < 0.01)   // black vs white
        #expect(abs(GlassContrast.contrastRatio(0.5, 0.5) - 1) < 0.01) // identical
    }

    @Test("Relative luminance orders black < mid < white")
    func luminanceOrdering() throws {
        let black = try #require(Color.black.glassRelativeLuminance)
        let white = try #require(Color.white.glassRelativeLuminance)
        let teal = try #require(brandTeal.glassRelativeLuminance)
        #expect(black < teal)
        #expect(teal < white)
        #expect(black >= 0 && white <= 1.0001)
    }

    @Test("A saturated tint composites to a darker surface on the native path")
    func nativeSurfaceIsDarker() throws {
        // The native glass tint reads saturated, so the modeled surface is much
        // darker than the pale fallback surface — the bug came from assuming the
        // pale value on the native path.
        let native = try #require(GlassContrast.surfaceLuminance(forTint: brandTeal, surfaceTintOpacity: nativeOpacity))
        let fallback = try #require(GlassContrast.surfaceLuminance(forTint: brandTeal, surfaceTintOpacity: fallbackOpacity))
        #expect(native < fallback)
        #expect(native < 0.35)   // matches the ~0.26 measured on device
        #expect(fallback > 0.7)  // pale
    }

    @Test("Native teal surface yields a white active item (legible + highlighted)")
    func nativeTealYieldsWhite() throws {
        let fg = GlassContrast.activeForeground(for: brandTeal, surfaceTintOpacity: nativeOpacity)
        #expect(fg == .white)

        // White clears large-text AA against the (mid/dark) native surface.
        let surface = try #require(GlassContrast.surfaceLuminance(forTint: brandTeal, surfaceTintOpacity: nativeOpacity))
        #expect(GlassContrast.contrastRatio(surface, 1.0) >= 3.0)
    }

    @Test("Pale fallback surface yields a dark active item")
    func paleFallbackYieldsDark() throws {
        let fg = GlassContrast.activeForeground(for: brandTeal, surfaceTintOpacity: fallbackOpacity)
        #expect(fg != .white) // near-black

        // The near-black clears AA against the pale fallback surface.
        let surface = try #require(GlassContrast.surfaceLuminance(forTint: brandTeal, surfaceTintOpacity: fallbackOpacity))
        let darkLuminance = try #require(Color(white: 0.12).glassRelativeLuminance)
        #expect(GlassContrast.contrastRatio(surface, darkLuminance) >= 4.5)
    }

    @Test("A light tint yields a dark active item")
    func lightTintYieldsDark() {
        // Amber/yellow surfaces are too light for white, so the derivation must
        // pick the dark foreground.
        let amber = Color(red: 0xD9 / 255.0, green: 0x77 / 255.0, blue: 0x06 / 255.0)
        let fg = GlassContrast.activeForeground(for: amber, surfaceTintOpacity: nativeOpacity)
        #expect(fg != .white)
    }
}
